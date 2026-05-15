import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import '../models/content_block.dart';
import '../providers/reading_provider.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

typedef WordTapCallback = void Function(String word, String contextText);

List<String> splitIntoParagraphs(String text) {
  final paragraphs = <String>[];
  final blocks = text.split(RegExp(r'\n\s*\n'));
  for (final block in blocks) {
    final trimmed = block.trim();
    if (trimmed.isEmpty) continue;

    if (trimmed.length > 2000) {
      final sentences = trimmed.split(RegExp(r'(?<=[.!?])\s+'));
      var chunk = '';
      for (final sentence in sentences) {
        if (chunk.length + sentence.length > 2000 && chunk.isNotEmpty) {
          paragraphs.add(chunk.trim());
          chunk = sentence;
        } else {
          chunk += (chunk.isEmpty ? '' : ' ') + sentence;
        }
      }
      if (chunk.trim().isNotEmpty) {
        paragraphs.add(chunk.trim());
      }
    } else {
      paragraphs.add(trimmed);
    }
  }
  if (paragraphs.isEmpty) {
    paragraphs.add(text.trim());
  }
  return paragraphs;
}

Widget buildWordTapable({
  required String word,
  required Color color,
  required TextStyle textStyle,
  required WordTapCallback onWordTapped,
  required String contextText,
}) {
  return GestureDetector(
    onTap: () => onWordTapped(word, contextText),
    child: Text(
      word,
      style: textStyle.copyWith(
        fontWeight: FontWeight.w600,
        color: color,
        decoration: TextDecoration.underline,
        decorationColor: color.withValues(alpha: 0.5),
      ),
    ),
  );
}

InlineSpan buildHighlightedText(
  AnalysisResult result,
  ThemeData theme, {
  required WordTapCallback onWordTapped,
  double fontSize = 16.0,
  double lineHeight = 2.0,
  String fontFamily = 'Serif',
  VocabularyColorSettings? colorSettings,
}) {
  return _HighlightBuilder(
    result,
    theme,
    onWordTapped,
    fontSize,
    lineHeight,
    fontFamily,
    colorSettings,
  ).build();
}

InlineSpan buildHighlightedParagraph(
  String paragraph,
  AnalysisResult result,
  ThemeData theme, {
  required WordTapCallback onWordTapped,
  double fontSize = 16.0,
  double lineHeight = 2.0,
  String fontFamily = 'Serif',
  VocabularyColorSettings? colorSettings,
}) {
  return _HighlightBuilder(
    result,
    theme,
    onWordTapped,
    fontSize,
    lineHeight,
    fontFamily,
    colorSettings,
  ).buildParagraph(paragraph);
}

InlineSpan buildStyledBlock(
  TextBlock block,
  AnalysisResult result,
  ThemeData theme, {
  required WordTapCallback onWordTapped,
  double fontSize = 16.0,
  double lineHeight = 2.0,
  String fontFamily = 'Serif',
  VocabularyColorSettings? colorSettings,
}) {
  return _StyledBlockBuilder(
    block,
    result,
    theme,
    onWordTapped,
    fontSize,
    lineHeight,
    fontFamily,
    colorSettings,
  ).build();
}

Widget buildBlockWidget(
  ContentBlock block,
  AnalysisResult result,
  ThemeData theme, {
  required WordTapCallback onWordTapped,
  void Function(String)? onParagraphLongPress,
  double fontSize = 16.0,
  double lineHeight = 2.0,
  String fontFamily = 'Serif',
  VocabularyColorSettings? colorSettings,
}) {
  switch (block) {
    case TextBlock():
      final effectiveFontSize = switch (block.type) {
        BlockType.heading => switch (block.headingLevel) {
          1 => fontSize * 1.5,
          2 => fontSize * 1.3,
          3 => fontSize * 1.15,
          _ => fontSize * 1.1,
        },
        _ => fontSize,
      };

      final span = buildStyledBlock(
        block,
        result,
        theme,
        onWordTapped: onWordTapped,
        fontSize: effectiveFontSize,
        lineHeight: lineHeight,
        fontFamily: fontFamily,
        colorSettings: colorSettings,
      );

      final richText = Text.rich(
        span as TextSpan,
        style: theme.textTheme.bodyLarge?.copyWith(
          height: lineHeight,
          letterSpacing: 0.3,
          fontFamily: fontFamily,
          fontSize: effectiveFontSize,
          fontWeight: block.type == BlockType.heading ? FontWeight.bold : null,
        ),
      );

      Widget textWidget = onParagraphLongPress == null
          ? richText
          : GestureDetector(
              onLongPress: () => onParagraphLongPress(block.plainText),
              child: richText,
            );

      final padding = switch (block.type) {
        BlockType.heading => const EdgeInsets.only(top: 16, bottom: 8),
        BlockType.paragraph => const EdgeInsets.only(bottom: 12),
        BlockType.listItem => const EdgeInsets.only(bottom: 4),
        BlockType.blockquote => const EdgeInsets.only(bottom: 12),
      };

      if (block.type == BlockType.listItem) {
        textWidget = Padding(
          padding: EdgeInsets.only(left: 16.0 * block.indent),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 8),
                child: Text('•', style: TextStyle(fontSize: fontSize)),
              ),
              Expanded(child: textWidget),
            ],
          ),
        );
      } else if (block.type == BlockType.blockquote) {
        textWidget = Container(
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: theme.colorScheme.outlineVariant,
                width: 3,
              ),
            ),
          ),
          child: textWidget,
        );
      }

      return Padding(padding: padding, child: textWidget);

    case ImageBlock():
      if (block.bytes == null) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: Image.memory(
            block.bytes!,
            fit: BoxFit.contain,
            errorBuilder: (_, e, s) => const SizedBox.shrink(),
          ),
        ),
      );
  }
}

class _HighlightBuilder {
  final AnalysisResult result;
  final ThemeData theme;
  final WordTapCallback onWordTapped;
  final double fontSize;
  final double lineHeight;
  final String fontFamily;
  final VocabularyColorSettings? colorSettings;
  late final Map<String, Vocabulary> vocabWords;
  late final Set<String> knownSet;
  late final Set<String> learningSet;

  _HighlightBuilder(
    this.result,
    this.theme,
    this.onWordTapped,
    this.fontSize,
    this.lineHeight,
    this.fontFamily,
    this.colorSettings,
  ) {
    vocabWords = {};
    for (final v in result.vocabulary) {
      vocabWords[v.word.toLowerCase()] = v;
    }
    knownSet = result.knownWords;
    learningSet = result.learningWords;
  }

  Color _colorForVocab(String lower, Vocabulary vocab) {
    if (learningSet.contains(lower)) {
      return colorSettings?.learningColor ?? AppColors.vocabLearning;
    }
    // 0.45 = learning, 0.2 = unknown
    if (vocab.familiarity >= 0.4 && vocab.familiarity <= 0.5) {
      return colorSettings?.learningColor ?? AppColors.vocabLearning;
    }
    return colorSettings?.unknownColor ?? AppColors.familiarityLow;
  }

  Color _colorForLearning() {
    return colorSettings?.learningColor ?? AppColors.vocabLearning;
  }

  InlineSpan build() {
    return buildParagraph(result.passageText);
  }

  InlineSpan buildParagraph(String paragraph) {
    final spans = <InlineSpan>[];
    final wordPattern = RegExp(r"[a-zA-Z]+(?:'[a-zA-Z]+)?");
    final matches = wordPattern.allMatches(paragraph).toList();
    int lastIndex = 0;

    for (final match in matches) {
      final word = match.group(0)!;
      final lower = word.toLowerCase();

      if (match.start > lastIndex) {
        spans.add(TextSpan(text: paragraph.substring(lastIndex, match.start)));
      }

      final isVocab = vocabWords.containsKey(lower);
      final isKnown = knownSet.contains(lower);
      final isLearning = !isVocab && learningSet.contains(lower);

      if (isVocab) {
        final vocab = vocabWords[lower]!;
        final color = _colorForVocab(lower, vocab);
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: buildWordTapable(
              word: word,
              color: color,
              textStyle: theme.textTheme.bodyLarge!.copyWith(
                height: lineHeight,
                letterSpacing: 0.3,
                fontFamily: fontFamily,
                fontSize: fontSize,
              ),
              onWordTapped: onWordTapped,
              contextText: vocab.context,
            ),
          ),
        );
      } else if (isLearning) {
        final learningColor = _colorForLearning();
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: buildWordTapable(
              word: word,
              color: learningColor,
              textStyle: theme.textTheme.bodyLarge!.copyWith(
                height: lineHeight,
                letterSpacing: 0.3,
                fontFamily: fontFamily,
                fontSize: fontSize,
              ),
              onWordTapped: onWordTapped,
              contextText: '...$word...',
            ),
          ),
        );
      } else if (isKnown || lower.length < AppConstants.minWordLength) {
        spans.add(TextSpan(text: word));
      } else {
        final unknownColor =
            colorSettings?.unknownColor ?? AppColors.familiarityLow;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: buildWordTapable(
              word: word,
              color: unknownColor,
              textStyle: theme.textTheme.bodyLarge!.copyWith(
                height: lineHeight,
                letterSpacing: 0.3,
                fontFamily: fontFamily,
                fontSize: fontSize,
              ),
              onWordTapped: onWordTapped,
              contextText: '...$word...',
            ),
          ),
        );
      }
      lastIndex = match.end;
    }

    if (lastIndex < paragraph.length) {
      spans.add(TextSpan(text: paragraph.substring(lastIndex)));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: paragraph));
    }
    return TextSpan(children: spans);
  }
}

class _StyledBlockBuilder {
  final TextBlock block;
  final AnalysisResult result;
  final ThemeData theme;
  final WordTapCallback onWordTapped;
  final double fontSize;
  final double lineHeight;
  final String fontFamily;
  final VocabularyColorSettings? colorSettings;
  late final Map<String, Vocabulary> vocabWords;
  late final Set<String> knownSet;
  late final Set<String> learningSet;

  _StyledBlockBuilder(
    this.block,
    this.result,
    this.theme,
    this.onWordTapped,
    this.fontSize,
    this.lineHeight,
    this.fontFamily,
    this.colorSettings,
  ) {
    vocabWords = {};
    for (final v in result.vocabulary) {
      vocabWords[v.word.toLowerCase()] = v;
    }
    knownSet = result.knownWords;
    learningSet = result.learningWords;
  }

  Color _colorForVocab(String lower, Vocabulary vocab) {
    if (learningSet.contains(lower)) {
      return colorSettings?.learningColor ?? AppColors.vocabLearning;
    }
    if (vocab.familiarity >= 0.4 && vocab.familiarity <= 0.5) {
      return colorSettings?.learningColor ?? AppColors.vocabLearning;
    }
    return colorSettings?.unknownColor ?? AppColors.familiarityLow;
  }

  Color _colorForLearning() {
    return colorSettings?.learningColor ?? AppColors.vocabLearning;
  }

  InlineSpan build() {
    final fullText = block.plainText;
    final spans = <InlineSpan>[];
    final wordPattern = RegExp(r"[a-zA-Z]+(?:'[a-zA-Z]+)?");
    final matches = wordPattern.allMatches(fullText).toList();
    int lastIndex = 0;

    // Build offset-to-style mapping
    final styleRanges = <({int start, int end, InlineStyle style})>[];
    int offset = 0;
    for (final styledText in block.spans) {
      styleRanges.add((
        start: offset,
        end: offset + styledText.text.length,
        style: styledText.style,
      ));
      offset += styledText.text.length;
    }

    for (final match in matches) {
      final word = match.group(0)!;
      final lower = word.toLowerCase();

      if (match.start > lastIndex) {
        final segment = fullText.substring(lastIndex, match.start);
        final segStyle = _styleAt(styleRanges, lastIndex);
        spans.add(TextSpan(text: segment, style: _textStyleFor(segStyle)));
      }

      final wordStyle = _styleAt(styleRanges, match.start);
      final isVocab = vocabWords.containsKey(lower);
      final isKnown = knownSet.contains(lower);
      final isLearning = !isVocab && learningSet.contains(lower);

      if (isVocab) {
        final vocab = vocabWords[lower]!;
        final color = _colorForVocab(lower, vocab);
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => onWordTapped(word, vocab.context),
              child: Text(
                word,
                style: _textStyleFor(wordStyle).copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                  decoration: TextDecoration.underline,
                  decorationColor: color.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        );
      } else if (isLearning) {
        final learningColor = _colorForLearning();
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => onWordTapped(word, '...$word...'),
              child: Text(
                word,
                style: _textStyleFor(wordStyle).copyWith(
                  fontWeight: FontWeight.w600,
                  color: learningColor,
                  decoration: TextDecoration.underline,
                  decorationColor: learningColor.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        );
      } else if (isKnown || lower.length < AppConstants.minWordLength) {
        spans.add(TextSpan(text: word, style: _textStyleFor(wordStyle)));
      } else {
        final unknownColor =
            colorSettings?.unknownColor ?? AppColors.familiarityLow;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => onWordTapped(word, '...$word...'),
              child: Text(
                word,
                style: _textStyleFor(wordStyle).copyWith(
                  fontWeight: FontWeight.w600,
                  color: unknownColor,
                  decoration: TextDecoration.underline,
                  decorationColor: unknownColor.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        );
      }
      lastIndex = match.end;
    }

    if (lastIndex < fullText.length) {
      final segStyle = _styleAt(styleRanges, lastIndex);
      spans.add(
        TextSpan(
          text: fullText.substring(lastIndex),
          style: _textStyleFor(segStyle),
        ),
      );
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: fullText));
    }
    return TextSpan(children: spans);
  }

  InlineStyle _styleAt(
    List<({int start, int end, InlineStyle style})> ranges,
    int offset,
  ) {
    for (final range in ranges) {
      if (offset >= range.start && offset < range.end) {
        return range.style;
      }
    }
    return InlineStyle.normal;
  }

  TextStyle _textStyleFor(InlineStyle style) {
    return theme.textTheme.bodyLarge!.copyWith(
      height: lineHeight,
      letterSpacing: 0.3,
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: style.bold ? FontWeight.bold : null,
      fontStyle: style.italic ? FontStyle.italic : null,
    );
  }
}

Widget buildChapterNav(
  BuildContext context,
  ReadingProvider provider,
  ThemeData theme,
) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: Border(
        bottom: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
    ),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: '上一个目录项',
          onPressed: provider.currentChapter > 0
              ? () => provider.goToChapter(provider.currentChapter - 1)
              : null,
        ),
        Expanded(
          child: Text(
            '位置 ${provider.currentChapter + 1} / ${provider.chapterCount}',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: '下一个目录项',
          onPressed: provider.currentChapter < provider.chapterCount - 1
              ? () => provider.goToChapter(provider.currentChapter + 1)
              : null,
        ),
      ],
    ),
  );
}

Widget buildProgressBar(
  BuildContext context,
  double readingProgress,
  ThemeData theme,
  String chapterTitle,
  int progressPercent,
) {
  return Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      border: Border(
        top: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                chapterTitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$progressPercent%',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: readingProgress,
            minHeight: 4,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildInlineDictionaryPopup(
  BuildContext context,
  ReadingProvider provider,
  ThemeData theme,
) {
  return Container(
    constraints: const BoxConstraints(maxHeight: 300),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPopupHeader(provider, theme),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildDictionaryContent(provider, theme),
          ),
        ),
      ],
    ),
  );
}

Widget _buildPopupHeader(ReadingProvider provider, ThemeData theme) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: Border(
        bottom: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
    ),
    child: Row(
      children: [
        Icon(Icons.translate, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            provider.selectedWord!,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (provider.isLoadingWord)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: provider.clearWordLookup,
          ),
      ],
    ),
  );
}

Widget _buildDictionaryContent(ReadingProvider provider, ThemeData theme) {
  if (provider.isLoadingWord) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
    );
  }
  final entry = provider.selectedWordEntry;
  if (entry == null) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No definition found',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Try checking the spelling or your network connection.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (entry.phonetic != null) ...[
        Text(
          entry.phonetic!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
      ],
      ...entry.meanings.map(
        (meaning) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (meaning.partOfSpeech.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    meaning.partOfSpeech,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              ...meaning.definitions.asMap().entries.map((e) {
                final isExample = e.value.startsWith('Example:');
                return Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    '${e.key + 1}. ${e.value}',
                    style:
                        (isExample
                                ? theme.textTheme.bodySmall
                                : theme.textTheme.bodyMedium)
                            ?.copyWith(
                              color: isExample
                                  ? theme.colorScheme.tertiary
                                  : theme.colorScheme.onSurface,
                              fontStyle: isExample ? FontStyle.italic : null,
                            ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    ],
  );
}

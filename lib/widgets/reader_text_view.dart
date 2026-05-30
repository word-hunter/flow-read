import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import '../models/content_block.dart';
import '../providers/reading_provider.dart';
import '../services/common_words.dart';
import '../services/english_word_utils.dart';
import '../services/settings_service.dart';
import '../services/word_level_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';
import 'dictionary_detail_view.dart';
import 'pronunciation_button.dart';

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

TextSpan buildTappableWordSpan({
  required String word,
  required Color color,
  required TextStyle textStyle,
  required WordTapCallback onWordTapped,
  required String contextText,
  required ThemeData theme,
  String? searchQuery,
}) {
  final isSearchMatch = _containsSearchMatch(word, searchQuery);
  return TextSpan(
    text: word,
    style: textStyle.copyWith(
      fontWeight: FontWeight.w600,
      color: isSearchMatch ? searchHighlightForegroundFor(theme) : color,
      backgroundColor: isSearchMatch
          ? searchHighlightBackgroundFor(theme)
          : textStyle.backgroundColor,
      decoration: TextDecoration.underline,
      decorationColor: color.withValues(alpha: 0.5),
    ),
    mouseCursor: SystemMouseCursors.click,
    recognizer: TapGestureRecognizer()
      ..onTap = () => onWordTapped(word, contextText),
  );
}

TextSpan buildPlainLookupWordSpan({
  required String word,
  required TextStyle textStyle,
  required WordTapCallback onWordTapped,
  required String contextText,
  required ThemeData theme,
  String? searchQuery,
}) {
  final isSearchMatch = _containsSearchMatch(word, searchQuery);
  return TextSpan(
    text: word,
    style: isSearchMatch ? _withSearchHighlight(textStyle, theme) : textStyle,
    mouseCursor: SystemMouseCursors.click,
    recognizer: TapGestureRecognizer()
      ..onTap = () => onWordTapped(word, contextText),
  );
}

List<InlineSpan> _buildSearchHighlightedSpans(
  String text,
  ThemeData theme, {
  TextStyle? style,
  String? searchQuery,
}) {
  final query = searchQuery?.trim();
  if (query == null || query.isEmpty) {
    return [TextSpan(text: text, style: style)];
  }

  final lowerText = text.toLowerCase();
  final lowerQuery = query.toLowerCase();
  final spans = <InlineSpan>[];
  var lastIndex = 0;

  while (lastIndex < text.length) {
    final matchStart = lowerText.indexOf(lowerQuery, lastIndex);
    if (matchStart < 0) break;
    final matchEnd = matchStart + query.length;

    if (matchStart > lastIndex) {
      spans.add(
        TextSpan(text: text.substring(lastIndex, matchStart), style: style),
      );
    }
    spans.add(
      TextSpan(
        text: text.substring(matchStart, matchEnd),
        style: _withSearchHighlight(style, theme),
      ),
    );
    lastIndex = matchEnd;
  }

  if (lastIndex < text.length) {
    spans.add(TextSpan(text: text.substring(lastIndex), style: style));
  }
  if (spans.isEmpty) {
    spans.add(TextSpan(text: text, style: style));
  }
  return spans;
}

TextStyle _withSearchHighlight(TextStyle? style, ThemeData theme) {
  final effectiveStyle = style ?? const TextStyle();
  return effectiveStyle.copyWith(
    backgroundColor: searchHighlightBackgroundFor(theme),
    color: searchHighlightForegroundFor(theme),
  );
}

bool _containsSearchMatch(String text, String? searchQuery) {
  final query = searchQuery?.trim();
  if (query == null || query.isEmpty) return false;
  return text.toLowerCase().contains(query.toLowerCase());
}

Color searchHighlightBackgroundFor(ThemeData theme) {
  if (theme.brightness == Brightness.dark) {
    return const Color(0xFF18D6C3);
  }
  return const Color(0xFFFFD84D);
}

Color searchHighlightForegroundFor(ThemeData theme) {
  if (theme.brightness == Brightness.dark) {
    return const Color(0xFF05211F);
  }
  return const Color(0xFF261900);
}

InlineSpan buildHighlightedText(
  AnalysisResult result,
  ThemeData theme, {
  required WordTapCallback onWordTapped,
  double fontSize = 16.0,
  double lineHeight = 2.0,
  String fontFamily = 'Serif',
  VocabularyColorSettings? colorSettings,
  String? searchQuery,
  WordLevelService? wordLevelService,
}) {
  return _HighlightBuilder(
    result,
    theme,
    onWordTapped,
    fontSize,
    lineHeight,
    fontFamily,
    colorSettings,
    searchQuery,
    wordLevelService,
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
  String? searchQuery,
  WordLevelService? wordLevelService,
}) {
  return _HighlightBuilder(
    result,
    theme,
    onWordTapped,
    fontSize,
    lineHeight,
    fontFamily,
    colorSettings,
    searchQuery,
    wordLevelService,
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
  String? searchQuery,
  WordLevelService? wordLevelService,
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
    searchQuery,
    wordLevelService,
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
  String? searchQuery,
  WordLevelService? wordLevelService,
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
        searchQuery: searchQuery,
        wordLevelService: wordLevelService,
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
      return _EpubImageBlockView(block: block);
  }
}

class _EpubImageBlockView extends StatelessWidget {
  static const double _fallbackAspectRatio = 4 / 3;
  static const double _maxImageHeight = 520;

  final ImageBlock block;

  const _EpubImageBlockView({required this.block});

  @override
  Widget build(BuildContext context) {
    final bytes = block.bytes;
    if (bytes == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth =
              constraints.hasBoundedWidth && constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 720.0;
          final maxHeight = math.min(
            _maxImageHeight,
            math.max(220.0, availableWidth * 1.25),
          );
          final aspectRatio = (block.aspectRatio ?? _fallbackAspectRatio)
              .clamp(0.2, 6.0)
              .toDouble();
          final frameWidth = math.min(availableWidth, maxHeight * aspectRatio);

          return Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: frameWidth,
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                  semanticLabel: block.alt,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          );
        },
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
  final String? searchQuery;
  final WordLevelService? wordLevelService;
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
    this.searchQuery,
    this.wordLevelService,
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

  String _keyFor(String word) {
    final lower = normalizeEnglishApostrophes(word).toLowerCase().trim();
    if (lower.isEmpty) return lower;
    return wordLevelService?.canonicalForm(lower) ??
        canonicalEnglishContraction(lower) ??
        lower;
  }

  InlineSpan build() {
    return buildParagraph(result.passageText);
  }

  InlineSpan buildParagraph(String paragraph) {
    final spans = <InlineSpan>[];
    final wordPattern = englishWordPattern;
    final matches = wordPattern.allMatches(paragraph).toList();
    int lastIndex = 0;

    for (final match in matches) {
      final word = match.group(0)!;
      final lower = word.toLowerCase();
      final key = _keyFor(lower);

      if (match.start > lastIndex) {
        spans.addAll(
          _buildSearchHighlightedSpans(
            paragraph.substring(lastIndex, match.start),
            theme,
            searchQuery: searchQuery,
          ),
        );
      }

      final isVocab = vocabWords.containsKey(key);
      final isKnown = knownSet.contains(key);
      final isLearning = !isVocab && learningSet.contains(key);

      if (isVocab) {
        final vocab = vocabWords[key]!;
        final color = _colorForVocab(key, vocab);
        spans.add(
          buildTappableWordSpan(
            word: word,
            color: color,
            textStyle: theme.textTheme.bodyLarge!.copyWith(
              height: lineHeight,
              letterSpacing: 0.3,
              fontFamily: fontFamily,
              fontSize: fontSize,
            ),
            theme: theme,
            searchQuery: searchQuery,
            onWordTapped: onWordTapped,
            contextText: vocab.context,
          ),
        );
      } else if (isLearning) {
        final learningColor = _colorForLearning();
        spans.add(
          buildTappableWordSpan(
            word: word,
            color: learningColor,
            textStyle: theme.textTheme.bodyLarge!.copyWith(
              height: lineHeight,
              letterSpacing: 0.3,
              fontFamily: fontFamily,
              fontSize: fontSize,
            ),
            theme: theme,
            searchQuery: searchQuery,
            onWordTapped: onWordTapped,
            contextText: '...$word...',
          ),
        );
      } else if (isKnown ||
          key.length < AppConstants.minWordLength ||
          _isCommonContraction(word, key)) {
        spans.add(
          buildPlainLookupWordSpan(
            word: word,
            textStyle: theme.textTheme.bodyLarge!.copyWith(
              height: lineHeight,
              letterSpacing: 0.3,
              fontFamily: fontFamily,
              fontSize: fontSize,
            ),
            theme: theme,
            searchQuery: searchQuery,
            onWordTapped: onWordTapped,
            contextText: paragraph,
          ),
        );
      } else {
        final unknownColor =
            colorSettings?.unknownColor ?? AppColors.familiarityLow;
        spans.add(
          buildTappableWordSpan(
            word: word,
            color: unknownColor,
            textStyle: theme.textTheme.bodyLarge!.copyWith(
              height: lineHeight,
              letterSpacing: 0.3,
              fontFamily: fontFamily,
              fontSize: fontSize,
            ),
            theme: theme,
            searchQuery: searchQuery,
            onWordTapped: onWordTapped,
            contextText: '...$word...',
          ),
        );
      }
      lastIndex = match.end;
    }

    if (lastIndex < paragraph.length) {
      spans.addAll(
        _buildSearchHighlightedSpans(
          paragraph.substring(lastIndex),
          theme,
          searchQuery: searchQuery,
        ),
      );
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
  final String? searchQuery;
  final WordLevelService? wordLevelService;
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
    this.searchQuery,
    this.wordLevelService,
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

  String _keyFor(String word) {
    final lower = normalizeEnglishApostrophes(word).toLowerCase().trim();
    if (lower.isEmpty) return lower;
    return wordLevelService?.canonicalForm(lower) ??
        canonicalEnglishContraction(lower) ??
        lower;
  }

  InlineSpan build() {
    final fullText = block.plainText;
    final spans = <InlineSpan>[];
    final wordPattern = englishWordPattern;
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
      final key = _keyFor(lower);

      if (match.start > lastIndex) {
        final segment = fullText.substring(lastIndex, match.start);
        final segStyle = _styleAt(styleRanges, lastIndex);
        spans.addAll(
          _buildSearchHighlightedSpans(
            segment,
            theme,
            style: _textStyleFor(segStyle),
            searchQuery: searchQuery,
          ),
        );
      }

      final wordStyle = _styleAt(styleRanges, match.start);
      final isVocab = vocabWords.containsKey(key);
      final isKnown = knownSet.contains(key);
      final isLearning = !isVocab && learningSet.contains(key);

      if (isVocab) {
        final vocab = vocabWords[key]!;
        final color = _colorForVocab(key, vocab);
        spans.add(
          buildTappableWordSpan(
            word: word,
            color: color,
            textStyle: _textStyleFor(wordStyle),
            theme: theme,
            searchQuery: searchQuery,
            onWordTapped: onWordTapped,
            contextText: vocab.context,
          ),
        );
      } else if (isLearning) {
        final learningColor = _colorForLearning();
        spans.add(
          buildTappableWordSpan(
            word: word,
            color: learningColor,
            textStyle: _textStyleFor(wordStyle),
            theme: theme,
            searchQuery: searchQuery,
            onWordTapped: onWordTapped,
            contextText: '...$word...',
          ),
        );
      } else if (isKnown ||
          key.length < AppConstants.minWordLength ||
          _isCommonContraction(word, key)) {
        spans.add(
          buildPlainLookupWordSpan(
            word: word,
            textStyle: _textStyleFor(wordStyle),
            theme: theme,
            searchQuery: searchQuery,
            onWordTapped: onWordTapped,
            contextText: fullText,
          ),
        );
      } else {
        final unknownColor =
            colorSettings?.unknownColor ?? AppColors.familiarityLow;
        spans.add(
          buildTappableWordSpan(
            word: word,
            color: unknownColor,
            textStyle: _textStyleFor(wordStyle),
            theme: theme,
            searchQuery: searchQuery,
            onWordTapped: onWordTapped,
            contextText: '...$word...',
          ),
        );
      }
      lastIndex = match.end;
    }

    if (lastIndex < fullText.length) {
      final segStyle = _styleAt(styleRanges, lastIndex);
      spans.addAll(
        _buildSearchHighlightedSpans(
          fullText.substring(lastIndex),
          theme,
          style: _textStyleFor(segStyle),
          searchQuery: searchQuery,
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

bool _isCommonContraction(String word, String key) {
  final contractionKey = canonicalEnglishContraction(word) ?? key;
  return isCommonWord(contractionKey);
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
        else ...[
          if (provider.canPronounceWords)
            PronunciationButton(
              word: provider.selectedWord!,
              onSpeakWord: provider.speakWord,
              buttonSize: 32,
              iconSize: 18,
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: provider.clearWordLookup,
          ),
        ],
      ],
    ),
  );
}

Widget _buildDictionaryContent(ReadingProvider provider, ThemeData _) {
  final word = provider.selectedWord;
  if (word == null) return const SizedBox.shrink();
  return DictionaryDetailView.fromProvider(
    provider: provider,
    word: word,
    showWordHeader: false,
  );
}

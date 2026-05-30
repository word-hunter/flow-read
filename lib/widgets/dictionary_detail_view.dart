import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/word_context_example.dart';
import '../models/word_level.dart';
import '../providers/reading_provider.dart';
import '../services/dictionary/word_repository.dart';
import '../services/english_word_utils.dart';
import 'imported_word_examples.dart';
import 'pronunciation_button.dart';

class DictionaryDetailView extends StatelessWidget {
  final String word;
  final DictionaryEntry? entry;
  final String? primaryDefinition;
  final bool isLoading;
  final String? contextText;
  final int? contextWordStart;
  final int? contextWordEnd;
  final List<WordContextExample> importedExamples;
  final LevelKey? level;
  final bool showWordHeader;
  final bool showContext;
  final SpeakWordCallback? onSpeakWord;
  final ValueChanged<String>? onLookupWord;
  final VoidCallback? onGoBack;
  final bool canGoBack;

  const DictionaryDetailView({
    super.key,
    required this.word,
    required this.entry,
    required this.primaryDefinition,
    required this.isLoading,
    this.contextText,
    this.contextWordStart,
    this.contextWordEnd,
    this.importedExamples = const [],
    this.level,
    this.showWordHeader = true,
    this.showContext = false,
    this.onSpeakWord,
    this.onLookupWord,
    this.onGoBack,
    this.canGoBack = false,
  });

  factory DictionaryDetailView.fromProvider({
    Key? key,
    required ReadingProvider provider,
    required String word,
    bool showWordHeader = true,
    bool showContext = false,
  }) {
    final levelService = provider.wordLevelService;
    LevelKey? level;
    if (levelService != null && levelService.hasWord(word)) {
      level = levelService.getLevel(word);
    }

    return DictionaryDetailView(
      key: key,
      word: word,
      entry: provider.selectedWordEntry,
      primaryDefinition: provider.selectedWordTranslation,
      isLoading: provider.isLoadingWord,
      contextText: provider.selectedWordContext,
      contextWordStart: provider.selectedWordContextStart,
      contextWordEnd: provider.selectedWordContextEnd,
      importedExamples: provider.importedExamplesFor(word),
      level: level,
      showWordHeader: showWordHeader,
      showContext: showContext,
      onSpeakWord: provider.canPronounceWords ? provider.speakWord : null,
      onLookupWord: provider.lookupRelatedWord,
      onGoBack: provider.canGoBackWordLookup ? provider.goBackWordLookup : null,
      canGoBack: provider.canGoBackWordLookup,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final hasEntryContent = entry != null && !entry!.isEmpty;
    final hasPrimaryDefinition =
        primaryDefinition != null && primaryDefinition!.trim().isNotEmpty;
    final hasContent =
        hasEntryContent || hasPrimaryDefinition || importedExamples.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canGoBack && onGoBack != null) ...[
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => onGoBack?.call(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('返回上一个词条'),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (showWordHeader) ...[
          _WordHeader(
            word: word,
            entry: entry,
            level: level,
            onSpeakWord: onSpeakWord,
          ),
          const SizedBox(height: 16),
        ],
        if (!hasContent)
          _EmptyDictionaryState(errorMessage: entry?.errorMessage)
        else ...[
          if (hasPrimaryDefinition) ...[
            _SectionLabel(label: '释义'),
            const SizedBox(height: 6),
            _PrimaryDefinition(
              text: primaryDefinition!.trim(),
              currentWord: word,
              onLookupWord: onLookupWord,
            ),
            const SizedBox(height: 14),
          ],
          if (entry != null) ...[
            if (entry!.errorMessage != null &&
                entry!.errorMessage!.trim().isNotEmpty) ...[
              _StatusHint(
                icon: Icons.warning_amber_rounded,
                text: entry!.errorMessage!.trim(),
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
            ],
            for (final meaning in entry!.meanings)
              _MeaningBlock(
                meaning: meaning,
                primaryDefinition: primaryDefinition?.trim(),
                currentWord: word,
                onLookupWord: onLookupWord,
              ),
          ],
          if (importedExamples.isNotEmpty) ...[
            const SizedBox(height: 2),
            ImportedWordExamples(examples: importedExamples),
          ],
        ],
        if (showContext) ...[
          const SizedBox(height: 18),
          DictionaryContextBlock(
            word: word,
            contextText: contextText,
            contextWordStart: contextWordStart,
            contextWordEnd: contextWordEnd,
          ),
        ],
      ],
    );
  }
}

class _WordHeader extends StatelessWidget {
  final String word;
  final DictionaryEntry? entry;
  final LevelKey? level;
  final SpeakWordCallback? onSpeakWord;

  const _WordHeader({
    required this.word,
    required this.entry,
    required this.level,
    required this.onSpeakWord,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sourceName = entry?.sourceName;
    final phonetic = entry?.phonetic?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                word,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Serif',
                  color: theme.colorScheme.onSurface,
                  height: 1.05,
                ),
              ),
            ),
            if (onSpeakWord != null) ...[
              const SizedBox(width: 8),
              PronunciationButton(word: word, onSpeakWord: onSpeakWord),
            ],
          ],
        ),
        if (phonetic != null && phonetic.isNotEmpty) ...[
          const SizedBox(height: 6),
          DictionaryPhoneticText(text: phonetic),
        ],
        if (level != null || sourceName != null) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (level != null)
                _MetaChip(
                  label: '${level!.shortLabel} ${level!.label}',
                  color: _levelColor(level!),
                ),
              if (sourceName != null) DictionarySourceBadge(entry: entry!),
            ],
          ),
        ],
      ],
    );
  }

  Color _levelColor(LevelKey level) {
    switch (level) {
      case LevelKey.p:
        return Colors.green;
      case LevelKey.m:
        return Colors.teal;
      case LevelKey.h:
        return Colors.blue;
      case LevelKey.cet4:
        return Colors.orange;
      case LevelKey.cet6:
        return Colors.deepOrange;
      case LevelKey.gre:
        return Colors.red;
      case LevelKey.other:
        return Colors.grey;
    }
  }
}

class DictionaryPhoneticText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const DictionaryPhoneticText({super.key, required this.text, this.style});

  static const _fontFamilyFallback = [
    'Lucida Grande',
    'Helvetica Neue',
    'Arial Unicode MS',
    'Noto Sans',
    'DejaVu Sans',
    'Segoe UI',
    'Arial',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: (style ?? theme.textTheme.bodyMedium)?.copyWith(
        color: style?.color ?? theme.colorScheme.onSurfaceVariant,
        fontFamily: 'Lucida Grande',
        fontFamilyFallback: _fontFamilyFallback,
        fontStyle: FontStyle.normal,
        letterSpacing: 0,
      ),
    );
  }
}

class DictionarySourceBadge extends StatelessWidget {
  final DictionaryEntry entry;

  const DictionarySourceBadge({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = entry.fromCache
        ? '${entry.sourceName ?? '词典'} · 缓存'
        : entry.sourceName ?? '词典';
    return _MetaChip(label: label, color: theme.colorScheme.onSurfaceVariant);
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _PrimaryDefinition extends StatelessWidget {
  final String text;
  final String currentWord;
  final ValueChanged<String>? onLookupWord;

  const _PrimaryDefinition({
    required this.text,
    required this.currentWord,
    required this.onLookupWord,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: _InteractiveDictionaryText(
        text: text,
        currentWord: currentWord,
        onLookupWord: onLookupWord,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onPrimaryContainer,
          height: 1.45,
        ),
      ),
    );
  }
}

class _MeaningBlock extends StatelessWidget {
  final Meaning meaning;
  final String? primaryDefinition;
  final String currentWord;
  final ValueChanged<String>? onLookupWord;

  const _MeaningBlock({
    required this.meaning,
    required this.currentWord,
    required this.onLookupWord,
    this.primaryDefinition,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final legacyExamples = meaning.definitions
        .where((definition) => definition.startsWith('Example:'))
        .map((definition) => definition.replaceFirst('Example:', '').trim())
        .where((definition) => definition.isNotEmpty)
        .toList();
    final definitions = meaning.definitions
        .where((definition) => !definition.startsWith('Example:'))
        .where((definition) => definition.trim() != primaryDefinition)
        .toList();
    final examples = [...meaning.examples, ...legacyExamples];

    if (definitions.isEmpty &&
        examples.isEmpty &&
        meaning.partOfSpeech.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (meaning.partOfSpeech.isNotEmpty)
            _PartOfSpeechChip(label: meaning.partOfSpeech),
          if (definitions.isNotEmpty) const SizedBox(height: 6),
          for (final item in definitions.asMap().entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: _InteractiveDictionaryText(
                text: '${item.key + 1}. ${item.value}',
                currentWord: currentWord,
                onLookupWord: onLookupWord,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.35,
                ),
              ),
            ),
          if (examples.isNotEmpty) ...[
            if (definitions.isNotEmpty) const SizedBox(height: 4),
            DictionaryExamplesSection(
              examples: examples,
              currentWord: currentWord,
              onLookupWord: onLookupWord,
            ),
          ],
        ],
      ),
    );
  }
}

class _PartOfSpeechChip extends StatelessWidget {
  final String label;

  const _PartOfSpeechChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class DictionaryExamplesSection extends StatelessWidget {
  final List<String> examples;
  final String? currentWord;
  final ValueChanged<String>? onLookupWord;

  const DictionaryExamplesSection({
    super.key,
    required this.examples,
    this.currentWord,
    this.onLookupWord,
  });

  @override
  Widget build(BuildContext context) {
    if (examples.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final visible = examples.take(3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final example in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: _InteractiveDictionaryText(
              text: example,
              currentWord: currentWord,
              onLookupWord: onLookupWord,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.tertiary,
                fontStyle: FontStyle.italic,
                height: 1.35,
              ),
            ),
          ),
      ],
    );
  }
}

class _InteractiveDictionaryText extends StatefulWidget {
  const _InteractiveDictionaryText({
    required this.text,
    required this.style,
    this.currentWord,
    this.onLookupWord,
  });

  final String text;
  final TextStyle? style;
  final String? currentWord;
  final ValueChanged<String>? onLookupWord;

  @override
  State<_InteractiveDictionaryText> createState() =>
      _InteractiveDictionaryTextState();
}

class _InteractiveDictionaryTextState
    extends State<_InteractiveDictionaryText> {
  final Map<int, TapGestureRecognizer> _recognizers = {};
  int? _hoveredTokenStart;
  int? _pendingHoveredTokenStart;
  bool _hoverUpdateScheduled = false;
  int _hoverUpdateGeneration = 0;

  @override
  void dispose() {
    _hoverUpdateGeneration += 1;
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _InteractiveDictionaryText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.currentWord != widget.currentWord) {
      _hoveredTokenStart = null;
      _pendingHoveredTokenStart = null;
      _hoverUpdateGeneration += 1;
      for (final recognizer in _recognizers.values) {
        recognizer.dispose();
      }
      _recognizers.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(style: widget.style, children: _buildSpans(context)),
    );
  }

  List<TextSpan> _buildSpans(BuildContext context) {
    final callback = widget.onLookupWord;
    if (callback == null) {
      _disposeInactiveRecognizers(const {});
      return [TextSpan(text: widget.text)];
    }

    final spans = <TextSpan>[];
    final pattern = RegExp(r"[A-Za-z][A-Za-z'-]*");
    final activeTokenStarts = <int>{};
    var cursor = 0;
    for (final match in pattern.allMatches(widget.text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: widget.text.substring(cursor, match.start)));
      }

      final token = widget.text.substring(match.start, match.end);
      if (_isLookupCandidate(token)) {
        final tokenStart = match.start;
        activeTokenStarts.add(tokenStart);
        final recognizer = _recognizers[tokenStart] ??= TapGestureRecognizer();
        recognizer.onTap = () => callback(_normalizeLookupToken(token));
        final hovered = _hoveredTokenStart == tokenStart;
        spans.add(
          TextSpan(
            text: token,
            mouseCursor: SystemMouseCursors.click,
            onEnter: (_) => _scheduleHoveredToken(tokenStart),
            onExit: (_) {
              if (_hoveredTokenStart == tokenStart ||
                  _pendingHoveredTokenStart == tokenStart) {
                _scheduleHoveredToken(null);
              }
            },
            style: hovered
                ? TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dotted,
                  )
                : null,
            recognizer: recognizer,
          ),
        );
      } else {
        spans.add(TextSpan(text: token));
      }
      cursor = match.end;
    }

    if (cursor < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(cursor)));
    }
    _disposeInactiveRecognizers(activeTokenStarts);
    return spans;
  }

  void _scheduleHoveredToken(int? tokenStart) {
    _pendingHoveredTokenStart = tokenStart;
    if (_hoverUpdateScheduled) return;

    _hoverUpdateScheduled = true;
    final generation = _hoverUpdateGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hoverUpdateScheduled = false;
      if (!mounted || generation != _hoverUpdateGeneration) return;
      final nextHoveredTokenStart = _pendingHoveredTokenStart;
      if (_hoveredTokenStart == nextHoveredTokenStart) return;
      setState(() => _hoveredTokenStart = nextHoveredTokenStart);
    });
  }

  void _disposeInactiveRecognizers(Set<int> activeTokenStarts) {
    final inactiveStarts = _recognizers.keys
        .where((start) => !activeTokenStarts.contains(start))
        .toList();
    for (final start in inactiveStarts) {
      _recognizers.remove(start)?.dispose();
    }
  }

  bool _isLookupCandidate(String token) {
    final normalized = _normalizeLookupToken(token);
    if (normalized.length < 2) return false;
    final current = widget.currentWord?.trim().toLowerCase();
    return current == null || current != normalized;
  }

  String _normalizeLookupToken(String token) {
    return token
        .replaceAll(RegExp(r"(^[^A-Za-z]+|[^A-Za-z]+$)"), '')
        .toLowerCase();
  }
}

class DictionaryContextBlock extends StatelessWidget {
  static const _maxContextLines = 4;
  static const _maxContextCharacters = 150;
  static const _contextLeadCharacters = 52;

  final String word;
  final String? contextText;
  final int? contextWordStart;
  final int? contextWordEnd;
  final Widget? trailing;

  const DictionaryContextBlock({
    super.key,
    required this.word,
    this.contextText,
    this.contextWordStart,
    this.contextWordEnd,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = contextText?.trim();
    final excerpt = text == null || text.isEmpty ? null : _contextExcerpt(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionLabel(label: '原文语境'),
            if (trailing != null) ...[const Spacer(), trailing!],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: text == null || text.isEmpty
              ? Text(
                  '暂无原文语境',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : Text.rich(
                  _highlightContext(theme, excerpt!),
                  maxLines: _maxContextLines,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
        ),
      ],
    );
  }

  String _contextExcerpt(String text) {
    final normalized = text.trim();
    if (normalized.length <= _maxContextCharacters) return normalized;

    final wordMatch =
        _findAnchoredContextWordMatch(normalized) ??
        _findFirstContextWordMatch(normalized);

    if (wordMatch == null) {
      final excerpt = normalized
          .substring(0, _maxContextCharacters)
          .trimRight();
      return '$excerpt...';
    }

    final start = (wordMatch.start - _contextLeadCharacters).clamp(
      0,
      normalized.length,
    );
    final end = (start + _maxContextCharacters).clamp(0, normalized.length);

    final prefix = start > 0 ? '...' : '';
    final suffix = end < normalized.length ? '...' : '';
    return '$prefix${normalized.substring(start, end).trim()}$suffix';
  }

  TextSpan _highlightContext(ThemeData theme, String text) {
    final wordMatches = _findContextWordMatches(text);
    if (wordMatches.isEmpty) {
      return TextSpan(
        text: text,
        style: TextStyle(color: theme.colorScheme.onSurface),
      );
    }

    final children = <TextSpan>[];
    var lastIndex = 0;
    for (final wordMatch in wordMatches) {
      if (wordMatch.start > lastIndex) {
        children.add(
          TextSpan(text: text.substring(lastIndex, wordMatch.start)),
        );
      }
      children.add(
        TextSpan(
          text: text.substring(wordMatch.start, wordMatch.end),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
      lastIndex = wordMatch.end;
    }
    if (lastIndex < text.length) {
      children.add(TextSpan(text: text.substring(lastIndex)));
    }

    return TextSpan(
      style: TextStyle(color: theme.colorScheme.onSurface),
      children: children,
    );
  }

  RegExpMatch? _findAnchoredContextWordMatch(String text) {
    final start = contextWordStart;
    final end = contextWordEnd;
    if (start == null || end == null) return null;

    for (final match in _findContextWordMatches(text)) {
      if (match.start == start && match.end == end) return match;
    }

    return null;
  }

  RegExpMatch? _findFirstContextWordMatch(String text) {
    return _findContextWordMatches(text).firstOrNull;
  }

  List<RegExpMatch> _findContextWordMatches(String text) {
    final target = normalizeEnglishApostrophes(word).toLowerCase().trim();
    if (target.isEmpty) return const [];

    return englishWordPattern.allMatches(text).where((match) {
      final token = normalizeEnglishApostrophes(match.group(0)!).toLowerCase();
      return token == target;
    }).toList();
  }
}

class _StatusHint extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusHint({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _EmptyDictionaryState extends StatelessWidget {
  final String? errorMessage;

  const _EmptyDictionaryState({this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = errorMessage?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '未找到释义',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message == null || message.isEmpty ? '请检查拼写或网络连接。' : message,
          style: theme.textTheme.bodySmall?.copyWith(
            color: message == null || message.isEmpty
                ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                : theme.colorScheme.error,
          ),
        ),
      ],
    );
  }
}

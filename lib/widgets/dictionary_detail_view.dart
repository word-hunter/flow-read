import 'package:flutter/material.dart';

import '../models/word_context_example.dart';
import '../models/word_level.dart';
import '../providers/reading_provider.dart';
import '../services/dictionary/word_repository.dart';
import 'imported_word_examples.dart';

class DictionaryDetailView extends StatelessWidget {
  final String word;
  final DictionaryEntry? entry;
  final String? primaryDefinition;
  final bool isLoading;
  final String? contextText;
  final List<WordContextExample> importedExamples;
  final LevelKey? level;
  final bool showWordHeader;
  final bool showContext;

  const DictionaryDetailView({
    super.key,
    required this.word,
    required this.entry,
    required this.primaryDefinition,
    required this.isLoading,
    this.contextText,
    this.importedExamples = const [],
    this.level,
    this.showWordHeader = true,
    this.showContext = false,
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
      importedExamples: provider.importedExamplesFor(word),
      level: level,
      showWordHeader: showWordHeader,
      showContext: showContext,
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
        if (showWordHeader) ...[
          _WordHeader(word: word, entry: entry, level: level),
          const SizedBox(height: 16),
        ],
        if (!hasContent)
          _EmptyDictionaryState(errorMessage: entry?.errorMessage)
        else ...[
          if (hasPrimaryDefinition) ...[
            _SectionLabel(label: '释义'),
            const SizedBox(height: 6),
            _PrimaryDefinition(text: primaryDefinition!.trim()),
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
              ),
          ],
          if (importedExamples.isNotEmpty) ...[
            const SizedBox(height: 2),
            ImportedWordExamples(examples: importedExamples),
          ],
        ],
        if (showContext) ...[
          const SizedBox(height: 18),
          _ContextBlock(word: word, contextText: contextText),
        ],
      ],
    );
  }
}

class _WordHeader extends StatelessWidget {
  final String word;
  final DictionaryEntry? entry;
  final LevelKey? level;

  const _WordHeader({required this.word, required this.entry, this.level});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sourceName = entry?.sourceName;
    final phonetic = entry?.phonetic?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          word,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontFamily: 'Serif',
            color: theme.colorScheme.onSurface,
            height: 1.05,
          ),
        ),
        if (phonetic != null && phonetic.isNotEmpty) ...[
          const SizedBox(height: 6),
          _PhoneticText(text: phonetic),
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

class _PhoneticText extends StatelessWidget {
  final String text;

  const _PhoneticText({required this.text});

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
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
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

  const _PrimaryDefinition({required this.text});

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
      child: Text(
        text,
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

  const _MeaningBlock({required this.meaning, this.primaryDefinition});

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
              child: Text(
                '${item.key + 1}. ${item.value}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.35,
                ),
              ),
            ),
          if (examples.isNotEmpty) ...[
            if (definitions.isNotEmpty) const SizedBox(height: 4),
            DictionaryExamplesSection(examples: examples),
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

  const DictionaryExamplesSection({super.key, required this.examples});

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
            child: Text(
              example,
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

class _ContextBlock extends StatelessWidget {
  final String word;
  final String? contextText;

  const _ContextBlock({required this.word, this.contextText});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = contextText?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: '原文语境'),
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
                  _highlightContext(theme, text),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
        ),
      ],
    );
  }

  TextSpan _highlightContext(ThemeData theme, String text) {
    final lowerContext = text.toLowerCase();
    final lowerWord = word.toLowerCase();
    final index = lowerContext.indexOf(lowerWord);
    if (index < 0) {
      return TextSpan(
        text: text,
        style: TextStyle(color: theme.colorScheme.onSurface),
      );
    }

    return TextSpan(
      style: TextStyle(color: theme.colorScheme.onSurface),
      children: [
        TextSpan(text: text.substring(0, index)),
        TextSpan(
          text: text.substring(index, index + word.length),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        TextSpan(text: text.substring(index + word.length)),
      ],
    );
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

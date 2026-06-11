import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../../models/analysis_result.dart';
import '../../models/user_vocabulary.dart';
import '../../providers/reading/current_book_notifier.dart';
import '../../providers/reading/vocabulary_notifier.dart';
import '../../providers/reading/word_lookup_notifier.dart';
import 'reader_word_sidebar.dart';

class ReaderVocabularyPanel extends riverpod.ConsumerWidget {
  const ReaderVocabularyPanel({
    super.key,
    required this.onVocabularySelected,
    this.onClose,
    this.onOpenAssistant,
  });

  final ValueChanged<Vocabulary> onVocabularySelected;
  final VoidCallback? onClose;
  final VoidCallback? onOpenAssistant;

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final lookupState = ref.watch(wordLookupNotifierProvider);
    if (lookupState.selectedWord != null) {
      return ReaderWordSidebar(
        onClose: onClose,
        onOpenAssistant: onOpenAssistant,
      );
    }

    ref.watch(currentBookNotifierProvider);
    ref.watch(vocabularyNotifierProvider);
    final currentBook = ref.read(currentBookNotifierProvider.notifier);
    final vocabulary = ref.read(vocabularyNotifierProvider.notifier);
    final words = currentBook.result?.vocabulary ?? const <Vocabulary>[];
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: Row(
            children: [
              Icon(
                Icons.text_fields_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '本章词汇',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${words.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: words.isEmpty
              ? _EmptyVocabularyState(theme: theme)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  itemCount: words.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final word = words[index];
                    return _VocabularyRow(
                      vocabulary: word,
                      status: vocabulary.getWordStatus(word.word),
                      onTap: () => onVocabularySelected(word),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _VocabularyRow extends StatelessWidget {
  const _VocabularyRow({
    required this.vocabulary,
    required this.status,
    required this.onTap,
  });

  final Vocabulary vocabulary;
  final UserWordStatus? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = switch (status) {
      UserWordStatus.known => '已掌握',
      UserWordStatus.learning => '学习中',
      null => '生词',
    };
    final statusColor = switch (status) {
      UserWordStatus.known => Colors.green,
      UserWordStatus.learning => theme.colorScheme.primary,
      null => theme.colorScheme.error,
    };

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(8),
        hoverColor: theme.colorScheme.primary.withValues(alpha: 0.06),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vocabulary.word,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(label: statusLabel, color: statusColor),
                ],
              ),
              if (vocabulary.meaning.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  vocabulary.meaning,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EmptyVocabularyState extends StatelessWidget {
  const _EmptyVocabularyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.text_fields_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.34),
            ),
            const SizedBox(height: 12),
            Text(
              '本章暂无词汇分析',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

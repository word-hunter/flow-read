import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import '../../providers/reading/services_provider.dart';
import '../../providers/reading/word_lookup_notifier.dart';
import '../dictionary_detail_view.dart';

class ReaderWordSidebar extends riverpod.ConsumerWidget {
  final VoidCallback? onClose;

  const ReaderWordSidebar({super.key, this.onClose});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final lookupState = ref.watch(wordLookupNotifierProvider);
    final lookupNotifier = ref.read(wordLookupNotifierProvider.notifier);
    final theme = Theme.of(context);
    final word = lookupState.selectedWord;

    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          Expanded(
            child: word == null
                ? _buildEmptyState(theme)
                : _buildLookupLayout(
                    ref,
                    lookupState,
                    lookupNotifier,
                    word,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 10, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '词典',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              tooltip: '收起侧栏',
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            '点击文中生词查看释义',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLookupLayout(
    riverpod.WidgetRef ref,
    WordLookupState lookupState,
    WordLookupNotifier lookupNotifier,
    String word,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: DictionaryDetailView.fromWordLookup(
        word: word,
        lookupState: lookupState,
        lookupNotifier: lookupNotifier,
        wordLevelService: ref.read(wordLevelServiceProvider),
        canPronounceWords: true,
      ),
    );
  }
}

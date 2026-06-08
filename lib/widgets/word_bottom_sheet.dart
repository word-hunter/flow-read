import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import '../models/ai_context_snapshot.dart';
import '../models/user_vocabulary.dart';
import '../providers/reading/bookmark_notifier.dart';
import '../providers/reading/services_provider.dart';
import '../providers/reading/vocabulary_notifier.dart';
import '../providers/reading/word_lookup_notifier.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import 'dictionary_detail_view.dart';
import 'word_mastery_confetti.dart';

class WordBottomSheet extends riverpod.ConsumerStatefulWidget {
  final String word;

  const WordBottomSheet({super.key, required this.word});

  @override
  riverpod.ConsumerState<WordBottomSheet> createState() =>
      _WordBottomSheetState();
}

class _WordBottomSheetState extends riverpod.ConsumerState<WordBottomSheet> {
  bool _bookmarkAdded = false;
  bool _learningItemSaved = false;
  String? _currentWord;

  @override
  Widget build(BuildContext context) {
    final lookupState = ref.watch(wordLookupNotifierProvider);
    final lookupNotifier = ref.read(wordLookupNotifierProvider.notifier);
    ref.watch(vocabularyNotifierProvider);
    final vocabularyNotifier = ref.read(vocabularyNotifierProvider.notifier);
    ref.watch(bookmarkNotifierProvider);
    final bookmarkNotifier = ref.read(bookmarkNotifierProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final word = lookupState.selectedWord ?? widget.word;
    if (_currentWord != word) {
      _currentWord = word;
      _bookmarkAdded = false;
      _learningItemSaved = false;
    }
    final isBookmarked = bookmarkNotifier.isBookmarked(word) || _bookmarkAdded;
    final status = vocabularyNotifier.getWordStatus(word);

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.25,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(theme),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: _buildContent(lookupState, lookupNotifier, word),
                ),
              ),
              _buildBottomActions(
                lookupState,
                lookupNotifier,
                vocabularyNotifier,
                bookmarkNotifier,
                settings,
                theme,
                word,
                status,
                isBookmarked,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    WordLookupState lookupState,
    WordLookupNotifier lookupNotifier,
    String word,
  ) {
    return DictionaryDetailView.fromWordLookup(
      lookupState: lookupState,
      lookupNotifier: lookupNotifier,
      word: word,
      wordLevelService: ref.read(wordLevelServiceProvider),
      canPronounceWords: true,
    );
  }

  Widget _buildBottomActions(
    WordLookupState lookupState,
    WordLookupNotifier lookupNotifier,
    VocabularyNotifier vocabularyNotifier,
    BookmarkNotifier bookmarkNotifier,
    SettingsService settings,
    ThemeData theme,
    String word,
    UserWordStatus? status,
    bool isBookmarked,
  ) {
    final canToggleAIAnalysis = settings.aiFeaturesEnabled;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canToggleAIAnalysis
                  ? () {
                      final assistant = ref.read(aiAssistantControllerProvider);
                      assistant.setContext(
                        AIContextSnapshot(
                          source: AIContextSource.readerWord,
                          word: word,
                          wordSentence: lookupState.selectedWordContext ?? '',
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  : null,
              icon: const Icon(Icons.psychology, size: 20),
              label: const Text(
                'AI 详解此词',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 11,
                  horizontal: 14,
                ),
                side: BorderSide(
                  color: AppColors.vocabLearning.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (status != UserWordStatus.known)
                Expanded(
                  child: WordMasteryActionAnchor(
                    builder: (context, origin) => _actionButton(
                      theme: theme,
                      label: 'Known',
                      icon: Icons.check_circle_outline,
                      color: AppColors.familiarityHigh,
                          onPressed: () => vocabularyNotifier.markWordKnown(
                            word,
                            celebrationOrigin: origin(),
                          ),
                    ),
                  ),
                ),
              if (status != UserWordStatus.learning)
                Expanded(
                  child: _actionButton(
                    theme: theme,
                    label: 'Learning',
                    icon: Icons.school_outlined,
                    color: AppColors.vocabLearning,
                      onPressed: () => vocabularyNotifier.markWordLearning(word),
                  ),
                ),
              if (status != null || isBookmarked)
                Expanded(
                  child: _actionButton(
                    theme: theme,
                    label: 'Unknown',
                    icon: Icons.help_outline,
                    color: AppColors.familiarityLow,
                    onPressed: () =>
                        _markWordUnknown(vocabularyNotifier, bookmarkNotifier, word),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _learningItemSaved
              ? _savedLearningItemHint(theme)
              : SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        vocabularyNotifier.canCreateLearningItems &&
                            lookupState.selectedWordTranslation != null
                        ? () => _addLearningItem()
                        : null,
                    icon: const Icon(Icons.add_card_outlined, size: 20),
                    label: const Text('加入学习卡片'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 8),
          isBookmarked
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '已加入生词本',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: lookupState.selectedWordTranslation != null
                        ? () {
                            bookmarkNotifier.addBookmark(
                              word,
                              lookupState.selectedWordTranslation!,
                            );
                            setState(() => _bookmarkAdded = true);
                          }
                        : null,
                    icon: const Icon(Icons.bookmark_border, size: 22),
                    label: const Text('加入生词本'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(58),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 18,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _addLearningItem() async {
    final result = await ref.read(vocabularyNotifierProvider.notifier).addSelectedWordLearningItem();
    if (!mounted) return;
    if (result != null) {
      setState(() => _learningItemSaved = true);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == null
              ? '无法加入学习卡片'
              : result.created
              ? '已加入学习卡片'
              : '学习卡片已存在',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _markWordUnknown(
    VocabularyNotifier vocabularyNotifier,
    BookmarkNotifier bookmarkNotifier,
    String word,
  ) async {
    await vocabularyNotifier.markWordUnknown(word);
    if (bookmarkNotifier.isBookmarked(word)) {
      bookmarkNotifier.removeBookmark(word);
    }
    if (mounted) setState(() => _bookmarkAdded = false);
  }

  Widget _savedLearningItemHint(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_card,
            size: 18,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Text(
            '已加入学习卡片',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required ThemeData theme,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: color),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size(0, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

}

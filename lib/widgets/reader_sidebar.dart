import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis_result.dart';
import '../models/user_vocabulary.dart';
import '../providers/reading/bookmark_notifier.dart';
import '../providers/reading/current_book_notifier.dart';
import '../providers/reading/reading_provider_riverpod.dart'
    as riverpod_reading;
import '../providers/reading/services_provider.dart';
import '../providers/reading/vocabulary_notifier.dart';
import '../providers/reading/word_lookup_notifier.dart';
import '../providers/reading_provider.dart';
import '../services/word_level_service.dart';
import '../theme/app_colors.dart';
import 'dictionary_detail_view.dart';
import 'pronunciation_button.dart';
import 'reader_text_view.dart' show WordTapCallback;
import 'word_mastery_confetti.dart';

Color _sidebarLevelColor(String level) {
  switch (level) {
    case 'Primary School':
      return Colors.green;
    case 'Middle School':
      return Colors.teal;
    case 'High School':
      return Colors.blue;
    case 'CET-4':
      return Colors.orange;
    case 'CET-6':
      return Colors.deepOrange;
    case 'GRE':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

class ReaderSidebar extends ConsumerWidget {
  final AnalysisResult result;
  final WordTapCallback onWordTapped;

  const ReaderSidebar({
    super.key,
    required this.result,
    required this.onWordTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBookState = ref.watch(currentBookNotifierProvider);
    final currentBookNotifier = ref.read(currentBookNotifierProvider.notifier);
    final lookupState = ref.watch(wordLookupNotifierProvider);
    final lookupNotifier = ref.read(wordLookupNotifierProvider.notifier);
    ref.watch(vocabularyNotifierProvider);
    final vocabularyNotifier = ref.read(vocabularyNotifierProvider.notifier);
    ref.watch(bookmarkNotifierProvider);
    final bookmarkNotifier = ref.read(bookmarkNotifierProvider.notifier);
    final reader = ref.read(riverpod_reading.readingProvider);
    final wordLevelService = ref.read(wordLevelServiceProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildHeader(theme),
        if (currentBookNotifier.hasBook && currentBookNotifier.chapterCount > 1) ...[
          _buildChapterList(context, theme, currentBookNotifier, currentBookState),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ],
        Expanded(
          child: _buildVocabularyPanel(context, theme, result, lookupState, reader, wordLevelService),
        ),
        if (lookupState.selectedWord != null)
          _buildFloatingWordCard(
            theme, lookupState, lookupNotifier, vocabularyNotifier, bookmarkNotifier, reader, wordLevelService,
          ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final unknownCount = result.vocabulary
        .where((v) => v.familiarity <= 0.3)
        .length;
    final learningCount = result.vocabulary
        .where((v) => v.familiarity > 0.3 && v.familiarity <= 0.5)
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Vocabulary',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (unknownCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.familiarityLow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$unknownCount new',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.familiarityLow,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (learningCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.vocabLearning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$learningCount learning',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.vocabLearning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChapterList(
    BuildContext context,
    ThemeData theme,
    CurrentBookNotifier currentBook,
    CurrentBookState currentBookState,
  ) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: currentBook.chapterCount,
        itemBuilder: (context, index) {
          final isSelected = index == currentBookState.currentChapter;
          return ListTile(
            dense: true,
            selected: isSelected,
            selectedTileColor: theme.colorScheme.primaryContainer.withValues(
              alpha: 0.3,
            ),
            leading: CircleAvatar(
              radius: 12,
              backgroundColor: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            title: Text(
              currentBook.book!.chapters[index].title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            onTap: () => currentBook.goToChapter(index),
          );
        },
      ),
    );
  }

  Widget _buildVocabularyPanel(
    BuildContext context,
    ThemeData theme,
    AnalysisResult result,
    WordLookupState lookupState,
    ReadingProvider reader,
    WordLevelService wordLevelService,
  ) {
    if (result.vocabulary.isEmpty) {
      return Center(
        child: Text(
          '暂无生词',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: result.vocabulary.length,
      itemBuilder: (context, index) {
        final vocab = result.vocabulary[index];
        final isSelected =
            vocab.word.toLowerCase() ==
            (lookupState.selectedWord?.toLowerCase() ?? '');

        return Card(
          elevation: 0,
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: InkWell(
            onTap: () => onWordTapped(
              vocab.word,
              reader.activeLanguageModule.canonicalize(vocab.word),
              reader.activeLanguageModule.languageCode,
              vocab.context,
            ),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              vocab.word,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.familiarityColor(
                                  vocab.familiarity,
                                ),
                                fontFamily: 'Serif',
                              ),
                            ),
                            if (vocab.level != null) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: _sidebarLevelColor(
                                    vocab.level!,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  vocab.level!,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: _sidebarLevelColor(vocab.level!),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            if (vocab.familiarity > 0.3 &&
                                vocab.familiarity <= 0.5) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.vocabLearning.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'learning',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.vocabLearning.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          vocab.meaning,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(vocab.familiarity * 100).toInt()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.familiarityColor(vocab.familiarity),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingWordCard(
    ThemeData theme,
    WordLookupState lookupState,
    WordLookupNotifier lookupNotifier,
    VocabularyNotifier vocabularyNotifier,
    BookmarkNotifier bookmarkNotifier,
    ReadingProvider reader,
    WordLevelService wordLevelService,
  ) {
    final word = lookupState.selectedWord!;
    final status = vocabularyNotifier.getWordStatus(word);

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  word,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Serif',
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  bookmarkNotifier.isBookmarked(word)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  if (lookupState.selectedWordTranslation != null) {
                    if (bookmarkNotifier.isBookmarked(word)) {
                      bookmarkNotifier.removeBookmark(word);
                    } else {
                      bookmarkNotifier.addBookmark(
                        word,
                        lookupState.selectedWordTranslation!,
                      );
                    }
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              if (true)
                PronunciationButton(
                  word: word,
                  onSpeakWord: lookupNotifier.speakWord,
                  buttonSize: 32,
                  iconSize: 18,
                ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: lookupNotifier.clearWordLookup,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DictionaryDetailView.fromWordLookup(
            lookupState: lookupState,
            lookupNotifier: lookupNotifier,
            word: word,
            showWordHeader: false,
            wordLevelService: wordLevelService,
            canPronounceWords: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (status != UserWordStatus.known)
                WordMasteryActionAnchor(
                  builder: (context, origin) => _miniActionChip(
                    label: 'Known',
                    icon: Icons.check_circle_outline,
                    color: AppColors.familiarityHigh,
                      onTap: () => vocabularyNotifier.markWordKnown(
                        word,
                        celebrationOrigin: origin(),
                      ),
                  ),
                ),
              if (status != UserWordStatus.learning)
                _miniActionChip(
                  label: 'Learning',
                  icon: Icons.school_outlined,
                  color: AppColors.vocabLearning,
                    onTap: () => vocabularyNotifier.markWordLearning(word),
                ),
              if (status != null)
                _miniActionChip(
                  label: 'Unknown',
                  icon: Icons.help_outline,
                  color: AppColors.familiarityLow,
                    onTap: () => vocabularyNotifier.markWordUnknown(word),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniActionChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

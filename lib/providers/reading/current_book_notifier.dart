import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/analysis_result.dart';
import '../../models/book.dart';
import '../../models/book_difficulty.dart';
import '../../services/analysis_service.dart';
import '../../services/book_service.dart';
import '../../services/language/english_language_module.dart';
import '../../services/language/language_registry.dart';
import '../../services/reading_time_service.dart';
import '../../storage/hive_box_names.dart';
import '../settings_provider.dart';
import 'ai_notifier.dart';
import 'bookshelf_notifier.dart';
import 'reading_search_notifier.dart';
import 'services_provider.dart';

@immutable
class CurrentBookState {
  const CurrentBookState({
    this.currentChapter = 0,
    this.readingProgress = 0.0,
    this.readingScrollOffset,
    this.isReading = false,
    this.hasBeenOpened = false,
    this.currentTab = 0,
    this.result,
    this.currentBookDifficulty,
  });

  final int currentChapter;
  final double readingProgress;
  final double? readingScrollOffset;
  final bool isReading;
  final bool hasBeenOpened;
  final int currentTab;
  final AnalysisResult? result;
  final BookDifficultyRating? currentBookDifficulty;

  CurrentBookState copyWith({
    int? currentChapter,
    double? readingProgress,
    double? readingScrollOffset,
    bool? isReading,
    bool? hasBeenOpened,
    int? currentTab,
    AnalysisResult? result,
    BookDifficultyRating? currentBookDifficulty,
    bool clearScrollOffset = false,
    bool clearResult = false,
    bool clearDifficulty = false,
  }) {
    return CurrentBookState(
      currentChapter: currentChapter ?? this.currentChapter,
      readingProgress: readingProgress ?? this.readingProgress,
      readingScrollOffset: clearScrollOffset
          ? null
          : (readingScrollOffset ?? this.readingScrollOffset),
      isReading: isReading ?? this.isReading,
      hasBeenOpened: hasBeenOpened ?? this.hasBeenOpened,
      currentTab: currentTab ?? this.currentTab,
      result: clearResult ? null : (result ?? this.result),
      currentBookDifficulty:
          clearDifficulty ? null : (currentBookDifficulty ?? this.currentBookDifficulty),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentBookState &&
        other.currentChapter == currentChapter &&
        other.readingProgress == readingProgress &&
        other.readingScrollOffset == readingScrollOffset &&
        other.isReading == isReading &&
        other.hasBeenOpened == hasBeenOpened &&
        other.currentTab == currentTab &&
        other.result == result &&
        other.currentBookDifficulty == currentBookDifficulty;
  }

  @override
  int get hashCode => Object.hash(
        currentChapter,
        readingProgress,
        readingScrollOffset,
        isReading,
        hasBeenOpened,
        currentTab,
        result,
        currentBookDifficulty,
      );
}

class CurrentBookNotifier extends Notifier<CurrentBookState> {
  BookService get _bookService => ref.read(bookServiceProvider);
  ReadingTimeService? get _readingTime => ref.read(readingTimeServiceProvider);

  @override
  CurrentBookState build() {
    return const CurrentBookState();
  }

  Book? get book => ref.read(bookshelfNotifierProvider).book;

  String? get activeBookId => ref.read(bookshelfNotifierProvider).activeBookId;

  int get chapterCount => ref.read(bookshelfNotifierProvider).chapterCount;

  bool get hasBook => activeBookId != null;

  AnalysisResult? get result => state.result;

  BookDifficultyRating? get currentBookDifficulty => state.currentBookDifficulty;

  void updateReadingProgress(double progress, {double? scrollOffset}) {
    state = state.copyWith(
      readingProgress: progress.clamp(0.0, 1.0),
      readingScrollOffset:
          scrollOffset != null && scrollOffset >= 0 ? scrollOffset : null,
    );
  }

  Future<void> goToChapter(int index) async {
    final book = ref.read(bookshelfNotifierProvider).book;
    if (book == null || index == state.currentChapter) return;
    if (index < 0 || index >= book.chapters.length) return;
    if (state.isReading) {
      final bookId = activeBookId;
      if (bookId != null) {
        await _readingTime?.switchTarget(bookId, index);
      }
    }

    state = state.copyWith(
      currentChapter: index,
      readingProgress: 0.0,
      readingScrollOffset: 0.0,
      clearResult: true,
      clearDifficulty: true,
    );
    _saveCurrentProgress();

    ref.read(readingSearchNotifierProvider.notifier).clearSourceHighlight();
    ref.read(aiNotifierProvider.notifier).clearAIResults();

    await _analyzeCurrentChapter();
  }

  void enterReader() {
    final book = ref.read(bookshelfNotifierProvider).book;
    final bookId = activeBookId;
    if (book == null || bookId == null) return;
    _readingTime?.start(bookId, state.currentChapter);
    state = state.copyWith(isReading: true, hasBeenOpened: true);
  }

  void exitReader() {
    _readingTime?.stop();
    _saveCurrentProgress();
    state = state.copyWith(isReading: false);
  }

  void switchTab(int index) {
    state = state.copyWith(currentTab: index);
  }

  void highlightSourceExcerpt(String excerpt) {
    ref.read(readingSearchNotifierProvider.notifier).highlightSourceExcerpt(excerpt);
  }

  // ---- Internal ----

  void _saveCurrentProgress() {
    final bookId = activeBookId;
    final shelfBook = ref.read(bookshelfNotifierProvider).book;
    if (bookId == null || shelfBook == null) return;
    _bookService.updateProgress(
      bookId,
      state.currentChapter,
      state.readingProgress,
      chapterScrollOffset: state.readingScrollOffset,
    );
  }

  Future<void> _analyzeCurrentChapter() async {
    final book = ref.read(bookshelfNotifierProvider).book;
    if (book == null) return;
    final chapter = book.chapters[state.currentChapter];
    final userVocab = ref.read(userVocabularyServiceProvider);
    final wordLevelService = ref.read(wordLevelServiceProvider);
    final settings = ref.read(settingsProvider);
    final code = settings.activeSourceLanguage ?? HiveBoxNames.defaultLanguageCode;
    final languageModule = LanguageRegistry.instance.get(code) ??
        const EnglishLanguageModule();

    final analysis = AnalysisService.analyzeChapter(
      chapter.title,
      chapter.plainText,
      userVocab,
      wordLevelService,
      languageModule,
    );
    state = state.copyWith(result: analysis);
  }
}

final currentBookNotifierProvider =
    NotifierProvider<CurrentBookNotifier, CurrentBookState>(
  CurrentBookNotifier.new,
);

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/analysis_result.dart';
import '../../models/book.dart';
import '../../models/book_difficulty.dart';
import '../../models/book_metadata.dart';
import '../../services/analysis_service.dart';
import 'package:flow_language/flow_language.dart';
import '../../services/reading_time_service.dart';
import '../settings_provider.dart';
import 'ai_notifier.dart';
import 'bookshelf_notifier.dart';
import 'reading_search_notifier.dart';
import 'services_provider.dart';
import 'text_selection_notifier.dart';
import 'word_lookup_notifier.dart';

const double _readingProgressUpdateTolerance = 0.0005;
const double _readingScrollOffsetUpdateTolerance = 0.5;

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
      currentBookDifficulty: clearDifficulty
          ? null
          : (currentBookDifficulty ?? this.currentBookDifficulty),
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
  ReadingTimeService? get _readingTime => ref.read(readingTimeServiceProvider);

  final Map<int, AnalysisResult> _chapterAnalysisCache = {};

  @override
  CurrentBookState build() {
    return const CurrentBookState();
  }

  Book? get book => ref.read(bookshelfNotifierProvider).book;

  String? get activeBookId => ref.read(bookshelfNotifierProvider).activeBookId;

  int get chapterCount => ref.read(bookshelfNotifierProvider).chapterCount;

  bool get hasBook => activeBookId != null;

  AnalysisResult? get result => state.result;

  BookDifficultyRating? get currentBookDifficulty =>
      state.currentBookDifficulty;

  void updateReadingProgress(double progress, {double? scrollOffset}) {
    final nextProgress = progress.clamp(0.0, 1.0).toDouble();
    final nextScrollOffset = scrollOffset != null && scrollOffset >= 0
        ? scrollOffset
        : state.readingScrollOffset;
    final sameProgress =
        (state.readingProgress - nextProgress).abs() <
        _readingProgressUpdateTolerance;
    final currentOffset = state.readingScrollOffset;
    final sameScrollOffset = currentOffset == null || nextScrollOffset == null
        ? currentOffset == nextScrollOffset
        : (currentOffset - nextScrollOffset).abs() <
              _readingScrollOffsetUpdateTolerance;
    if (sameProgress && sameScrollOffset) return;

    state = state.copyWith(
      readingProgress: nextProgress,
      readingScrollOffset: nextScrollOffset,
    );
  }

  Future<void> goToChapter(int index) async {
    final book = ref.read(bookshelfNotifierProvider).book;
    if (book == null) return;
    if (index < 0 || index >= book.chapters.length) return;
    final sameChapter = index == state.currentChapter;
    if (sameChapter && state.result != null) return;

    if (!sameChapter && state.isReading) {
      final bookId = activeBookId;
      if (bookId != null) {
        await _readingTime?.switchTarget(bookId, index);
      }
    }

    final cached = _chapterAnalysisCache[index];

    state = state.copyWith(
      currentChapter: index,
      readingProgress: sameChapter ? state.readingProgress : 0.0,
      readingScrollOffset: sameChapter ? state.readingScrollOffset : 0.0,
      result: cached,
      clearResult: cached == null,
      clearDifficulty: true,
    );
    if (!sameChapter) {
      await _saveCurrentProgress();
    }

    ref.read(readingSearchNotifierProvider.notifier).clearSourceHighlight();
    ref.read(aiNotifierProvider.notifier).clearAIResults();

    if (cached == null) {
      if (sameChapter) {
        await _analyzeCurrentChapter();
        return;
      }
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!ref.mounted) return;
        _analyzeCurrentChapter();
      });
    }
  }

  void enterReader() {
    final book = ref.read(bookshelfNotifierProvider).book;
    final bookId = activeBookId;
    if (book == null || bookId == null) return;
    _readingTime?.start(bookId, state.currentChapter);
    state = state.copyWith(isReading: true, hasBeenOpened: true);
  }

  Future<void> exitReader() async {
    await _readingTime?.stop();
    await _saveCurrentProgress();
    if (!ref.mounted) return;
    state = state.copyWith(isReading: false);
    ref.read(wordLookupNotifierProvider.notifier).clearWordLookup();
    ref.read(readingSearchNotifierProvider.notifier).clearSearch();
    ref.read(textSelectionNotifierProvider.notifier).clearSelectedText();
    ref.read(aiNotifierProvider.notifier).clearAIResults();
  }

  void switchTab(int index) {
    state = state.copyWith(currentTab: index);
  }

  void highlightSourceExcerpt(String excerpt) {
    ref
        .read(readingSearchNotifierProvider.notifier)
        .highlightSourceExcerpt(excerpt);
  }

  Future<void> reanalyzeCurrentChapter() async {
    _chapterAnalysisCache.remove(state.currentChapter);
    await _analyzeCurrentChapter();
  }

  // ---- Internal ----

  Future<void> _saveCurrentProgress() async {
    await ref
        .read(bookshelfNotifierProvider.notifier)
        .persistReadingProgress(state);
  }

  Future<void> _analyzeCurrentChapter() async {
    final book = ref.read(bookshelfNotifierProvider).book;
    if (book == null) return;
    final chapter = book.chapters[state.currentChapter];
    final userVocab = ref.read(userVocabularyServiceProvider);
    final wordLevelService = ref.read(wordLevelServiceProvider);
    final languageModule = _currentLanguageModule();

    await wordLevelService.init();
    if (!ref.mounted) return;

    final analysis = AnalysisService.analyzeChapter(
      chapter.title,
      chapter.plainText,
      userVocab,
      wordLevelService,
      languageModule,
    );
    _chapterAnalysisCache[state.currentChapter] = analysis;
    state = state.copyWith(result: analysis);
  }

  LanguageModule _currentLanguageModule() {
    final settings = ref.read(settingsProvider);
    final metadata = _activeBookMetadata();
    final preferredCode =
        LanguageRegistry.normalizeLanguageCode(
          metadata?.effectiveSourceLanguage,
        ) ??
        LanguageRegistry.normalizeLanguageCode(settings.activeSourceLanguage) ??
        settings.activeSourceLanguage.trim().toLowerCase();
    final module =
        LanguageRegistry.instance.get(preferredCode) ??
        LanguageRegistry.instance.defaultModule;
    if (module == null) {
      throw StateError('Language "$preferredCode" not registered');
    }
    return module;
  }

  BookMetadata? _activeBookMetadata() {
    final bookId = activeBookId;
    if (bookId == null) return null;
    final bookService = ref.read(bookServiceProvider);
    return bookService.books.where((b) => b.id == bookId).firstOrNull;
  }

  void invalidateChapterAnalysisCache() {
    _chapterAnalysisCache.clear();
    state = state.copyWith(clearResult: true, clearDifficulty: true);
  }
}

final currentBookNotifierProvider =
    NotifierProvider<CurrentBookNotifier, CurrentBookState>(
      CurrentBookNotifier.new,
    );

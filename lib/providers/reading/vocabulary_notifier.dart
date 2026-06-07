import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/aggregated_vocabulary.dart';
import '../../models/book_difficulty.dart';
import '../../models/book_metadata.dart';
import '../../models/learning_analytics.dart';
import '../../models/learning_item.dart';
import '../../models/user_vocabulary.dart';
import '../../models/word_context_example.dart';
import '../../services/analysis_service.dart';
import '../../services/epub_parse_worker.dart';
import '../../services/language/language_module.dart';
import '../../services/language/language_registry.dart';
import '../../services/user_vocabulary_service.dart';
import '../../services/word_context_service.dart';
import '../../services/word_level_service.dart';
import '../../storage/hive_box_names.dart';
import '../settings_provider.dart';
import 'bookshelf_notifier.dart';
import 'current_book_notifier.dart';
import 'reading_provider_riverpod.dart';
import 'services_provider.dart';

@immutable
class VocabularyState {
  const VocabularyState({
    this.currentBookDifficulty,
    this.wordMasteredCelebrationTick = 0,
    this.wordMasteredCelebrationWord,
    this.wordMasteredCelebrationOrigin,
  });

  final BookDifficultyRating? currentBookDifficulty;
  final int wordMasteredCelebrationTick;
  final String? wordMasteredCelebrationWord;
  final Offset? wordMasteredCelebrationOrigin;

  VocabularyState copyWith({
    BookDifficultyRating? currentBookDifficulty,
    int? wordMasteredCelebrationTick,
    String? wordMasteredCelebrationWord,
    Offset? wordMasteredCelebrationOrigin,
  }) {
    return VocabularyState(
      currentBookDifficulty: currentBookDifficulty ?? this.currentBookDifficulty,
      wordMasteredCelebrationTick:
          wordMasteredCelebrationTick ?? this.wordMasteredCelebrationTick,
      wordMasteredCelebrationWord:
          wordMasteredCelebrationWord ?? this.wordMasteredCelebrationWord,
      wordMasteredCelebrationOrigin:
          wordMasteredCelebrationOrigin ?? this.wordMasteredCelebrationOrigin,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VocabularyState &&
        other.currentBookDifficulty == currentBookDifficulty &&
        other.wordMasteredCelebrationTick == wordMasteredCelebrationTick &&
        other.wordMasteredCelebrationWord == wordMasteredCelebrationWord &&
        other.wordMasteredCelebrationOrigin == wordMasteredCelebrationOrigin;
  }

  @override
  int get hashCode => Object.hash(
        currentBookDifficulty,
        wordMasteredCelebrationTick,
        wordMasteredCelebrationWord,
        wordMasteredCelebrationOrigin,
      );
}

class VocabularyNotifier extends Notifier<VocabularyState> {
  static const _difficultyRefreshDebounce = Duration(seconds: 2);
  static const _difficultyRefreshBatchSize = 4;
  static const _difficultyRefreshBatchPause = Duration(milliseconds: 16);

  final Map<String, AggregatedVocabulary> _allVocab = {};
  final Map<String, Set<String>> _bookStudyWordsById = {};
  final Map<String, BookDifficultyRating> _bookDifficultyById = {};
  final Map<String, String> _bookDifficultyFailureKeys = {};
  final Set<String> _loadingBookDifficultyIds = {};
  final Set<String> _pendingDifficultyRefreshBookIds = {};
  Timer? _difficultyRefreshTimer;
  bool _isRefreshingBookDifficulties = false;

  WordLevelService? get _wordLevelService =>
      ref.read(wordLevelServiceProvider);
  WordContextService? get _wordContextService =>
      ref.read(wordContextServiceProvider);

  LanguageModule get _activeLanguageModule {
    final reader = ref.read(readingProvider);
    return reader.activeLanguageModule;
  }

  @override
  VocabularyState build() {
    ref.onDispose(() {
      _difficultyRefreshTimer?.cancel();
    });
    try {
      _loadCachedBookDifficultyInputs();
    } catch (_) {
      // BookService not yet available or not overridden in tests.
    }
    return const VocabularyState();
  }

  // ---- Public API ----

  int get totalVocabularyCount => _allVocab.length;

  List<LearningItem> get learningItems {
    final reader = ref.read(readingProvider);
    return reader.learningItems;
  }

  int get knownWordCount {
    final reader = ref.read(readingProvider);
    return reader.userVocabulary?.knownWords.length ?? 0;
  }

  int get learningWordCount {
    final reader = ref.read(readingProvider);
    return reader.userVocabulary?.learningWords.length ?? 0;
  }

  int get todayReviewDueCount {
    final reader = ref.read(readingProvider);
    return reader.todayReviewDueCount;
  }

  int get learningItemCount {
    final reader = ref.read(readingProvider);
    return reader.learningItemCount;
  }

  ChapterLearningReport? get currentChapterLearningReport {
    final reader = ref.read(readingProvider);
    return reader.currentChapterLearningReport;
  }

  WeeklyLearningSummary? get weeklyLearningSummary {
    final reader = ref.read(readingProvider);
    return reader.weeklyLearningSummary;
  }

  List<AggregatedVocabulary> getAllVocabulary({bool alphabetical = false}) {
    final vocab = _allVocab.values.toList();
    if (alphabetical) {
      vocab.sort((a, b) => a.word.compareTo(b.word));
    } else {
      vocab.sort((a, b) {
        final c = a.firstChapter.compareTo(b.firstChapter);
        if (c != 0) return c;
        return a.word.compareTo(b.word);
      });
    }
    return vocab;
  }

  BookDifficultyRating? difficultyForBook(String bookId) {
    final reader = ref.read(readingProvider);
    final activeBookId =
        ref.read(bookshelfNotifierProvider).activeBookId ?? reader.activeBookId;
    if (bookId == activeBookId) return state.currentBookDifficulty;
    return _bookDifficultyById[bookId];
  }

  bool isBookDifficultyLoading(String bookId) {
    return _loadingBookDifficultyIds.contains(bookId);
  }

  bool get isLoadingBookDifficulties => _loadingBookDifficultyIds.isNotEmpty;
  int get loadingBookDifficultyCount => _loadingBookDifficultyIds.length;

  Future<void> ensureBookDifficulties(Iterable<BookMetadata> books) async {
    final reader = ref.read(readingProvider);
    var hydratedFromCache = false;
    for (final book in books) {
      if (_bookDifficultyById.containsKey(book.id) ||
          _loadingBookDifficultyIds.contains(book.id)) {
        continue;
      }
      if (_bookDifficultyFailureKeys[book.id] == _difficultyFailureKey(book)) {
        continue;
      }
      hydratedFromCache =
          await _tryUseCachedDifficulty(book) || hydratedFromCache;
    }
    _scheduleDifficultyRefresh();

    final pending = books
        .where(
          (book) =>
              !_bookDifficultyById.containsKey(book.id) &&
              !_loadingBookDifficultyIds.contains(book.id) &&
              _bookDifficultyFailureKeys[book.id] !=
                  _difficultyFailureKey(book),
        )
        .toList(growable: false);
    if (pending.isEmpty) return;

    _loadingBookDifficultyIds.addAll(pending.map((book) => book.id));

    for (final meta in pending) {
      try {
        final shelf = ref.read(bookshelfNotifierProvider);
        final shelfBook = shelf.book ?? reader.book;
        final activeBookId = shelf.activeBookId ?? reader.activeBookId;
        final book = meta.id == activeBookId && shelfBook != null
            ? shelfBook
            : await EpubParseWorker.parseInIsolate(meta.sourcePath);
        final studyWords = AnalysisService.collectBookStudyWords(
          book,
          _wordLevelService,
          _activeLanguageModule,
        );
        final rating = AnalysisService.rateBookDifficulty(
          studyWords,
          reader.userVocabulary,
        );
        await _persistBookDifficulty(meta.id, studyWords, rating);
        _bookDifficultyFailureKeys.remove(meta.id);
      } catch (_) {
        _bookDifficultyById.remove(meta.id);
        _bookStudyWordsById.remove(meta.id);
        _bookDifficultyFailureKeys[meta.id] = _difficultyFailureKey(meta);
      } finally {
        _loadingBookDifficultyIds.remove(meta.id);
      }
    }
  }

  UserWordStatus? getWordStatus(String word) {
    final reader = ref.read(readingProvider);
    return reader.userVocabulary?.getStatus(_canonicalWord(word));
  }

  bool isWordKnown(String word) {
    final reader = ref.read(readingProvider);
    return reader.userVocabulary?.isKnown(_canonicalWord(word)) ?? false;
  }

  bool isWordLearning(String word) {
    final reader = ref.read(readingProvider);
    return reader.userVocabulary?.isLearning(_canonicalWord(word)) ?? false;
  }

  Future<void> markWordKnown(String word, {Offset? celebrationOrigin}) async {
    final reader = ref.read(readingProvider);
    final vocab = reader.userVocabulary;
    final canonical = _canonicalWord(word);
    final previousStatus = vocab?.getStatus(canonical);
    await vocab?.setKnown(canonical);
    _recordWordMasteredCelebration(
      canonical,
      previousStatus,
      origin: celebrationOrigin,
    );
    _queueDifficultyRefreshForVocabularyChange(
      canonical,
      previousStatus,
      UserWordStatus.known,
    );
    await _analyzeCurrentChapter();
  }

  Future<void> markWordLearning(String word) async {
    final reader = ref.read(readingProvider);
    final vocab = reader.userVocabulary;
    final canonical = _canonicalWord(word);
    final previousStatus = vocab?.getStatus(canonical);
    await vocab?.setLearning(canonical);
    _queueDifficultyRefreshForVocabularyChange(
      canonical,
      previousStatus,
      UserWordStatus.learning,
    );
    await _analyzeCurrentChapter();
  }

  Future<void> markWordUnknown(String word) async {
    final reader = ref.read(readingProvider);
    final vocab = reader.userVocabulary;
    final canonical = _canonicalWord(word);
    final previousStatus = vocab?.getStatus(canonical);
    await vocab?.setUnknown(canonical);
    _queueDifficultyRefreshForVocabularyChange(canonical, previousStatus, null);
    await _analyzeCurrentChapter();
  }

  Future<void> deleteLearningItem(String id) async {
    final reader = ref.read(readingProvider);
    await reader.deleteLearningItem(id);
  }

  bool get canCreateLearningItems {
    final reader = ref.read(readingProvider);
    return reader.canCreateLearningItems;
  }

  Future<LearningItemSaveResult?> addSelectedWordLearningItem() {
    final reader = ref.read(readingProvider);
    return reader.addSelectedWordLearningItem();
  }

  Future<LearningItemSaveResult?> addSelectedTextLearningItem() {
    final reader = ref.read(readingProvider);
    return reader.addSelectedTextLearningItem();
  }

  LanguageModule get activeLanguageModule {
    final reader = ref.read(readingProvider);
    return reader.activeLanguageModule;
  }

  UserVocabularyService? get userVocabulary {
    final reader = ref.read(readingProvider);
    return reader.userVocabulary;
  }

  List<WordContextExample> importedExamplesFor(String word) {
    return _wordContextService?.examplesFor(word) ?? const [];
  }

  // ---- Chapter re-analysis ----

  Future<void> _analyzeCurrentChapter() async {
    final reader = ref.read(readingProvider);
    final shelfBook =
        ref.read(bookshelfNotifierProvider).book ?? reader.book;
    if (shelfBook == null) return;
    _updateAllVocab();
  }

  void _updateAllVocab() {
    final reader = ref.read(readingProvider);
    final vocab = reader.userVocabulary;
    final result = reader.result;
    if (result == null) return;
    final currentChapter = ref.read(currentBookNotifierProvider).currentChapter;
    _allVocab.removeWhere(
      (_, aggVocab) => reader.userVocabulary?.isKnown(aggVocab.word) ?? false,
    );
    final languageId = _activeVocabularyLanguageId;
    for (final v in result.vocabulary) {
      final lower = v.word;
      if (vocab?.isKnown(lower) ?? false) continue;
      final vocabularyKey = _aggregatedVocabularyKey(languageId, lower);
      if (_allVocab.containsKey(vocabularyKey)) {
        final existing = _allVocab[vocabularyKey]!;
        _allVocab[vocabularyKey] = existing.copyWith(
          chapterIndices:
              existing.updatedChapters(currentChapter),
          level: v.level,
          languageId: languageId,
        );
      } else {
        _allVocab[vocabularyKey] = AggregatedVocabulary(
          word: lower,
          meaning: v.meaning,
          firstChapter: currentChapter,
          context: v.context,
          chapterIndices: {currentChapter},
          level: v.level,
          languageId: languageId,
        );
      }
    }
  }

  String get _activeVocabularyLanguageId {
    final reader = ref.read(readingProvider);
    final sourceLanguage = reader.activeBookMetadata?.effectiveSourceLanguage;
    final settings = ref.read(settingsProvider);
    return LanguageRegistry.normalizeLanguageCode(sourceLanguage) ??
        LanguageRegistry.normalizeLanguageCode(
          settings.activeSourceLanguage,
        ) ??
        HiveBoxNames.defaultLanguageCode;
  }

  String _aggregatedVocabularyKey(String languageId, String canonical) {
    return '${languageId.toLowerCase().trim()}_${canonical.toLowerCase().trim()}';
  }

  // ---- Celebration ----

  void _recordWordMasteredCelebration(
    String word,
    UserWordStatus? previousStatus, {
    Offset? origin,
  }) {
    final reader = ref.read(readingProvider);
    if (reader.userVocabulary == null || previousStatus == UserWordStatus.known) return;
    state = state.copyWith(
      wordMasteredCelebrationWord: word,
      wordMasteredCelebrationOrigin: origin,
      wordMasteredCelebrationTick: state.wordMasteredCelebrationTick + 1,
    );
  }

  // ---- Difficulty refresh ----

  void _loadCachedBookDifficultyInputs() {
    final bookService = ref.read(bookServiceProvider);
    _difficultyRefreshTimer?.cancel();
    _difficultyRefreshTimer = null;
    _pendingDifficultyRefreshBookIds.clear();
    final bookIds = bookService.books.map((book) => book.id).toSet();
    _bookStudyWordsById.removeWhere((id, _) => !bookIds.contains(id));
    _bookDifficultyById.removeWhere((id, _) => !bookIds.contains(id));
    _bookDifficultyFailureKeys.removeWhere((id, _) => !bookIds.contains(id));

    for (final meta in bookService.books) {
      _usePersistedDifficulty(meta);
    }
    _scheduleDifficultyRefresh();
  }

  void _usePersistedDifficulty(BookMetadata meta) {
    final cached = meta.difficultyStudyWords;
    if (cached != null) {
      _bookStudyWordsById[meta.id] = cached.toSet();
    }
    final rating = meta.difficultyRating;
    if (rating != null) {
      _bookDifficultyById[meta.id] = rating;
      _bookDifficultyFailureKeys.remove(meta.id);
    }
    final reader = ref.read(readingProvider);
    final activeBookId =
        ref.read(bookshelfNotifierProvider).activeBookId ?? reader.activeBookId;
    if (meta.id == activeBookId) {
      state = state.copyWith(currentBookDifficulty: rating);
    }
    if (cached != null && _isDifficultyCacheStale(meta)) {
      _pendingDifficultyRefreshBookIds.add(meta.id);
    }
  }

  Future<bool> _tryUseCachedDifficulty(BookMetadata meta) async {
    _usePersistedDifficulty(meta);
    if (_bookDifficultyById.containsKey(meta.id)) return true;

    final studyWords = _bookStudyWordsById[meta.id];
    if (studyWords == null) return false;
    final reader = ref.read(readingProvider);
    final rating =
        AnalysisService.rateBookDifficulty(studyWords, reader.userVocabulary);
    await _persistBookDifficulty(meta.id, studyWords, rating);
    return true;
  }

  bool _isDifficultyCacheStale(BookMetadata meta) {
    return meta.difficultyVocabularySignature != _vocabularySignature;
  }

  String _difficultyFailureKey(BookMetadata meta) {
    return '${meta.sourcePath}|$_vocabularySignature';
  }

  Future<void> _persistBookDifficulty(
    String bookId,
    Set<String> studyWords,
    BookDifficultyRating rating,
  ) async {
    final reader = ref.read(readingProvider);
    final bookService = ref.read(bookServiceProvider);
    _bookStudyWordsById[bookId] = studyWords;
    _bookDifficultyById[bookId] = rating;
    final activeBookId =
        ref.read(bookshelfNotifierProvider).activeBookId ?? reader.activeBookId;
    if (bookId == activeBookId) {
      state = state.copyWith(currentBookDifficulty: rating);
    }
    await bookService.updateDifficultyCache(
      id: bookId,
      studyWords: studyWords,
      rating: rating,
      vocabularySignature: _vocabularySignature,
    );
  }

  void _queueDifficultyRefreshForWord(String word) {
    final affectedBookIds = _bookStudyWordsById.entries
        .where((entry) => entry.value.contains(word))
        .map((entry) => entry.key);
    _pendingDifficultyRefreshBookIds.addAll(affectedBookIds);
    _scheduleDifficultyRefresh();
  }

  void _queueDifficultyRefreshForVocabularyChange(
    String word,
    UserWordStatus? previousStatus,
    UserWordStatus? nextStatus,
  ) {
    if (previousStatus == UserWordStatus.known ||
        nextStatus == UserWordStatus.known) {
      _pendingDifficultyRefreshBookIds.addAll(_bookStudyWordsById.keys);
      _scheduleDifficultyRefresh();
      return;
    }
    _queueDifficultyRefreshForWord(word);
  }

  void _scheduleDifficultyRefresh() {
    if (_pendingDifficultyRefreshBookIds.isEmpty ||
        _isRefreshingBookDifficulties) {
      return;
    }
    _difficultyRefreshTimer?.cancel();
    _difficultyRefreshTimer = Timer(_difficultyRefreshDebounce, () {
      unawaited(_refreshPendingBookDifficulties());
    });
  }

  Future<void> _refreshPendingBookDifficulties() async {
    if (_isRefreshingBookDifficulties ||
        _pendingDifficultyRefreshBookIds.isEmpty) {
      return;
    }

    _difficultyRefreshTimer?.cancel();
    _difficultyRefreshTimer = null;
    _isRefreshingBookDifficulties = true;
    try {
      while (_pendingDifficultyRefreshBookIds.isNotEmpty) {
        final batch = _takeDifficultyRefreshBatch();
        for (final bookId in batch) {
          final studyWords = _bookStudyWordsById[bookId];
          if (studyWords == null) continue;
          final reader = ref.read(readingProvider);
          final rating = AnalysisService.rateBookDifficulty(
            studyWords,
            reader.userVocabulary,
          );
          await _persistBookDifficulty(bookId, studyWords, rating);
        }
        if (_pendingDifficultyRefreshBookIds.isNotEmpty) {
          await Future<void>.delayed(_difficultyRefreshBatchPause);
        }
      }
    } finally {
      _isRefreshingBookDifficulties = false;
      _scheduleDifficultyRefresh();
    }
  }

  List<String> _takeDifficultyRefreshBatch() {
    final batch = <String>[];
    for (final bookId in _pendingDifficultyRefreshBookIds) {
      batch.add(bookId);
      if (batch.length >= _difficultyRefreshBatchSize) break;
    }
    _pendingDifficultyRefreshBookIds.removeAll(batch);
    return batch;
  }

  String get _vocabularySignature {
    final reader = ref.read(readingProvider);
    return reader.userVocabulary?.revisionSignature ??
        UserVocabularyService.emptyRevisionSignature;
  }

  // ---- Word canonicalization ----

  String _canonicalWord(String word) {
    final key = _activeLanguageModule.canonicalize(word);
    if (key.isEmpty) return key;
    return _wordLevelService?.canonicalForm(key) ?? key;
  }

}

final vocabularyNotifierProvider =
    NotifierProvider<VocabularyNotifier, VocabularyState>(
  VocabularyNotifier.new,
);

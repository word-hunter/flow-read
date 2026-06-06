import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:epub_reader_core/epub_reader_core.dart' as core;
import 'package:flutter/foundation.dart';

import '../controllers/reading_search_controller.dart';
import '../models/aggregated_vocabulary.dart';
import '../models/ai_chapter_preview.dart';
import '../models/ai_practice_questions.dart';
import '../models/ai_summary.dart';
import '../models/ai_text_analysis.dart';
import '../models/analysis_result.dart';
import '../models/book.dart';
import '../models/book_difficulty.dart';
import '../models/book_metadata.dart';
import '../models/bookmarked_word.dart';
import '../models/chapter_ai_coverage.dart';
import '../models/chapter_ai_status.dart';
import '../models/learning_item.dart';
import '../models/learning_analytics.dart';
import '../models/reader_font.dart';
import '../models/reading_search_result.dart';
import '../models/reading_bookmark.dart';
import '../models/sentence_breakdown.dart';
import '../models/user_vocabulary.dart';
import '../models/word_context_example.dart';
import '../models/word_analysis.dart';
import '../services/ai_cache_service.dart';
import '../services/ai_service.dart';
import '../services/analysis_service.dart';
import '../services/app_logger.dart';
import '../services/book_service.dart';
import '../services/bookmark_service.dart';
import '../services/chapter_ai_job.dart';
import '../services/compound_word_analyzer.dart';
import '../services/epub_import_source.dart';
import '../services/epub_parse_worker.dart';
import '../services/learning_item_service.dart';
import '../services/learning_analytics_service.dart';
import '../services/language/english_language_module.dart';
import '../services/language/language_module.dart';
import '../services/language/language_registry.dart';
import '../services/passage_request_builder.dart';
import '../services/prompt_builder.dart';
import '../services/pronunciation_service.dart';
import '../services/reading_config_service.dart';
import '../services/reading_search_service.dart';
import '../services/review_schedule_service.dart';
import '../services/reading_time_service.dart';
import '../services/sentence_analyzer.dart';
import '../services/settings_service.dart';
import '../services/user_vocabulary_service.dart';
import '../services/word_context_service.dart';
import '../services/word_level_service.dart';
import '../services/dictionary/word_repository.dart';
import '../services/dictionary/wordnet_repository.dart';
import '../storage/hive_box_names.dart';

class _ImportCancelledException implements Exception {
  const _ImportCancelledException();
}

enum BookImportResult { imported, cancelled, failed, ignored }

class ImportProgressState {
  const ImportProgressState({
    this.isImportingBook = false,
    this.isCancellingImport = false,
    this.canCancelImport = false,
    this.progress,
    this.fileName,
    this.stage = '',
  });

  static const idle = ImportProgressState();

  final bool isImportingBook;
  final bool isCancellingImport;
  final bool canCancelImport;
  final double? progress;
  final String? fileName;
  final String stage;

  @override
  bool operator ==(Object other) {
    return other is ImportProgressState &&
        other.isImportingBook == isImportingBook &&
        other.isCancellingImport == isCancellingImport &&
        other.canCancelImport == canCancelImport &&
        other.progress == progress &&
        other.fileName == fileName &&
        other.stage == stage;
  }

  @override
  int get hashCode => Object.hash(
    isImportingBook,
    isCancellingImport,
    canCancelImport,
    progress,
    fileName,
    stage,
  );
}

class ImportProgressNotifier extends ValueNotifier<ImportProgressState> {
  ImportProgressNotifier() : super(ImportProgressState.idle);
}

class ReadingProvider extends ChangeNotifier {
  static const _difficultyRefreshDebounce = Duration(seconds: 2);
  static const _difficultyRefreshBatchSize = 4;
  static const _difficultyRefreshBatchPause = Duration(milliseconds: 16);
  static const _importCancelDelay = Duration(seconds: 10);
  static const _importParseProgressStart = 0.18;
  static const _importParseProgressEnd = 0.72;
  static const _compoundMeaningHints = <String, String>{
    'god': '神',
    'gods': '众神',
    'wood': '树林',
    'dragon': '龙',
    'glass': '玻璃',
    'king': '国王',
    'road': '道路',
  };

  // ============================================================
  // Dependencies
  // ============================================================
  WordRepository _wordRepo = WordNetRepository();
  UserVocabularyService? _userVocab;
  late BookService _bookService;
  BookmarkService? _bookmarkService;
  ReadingConfigService? _readingConfig;
  ReadingTimeService? _readingTime;
  SentenceAnalyzer _sentenceAnalyzer = RuleBasedSentenceAnalyzer();
  final PassageRequestBuilder _passageRequestBuilder =
      const PassageRequestBuilder();
  SettingsService? _settings;
  AIService? _aiService;
  AICacheService? _aiCache;
  WordLevelService? _wordLevelService;
  WordContextService? _wordContextService;
  LearningItemService? _learningItemService;
  LearningAnalyticsService? _learningAnalyticsService;
  ReviewScheduleService? _reviewScheduleService;
  PronunciationService? _pronunciationService;

  // ============================================================
  // Core reading state
  // ============================================================
  Book? _book;
  String? _activeBookId;
  AnalysisResult? _result;
  int _currentChapter = 0;
  double _readingProgress = 0.0;
  double? _readingScrollOffset;
  bool _isReading = false;
  bool _hasBeenOpened = false;
  final Map<String, AggregatedVocabulary> _allVocab = {};
  Set<String> _currentBookStudyWords = {};
  BookDifficultyRating? _currentBookDifficulty;
  final Map<String, Set<String>> _bookStudyWordsById = {};
  final Map<String, BookDifficultyRating> _bookDifficultyById = {};
  final Map<String, String> _bookDifficultyFailureKeys = {};
  final Set<String> _loadingBookDifficultyIds = {};
  final Set<String> _pendingDifficultyRefreshBookIds = {};
  Timer? _difficultyRefreshTimer;
  bool _isRefreshingBookDifficulties = false;

  // ============================================================
  // Bookmarks (in-memory, backed by BookmarkService)
  // ============================================================
  final List<BookmarkedWord> _bookmarkedWords = [];
  final List<ReadingBookmark> _readingBookmarks = [];

  // ============================================================
  // UI state
  // ============================================================
  int _currentTab = 0;
  bool _isLoading = false;
  String? _errorMessage;
  String _importStage = '';
  bool _isImportingBook = false;
  bool _isCancellingImport = false;
  bool _showImportCancel = false;
  bool _importCancellationRequested = false;
  double? _importProgress;
  String? _importFileName;
  Timer? _importCancelTimer;
  EpubParseTask? _activeImportParseTask;
  BookImportResult _lastImportResult = BookImportResult.ignored;
  final ImportProgressNotifier _importProgressNotifier =
      ImportProgressNotifier();
  int _wordMasteredCelebrationTick = 0;
  String? _wordMasteredCelebrationWord;
  Offset? _wordMasteredCelebrationOrigin;

  // ============================================================
  // Word lookup state
  // ============================================================
  String? _selectedWord;
  String? _selectedWordTranslation;
  String? _selectedWordContext;
  int? _selectedWordContextStart;
  int? _selectedWordContextEnd;
  DictionaryEntry? _selectedWordEntry;
  DictionaryLookupResult? _selectedWordLookupResult;
  final List<DictionaryLookupResult> _wordLookupHistory = [];
  bool _isLoadingWord = false;
  int _wordLookupRequestVersion = 0;

  // ============================================================
  // Text selection / analysis state
  // ============================================================
  String? _selectedText;
  AnalysisResult? _selectedAnalysis;
  List<SentenceBreakdown>? _selectedBreakdowns;

  // ============================================================
  // Full-book search state
  // ============================================================
  final ReadingSearchController _searchController = ReadingSearchController();
  String _sourceHighlightQuery = '';

  // ============================================================
  // AI state
  // ============================================================
  AITextAnalysis? _aiTextAnalysis;
  bool _isAnalyzingText = false;
  String? _aiTranslation;
  bool _isTranslatingText = false;
  AISummary? _aiSummary;
  bool _isGeneratingSummary = false;
  AIChapterPreview? _aiChapterPreview;
  bool _isGeneratingChapterPreview = false;
  ChapterAIStatus? _chapterAIStatus;
  ChapterAISummaryCoverage? _chapterAISummaryCoverage;
  bool _isLoadingChapterAISummaryCoverage = false;
  String _summaryLanguage = 'zh';
  AIPracticeSet? _aiPractice;
  bool _isGeneratingPractice = false;
  WordAnalysis? _aiWordAnalysis;
  bool _isAnalyzingWord = false;

  ReadingProvider() {
    _searchController.addListener(notifyListeners);
  }

  // ============================================================
  // Public getters
  // ============================================================

  // -- Core --
  Book? get book => _book;
  String? get activeBookId => _activeBookId;
  BookMetadata? get activeBookMetadata => _activeBookMetadata;
  AnalysisResult? get result => _result;
  int get currentChapter => _currentChapter;
  double get readingProgress => _readingProgress;
  double? get readingScrollOffset => _readingScrollOffset;
  bool get isReading => _isReading;
  bool get hasBook => _book != null;
  int get chapterCount => _book?.chapters.length ?? 0;
  bool get hasBeenOpened => _hasBeenOpened;
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

  int get totalVocabularyCount => _allVocab.length;
  BookDifficultyRating? get currentBookDifficulty => _currentBookDifficulty;
  bool get isLoadingBookDifficulties => _loadingBookDifficultyIds.isNotEmpty;
  int get loadingBookDifficultyCount => _loadingBookDifficultyIds.length;

  // -- Bookmarks --
  List<BookmarkedWord> get bookmarkedWords =>
      List.unmodifiable(_bookmarkedWords);
  List<ReadingBookmark> get readingBookmarks =>
      List.unmodifiable(_readingBookmarks);

  // -- Bookshelf --
  List<BookMetadata> get allBooks {
    final list = _bookService.books;
    list.sort((a, b) {
      final aTime = a.lastReadAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.lastReadAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });
    return list;
  }

  double get globalProgress {
    if (_activeBookId != null) {
      final meta = _bookService.books
          .where((b) => b.id == _activeBookId)
          .firstOrNull;
      if (meta != null) return meta.globalProgress;
    }
    return 0.0;
  }

  Uint8List? getCoverBytes(String bookId) => _bookService.loadCover(bookId);

  BookMetadata? get _activeBookMetadata {
    final bookId = _activeBookId;
    if (bookId == null) return null;
    return _bookService.books.where((book) => book.id == bookId).firstOrNull;
  }

  int noteCountForBook(String bookId) {
    final wordCount = _bookmarkService?.loadWordBookmarks(bookId).length ?? 0;
    final readingCount =
        _bookmarkService?.loadReadingBookmarks(bookId).length ?? 0;
    return wordCount + readingCount;
  }

  String? latestReadingExcerptForBook(String bookId) {
    final bookmarks = _bookmarkService?.loadReadingBookmarks(bookId) ?? [];
    for (final bookmark in bookmarks) {
      final excerpt = bookmark.excerpt.trim();
      if (excerpt.isNotEmpty) return excerpt;
    }
    return null;
  }

  BookDifficultyRating? difficultyForBook(String bookId) {
    if (bookId == _activeBookId) return _currentBookDifficulty;
    return _bookDifficultyById[bookId];
  }

  bool isBookDifficultyLoading(String bookId) {
    return _loadingBookDifficultyIds.contains(bookId);
  }

  Future<void> ensureBookDifficulties(Iterable<BookMetadata> books) async {
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
    if (hydratedFromCache) notifyListeners();
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
    notifyListeners();

    for (final meta in pending) {
      try {
        final book = meta.id == _activeBookId && _book != null
            ? _book!
            : await EpubParseWorker.parseInIsolate(meta.sourcePath);
        final studyWords = AnalysisService.collectBookStudyWords(
          book,
          _wordLevelService,
          activeLanguageModule,
        );
        final rating = AnalysisService.rateBookDifficulty(
          studyWords,
          _userVocab,
        );
        await _persistBookDifficulty(meta.id, studyWords, rating);
        _bookDifficultyFailureKeys.remove(meta.id);
      } catch (_) {
        _bookDifficultyById.remove(meta.id);
        _bookStudyWordsById.remove(meta.id);
        _bookDifficultyFailureKeys[meta.id] = _difficultyFailureKey(meta);
      } finally {
        _loadingBookDifficultyIds.remove(meta.id);
        notifyListeners();
      }
    }

    notifyListeners();
  }

  // -- UI --
  int get currentTab => _currentTab;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get importStage => _importStage;
  bool get isImportingBook => _isImportingBook;
  bool get isCancellingImport => _isCancellingImport;
  bool get canCancelImport =>
      _isImportingBook && _showImportCancel && !_isCancellingImport;
  double? get importProgress => _importProgress;
  String? get importFileName => _importFileName;
  BookImportResult get lastImportResult => _lastImportResult;
  ImportProgressNotifier get importProgressNotifier => _importProgressNotifier;

  // -- Word lookup --
  String? get selectedWord => _selectedWord;
  String? get selectedWordTranslation => _selectedWordTranslation;
  String? get selectedWordContext => _selectedWordContext;
  int? get selectedWordContextStart => _selectedWordContextStart;
  int? get selectedWordContextEnd => _selectedWordContextEnd;
  DictionaryEntry? get selectedWordEntry => _selectedWordEntry;
  DictionaryLookupResult? get selectedWordLookupResult =>
      _selectedWordLookupResult;
  bool get canGoBackWordLookup => _wordLookupHistory.isNotEmpty;
  bool get isLoadingWord => _isLoadingWord;

  // -- Text analysis --
  String? get selectedText => _selectedText;
  AnalysisResult? get selectedAnalysis => _selectedAnalysis;
  List<SentenceBreakdown>? get selectedBreakdowns => _selectedBreakdowns;
  SentenceAnalyzer get sentenceAnalyzer => _sentenceAnalyzer;

  // -- Full-book search --
  String get searchQuery => _searchController.query;
  List<ReadingSearchResult> get searchResults => _searchController.results;
  bool get isSearching => _searchController.isSearching;
  bool get searchStoppedAtLimit => _searchController.stoppedAtLimit;
  ReadingSearchResult? get activeSearchResult => _searchController.activeResult;
  String get sourceHighlightQuery => _sourceHighlightQuery;

  // -- Reading config (delegated to ReadingConfigService) --
  double get fontSize => _readingConfig?.fontSize ?? 16.0;
  String get fontFamily =>
      _readingConfig?.fontFamily ?? ReaderFonts.defaultFamily;
  double get lineHeight => _readingConfig?.lineHeight ?? 2.0;
  String get readingTheme => _readingConfig?.theme ?? 'light';

  // -- Reading time (delegated to ReadingTimeService) --
  int get readingTimeSeconds => _readingTime?.totalSeconds ?? 0;
  String get readingTimeDisplay => _readingTime?.displayText ?? '0 秒';
  int get todayReadingTimeSeconds => _readingTime?.todaySeconds ?? 0;
  int get dailyReadingGoalSeconds =>
      _settings?.dailyReadingGoalSeconds ??
      SettingsService.defaultDailyReadingGoalMinutes * 60;
  bool get dailyReadingGoalReached =>
      dailyReadingGoalSeconds > 0 &&
      todayReadingTimeSeconds >= dailyReadingGoalSeconds;
  int readingTimeSecondsForBook(String bookId) {
    final seconds = _readingTime?.secondsForBook(bookId) ?? 0;
    if (seconds > 0 || _bookService.books.length != 1) return seconds;
    return readingTimeSeconds;
  }

  int get weekReadingTimeSeconds => _readingTime?.secondsForWeek() ?? 0;
  int get monthReadingTimeSeconds => _readingTime?.secondsForMonth() ?? 0;
  DateTime get readingGoalDate => _readingTime?.currentDate ?? DateTime.now();
  List<int> get weekDailyReadingSeconds =>
      _readingTime?.secondsByDayForWeek() ?? const [0, 0, 0, 0, 0, 0, 0];
  List<int> get monthDailyReadingSeconds =>
      _readingTime?.secondsByDayForMonth() ?? const [];

  int get readingGoalReachedDaysThisWeek {
    return _readingTime?.goalReachedDaysForWeek(dailyReadingGoalSeconds) ?? 0;
  }

  // -- AI --
  AITextAnalysis? get aiTextAnalysis => _aiTextAnalysis;
  bool get isAnalyzingText => _isAnalyzingText;
  String? get aiTranslation => _aiTranslation;
  bool get isTranslatingText => _isTranslatingText;
  AISummary? get aiSummary => _aiSummary;
  bool get isGeneratingSummary => _isGeneratingSummary;
  AIChapterPreview? get aiChapterPreview => _aiChapterPreview;
  bool get isGeneratingChapterPreview => _isGeneratingChapterPreview;
  ChapterAIStatus? get chapterAIStatus {
    if (!aiFeaturesEnabled) {
      return ChapterAIStatus.unconfigured(aiFeatureDisabledReason);
    }
    if (_isGeneratingChapterPreview) {
      return const ChapterAIStatus.loading(
        ChapterAIFeature.preview,
        '正在生成读前预览...',
      );
    }
    if (_isGeneratingSummary) {
      return const ChapterAIStatus.loading(
        ChapterAIFeature.summary,
        '正在生成章节总结...',
      );
    }
    if (_isGeneratingPractice) {
      return const ChapterAIStatus.loading(
        ChapterAIFeature.practice,
        '正在生成练习题...',
      );
    }
    return _chapterAIStatus;
  }

  ChapterAISummaryCoverage? get chapterAISummaryCoverage =>
      _chapterAISummaryCoverage;
  bool get isLoadingChapterAISummaryCoverage =>
      _isLoadingChapterAISummaryCoverage;
  String get summaryLanguage => _summaryLanguage;
  String get effectiveTargetExplanationLanguage {
    final globalLanguage = _settings?.targetExplanationLanguage ?? 'zh';
    return _activeBookMetadata?.effectiveTargetExplanationLanguage(
          globalLanguage,
        ) ??
        globalLanguage;
  }

  AIPracticeSet? get aiPractice => _aiPractice;
  bool get isGeneratingPractice => _isGeneratingPractice;
  WordAnalysis? get aiWordAnalysis => _aiWordAnalysis;
  bool get isAnalyzingWord => _isAnalyzingWord;
  bool get aiFeaturesEnabled =>
      _aiService != null && (_settings?.aiFeaturesEnabled ?? false);
  String get aiFeatureDisabledReason =>
      _settings?.aiFeatureDisabledReason ?? 'AI 服务未初始化';

  UserWordStatus? getWordStatus(String word) =>
      _userVocab?.getStatus(_canonicalWord(word));
  bool isWordKnown(String word) =>
      _userVocab?.isKnown(_canonicalWord(word)) ?? false;
  bool isWordLearning(String word) =>
      _userVocab?.isLearning(_canonicalWord(word)) ?? false;
  UserVocabularyService? get userVocabulary => _userVocab;
  LanguageModule get activeLanguageModule {
    final code =
        _settings?.activeSourceLanguage ?? HiveBoxNames.defaultLanguageCode;
    return LanguageRegistry.instance.get(code) ??
        LanguageRegistry.instance.defaultModule ??
        const EnglishLanguageModule();
  }

  WordLevelService? get wordLevelService => _wordLevelService;
  WordContextService? get wordContextService => _wordContextService;
  List<LearningItem> get learningItems =>
      _learningItemService?.allItems ?? const [];
  int get learningItemCount => _learningItemService?.count ?? 0;
  int get todayReviewDueCount => _reviewScheduleService?.dueCount() ?? 0;
  List<LearningReviewCard> get todayReviewCards =>
      _reviewScheduleService?.buildSessionCards() ?? const [];
  bool get canCreateLearningItems => _learningItemService != null;
  bool get canPronounceWords => _pronunciationService != null;
  int get wordMasteredCelebrationTick => _wordMasteredCelebrationTick;
  String? get wordMasteredCelebrationWord => _wordMasteredCelebrationWord;
  Offset? get wordMasteredCelebrationOrigin => _wordMasteredCelebrationOrigin;

  ChapterLearningReport? get currentChapterLearningReport {
    final book = _book;
    final bookId = _activeBookId;
    final analytics = _learningAnalyticsService;
    if (book == null ||
        book.chapters.isEmpty ||
        bookId == null ||
        analytics == null) {
      return null;
    }
    return analytics.buildChapterReport(
      bookId: bookId,
      book: book,
      chapterIndex: _currentChapter,
      chapterProgress: _readingProgress,
      analysis: _result,
      readingTime: _readingTime,
      userVocabulary: _userVocab,
      learningItems: learningItems,
      dueReviewCount: todayReviewDueCount,
    );
  }

  WeeklyLearningSummary? get weeklyLearningSummary {
    final analytics = _learningAnalyticsService;
    if (analytics == null) return null;
    return analytics.buildWeeklySummary(
      readingTime: _readingTime,
      dailyGoalSeconds: dailyReadingGoalSeconds,
      learningItems: learningItems,
      dueReviewCount: todayReviewDueCount,
    );
  }

  // ============================================================
  // Dependency injection
  // ============================================================

  void setBookService(BookService service) => _bookService = service;
  void setBookmarkService(BookmarkService service) =>
      _bookmarkService = service;
  void setReadingConfig(ReadingConfigService service) =>
      _readingConfig = service;
  void setReadingTime(ReadingTimeService service) => _readingTime = service;
  void setWordRepository(WordRepository repo) => _wordRepo = repo;
  void setUserVocabulary(UserVocabularyService vocab) => _userVocab = vocab;
  void setSentenceAnalyzer(SentenceAnalyzer analyzer) =>
      _sentenceAnalyzer = analyzer;
  void setSettings(SettingsService settings) => _settings = settings;
  void setAIService(AIService service) => _aiService = service;
  void setAICache(AICacheService cache) => _aiCache = cache;
  void setWordLevelService(WordLevelService service) =>
      _wordLevelService = service;
  void setWordContextService(WordContextService service) =>
      _wordContextService = service;
  void setLearningItemService(LearningItemService service) =>
      _learningItemService = service;
  void setLearningAnalyticsService(LearningAnalyticsService service) =>
      _learningAnalyticsService = service;
  void setReviewScheduleService(ReviewScheduleService service) =>
      _reviewScheduleService = service;
  void setPronunciationService(PronunciationService service) =>
      _pronunciationService = service;

  // ============================================================
  // Initialisation
  // ============================================================

  Future<void> init() async {
    await _bookService.init();
    await _bookmarkService?.init();
    await _readingConfig?.init();
    await _readingTime?.init();
    await _userVocab?.init();
    await _wordLevelService?.init();
    await _wordContextService?.init();
    await _learningItemService?.init();
    await _learningAnalyticsService?.init();
    _loadCachedBookDifficultyInputs();
    if (_book != null) {
      await _refreshAndPersistCurrentBookDifficulty();
      await _analyzeCurrentChapter();
    } else {
      notifyListeners();
    }
  }

  Future<void> reloadAfterBackupRestore() async {
    _readingTime?.stop();
    _difficultyRefreshTimer?.cancel();
    _difficultyRefreshTimer = null;
    _pendingDifficultyRefreshBookIds.clear();
    _loadingBookDifficultyIds.clear();
    _bookDifficultyFailureKeys.clear();
    _isRefreshingBookDifficulties = false;

    _book = null;
    _activeBookId = null;
    _result = null;
    _currentChapter = 0;
    _readingProgress = 0.0;
    _readingScrollOffset = null;
    _isReading = false;
    _hasBeenOpened = false;
    _allVocab.clear();
    _currentBookStudyWords = {};
    _currentBookDifficulty = null;
    _bookmarkedWords.clear();
    _readingBookmarks.clear();
    _selectedWord = null;
    _selectedWordTranslation = null;
    _selectedWordContext = null;
    _selectedWordContextStart = null;
    _selectedWordContextEnd = null;
    _selectedWordEntry = null;
    _selectedText = null;
    _selectedAnalysis = null;
    _selectedBreakdowns = null;
    _aiTextAnalysis = null;
    _aiTranslation = null;
    _aiSummary = null;
    _aiChapterPreview = null;
    _aiPractice = null;
    _aiWordAnalysis = null;
    _chapterAIStatus = null;
    _chapterAISummaryCoverage = null;
    _isLoadingChapterAISummaryCoverage = false;
    _resetSearchState();

    await init();
  }

  List<WordContextExample> importedExamplesFor(String word) {
    return _wordContextService?.examplesFor(word) ?? const [];
  }

  Future<void> speakWord(String word) async {
    await _pronunciationService?.speakWord(word);
  }

  // ============================================================
  // Book import / management
  // ============================================================

  Future<BookImportResult> importBook(String filePath) {
    return importBookFromSource(EpubImportSource.path(filePath));
  }

  Future<BookImportResult> importBookFromBytes({
    required Uint8List bytes,
    required String fileName,
  }) {
    return importBookFromSource(
      EpubImportSource.bytes(bytes, fileName: fileName),
    );
  }

  void cancelImport() {
    if (!_isImportingBook || _isCancellingImport) return;
    _importCancellationRequested = true;
    _isCancellingImport = true;
    _importStage = '正在取消导入...';
    _activeImportParseTask?.cancel();
    _emitImportProgress();
  }

  Future<BookImportResult> importBookFromSource(EpubImportSource source) async {
    if (_isImportingBook) return BookImportResult.ignored;
    _beginImport(source.fileName);
    String? copiedPath;
    var shouldDeleteCopiedSource = true;

    try {
      final bookId = _generateBookId(source.fileName);
      var effectiveBookId = bookId;
      copiedPath = await _bookService.saveSource(bookId, source);
      _throwIfImportCancelled();

      _updateImportProgress('正在解析 EPUB...', 0.18);
      final parseTask = await EpubParseWorker.startParseInIsolate(
        copiedPath,
        onProgress: _handleImportParseProgress,
      );
      _activeImportParseTask = parseTask;
      if (_importCancellationRequested) {
        parseTask.cancel();
      }
      final book = await parseTask.future;
      _activeImportParseTask = null;
      _throwIfImportCancelled();

      _updateImportProgress('正在整理书籍信息...', 0.72);
      final restoredMeta = await _findMissingSourceRepairCandidate(book);
      if (restoredMeta != null) {
        effectiveBookId = restoredMeta.id;
        shouldDeleteCopiedSource = false;
        copiedPath = await _bookService.replaceSourceFile(
          effectiveBookId,
          copiedPath,
        );
      }
      _throwIfImportCancelled();

      String? coverPath;
      if (book.coverBytes != null) {
        _updateImportProgress('正在保存封面...', 0.78);
        coverPath = await _bookService.saveCover(
          effectiveBookId,
          book.coverBytes!,
        );
      }

      final sourceLanguage = LanguageRegistry.normalizeLanguageCode(
        book.language,
      );
      final languageConfidence = sourceLanguage == null ? null : 0.9;

      final metadata = restoredMeta == null
          ? BookMetadata(
              id: effectiveBookId,
              title: book.title,
              author: book.author,
              sourcePath: copiedPath,
              coverPath: coverPath,
              totalChapters: book.chapters.length,
              lastReadAt: DateTime.now(),
              sourceLanguage: sourceLanguage,
              languageConfidence: languageConfidence,
            )
          : restoredMeta.copyWith(
              title: book.title,
              author: book.author,
              sourcePath: copiedPath,
              coverPath: coverPath ?? restoredMeta.coverPath,
              totalChapters: book.chapters.length,
              sourceLanguage: sourceLanguage ?? restoredMeta.sourceLanguage,
              languageConfidence:
                  languageConfidence ?? restoredMeta.languageConfidence,
              currentChapter: _clampChapterIndex(
                restoredMeta.currentChapter,
                book.chapters.length,
              ),
            );

      _throwIfImportCancelled();
      _updateImportProgress('正在写入书架...', 0.84, canCancel: false);
      await _bookService.addBook(metadata);
      shouldDeleteCopiedSource = false;
      _bookDifficultyFailureKeys.remove(effectiveBookId);

      _book = book;
      _activeBookId = effectiveBookId;
      _currentChapter = restoredMeta == null ? 0 : metadata.currentChapter;
      _readingProgress = restoredMeta == null ? 0.0 : metadata.chapterProgress;
      _readingScrollOffset = restoredMeta == null
          ? 0.0
          : metadata.chapterScrollOffset;
      _hasBeenOpened = false;
      _allVocab.clear();
      await _refreshAndPersistCurrentBookDifficulty();
      _bookmarkedWords.clear();
      _readingBookmarks.clear();
      _resetSearchState();
      await _refreshChapterAISummaryCoverage(notify: false);

      _updateImportProgress('正在统计生词、分析句式...', 0.9, canCancel: false);
      await _analyzeCurrentChapter();
      _updateImportProgress('导入完成', 1, canCancel: false);
      _lastImportResult = BookImportResult.imported;
      return BookImportResult.imported;
    } on EpubParseCancelledException {
      await _cleanupCancelledImport(
        copiedPath,
        deleteCopiedSource: shouldDeleteCopiedSource,
      );
      _lastImportResult = BookImportResult.cancelled;
      return BookImportResult.cancelled;
    } on _ImportCancelledException {
      await _cleanupCancelledImport(
        copiedPath,
        deleteCopiedSource: shouldDeleteCopiedSource,
      );
      _lastImportResult = BookImportResult.cancelled;
      return BookImportResult.cancelled;
    } catch (e) {
      _errorMessage = 'Failed to import book: $e';
      _lastImportResult = BookImportResult.failed;
      return BookImportResult.failed;
    } finally {
      _finishImport();
    }
  }

  void _beginImport(String fileName) {
    _importCancelTimer?.cancel();
    _activeImportParseTask = null;
    _isLoading = true;
    _isImportingBook = true;
    _isCancellingImport = false;
    _showImportCancel = false;
    _importCancellationRequested = false;
    _errorMessage = null;
    _lastImportResult = BookImportResult.ignored;
    _importFileName = fileName;
    _importProgress = 0.06;
    _importStage = '正在读取 EPUB 文件...';
    _importCancelTimer = Timer(_importCancelDelay, () {
      if (!_isImportingBook || _isCancellingImport) return;
      _showImportCancel = true;
      _emitImportProgress();
    });
    _emitImportProgress();
    notifyListeners();
  }

  void _handleImportParseProgress(core.EpubParseEvent event) {
    if (!_isImportingBook || _isCancellingImport) return;
    final currentProgress = _importProgress ?? 0;
    final nextProgress = _mapImportParseProgress(event);
    _updateImportProgress(
      _importParseStage(event),
      nextProgress < currentProgress ? currentProgress : nextProgress,
    );
  }

  double _mapImportParseProgress(core.EpubParseEvent event) {
    return switch (event.phase) {
      core.EpubParsePhase.extractingMetadata => 0.1,
      core.EpubParsePhase.complete => _importParseProgressEnd,
      _ =>
        _importParseProgressStart +
            event.progress.clamp(0.0, 1.0).toDouble() *
                (_importParseProgressEnd - _importParseProgressStart),
    };
  }

  String _importParseStage(core.EpubParseEvent event) {
    return switch (event.phase) {
      core.EpubParsePhase.extractingMetadata => '正在读取书籍信息...',
      core.EpubParsePhase.parsingChapter ||
      core.EpubParsePhase.buildingBlocks ||
      core.EpubParsePhase.loadingImage => '正在解析 EPUB 内容...',
      core.EpubParsePhase.complete => '解析完成',
    };
  }

  void _updateImportProgress(
    String stage,
    double progress, {
    bool canCancel = true,
  }) {
    _importStage = stage;
    _importProgress = progress.clamp(0.0, 1.0).toDouble();
    if (!canCancel) {
      _showImportCancel = false;
      _importCancelTimer?.cancel();
      _importCancelTimer = null;
    }
    _emitImportProgress();
  }

  void _emitImportProgress() {
    _importProgressNotifier.value = ImportProgressState(
      isImportingBook: _isImportingBook,
      isCancellingImport: _isCancellingImport,
      canCancelImport: canCancelImport,
      progress: _importProgress,
      fileName: _importFileName,
      stage: _importStage,
    );
  }

  void _throwIfImportCancelled() {
    if (_importCancellationRequested) {
      throw const _ImportCancelledException();
    }
  }

  Future<void> _cleanupCancelledImport(
    String? copiedPath, {
    required bool deleteCopiedSource,
  }) async {
    if (!deleteCopiedSource || copiedPath == null) return;
    final file = File(copiedPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  void _finishImport() {
    _importCancelTimer?.cancel();
    _importCancelTimer = null;
    _activeImportParseTask = null;
    _isLoading = false;
    _isImportingBook = false;
    _isCancellingImport = false;
    _showImportCancel = false;
    _importCancellationRequested = false;
    _importStage = '';
    _importProgress = null;
    _importFileName = null;
    _emitImportProgress();
    notifyListeners();
  }

  Future<bool> switchToBook(String bookId) async {
    if (bookId == _activeBookId && _book != null) return true;
    _saveCurrentProgress();

    final meta = _bookService.books.where((b) => b.id == bookId).firstOrNull;
    if (meta == null) {
      _errorMessage = '打开书籍失败：书架中找不到这本书。';
      AppLogger.instance.event(
        'reader.open_missing_metadata',
        level: AppLogLevel.warning,
        source: 'reader',
        metadata: {'bookId': bookId},
      );
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _importStage = '正在解析 EPUB...';
    notifyListeners();

    try {
      final book = await EpubParseWorker.parseInIsolate(meta.sourcePath);
      _book = book;
      _activeBookId = bookId;
      _currentChapter = meta.currentChapter.clamp(0, book.chapters.length - 1);
      _readingProgress = meta.chapterProgress;
      _readingScrollOffset = meta.chapterScrollOffset;
      _allVocab.clear();
      await _refreshAndPersistCurrentBookDifficulty();
      _resetSearchState();

      _loadBookmarks(bookId);
      await _refreshChapterAISummaryCoverage(notify: false);

      await _analyzeCurrentChapter();
      return true;
    } catch (e, stackTrace) {
      _errorMessage = '打开书籍失败：无法读取书籍文件。请确认备份中包含该书，或重新导入 EPUB。';
      AppLogger.instance.event(
        'reader.open_failed',
        level: AppLogLevel.error,
        source: 'reader',
        metadata: {
          'bookId': bookId,
          'title': meta.title,
          'sourcePath': meta.sourcePath,
        },
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      _isLoading = false;
      _importStage = '';
      notifyListeners();
    }
  }

  Future<void> removeBook(String bookId) async {
    _errorMessage = null;
    await _bookService.removeBook(bookId);
    await _bookmarkService?.deleteWordBookmarks(bookId);
    await _bookmarkService?.deleteReadingBookmarks(bookId);
    await _learningItemService?.deleteForBook(bookId);
    await _aiCache?.clearBookCache(bookId);
    _bookStudyWordsById.remove(bookId);
    _bookDifficultyById.remove(bookId);
    _loadingBookDifficultyIds.remove(bookId);

    if (_activeBookId == bookId) {
      _book = null;
      _activeBookId = null;
      _result = null;
      _currentChapter = 0;
      _readingProgress = 0.0;
      _readingScrollOffset = null;
      _hasBeenOpened = false;
      _allVocab.clear();
      _currentBookStudyWords = {};
      _currentBookDifficulty = null;
      _bookmarkedWords.clear();
      _readingBookmarks.clear();
      _selectedWord = null;
      _selectedWordTranslation = null;
      _selectedWordContext = null;
      _selectedWordContextStart = null;
      _selectedWordContextEnd = null;
      _selectedWordEntry = null;
      _selectedText = null;
      _selectedAnalysis = null;
      _selectedBreakdowns = null;
      _aiTextAnalysis = null;
      _aiTranslation = null;
      _aiSummary = null;
      _aiChapterPreview = null;
      _aiPractice = null;
      _aiWordAnalysis = null;
      _chapterAIStatus = null;
      _chapterAISummaryCoverage = null;
      _isLoadingChapterAISummaryCoverage = false;
      _isReading = false;
      _resetSearchState();
    }
    notifyListeners();
  }

  Future<void> renameBook(String bookId, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    await _bookService.renameBook(bookId, trimmed);
    notifyListeners();
  }

  // ============================================================
  // Navigation
  // ============================================================

  void switchTab(int index) {
    _currentTab = index;
    notifyListeners();
  }

  void enterReader() {
    if (_book == null || _activeBookId == null) {
      _errorMessage = '打开书籍失败：书籍尚未加载完成。';
      AppLogger.instance.event(
        'reader.enter_without_book',
        level: AppLogLevel.warning,
        source: 'reader',
      );
      notifyListeners();
      return;
    }
    _isReading = true;
    _hasBeenOpened = true;
    _readingTime?.start(_activeBookId, _currentChapter);
    notifyListeners();
  }

  void exitReader() {
    _isReading = false;
    _readingTime?.stop();
    _saveCurrentProgress();
    notifyListeners();
  }

  Future<void> goToChapter(int index) async {
    if (_book == null || index == _currentChapter) return;
    if (index < 0 || index >= _book!.chapters.length) return;
    if (_isReading) {
      await _readingTime?.switchTarget(_activeBookId, index);
    }
    _currentChapter = index;
    _readingProgress = 0.0;
    _readingScrollOffset = 0.0;
    _sourceHighlightQuery = '';
    _aiSummary = null;
    _aiChapterPreview = null;
    _aiPractice = null;
    _chapterAIStatus = null;
    _saveCurrentProgress();
    notifyListeners();
    await _analyzeCurrentChapter();
  }

  void updateReadingProgress(double progress, {double? scrollOffset}) {
    _readingProgress = progress.clamp(0.0, 1.0);
    if (scrollOffset != null) {
      _readingScrollOffset = scrollOffset < 0 ? 0.0 : scrollOffset;
    }
  }

  // ============================================================
  // Chapter analysis
  // ============================================================

  Future<void> _analyzeCurrentChapter() async {
    if (_book == null) return;
    final chapter = _book!.chapters[_currentChapter];
    _result = AnalysisService.analyzeChapter(
      chapter.title,
      chapter.plainText,
      _userVocab,
      _wordLevelService,
      activeLanguageModule,
    );
    _updateAllVocab();
    notifyListeners();
  }

  void _loadCachedBookDifficultyInputs() {
    _difficultyRefreshTimer?.cancel();
    _difficultyRefreshTimer = null;
    _pendingDifficultyRefreshBookIds.clear();
    final bookIds = _bookService.books.map((book) => book.id).toSet();
    _bookStudyWordsById.removeWhere((id, _) => !bookIds.contains(id));
    _bookDifficultyById.removeWhere((id, _) => !bookIds.contains(id));
    _bookDifficultyFailureKeys.removeWhere((id, _) => !bookIds.contains(id));

    for (final meta in _bookService.books) {
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
    if (meta.id == _activeBookId) {
      _currentBookStudyWords = _bookStudyWordsById[meta.id] ?? {};
      _currentBookDifficulty = rating;
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
    final rating = AnalysisService.rateBookDifficulty(studyWords, _userVocab);
    await _persistBookDifficulty(meta.id, studyWords, rating);
    return true;
  }

  bool _isDifficultyCacheStale(BookMetadata meta) {
    return meta.difficultyVocabularySignature != _vocabularySignature;
  }

  String _difficultyFailureKey(BookMetadata meta) {
    return '${meta.sourcePath}|$_vocabularySignature';
  }

  Future<void> _refreshAndPersistCurrentBookDifficulty() async {
    _refreshCurrentBookStudyWords();
    final bookId = _activeBookId;
    if (bookId == null) return;
    final rating = AnalysisService.rateBookDifficulty(
      _currentBookStudyWords,
      _userVocab,
    );
    await _persistBookDifficulty(bookId, _currentBookStudyWords, rating);
  }

  void _refreshCurrentBookStudyWords() {
    final book = _book;
    _currentBookStudyWords = book == null
        ? {}
        : AnalysisService.collectBookStudyWords(
            book,
            _wordLevelService,
            activeLanguageModule,
          );
    if (_activeBookId != null) {
      _bookStudyWordsById[_activeBookId!] = _currentBookStudyWords;
    }
  }

  Future<void> _persistBookDifficulty(
    String bookId,
    Set<String> studyWords,
    BookDifficultyRating rating,
  ) async {
    _bookStudyWordsById[bookId] = studyWords;
    _bookDifficultyById[bookId] = rating;
    if (bookId == _activeBookId) {
      _currentBookStudyWords = studyWords;
      _currentBookDifficulty = rating;
    }
    await _bookService.updateDifficultyCache(
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
        var changedInBatch = false;
        for (final bookId in batch) {
          final studyWords = _bookStudyWordsById[bookId];
          if (studyWords == null) continue;
          final rating = AnalysisService.rateBookDifficulty(
            studyWords,
            _userVocab,
          );
          await _persistBookDifficulty(bookId, studyWords, rating);
          changedInBatch = true;
        }
        if (changedInBatch) notifyListeners();
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
    return _userVocab?.revisionSignature ??
        UserVocabularyService.emptyRevisionSignature;
  }

  void _updateAllVocab() {
    if (_result == null) return;
    _allVocab.removeWhere((key, _) => _userVocab?.isKnown(key) ?? false);
    for (final v in _result!.vocabulary) {
      final lower = v.word;
      if (_userVocab?.isKnown(lower) ?? false) continue;
      if (_allVocab.containsKey(lower)) {
        final existing = _allVocab[lower]!;
        _allVocab[lower] = existing.copyWith(
          chapterIndices: existing.updatedChapters(_currentChapter),
          level: v.level,
        );
      } else {
        _allVocab[lower] = AggregatedVocabulary(
          word: lower,
          meaning: v.meaning,
          firstChapter: _currentChapter,
          context: v.context,
          chapterIndices: {_currentChapter},
          level: v.level,
        );
      }
    }
  }

  // ============================================================
  // Vocabulary actions
  // ============================================================

  Future<void> markWordKnown(String word, {Offset? celebrationOrigin}) async {
    final canonical = _canonicalWord(word);
    final previousStatus = _userVocab?.getStatus(canonical);
    await _userVocab?.setKnown(canonical);
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
    notifyListeners();
  }

  void _recordWordMasteredCelebration(
    String word,
    UserWordStatus? previousStatus, {
    Offset? origin,
  }) {
    if (_userVocab == null || previousStatus == UserWordStatus.known) return;
    _wordMasteredCelebrationWord = word;
    _wordMasteredCelebrationOrigin = origin;
    _wordMasteredCelebrationTick += 1;
  }

  Future<void> markWordLearning(String word) async {
    final canonical = _canonicalWord(word);
    final previousStatus = _userVocab?.getStatus(canonical);
    await _userVocab?.setLearning(canonical);
    _queueDifficultyRefreshForVocabularyChange(
      canonical,
      previousStatus,
      UserWordStatus.learning,
    );
    await _analyzeCurrentChapter();
    notifyListeners();
  }

  Future<void> markWordUnknown(String word) async {
    final canonical = _canonicalWord(word);
    final previousStatus = _userVocab?.getStatus(canonical);
    await _userVocab?.setUnknown(canonical);
    _queueDifficultyRefreshForVocabularyChange(canonical, previousStatus, null);
    await _analyzeCurrentChapter();
    notifyListeners();
  }

  // ============================================================
  // Word lookup
  // ============================================================

  Future<void> lookupWord(
    String word, {
    String? canonicalForm,
    String? languageCode,
    String? reading,
    String? contextText,
    int? contextWordStart,
    int? contextWordEnd,
    bool trackReadingLookup = false,
  }) async {
    _wordLookupHistory.clear();
    final activeModule = activeLanguageModule;
    final normalizedContext = _normalizeLookupContext(
      contextText,
      contextWordStart: contextWordStart,
      contextWordEnd: contextWordEnd,
    );
    await _lookupWord(
      DictionaryLookupRequest(
        word: word,
        languageCode:
            _nonEmptyOrNull(languageCode) ?? activeModule.languageCode,
        canonicalForm:
            _nonEmptyOrNull(canonicalForm) ?? activeModule.canonicalize(word),
        reading: _nonEmptyOrNull(reading),
        contextText: normalizedContext.text,
        contextWordStart: normalizedContext.wordStart,
        contextWordEnd: normalizedContext.wordEnd,
      ),
      trackReadingLookup: trackReadingLookup,
    );
  }

  String? _nonEmptyOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<void> lookupRelatedWord(String word) async {
    final current = _selectedWordLookupResult;
    if (current != null) {
      _wordLookupHistory.add(current);
    }
    await _lookupWord(
      DictionaryLookupRequest(
        word: word,
        languageCode: activeLanguageModule.languageCode,
        canonicalForm: activeLanguageModule.canonicalize(word),
      ),
    );
  }

  Future<void> _lookupWord(
    DictionaryLookupRequest request, {
    bool trackReadingLookup = false,
  }) async {
    final requestVersion = ++_wordLookupRequestVersion;
    _selectedWord = request.displayWord;
    _selectedWordTranslation = null;
    _selectedWordContext = request.contextText;
    _selectedWordContextStart = request.contextWordStart;
    _selectedWordContextEnd = request.contextWordEnd;
    _selectedWordEntry = null;
    _selectedWordLookupResult = null;
    _isLoadingWord = true;
    notifyListeners();

    final activeBookId = _activeBookId;
    if (trackReadingLookup && activeBookId != null && _book != null) {
      await _learningAnalyticsService?.recordLookup(
        bookId: activeBookId,
        chapterIndex: _currentChapter,
        word: request.displayWord,
      );
    }
    if (requestVersion != _wordLookupRequestVersion) return;

    var result = await _wordRepo.lookupRequest(request);
    if (requestVersion != _wordLookupRequestVersion) return;
    result = await _withDictionaryFallbacks(result);
    if (requestVersion != _wordLookupRequestVersion) return;
    _applyWordLookupResult(result);
    _isLoadingWord = false;
    notifyListeners();
  }

  void goBackWordLookup() {
    if (_wordLookupHistory.isEmpty) return;
    final previous = _wordLookupHistory.removeLast();
    _applyWordLookupResult(previous);
    _isLoadingWord = false;
    notifyListeners();
  }

  void clearWordLookup() {
    _wordLookupRequestVersion += 1;
    _selectedWord = null;
    _selectedWordTranslation = null;
    _selectedWordContext = null;
    _selectedWordContextStart = null;
    _selectedWordContextEnd = null;
    _selectedWordEntry = null;
    _selectedWordLookupResult = null;
    _wordLookupHistory.clear();
    _isLoadingWord = false;
    notifyListeners();
  }

  void _applyWordLookupResult(DictionaryLookupResult result) {
    _selectedWordLookupResult = result;
    _selectedWord = result.request.displayWord;
    _selectedWordContext = result.request.contextText;
    _selectedWordContextStart = result.request.contextWordStart;
    _selectedWordContextEnd = result.request.contextWordEnd;
    _selectedWordEntry = result.entry;
    _selectedWordTranslation = result.primaryDefinition;
  }

  Future<DictionaryLookupResult> _withDictionaryFallbacks(
    DictionaryLookupResult result,
  ) async {
    if (result.hasDictionaryContent || result.hasDictionaryError) {
      return result;
    }

    final request = result.request;
    final compoundAnalysis = request.languageCode == 'en'
        ? _compoundAnalyzer().analyze(request.query)
        : null;
    final bookContexts = await _bookContextSnippets(request);

    if (compoundAnalysis == null && bookContexts.isEmpty) return result;
    return result.copyWith(
      compoundAnalysis: compoundAnalysis,
      bookContexts: bookContexts,
    );
  }

  CompoundWordAnalyzer _compoundAnalyzer() {
    return CompoundWordAnalyzer(
      isKnownWord: (word) {
        final normalized = activeLanguageModule.canonicalize(word);
        return _compoundMeaningHints.containsKey(word) ||
            _compoundMeaningHints.containsKey(normalized) ||
            (_wordLevelService?.hasWord(word) ?? false) ||
            (_wordLevelService?.hasWord(normalized) ?? false);
      },
      getMeaning: (word) {
        final normalized = activeLanguageModule.canonicalize(word);
        return _compoundMeaningHints[word] ?? _compoundMeaningHints[normalized];
      },
    );
  }

  Future<List<BookContextSnippet>> _bookContextSnippets(
    DictionaryLookupRequest request,
  ) async {
    final book = _book;
    final query = request.query;
    if (book == null || query.isEmpty) return const [];

    final snippets = <BookContextSnippet>[];
    await for (final progress in ReadingSearchService.search(
      book,
      query,
      limit: 5,
    )) {
      final result = progress.result;
      if (result == null) continue;
      snippets.add(
        BookContextSnippet(
          text: result.snippet,
          chapterIndex: result.chapterIndex,
          chapterTitle: result.chapterTitle,
        ),
      );
    }
    return snippets;
  }

  ({String? text, int? wordStart, int? wordEnd}) _normalizeLookupContext(
    String? contextText, {
    int? contextWordStart,
    int? contextWordEnd,
  }) {
    final raw = contextText;
    if (raw == null) return (text: null, wordStart: null, wordEnd: null);

    final leadingWhitespace = raw.length - raw.trimLeft().length;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (text: null, wordStart: null, wordEnd: null);
    }

    if (contextWordStart == null || contextWordEnd == null) {
      return (text: trimmed, wordStart: null, wordEnd: null);
    }

    final normalizedStart = contextWordStart - leadingWhitespace;
    final normalizedEnd = contextWordEnd - leadingWhitespace;
    final hasValidRange =
        normalizedStart >= 0 &&
        normalizedEnd > normalizedStart &&
        normalizedEnd <= trimmed.length;

    return (
      text: trimmed,
      wordStart: hasValidRange ? normalizedStart : null,
      wordEnd: hasValidRange ? normalizedEnd : null,
    );
  }

  // ============================================================
  // Text selection / analysis
  // ============================================================

  void analyzeSelectedText(String text) {
    _selectedText = text;
    _selectedAnalysis = AnalysisService.analyzeChapter(
      'Selected Text',
      text,
      _userVocab,
      _wordLevelService,
      activeLanguageModule,
    );
    _selectedBreakdowns = _sentenceAnalyzer.analyze(text);
    notifyListeners();
  }

  void clearSelectedText() {
    _selectedText = null;
    _selectedAnalysis = null;
    _selectedBreakdowns = null;
  }

  // ============================================================
  // Full-book search
  // ============================================================

  Future<void> searchInBook(String query, {bool includeAll = false}) async {
    return _searchController.search(_book, query, includeAll: includeAll);
  }

  Future<void> searchAllInBook() {
    return _searchController.searchAll(_book);
  }

  Future<void> goToSearchResult(ReadingSearchResult result) async {
    if (_book == null) return;
    if (result.chapterIndex < 0 ||
        result.chapterIndex >= _book!.chapters.length) {
      return;
    }

    _searchController.activateResult(result);
    if (result.chapterIndex != _currentChapter) {
      await goToChapter(result.chapterIndex);
      return;
    }
    notifyListeners();
  }

  void clearSearch() {
    _resetSearchState();
  }

  // ============================================================
  // Bookmarks (delegated to BookmarkService)
  // ============================================================

  void _loadBookmarks(String bookId) {
    _bookmarkedWords
      ..clear()
      ..addAll(_bookmarkService?.loadWordBookmarks(bookId) ?? []);
    _readingBookmarks
      ..clear()
      ..addAll(_bookmarkService?.loadReadingBookmarks(bookId) ?? []);
  }

  bool isBookmarked(String word) {
    final lower = word.toLowerCase().trim();
    return _bookmarkedWords.any((b) => b.word.toLowerCase() == lower);
  }

  void addBookmark(String word, String translation) {
    if (_activeBookId == null) return;
    final lower = word.toLowerCase().trim();
    if (_bookmarkedWords.any((b) => b.word.toLowerCase() == lower)) return;

    String context = _selectedWordContext ?? '';
    if (context.isEmpty && _result != null) {
      for (final v in _result!.vocabulary) {
        if (v.word.toLowerCase() == lower) {
          context = v.context;
          break;
        }
      }
    }
    _bookmarkedWords.insert(
      0,
      BookmarkedWord(
        word: word,
        translation: translation,
        context: context,
        addedAt: DateTime.now(),
        bookId: _activeBookId!,
      ),
    );
    _bookmarkService?.saveWordBookmarks(_activeBookId!, _bookmarkedWords);
    notifyListeners();
  }

  void removeBookmark(String word) {
    if (_activeBookId == null) return;
    final lower = word.toLowerCase().trim();
    _bookmarkedWords.removeWhere((b) => b.word.toLowerCase() == lower);
    _bookmarkService?.saveWordBookmarks(_activeBookId!, _bookmarkedWords);
    notifyListeners();
  }

  // ============================================================
  // Learning items
  // ============================================================

  Future<LearningItemSaveResult?> addSelectedWordLearningItem() async {
    final service = _learningItemService;
    final word = _selectedWord?.trim();
    if (service == null || word == null || word.isEmpty) return null;

    final definition = _selectedWordTranslation?.trim() ?? '';
    final draft = LearningItemDraft.word(
      word: word,
      definition: definition,
      context: _selectedWordContext ?? '',
      source: _currentLearningItemSource(),
      metadata: {
        if (_selectedWordEntry?.sourceName != null)
          'dictionarySource': _selectedWordEntry!.sourceName!,
        if (_selectedWordEntry?.phonetic?.trim().isNotEmpty ?? false)
          'phonetic': _selectedWordEntry!.phonetic!.trim(),
      },
    );
    final result = await service.saveDraft(draft);
    notifyListeners();
    return result;
  }

  Future<LearningItemSaveResult?> addSelectedTextLearningItem() async {
    final service = _learningItemService;
    final selectedText = _selectedText?.trim();
    final analysis = _aiTextAnalysis;
    if (service == null ||
        selectedText == null ||
        selectedText.isEmpty ||
        analysis == null) {
      return null;
    }

    final result = await service.saveDraft(
      LearningItemDraft.selectedText(
        selectedText: selectedText,
        analysis: analysis,
        source: _currentLearningItemSource(),
      ),
    );
    notifyListeners();
    return result;
  }

  Future<LearningItemSaveResult?> addAIVocabularyLearningItem(
    VocabularyNote note,
  ) async {
    final service = _learningItemService;
    final selectedText = _selectedText?.trim();
    if (service == null || selectedText == null || selectedText.isEmpty) {
      return null;
    }
    final result = await service.saveDraft(
      LearningItemDraft.vocabularyNote(
        note: note,
        selectedText: selectedText,
        source: _currentLearningItemSource(),
      ),
    );
    notifyListeners();
    return result;
  }

  Future<LearningItemSaveResult?> addAIGrammarLearningItem(
    GrammarPoint point,
  ) async {
    final service = _learningItemService;
    final selectedText = _selectedText?.trim();
    if (service == null || selectedText == null || selectedText.isEmpty) {
      return null;
    }
    final result = await service.saveDraft(
      LearningItemDraft.grammarPoint(
        point: point,
        selectedText: selectedText,
        source: _currentLearningItemSource(),
      ),
    );
    notifyListeners();
    return result;
  }

  Future<LearningItemSaveResult?> addAIExpressionLearningItem(
    ExpressionNote note,
  ) async {
    final service = _learningItemService;
    final selectedText = _selectedText?.trim();
    if (service == null || selectedText == null || selectedText.isEmpty) {
      return null;
    }
    final result = await service.saveDraft(
      LearningItemDraft.expressionNote(
        note: note,
        selectedText: selectedText,
        source: _currentLearningItemSource(),
      ),
    );
    notifyListeners();
    return result;
  }

  Future<LearningItemSaveResult?> addPracticeMistakeLearningItem(
    PracticeQuestion question,
    String selectedAnswer,
  ) async {
    final service = _learningItemService;
    if (service == null || question.question.trim().isEmpty) return null;

    final result = await service.saveDraft(
      LearningItemDraft.questionMistake(
        question: question.question,
        correctAnswer: question.answer,
        selectedAnswer: selectedAnswer,
        sourceExcerpt: question.sourceExcerpt,
        explanation: question.answerExplanation,
        source: _currentLearningItemSource(),
        metadata: {
          'questionType': question.type,
          'difficulty': question.difficulty,
        },
      ),
    );
    notifyListeners();
    return result;
  }

  Future<void> recordPracticeAnswer({required bool isCorrect}) async {
    final bookId = _activeBookId;
    if (bookId == null) return;

    await _learningAnalyticsService?.recordPracticeAnswer(
      bookId: bookId,
      chapterIndex: _currentChapter,
      isCorrect: isCorrect,
    );
    notifyListeners();
  }

  Future<void> recordLearningReview(
    String itemId,
    LearningReviewResult result,
  ) async {
    await _reviewScheduleService?.recordReview(itemId, result);
    notifyListeners();
  }

  Future<void> deleteLearningItem(String id) async {
    await _learningItemService?.delete(id);
    notifyListeners();
  }

  void highlightSourceExcerpt(String excerpt) {
    final normalized = excerpt.trim();
    if (normalized.isEmpty) return;
    _sourceHighlightQuery = normalized;
    notifyListeners();
  }

  void clearSourceHighlight() {
    if (_sourceHighlightQuery.isEmpty) return;
    _sourceHighlightQuery = '';
    notifyListeners();
  }

  // -- Reading bookmarks --

  bool isCurrentPositionBookmarked() {
    return _readingBookmarks.any(
      (b) =>
          b.chapterIndex == _currentChapter &&
          (b.progress - _readingProgress).abs() < 0.01,
    );
  }

  void addReadingBookmark() {
    if (_activeBookId == null || isCurrentPositionBookmarked()) return;

    String excerpt = '';
    if (_result != null) {
      final paragraphs = _result!.passageText.split(RegExp(r'\n\s*\n'));
      final idx = (_readingProgress * paragraphs.length).round().clamp(
        0,
        paragraphs.length - 1,
      );
      excerpt = paragraphs[idx].trim();
      if (excerpt.length > 80) excerpt = '${excerpt.substring(0, 80)}...';
    }
    String chapterTitle = _book?.chapters[_currentChapter].title ?? '';

    _readingBookmarks.insert(
      0,
      ReadingBookmark(
        chapterIndex: _currentChapter,
        progress: _readingProgress,
        chapterTitle: chapterTitle,
        excerpt: excerpt,
        createdAt: DateTime.now(),
        bookId: _activeBookId!,
      ),
    );
    _bookmarkService?.saveReadingBookmarks(_activeBookId!, _readingBookmarks);
    notifyListeners();
  }

  void removeReadingBookmark(int index) {
    if (_activeBookId == null ||
        index < 0 ||
        index >= _readingBookmarks.length) {
      return;
    }
    _readingBookmarks.removeAt(index);
    _bookmarkService?.saveReadingBookmarks(_activeBookId!, _readingBookmarks);
    notifyListeners();
  }

  void goToReadingBookmark(ReadingBookmark bookmark) {
    if (_book == null) return;
    if (bookmark.chapterIndex >= 0 &&
        bookmark.chapterIndex < _book!.chapters.length) {
      goToChapter(bookmark.chapterIndex);
    }
    _readingProgress = bookmark.progress;
    _readingScrollOffset = null;
    notifyListeners();
  }

  // ============================================================
  // Reading config (delegated to ReadingConfigService)
  // ============================================================

  void setFontSize(double size) {
    _readingConfig?.setFontSize(size);
    notifyListeners();
  }

  void setFontFamily(String family) {
    _readingConfig?.setFontFamily(family);
    notifyListeners();
  }

  void setLineHeight(double height) {
    _readingConfig?.setLineHeight(height);
    notifyListeners();
  }

  void setReadingTheme(String theme) {
    _readingConfig?.setTheme(theme);
    notifyListeners();
  }

  // ============================================================
  // AI
  // ============================================================

  Future<void> analyzeSelectedTextAI(String text, {String? sourceText}) async {
    if (!_ensureAIReady()) return;
    final request = _passageRequestBuilder.buildSelectedTextAnalysis(
      selectedText: text,
      sourceText: sourceText ?? _result?.passageText ?? text,
    );
    _selectedText = request.selectedText;
    _isAnalyzingText = true;
    _aiTextAnalysis = null;
    _aiTranslation = null;
    _errorMessage = null;
    notifyListeners();
    try {
      _aiTextAnalysis = await _aiService!.analyzeText(
        selectedText: request.selectedText,
        currentPassage: request.currentPassage,
        sourceLanguage: request.sourceLanguage,
        outputLanguage: OutputLanguage.fromCode(
          effectiveTargetExplanationLanguage,
        ),
        spoilerBoundary: request.spoilerBoundary,
      );
      _settings?.incrementAIUsage(textAnalysis: true);
    } catch (e) {
      _errorMessage = 'AI 解析失败: $e';
    }
    _isAnalyzingText = false;
    notifyListeners();
  }

  Future<void> translateSelectedTextAI(String text) async {
    if (!_ensureAIReady()) return;
    _selectedText = text;
    _isTranslatingText = true;
    _aiTranslation = null;
    _errorMessage = null;
    notifyListeners();
    try {
      _aiTranslation = await _aiService!.translateText(
        text,
        sourceLanguage: SourceLanguage.inferFromText(text),
        outputLanguage: OutputLanguage.fromCode(
          effectiveTargetExplanationLanguage,
        ),
        spoilerBoundary: SpoilerBoundary.currentPassage(),
      );
    } catch (e) {
      _errorMessage = '翻译失败: $e';
    }
    _isTranslatingText = false;
    notifyListeners();
  }

  Future<void> generateSummary() async {
    if (_result == null || !_ensureAIReady()) return;
    final bookId = _activeBookId;
    if (bookId == null) return;
    _isGeneratingSummary = true;
    _aiSummary = null;
    _chapterAIStatus = null;
    notifyListeners();
    try {
      final result = await _createChapterAIJob().generateSummary(
        ChapterSummaryJobRequest(
          bookId: bookId,
          chapterIndex: _currentChapter,
          chapterText: _result!.passageText,
          vocabulary: _result!.vocabulary.map((v) => v.word).toList(),
          outputLanguage: OutputLanguage.fromCode(_summaryLanguage),
        ),
      );
      _aiSummary = result.summary;
      _chapterAIStatus = result.status;
      await _refreshChapterAISummaryCoverage(notify: false);
    } catch (e) {
      _errorMessage = '生成总结失败: $e';
      _chapterAIStatus = ChapterAIStatus.failed(
        ChapterAIFeature.summary,
        '章节总结生成失败：$e',
      );
    }
    _isGeneratingSummary = false;
    notifyListeners();
  }

  Future<void> generateChapterPreview() async {
    if (_result == null || _book == null || !_ensureAIReady()) return;
    final bookId = _activeBookId;
    if (bookId == null) return;
    _isGeneratingChapterPreview = true;
    _aiChapterPreview = null;
    _chapterAIStatus = null;
    notifyListeners();
    try {
      final chapter = _book!.chapters[_currentChapter];
      final chapterText = _result!.passageText;
      final openingText = _chapterPreviewOpening(chapterText);
      final sourceLanguage = SourceLanguage.inferFromText(openingText);
      final outputLanguage = OutputLanguage.fromCode(
        effectiveTargetExplanationLanguage,
      );
      final vocabulary = _result!.vocabulary.map((v) => v.word).toList();
      final contentHash = AICacheService.contentHashFor(
        jsonEncode({
          'title': chapter.title,
          'openingText': openingText,
          'vocabulary': vocabulary.take(20).toList(),
        }),
      );
      final cacheJson = await _aiCache?.loadChapterPreview(
        bookId,
        _currentChapter,
        contentHash: contentHash,
        promptVersion: _aiService!.promptVersion,
        sourceLanguage: sourceLanguage.code,
        outputLanguage: outputLanguage.code,
      );
      if (cacheJson != null) {
        _aiChapterPreview = AIChapterPreview.fromJson(
          jsonDecode(cacheJson) as Map<String, dynamic>,
        );
        _chapterAIStatus = const ChapterAIStatus.cacheHit(
          ChapterAIFeature.preview,
          '已读取缓存的读前预览。',
        );
        _isGeneratingChapterPreview = false;
        notifyListeners();
        return;
      }

      final preview = await _aiService!.generateChapterPreview(
        chapterTitle: chapter.title,
        openingText: openingText,
        vocabulary: vocabulary,
        sourceLanguage: sourceLanguage,
        outputLanguage: outputLanguage,
        spoilerBoundary: SpoilerBoundary.chapter(
          bookId: bookId,
          chapterIndex: _currentChapter,
        ),
      );
      _aiChapterPreview = preview;
      _chapterAIStatus = ChapterAIStatus.fromPreview(preview);
      await _aiCache?.saveChapterPreview(
        bookId,
        _currentChapter,
        jsonEncode(preview.toJson()),
        contentHash: contentHash,
        promptVersion: _aiService!.promptVersion,
        sourceLanguage: sourceLanguage.code,
        outputLanguage: outputLanguage.code,
      );
    } catch (e) {
      _errorMessage = '生成读前预览失败: $e';
      _chapterAIStatus = ChapterAIStatus.failed(
        ChapterAIFeature.preview,
        '读前预览生成失败：$e',
      );
    }
    _isGeneratingChapterPreview = false;
    notifyListeners();
  }

  void toggleSummaryLanguage() {
    _summaryLanguage = _summaryLanguage == 'zh' ? 'en' : 'zh';
    _aiSummary = null;
    _chapterAIStatus = null;
    notifyListeners();
  }

  Future<void> generatePractice() async {
    if (_result == null || !_ensureAIReady()) return;
    final bookId = _activeBookId;
    if (bookId == null) return;
    _isGeneratingPractice = true;
    _aiPractice = null;
    _chapterAIStatus = null;
    notifyListeners();
    try {
      final result = await _createChapterAIJob().generatePractice(
        ChapterPracticeJobRequest(
          bookId: bookId,
          chapterIndex: _currentChapter,
          chapterText: _result!.passageText,
          vocabulary: _result!.vocabulary.map((v) => v.word).toList(),
          events: _aiSummary?.events ?? const [],
        ),
      );
      _aiPractice = result.practice;
      _chapterAIStatus = result.status;
    } catch (e) {
      _errorMessage = '生成练习题失败: $e';
      _chapterAIStatus = ChapterAIStatus.failed(
        ChapterAIFeature.practice,
        '练习题生成失败：$e',
      );
    }
    _isGeneratingPractice = false;
    notifyListeners();
  }

  Future<void> analyzeWordAI(String word, String sentence) async {
    final currentResult = result;
    if (currentResult == null || !_ensureAIReady()) return;
    final chapterText = currentResult.passageText;
    final sourceLanguage = SourceLanguage.inferFromText(
      '$sentence $chapterText',
    );
    final outputLanguage = OutputLanguage.fromCode(
      effectiveTargetExplanationLanguage,
    );
    final contentHash = AICacheService.contentHashFor(
      jsonEncode({
        'word': word.trim().toLowerCase(),
        'sentence': sentence.trim(),
        'chapterText': chapterText,
      }),
    );
    final cacheBookId = activeBookId ?? 'word-analysis';
    final cacheChapterIndex = currentChapter;

    try {
      final cacheJson = await _aiCache?.loadWordAnalysis(
        cacheBookId,
        cacheChapterIndex,
        contentHash: contentHash,
        promptVersion: _aiService!.promptVersion,
        sourceLanguage: sourceLanguage.code,
        outputLanguage: outputLanguage.code,
      );
      if (cacheJson != null) {
        _aiWordAnalysis = WordAnalysis.fromJson(
          jsonDecode(cacheJson) as Map<String, dynamic>,
        );
        _isAnalyzingWord = false;
        notifyListeners();
        return;
      }
    } catch (_) {
      // Ignore stale or invalid cache entries and fall back to a fresh request.
    }

    _isAnalyzingWord = true;
    _aiWordAnalysis = null;
    notifyListeners();
    try {
      final analysis = await _aiService!.analyzeWord(
        word: word,
        sentence: sentence,
        chapterContext: chapterText,
        sourceLanguage: sourceLanguage,
        outputLanguage: outputLanguage,
        spoilerBoundary: SpoilerBoundary.currentPassage(),
      );
      _aiWordAnalysis = analysis;
      _settings?.incrementAIUsage(wordAnalysis: true);
      await _aiCache?.saveWordAnalysis(
        cacheBookId,
        cacheChapterIndex,
        jsonEncode(analysis.toJson()),
        contentHash: contentHash,
        promptVersion: _aiService!.promptVersion,
        sourceLanguage: sourceLanguage.code,
        outputLanguage: outputLanguage.code,
      );
    } catch (e) {
      _errorMessage = 'AI 单词解析失败: $e';
    }
    _isAnalyzingWord = false;
    notifyListeners();
  }

  void clearAIResults() {
    _aiTextAnalysis = null;
    _aiTranslation = null;
    _aiSummary = null;
    _aiChapterPreview = null;
    _aiPractice = null;
    _aiWordAnalysis = null;
    _chapterAIStatus = null;
    notifyListeners();
  }

  Future<void> clearAICache() async {
    await _aiCache?.clearAllCache();
    final totalChapters = _book?.chapters.length;
    _chapterAISummaryCoverage = totalChapters == null
        ? null
        : ChapterAISummaryCoverage(
            totalChapters: totalChapters,
            generatedChapterIndexes: const [],
          );
    notifyListeners();
  }

  Future<void> refreshChapterAISummaryCoverage() {
    return _refreshChapterAISummaryCoverage();
  }

  bool _ensureAIReady() {
    if (_aiService == null) {
      _errorMessage = 'AI 服务未初始化';
      notifyListeners();
      return false;
    }
    if (!aiFeaturesEnabled) {
      _errorMessage = aiFeatureDisabledReason;
      notifyListeners();
      return false;
    }
    return true;
  }

  ChapterAIJob _createChapterAIJob() {
    return ChapterAIJob.fromServices(
      aiService: _aiService!,
      cache: _aiCache,
      settings: _settings,
    );
  }

  String _chapterPreviewOpening(String chapterText) {
    final trimmed = chapterText.trim();
    if (trimmed.length <= 1400) return trimmed;
    return trimmed.substring(0, 1400).trim();
  }

  Future<void> _refreshChapterAISummaryCoverage({bool notify = true}) async {
    final aiCache = _aiCache;
    final bookId = _activeBookId;
    final totalChapters = _book?.chapters.length;
    if (aiCache == null || bookId == null || totalChapters == null) {
      _chapterAISummaryCoverage = null;
      _isLoadingChapterAISummaryCoverage = false;
      if (notify) notifyListeners();
      return;
    }

    if (notify) {
      _isLoadingChapterAISummaryCoverage = true;
      notifyListeners();
    }

    try {
      final coverage = await aiCache.summaryCoverageFor(
        bookId,
        totalChapters: totalChapters,
      );
      if (_activeBookId == bookId && _book?.chapters.length == totalChapters) {
        _chapterAISummaryCoverage = coverage;
      }
    } catch (e, stackTrace) {
      AppLogger.instance.event(
        'ai.summary_coverage_failed',
        level: AppLogLevel.warning,
        source: 'ai',
        metadata: {'bookId': bookId},
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      if (notify) {
        _isLoadingChapterAISummaryCoverage = false;
        notifyListeners();
      }
    }
  }

  // ============================================================
  // Helpers
  // ============================================================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _saveCurrentProgress() {
    if (_activeBookId == null || _book == null) return;
    _bookService.updateProgress(
      _activeBookId!,
      _currentChapter,
      _readingProgress,
      chapterScrollOffset: _readingScrollOffset,
    );
  }

  void _resetSearchState() {
    _searchController.reset();
    _sourceHighlightQuery = '';
  }

  LearningItemSource _currentLearningItemSource() {
    return LearningItemSource(
      bookId: _activeBookId ?? '',
      chapterIndex: _book == null ? -1 : _currentChapter,
      chapterTitle: _book == null ? '' : _book!.chapters[_currentChapter].title,
    );
  }

  String _generateBookId(String fileName) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${fileName}_${ts}_${Random().nextInt(9999)}';
  }

  Future<BookMetadata?> _findMissingSourceRepairCandidate(Book book) async {
    final title = _normalizeBookIdentity(book.title);
    if (title.isEmpty) return null;
    final author = _normalizeBookIdentity(book.author);
    final matches = <BookMetadata>[];

    for (final meta in _bookService.books) {
      if (await File(meta.sourcePath).exists()) continue;
      if (_normalizeBookIdentity(meta.title) != title) continue;

      final metaAuthor = _normalizeBookIdentity(meta.author);
      if (author.isNotEmpty && metaAuthor.isNotEmpty && author != metaAuthor) {
        continue;
      }
      matches.add(meta);
    }

    return matches.length == 1 ? matches.single : null;
  }

  String _normalizeBookIdentity(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  int _clampChapterIndex(int chapterIndex, int chapterCount) {
    if (chapterCount <= 0) return 0;
    return chapterIndex.clamp(0, chapterCount - 1).toInt();
  }

  String _canonicalWord(String word) {
    final key = activeLanguageModule.canonicalize(word);
    if (key.isEmpty) return key;
    return _wordLevelService?.canonicalForm(key) ?? key;
  }

  @override
  void dispose() {
    _importCancelTimer?.cancel();
    _activeImportParseTask?.cancel();
    _difficultyRefreshTimer?.cancel();
    _searchController.removeListener(notifyListeners);
    _searchController.dispose();
    _importProgressNotifier.dispose();
    _pronunciationService?.dispose();
    super.dispose();
  }
}

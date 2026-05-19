import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../controllers/reading_search_controller.dart';
import '../models/aggregated_vocabulary.dart';
import '../models/ai_practice_questions.dart';
import '../models/ai_summary.dart';
import '../models/ai_text_analysis.dart';
import '../models/analysis_result.dart';
import '../models/book.dart';
import '../models/book_difficulty.dart';
import '../models/book_metadata.dart';
import '../models/bookmarked_word.dart';
import '../models/learning_item.dart';
import '../models/reading_search_result.dart';
import '../models/reading_bookmark.dart';
import '../models/sentence_breakdown.dart';
import '../models/user_vocabulary.dart';
import '../models/word_context_example.dart';
import '../models/word_analysis.dart';
import '../services/ai_cache_service.dart';
import '../services/ai_service.dart';
import '../services/analysis_service.dart';
import '../services/book_service.dart';
import '../services/bookmark_service.dart';
import '../services/epub_service.dart';
import '../services/learning_item_service.dart';
import '../services/reading_config_service.dart';
import '../services/reading_time_service.dart';
import '../services/sentence_analyzer.dart';
import '../services/settings_service.dart';
import '../services/user_vocabulary_service.dart';
import '../services/word_context_service.dart';
import '../services/word_level_service.dart';
import '../services/dictionary/word_repository.dart';
import '../services/dictionary/wordnet_repository.dart';

class ReadingProvider extends ChangeNotifier {
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
  SettingsService? _settings;
  AIService? _aiService;
  AICacheService? _aiCache;
  WordLevelService? _wordLevelService;
  WordContextService? _wordContextService;
  LearningItemService? _learningItemService;

  // ============================================================
  // Core reading state
  // ============================================================
  Book? _book;
  String? _activeBookId;
  AnalysisResult? _result;
  int _currentChapter = 0;
  double _readingProgress = 0.0;
  bool _isReading = false;
  bool _hasBeenOpened = false;
  final Map<String, AggregatedVocabulary> _allVocab = {};
  Set<String> _currentBookStudyWords = {};
  BookDifficultyRating? _currentBookDifficulty;
  final Map<String, Set<String>> _bookStudyWordsById = {};
  final Map<String, BookDifficultyRating> _bookDifficultyById = {};
  final Set<String> _loadingBookDifficultyIds = {};

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

  // ============================================================
  // Word lookup state
  // ============================================================
  String? _selectedWord;
  String? _selectedWordTranslation;
  String? _selectedWordContext;
  DictionaryEntry? _selectedWordEntry;
  bool _isLoadingWord = false;

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

  // ============================================================
  // AI state
  // ============================================================
  AITextAnalysis? _aiTextAnalysis;
  bool _isAnalyzingText = false;
  String? _aiTranslation;
  bool _isTranslatingText = false;
  AISummary? _aiSummary;
  bool _isGeneratingSummary = false;
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
  AnalysisResult? get result => _result;
  int get currentChapter => _currentChapter;
  double get readingProgress => _readingProgress;
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
    final pending = books
        .where(
          (book) =>
              !_bookDifficultyById.containsKey(book.id) &&
              !_loadingBookDifficultyIds.contains(book.id),
        )
        .toList(growable: false);
    if (pending.isEmpty) return;

    _loadingBookDifficultyIds.addAll(pending.map((book) => book.id));
    notifyListeners();

    for (final meta in pending) {
      try {
        final book = meta.id == _activeBookId && _book != null
            ? _book!
            : await EpubService.parseFile(meta.sourcePath);
        final studyWords = AnalysisService.collectBookStudyWords(
          book,
          _wordLevelService,
        );
        _bookStudyWordsById[meta.id] = studyWords;
        _bookDifficultyById[meta.id] = AnalysisService.rateBookDifficulty(
          studyWords,
          _userVocab,
        );
        if (meta.id == _activeBookId) {
          _currentBookStudyWords = studyWords;
          _currentBookDifficulty = _bookDifficultyById[meta.id];
        }
      } catch (_) {
        _bookDifficultyById.remove(meta.id);
        _bookStudyWordsById.remove(meta.id);
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

  // -- Word lookup --
  String? get selectedWord => _selectedWord;
  String? get selectedWordTranslation => _selectedWordTranslation;
  String? get selectedWordContext => _selectedWordContext;
  DictionaryEntry? get selectedWordEntry => _selectedWordEntry;
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

  // -- Reading config (delegated to ReadingConfigService) --
  double get fontSize => _readingConfig?.fontSize ?? 16.0;
  String get fontFamily => _readingConfig?.fontFamily ?? 'Serif';
  double get lineHeight => _readingConfig?.lineHeight ?? 2.0;
  String get readingTheme => _readingConfig?.theme ?? 'light';

  // -- Reading time (delegated to ReadingTimeService) --
  int get readingTimeSeconds => _readingTime?.totalSeconds ?? 0;
  String get readingTimeDisplay => _readingTime?.displayText ?? '0 秒';
  int readingTimeSecondsForBook(String bookId) {
    final seconds = _readingTime?.secondsForBook(bookId) ?? 0;
    if (seconds > 0 || _bookService.books.length != 1) return seconds;
    return readingTimeSeconds;
  }

  // -- AI --
  AITextAnalysis? get aiTextAnalysis => _aiTextAnalysis;
  bool get isAnalyzingText => _isAnalyzingText;
  String? get aiTranslation => _aiTranslation;
  bool get isTranslatingText => _isTranslatingText;
  AISummary? get aiSummary => _aiSummary;
  bool get isGeneratingSummary => _isGeneratingSummary;
  String get summaryLanguage => _summaryLanguage;
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
  WordLevelService? get wordLevelService => _wordLevelService;
  WordContextService? get wordContextService => _wordContextService;
  List<LearningItem> get learningItems =>
      _learningItemService?.allItems ?? const [];
  int get learningItemCount => _learningItemService?.count ?? 0;
  bool get canCreateLearningItems => _learningItemService != null;

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

  // ============================================================
  // Initialisation
  // ============================================================

  Future<void> init() async {
    await _bookService.init();
    await _bookmarkService?.init();
    await _readingConfig?.init();
    await _readingTime?.init();
    await _userVocab?.init();
    await _wordContextService?.init();
    await _learningItemService?.init();
    _refreshCachedBookDifficulties();
    if (_book != null) {
      _refreshCurrentBookStudyWords();
      await _analyzeCurrentChapter();
    } else {
      notifyListeners();
    }
  }

  List<WordContextExample> importedExamplesFor(String word) {
    return _wordContextService?.examplesFor(word) ?? const [];
  }

  // ============================================================
  // Book import / management
  // ============================================================

  Future<void> importBook(String filePath) async {
    _isLoading = true;
    _errorMessage = null;
    _importStage = '正在读取 EPUB 文件...';
    notifyListeners();

    try {
      final originalFile = File(filePath);
      final bookId = _generateBookId(originalFile.uri.pathSegments.last);
      final dir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${dir.path}/books');
      if (!await booksDir.exists()) await booksDir.create(recursive: true);
      final copiedPath = '${booksDir.path}/$bookId.epub';
      await originalFile.copy(copiedPath);

      final book = await EpubService.parseFile(copiedPath);

      String? coverPath;
      if (book.coverBytes != null) {
        coverPath = await _bookService.saveCover(bookId, book.coverBytes!);
      }

      await _bookService.addBook(
        BookMetadata(
          id: bookId,
          title: book.title,
          author: book.author,
          sourcePath: copiedPath,
          coverPath: coverPath,
          totalChapters: book.chapters.length,
          lastReadAt: DateTime.now(),
        ),
      );

      _book = book;
      _activeBookId = bookId;
      _currentChapter = 0;
      _readingProgress = 0.0;
      _hasBeenOpened = false;
      _allVocab.clear();
      _refreshCurrentBookStudyWords();
      _currentBookDifficulty = null;
      _bookmarkedWords.clear();
      _readingBookmarks.clear();
      _resetSearchState();

      _importStage = '正在统计生词、分析句式...';
      notifyListeners();
      await _analyzeCurrentChapter();
    } catch (e) {
      _errorMessage = 'Failed to import book: $e';
    }
    _isLoading = false;
    _importStage = '';
    notifyListeners();
  }

  Future<void> switchToBook(String bookId) async {
    if (bookId == _activeBookId && _book != null) return;
    _saveCurrentProgress();

    final meta = _bookService.books.where((b) => b.id == bookId).firstOrNull;
    if (meta == null) return;

    _isLoading = true;
    _errorMessage = null;
    _importStage = '正在加载...';
    notifyListeners();

    try {
      final book = await EpubService.parseFile(meta.sourcePath);
      _book = book;
      _activeBookId = bookId;
      _currentChapter = meta.currentChapter.clamp(0, book.chapters.length - 1);
      _readingProgress = meta.chapterProgress;
      _allVocab.clear();
      _refreshCurrentBookStudyWords();
      _currentBookDifficulty = null;
      _resetSearchState();

      _loadBookmarks(bookId);

      await _analyzeCurrentChapter();
    } catch (e) {
      _errorMessage = 'Failed to load book: $e';
    }
    _isLoading = false;
    _importStage = '';
    notifyListeners();
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
      _hasBeenOpened = false;
      _allVocab.clear();
      _currentBookStudyWords = {};
      _currentBookDifficulty = null;
      _bookmarkedWords.clear();
      _readingBookmarks.clear();
      _selectedWord = null;
      _selectedWordTranslation = null;
      _selectedWordContext = null;
      _selectedWordEntry = null;
      _selectedText = null;
      _selectedAnalysis = null;
      _selectedBreakdowns = null;
      _aiTextAnalysis = null;
      _aiTranslation = null;
      _aiSummary = null;
      _aiPractice = null;
      _aiWordAnalysis = null;
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
    _isReading = true;
    _hasBeenOpened = true;
    _readingTime?.start(_activeBookId);
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
    _currentChapter = index;
    _readingProgress = 0.0;
    _saveCurrentProgress();
    notifyListeners();
    await _analyzeCurrentChapter();
  }

  void updateReadingProgress(double progress) {
    _readingProgress = progress.clamp(0.0, 1.0);
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
    );
    _updateAllVocab();
    _updateCurrentBookDifficulty();
    notifyListeners();
  }

  void _updateCurrentBookDifficulty() {
    if (_book == null) {
      _currentBookDifficulty = null;
      return;
    }
    _currentBookDifficulty = AnalysisService.rateBookDifficulty(
      _currentBookStudyWords,
      _userVocab,
    );
    if (_activeBookId != null) {
      _bookDifficultyById[_activeBookId!] = _currentBookDifficulty!;
    }
  }

  void _refreshCurrentBookStudyWords() {
    final book = _book;
    _currentBookStudyWords = book == null
        ? {}
        : AnalysisService.collectBookStudyWords(book, _wordLevelService);
    if (_activeBookId != null) {
      _bookStudyWordsById[_activeBookId!] = _currentBookStudyWords;
    }
  }

  void _refreshCachedBookDifficulties() {
    for (final entry in _bookStudyWordsById.entries) {
      _bookDifficultyById[entry.key] = AnalysisService.rateBookDifficulty(
        entry.value,
        _userVocab,
      );
    }
    if (_activeBookId != null &&
        _bookDifficultyById.containsKey(_activeBookId)) {
      _currentBookDifficulty = _bookDifficultyById[_activeBookId];
    }
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

  Future<void> markWordKnown(String word) async {
    await _userVocab?.setKnown(_canonicalWord(word));
    _refreshCachedBookDifficulties();
    await _analyzeCurrentChapter();
    notifyListeners();
  }

  Future<void> markWordLearning(String word) async {
    await _userVocab?.setLearning(_canonicalWord(word));
    _refreshCachedBookDifficulties();
    await _analyzeCurrentChapter();
    notifyListeners();
  }

  Future<void> markWordUnknown(String word) async {
    await _userVocab?.setUnknown(_canonicalWord(word));
    _refreshCachedBookDifficulties();
    await _analyzeCurrentChapter();
    notifyListeners();
  }

  // ============================================================
  // Word lookup
  // ============================================================

  Future<void> lookupWord(String word, {String? contextText}) async {
    _selectedWord = word;
    _selectedWordTranslation = null;
    _selectedWordContext = _normalizeLookupContext(contextText);
    _selectedWordEntry = null;
    _isLoadingWord = true;
    notifyListeners();

    final entry = await _wordRepo.lookup(word);
    _selectedWordEntry = entry;
    final firstDefinition = entry?.meanings
        .expand((meaning) => meaning.definitions)
        .firstOrNull;
    if (firstDefinition != null) {
      _selectedWordTranslation = firstDefinition;
    }
    _isLoadingWord = false;
    notifyListeners();
  }

  void clearWordLookup() {
    _selectedWord = null;
    _selectedWordTranslation = null;
    _selectedWordContext = null;
    _selectedWordEntry = null;
    _isLoadingWord = false;
    notifyListeners();
  }

  String? _normalizeLookupContext(String? contextText) {
    final trimmed = contextText?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
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

  Future<void> deleteLearningItem(String id) async {
    await _learningItemService?.delete(id);
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

  Future<void> analyzeSelectedTextAI(
    String text,
    String before,
    String after,
  ) async {
    if (!_ensureAIReady()) return;
    _selectedText = text;
    _isAnalyzingText = true;
    _aiTextAnalysis = null;
    _aiTranslation = null;
    _errorMessage = null;
    notifyListeners();
    try {
      _aiTextAnalysis = await _aiService!.analyzeText(
        selectedText: text,
        contextBefore: before,
        contextAfter: after,
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
      _aiTranslation = await _aiService!.translateText(text);
    } catch (e) {
      _errorMessage = '翻译失败: $e';
    }
    _isTranslatingText = false;
    notifyListeners();
  }

  Future<void> generateSummary() async {
    if (_result == null || !_ensureAIReady()) return;
    _isGeneratingSummary = true;
    _aiSummary = null;
    notifyListeners();
    try {
      final cacheJson = await _aiCache?.loadSummary(
        _activeBookId!,
        _currentChapter,
        _summaryLanguage,
      );
      if (cacheJson != null) {
        _aiSummary = AISummary.fromJson(
          jsonDecode(cacheJson) as Map<String, dynamic>,
        );
        _isGeneratingSummary = false;
        notifyListeners();
        return;
      }
      await for (final summary in _aiService!.generateSummary(
        chapterText: _result!.passageText,
        vocabulary: _result!.vocabulary.map((v) => v.word).toList(),
        language: _summaryLanguage,
      )) {
        _aiSummary = summary;
        _settings?.incrementAIUsage(chapterSummary: true);
        await _aiCache?.saveSummary(
          _activeBookId!,
          _currentChapter,
          _summaryLanguage,
          jsonEncode(summary.toJson()),
        );
      }
    } catch (e) {
      _errorMessage = '生成总结失败: $e';
    }
    _isGeneratingSummary = false;
    notifyListeners();
  }

  void toggleSummaryLanguage() {
    _summaryLanguage = _summaryLanguage == 'zh' ? 'en' : 'zh';
    _aiSummary = null;
    notifyListeners();
  }

  Future<void> generatePractice() async {
    if (_result == null || !_ensureAIReady()) return;
    _isGeneratingPractice = true;
    _aiPractice = null;
    notifyListeners();
    try {
      final cacheJson = await _aiCache?.loadPractice(
        _activeBookId!,
        _currentChapter,
      );
      if (cacheJson != null) {
        _aiPractice = AIPracticeSet.fromJson(
          jsonDecode(cacheJson) as Map<String, dynamic>,
        );
        _isGeneratingPractice = false;
        notifyListeners();
        return;
      }
      await for (final practice in _aiService!.generatePractice(
        chapterText: _result!.passageText,
        vocabulary: _result!.vocabulary.map((v) => v.word).toList(),
        events: _aiSummary?.events ?? [],
      )) {
        _aiPractice = practice;
        _settings?.incrementAIUsage(practice: true);
        await _aiCache?.savePractice(
          _activeBookId!,
          _currentChapter,
          jsonEncode(practice.toJson()),
        );
      }
    } catch (e) {
      _errorMessage = '生成练习题失败: $e';
    }
    _isGeneratingPractice = false;
    notifyListeners();
  }

  Future<void> analyzeWordAI(String word, String sentence) async {
    if (_result == null || !_ensureAIReady()) return;
    _isAnalyzingWord = true;
    _aiWordAnalysis = null;
    notifyListeners();
    try {
      _aiWordAnalysis = await _aiService!.analyzeWord(
        word: word,
        sentence: sentence,
        chapterContext: _result!.passageText,
      );
      _settings?.incrementAIUsage(wordAnalysis: true);
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
    _aiPractice = null;
    _aiWordAnalysis = null;
    notifyListeners();
  }

  Future<void> clearAICache() async {
    await _aiCache?.clearAllCache();
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
    );
  }

  void _resetSearchState() {
    _searchController.reset();
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

  String _canonicalWord(String word) {
    final lower = word.toLowerCase().trim();
    if (lower.isEmpty) return lower;
    return _wordLevelService?.canonicalForm(lower) ?? lower;
  }

  @override
  void dispose() {
    _searchController.removeListener(notifyListeners);
    _searchController.dispose();
    super.dispose();
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:flow_ai/flow_ai.dart';

import '../models/book_glossary_entry.dart';
import '../services/book_glossary_service.dart';
import '../services/character_registry.dart';
import '../services/reading_memory/book_insight_source_scope_service.dart';
import '../services/reading_memory/chapter_summary_source_scope_cache.dart';

typedef BookSynthesisRunner =
    Future<BookSynthesisResult> Function(
      BookSynthesisRequest request,
    );

class BookInsightProvider extends ChangeNotifier {
  BookInsightProvider({
    required AICacheService cacheService,
    BookGlossaryService? glossaryService,
    CharacterRegistry? characterRegistry,
    ChapterSummarySourceScopeCache? chapterSummarySourceScopeCache,
    BookInsightSourceScopeService? bookInsightSourceScopeService,
    BookInsightRepository? repository,
    BookSynthesisService? synthesisService,
    BookSynthesisRunner? synthesisRunner,
  }) : _characterRegistry = characterRegistry,
       _repository = repository,
       _synthesisRunner = synthesisRunner ?? synthesisService?.synthesize,
       _bookInsightSourceScope =
           bookInsightSourceScopeService ??
           BookInsightSourceScopeService(
             cacheService: cacheService,
             glossaryService: glossaryService,
             characterRegistry: characterRegistry,
             chapterSummarySourceScopeCache: chapterSummarySourceScopeCache,
           );

  final CharacterRegistry? _characterRegistry;
  final BookInsightRepository? _repository;
  final BookSynthesisRunner? _synthesisRunner;
  final BookInsightSourceScopeService _bookInsightSourceScope;

  String? _bookId;
  String? _bookTitle;
  String? _author;
  String? _languageCode;
  int _totalChapters = 0;
  int _currentChapter = 0;

  BookStoryline? _storyline;
  BookAnalysisData? _analysisData;
  BookSynthesisResult? _readScopeSynthesis;
  BookSynthesisResult? _fullBookSynthesis;
  List<BookCharacterCard> _characterCards = const [];
  List<CharacterRegistryEntry> _characterRegistryEntries = const [];
  BookInsightCoverage? _coverage;
  Map<int, AISummary> _chapterSummaries = {};
  List<BookGlossaryEntry> _glossaryEntries = const [];
  bool _isLoading = false;
  bool _isGeneratingReadScopeSynthesis = false;
  bool _isGeneratingFullBookSynthesis = false;
  bool _showFullBook = false;
  String? _error;

  BookStoryline? get storyline => _storyline;
  BookAnalysisData? get analysisData => _analysisData;
  BookSynthesisResult? get readScopeSynthesis => _readScopeSynthesis;
  BookSynthesisResult? get fullBookSynthesis => _fullBookSynthesis;
  BookSynthesisResult? get visibleSynthesis =>
      _showFullBook ? _fullBookSynthesis : _readScopeSynthesis;
  List<BookCharacterCard> get characterCards => _characterCards;
  List<CharacterRegistryEntry> get characterRegistryEntries =>
      _characterRegistryEntries;
  BookInsightCoverage? get coverage => _coverage;
  Map<int, AISummary> get chapterSummaries => _chapterSummaries;
  List<BookGlossaryEntry> get glossaryEntries => _glossaryEntries;
  bool get isLoading => _isLoading;
  bool get isGeneratingReadScopeSynthesis => _isGeneratingReadScopeSynthesis;
  bool get isGeneratingFullBookSynthesis => _isGeneratingFullBookSynthesis;
  bool get isGeneratingVisibleSynthesis => _showFullBook
      ? _isGeneratingFullBookSynthesis
      : _isGeneratingReadScopeSynthesis;
  bool get showFullBook => _showFullBook;
  String? get error => _error;
  bool get canGenerateSynthesis =>
      _synthesisRunner != null && _analysisData != null;
  bool get canMaintainCharacters =>
      _bookId != null && _characterRegistry != null;
  bool get isEmpty =>
      _chapterSummaries.isEmpty &&
      _glossaryEntries.isEmpty &&
      _characterRegistryEntries.isEmpty;

  int get maxChapter => _showFullBook ? _totalChapters - 1 : _currentChapter;

  bool isLoadedForBook(String bookId) => _bookId == bookId;

  Future<void> loadForBook(
    String bookId, {
    required int totalChapters,
    required int currentChapter,
    String? bookTitle,
    String? author,
    String? languageCode,
  }) async {
    if (_isLoading && _bookId == bookId) return;
    final isNewBook = _bookId != bookId;
    _bookId = bookId;
    _bookTitle = bookTitle ?? (isNewBook ? null : _bookTitle);
    _author = author ?? (isNewBook ? null : _author);
    _languageCode = languageCode ?? (isNewBook ? null : _languageCode);
    _totalChapters = totalChapters;
    _currentChapter = currentChapter;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final projection = await _bookInsightSourceScope.loadProjection(
        bookId: bookId,
        maxReadChapter: maxChapter,
        totalChapters: totalChapters,
        readChapters: currentChapter + 1,
        bookTitle: _bookTitle,
        author: _author,
        languageCode: _languageCode,
      );
      _chapterSummaries = projection.chapterSummaries;
      _glossaryEntries = projection.glossaryEntries;
      _analysisData = projection.analysisData;
      _saveAnalysisSnapshot(projection);
      _storyline = projection.storyline;
      _characterCards = projection.characterCards;
      _characterRegistryEntries = projection.characterRegistryEntries;
      _coverage = projection.coverage;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleShowFullBook() {
    _showFullBook = !_showFullBook;
    if (_bookId == null) {
      notifyListeners();
      return;
    }
    unawaited(refresh());
  }

  Future<void> addCharacter(String canonicalName) async {
    final registry = _characterRegistry;
    final bookId = _bookId;
    final trimmed = canonicalName.trim();
    if (registry == null || bookId == null || trimmed.isEmpty) return;

    await registry.init();
    await registry.addEntry(
      bookId,
      CharacterRegistryEntry(
        canonicalName: trimmed,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    await refresh();
  }

  Future<void> confirmCharacterCard(BookCharacterCard card) async {
    final registry = _characterRegistry;
    final bookId = _bookId;
    final canonicalName = card.canonicalName.trim();
    if (registry == null || bookId == null || canonicalName.isEmpty) return;

    await registry.init();
    await registry.addEntry(
      bookId,
      CharacterRegistryEntry(
        canonicalName: canonicalName,
        firstAppearanceChapter: card.firstSeenChapter,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    await refresh();
  }

  Future<void> addCharacterAlias(
    String canonicalName,
    String alias, {
    bool userOverride = true,
  }) async {
    final registry = _characterRegistry;
    final bookId = _bookId;
    if (registry == null || bookId == null) return;
    await registry.init();
    await registry.addAlias(
      bookId,
      canonicalName,
      alias,
      userOverride: userOverride,
    );
    await refresh();
  }

  Future<void> removeCharacterAlias(
    String canonicalName,
    String alias,
  ) async {
    final registry = _characterRegistry;
    final bookId = _bookId;
    if (registry == null || bookId == null) return;
    await registry.init();
    await registry.removeAlias(bookId, canonicalName, alias);
    await refresh();
  }

  Future<void> removeCharacter(String canonicalName) async {
    final registry = _characterRegistry;
    final bookId = _bookId;
    if (registry == null || bookId == null) return;
    await registry.init();
    await registry.removeEntry(bookId, canonicalName);
    await refresh();
  }

  Future<void> refresh() async {
    if (_bookId == null) return;
    await loadForBook(
      _bookId!,
      totalChapters: _totalChapters,
      currentChapter: _currentChapter,
      bookTitle: _bookTitle,
      author: _author,
      languageCode: _languageCode,
    );
  }

  Future<void> refreshIfLoaded(String bookId) async {
    if (_bookId != bookId) return;
    await refresh();
  }

  Future<void> generateReadScopeSynthesis() async {
    await _generateSynthesis(fullBook: false);
  }

  Future<void> generateFullBookSynthesis() async {
    await _generateSynthesis(fullBook: true);
  }

  Future<void> _generateSynthesis({required bool fullBook}) async {
    final runner = _synthesisRunner;
    final bookId = _bookId;
    if (runner == null || bookId == null) return;

    if (fullBook) {
      if (_isGeneratingFullBookSynthesis) return;
      _isGeneratingFullBookSynthesis = true;
    } else {
      if (_isGeneratingReadScopeSynthesis) return;
      _isGeneratingReadScopeSynthesis = true;
    }
    _error = null;
    notifyListeners();

    try {
      final projection = await _bookInsightSourceScope.loadProjection(
        bookId: bookId,
        maxReadChapter: fullBook ? _totalChapters - 1 : _currentChapter,
        totalChapters: _totalChapters,
        readChapters: fullBook ? _totalChapters : _currentChapter + 1,
        bookTitle: _bookTitle,
        author: _author,
        languageCode: _languageCode,
      );
      final analysis = projection.analysisData;
      if (analysis == null) {
        _error = '暂无可分析的章节总结';
        return;
      }
      final result = await runner(
        BookSynthesisRequest(
          analysisData: analysis,
          bookTitle: _bookTitle ?? bookId,
          author: _author,
          chapterSummaries: _synthesisChapterSummaries(projection),
        ),
      );
      if (fullBook) {
        _fullBookSynthesis = result;
      } else {
        _readScopeSynthesis = result;
      }
      if (_showFullBook == fullBook) {
        _analysisData = analysis;
        _chapterSummaries = projection.chapterSummaries;
        _coverage = projection.coverage;
        _storyline = projection.storyline;
        _characterCards = projection.characterCards;
      }
    } catch (e) {
      _error = fullBook ? '生成全书分析失败: $e' : '生成已读范围分析失败: $e';
    } finally {
      if (fullBook) {
        _isGeneratingFullBookSynthesis = false;
      } else {
        _isGeneratingReadScopeSynthesis = false;
      }
      notifyListeners();
    }
  }

  void _saveAnalysisSnapshot(BookInsightSourceScopeProjection projection) {
    final repository = _repository;
    final analysis = projection.analysisData;
    if (repository == null || analysis == null) return;
    repository.saveAnalysisSnapshot(
      data: analysis,
      chapterCoverageHash: _chapterCoverageHash(projection.chapterSummaries),
    );
  }

  List<BookSynthesisChapterSummary> _synthesisChapterSummaries(
    BookInsightSourceScopeProjection projection,
  ) {
    final entries = projection.chapterSummaries.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map(
          (entry) => BookSynthesisChapterSummary(
            chapterIndex: entry.key,
            summary: _summaryForSynthesis(entry.value),
          ),
        )
        .toList(growable: false);
  }

  String _summaryForSynthesis(AISummary summary) {
    final parts = <String>[
      ...summary.events.map((event) => event.description),
      ...summary.characterDevelopments.map(
        (development) =>
            '${development.character}: ${development.change}'.trim(),
      ),
      if (summary.readingGuidance.trim().isNotEmpty) summary.readingGuidance,
    ];
    return parts
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join('\n');
  }

  String _chapterCoverageHash(Map<int, AISummary> summaries) {
    final entries = summaries.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return AICacheService.contentHashFor(
      jsonEncode(
        entries
            .map(
              (entry) => {
                'chapterIndex': entry.key,
                'summary': entry.value.toJson(),
              },
            )
            .toList(growable: false),
      ),
    );
  }
}

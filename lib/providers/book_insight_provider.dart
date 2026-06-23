import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flow_ai/flow_ai.dart';

import '../models/book_glossary_entry.dart';
import '../services/book_glossary_service.dart';
import '../services/character_registry.dart';
import '../services/reading_memory/book_insight_source_scope_service.dart';
import '../services/reading_memory/chapter_summary_source_scope_cache.dart';

class BookInsightProvider extends ChangeNotifier {
  BookInsightProvider({
    required AICacheService cacheService,
    BookGlossaryService? glossaryService,
    CharacterRegistry? characterRegistry,
    ChapterSummarySourceScopeCache? chapterSummarySourceScopeCache,
    BookInsightSourceScopeService? bookInsightSourceScopeService,
  }) : _characterRegistry = characterRegistry,
       _bookInsightSourceScope =
           bookInsightSourceScopeService ??
           BookInsightSourceScopeService(
             cacheService: cacheService,
             glossaryService: glossaryService,
             characterRegistry: characterRegistry,
             chapterSummarySourceScopeCache: chapterSummarySourceScopeCache,
           );

  final CharacterRegistry? _characterRegistry;
  final BookInsightSourceScopeService _bookInsightSourceScope;

  String? _bookId;
  String? _bookTitle;
  String? _author;
  String? _languageCode;
  int _totalChapters = 0;
  int _currentChapter = 0;

  BookStoryline? _storyline;
  List<BookCharacterCard> _characterCards = const [];
  List<CharacterRegistryEntry> _characterRegistryEntries = const [];
  BookInsightCoverage? _coverage;
  Map<int, AISummary> _chapterSummaries = {};
  List<BookGlossaryEntry> _glossaryEntries = const [];
  bool _isLoading = false;
  bool _showFullBook = false;
  String? _error;

  BookStoryline? get storyline => _storyline;
  List<BookCharacterCard> get characterCards => _characterCards;
  List<CharacterRegistryEntry> get characterRegistryEntries =>
      _characterRegistryEntries;
  BookInsightCoverage? get coverage => _coverage;
  Map<int, AISummary> get chapterSummaries => _chapterSummaries;
  List<BookGlossaryEntry> get glossaryEntries => _glossaryEntries;
  bool get isLoading => _isLoading;
  bool get showFullBook => _showFullBook;
  String? get error => _error;
  bool get canMaintainCharacters =>
      _bookId != null && _characterRegistry != null;
  bool get isEmpty =>
      _chapterSummaries.isEmpty &&
      _glossaryEntries.isEmpty &&
      _characterRegistryEntries.isEmpty;

  int get maxChapter => _showFullBook ? _totalChapters - 1 : _currentChapter;

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
}

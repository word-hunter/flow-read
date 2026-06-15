import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flow_ai/flow_ai.dart';

import '../models/book_glossary_entry.dart';
import '../services/book_glossary_service.dart';
import '../services/character_registry.dart';

class BookInsightProvider extends ChangeNotifier {
  BookInsightProvider({
    required AICacheService cacheService,
    BookGlossaryService? glossaryService,
    CharacterRegistry? characterRegistry,
  }) : _cacheService = cacheService,
       _glossaryService = glossaryService,
       _characterRegistry = characterRegistry;

  final AICacheService _cacheService;
  final BookGlossaryService? _glossaryService;
  final CharacterRegistry? _characterRegistry;
  final BookInsightAggregator _aggregator = const BookInsightAggregator();

  String? _bookId;
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
  bool get isEmpty =>
      _chapterSummaries.isEmpty &&
      _glossaryEntries.isEmpty &&
      _characterRegistryEntries.isEmpty;

  int get maxChapter => _showFullBook ? _totalChapters - 1 : _currentChapter;

  Future<void> loadForBook(
    String bookId, {
    required int totalChapters,
    required int currentChapter,
  }) async {
    if (_isLoading && _bookId == bookId) return;
    _bookId = bookId;
    _totalChapters = totalChapters;
    _currentChapter = currentChapter;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final entries = await _cacheService.listBookSummaries(bookId);
      final summaries = <int, AISummary>{};
      DateTime? lastGenerated;

      for (final entry in entries) {
        summaries[entry.chapterIndex] = entry.summary;
        if (entry.generatedAt != null) {
          if (lastGenerated == null ||
              entry.generatedAt!.isAfter(lastGenerated)) {
            lastGenerated = entry.generatedAt;
          }
        }
      }

      _chapterSummaries = summaries;
      _glossaryEntries = await _loadGlossary(bookId);

      final cachedChapters = summaries.keys.toSet();
      final readChapters = currentChapter + 1;
      final boundary = maxChapter;

      _storyline = _aggregator.buildStorylineFromChapters(
        bookId,
        summaries,
        boundary,
      );

      _characterCards = _aggregator.buildCharacterCards(
        bookId,
        summaries,
        boundary,
      );
      _characterRegistryEntries = await _loadCharacterRegistry(bookId);

      _coverage = _aggregator.buildCoverage(
        bookId,
        totalChapters,
        cachedChapters,
        readChapters,
        lastGenerated,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<BookGlossaryEntry>> _loadGlossary(String bookId) async {
    final service = _glossaryService;
    if (service == null) return const [];

    final entries = await service.getBookGlossary(bookId);
    entries.sort((a, b) {
      final wordCompare = a.word.toLowerCase().compareTo(
        b.word.toLowerCase(),
      );
      if (wordCompare != 0) return wordCompare;
      return (a.canonicalForm ?? '').toLowerCase().compareTo(
        (b.canonicalForm ?? '').toLowerCase(),
      );
    });
    return entries;
  }

  Future<List<CharacterRegistryEntry>> _loadCharacterRegistry(
    String bookId,
  ) async {
    final registry = _characterRegistry;
    if (registry == null) return const [];

    await registry.init();
    final entries = registry.getAll(bookId);
    return entries
        .where((entry) => entry.canonicalName.trim().isNotEmpty)
        .toList()
      ..sort((a, b) {
        final chapterA = a.firstAppearanceChapter ?? 1 << 30;
        final chapterB = b.firstAppearanceChapter ?? 1 << 30;
        final chapterCompare = chapterA.compareTo(chapterB);
        if (chapterCompare != 0) return chapterCompare;
        return a.canonicalName.toLowerCase().compareTo(
          b.canonicalName.toLowerCase(),
        );
      });
  }

  void toggleShowFullBook() {
    _showFullBook = !_showFullBook;
    if (_bookId == null) return;

    final boundary = maxChapter;
    _storyline = _aggregator.buildStorylineFromChapters(
      _bookId!,
      _chapterSummaries,
      boundary,
    );
    _characterCards = _aggregator.buildCharacterCards(
      _bookId!,
      _chapterSummaries,
      boundary,
    );
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_bookId == null) return;
    await loadForBook(
      _bookId!,
      totalChapters: _totalChapters,
      currentChapter: _currentChapter,
    );
  }
}

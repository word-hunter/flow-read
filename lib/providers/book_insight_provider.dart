import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flow_ai/flow_ai.dart';

class BookInsightProvider extends ChangeNotifier {
  BookInsightProvider({
    required AICacheService cacheService,
  }) : _cacheService = cacheService;

  final AICacheService _cacheService;
  final BookInsightAggregator _aggregator = const BookInsightAggregator();

  String? _bookId;
  int _totalChapters = 0;
  int _currentChapter = 0;

  BookStoryline? _storyline;
  List<BookCharacterCard> _characterCards = const [];
  BookInsightCoverage? _coverage;
  Map<int, AISummary> _chapterSummaries = {};
  bool _isLoading = false;
  bool _showFullBook = false;
  String? _error;

  BookStoryline? get storyline => _storyline;
  List<BookCharacterCard> get characterCards => _characterCards;
  BookInsightCoverage? get coverage => _coverage;
  Map<int, AISummary> get chapterSummaries => _chapterSummaries;
  bool get isLoading => _isLoading;
  bool get showFullBook => _showFullBook;
  String? get error => _error;
  bool get isEmpty => _chapterSummaries.isEmpty;

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

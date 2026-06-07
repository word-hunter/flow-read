import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../models/reading_search_result.dart';
import '../services/reading_search_service.dart';

class ReadingSearchController extends ChangeNotifier {
  static const int collapsedSearchLimit = 100;

  int _generation = 0;
  String _query = '';
  final List<ReadingSearchResult> _results = [];
  bool _isSearching = false;
  bool _stoppedAtLimit = false;
  ReadingSearchResult? _activeResult;

  String get query => _query;
  List<ReadingSearchResult> get results => List.unmodifiable(_results);
  bool get isSearching => _isSearching;
  bool get stoppedAtLimit => _stoppedAtLimit;
  ReadingSearchResult? get activeResult => _activeResult;

  Future<void> search(
    Book? book,
    String query, {
    bool includeAll = false,
  }) async {
    final trimmedQuery = query.trim();
    final generation = ++_generation;

    _query = trimmedQuery;
    _results.clear();
    _stoppedAtLimit = false;
    _activeResult = null;

    if (book == null || trimmedQuery.isEmpty) {
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    final limit = includeAll ? null : collapsedSearchLimit;
    var batchCount = 0;
    await for (final progress in ReadingSearchService.search(
      book,
      trimmedQuery,
      limit: limit,
    )) {
      if (generation != _generation) return;

      if (progress.stoppedAtLimit) {
        _isSearching = false;
        _stoppedAtLimit = true;
        notifyListeners();
        return;
      }

      final result = progress.result;
      if (result == null) continue;
      _results.add(result);
      batchCount++;
      if (batchCount % 10 == 0) {
        notifyListeners();
      }
    }

    if (generation != _generation) return;
    _isSearching = false;
    _stoppedAtLimit = false;
    notifyListeners();
  }

  Future<void> searchAll(Book? book) {
    return search(book, _query, includeAll: true);
  }

  void activateResult(ReadingSearchResult result) {
    _activeResult = result;
    notifyListeners();
  }

  void reset() {
    _generation += 1;
    _query = '';
    _results.clear();
    _isSearching = false;
    _stoppedAtLimit = false;
    _activeResult = null;
    notifyListeners();
  }
}

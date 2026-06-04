import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/reading_search_result.dart';
import '../reading_provider.dart';
import 'reading_provider_riverpod.dart';

class ReadingSearchFacade {
  const ReadingSearchFacade(this._reader);

  final ReadingProvider _reader;

  String get query => _reader.searchQuery;
  String get sourceHighlightQuery => _reader.sourceHighlightQuery;
  List<ReadingSearchResult> get results => _reader.searchResults;
  bool get isSearching => _reader.isSearching;
  bool get stoppedAtLimit => _reader.searchStoppedAtLimit;
  ReadingSearchResult? get activeResult => _reader.activeSearchResult;

  void clearSourceHighlight() => _reader.clearSourceHighlight();

  Future<void> searchInBook(String query, {bool includeAll = false}) {
    return _reader.searchInBook(query, includeAll: includeAll);
  }

  Future<void> searchAllInBook() {
    return _reader.searchAllInBook();
  }

  Future<void> goToSearchResult(ReadingSearchResult result) {
    return _reader.goToSearchResult(result);
  }
}

final readingSearchProvider = Provider<ReadingSearchFacade>((ref) {
  return ReadingSearchFacade(ref.watch(readingProvider));
});

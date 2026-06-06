import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bookshelf_notifier.dart';
import 'current_book_notifier.dart';
import '../../controllers/reading_search_controller.dart';
import '../../models/reading_search_result.dart';
import 'reading_provider_riverpod.dart';

@immutable
class ReadingSearchState {
  const ReadingSearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
    this.stoppedAtLimit = false,
    this.activeResult,
    this.sourceHighlightQuery = '',
  });

  final String query;
  final List<ReadingSearchResult> results;
  final bool isSearching;
  final bool stoppedAtLimit;
  final ReadingSearchResult? activeResult;
  final String sourceHighlightQuery;

  ReadingSearchState copyWith({
    String? query,
    List<ReadingSearchResult>? results,
    bool? isSearching,
    bool? stoppedAtLimit,
    ReadingSearchResult? activeResult,
    String? sourceHighlightQuery,
    bool clearActiveResult = false,
  }) {
    return ReadingSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      stoppedAtLimit: stoppedAtLimit ?? this.stoppedAtLimit,
      activeResult: clearActiveResult ? null : (activeResult ?? this.activeResult),
      sourceHighlightQuery: sourceHighlightQuery ?? this.sourceHighlightQuery,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReadingSearchState &&
        other.query == query &&
        other.results.length == results.length &&
        other.isSearching == isSearching &&
        other.stoppedAtLimit == stoppedAtLimit &&
        other.activeResult == activeResult &&
        other.sourceHighlightQuery == sourceHighlightQuery;
  }

  @override
  int get hashCode => Object.hash(
        query,
        results.length,
        isSearching,
        stoppedAtLimit,
        activeResult,
        sourceHighlightQuery,
      );
}

class ReadingSearchNotifier extends Notifier<ReadingSearchState> {
  final ReadingSearchController _searchController = ReadingSearchController();

  ReadingSearchNotifier() {
    _searchController.addListener(_syncFromController);
  }

  void _syncFromController() {
    state = state.copyWith(
      query: _searchController.query,
      results: _searchController.results,
      isSearching: _searchController.isSearching,
      stoppedAtLimit: _searchController.stoppedAtLimit,
      activeResult: _searchController.activeResult,
    );
  }

  @override
  ReadingSearchState build() {
    ref.onDispose(() {
      _searchController.removeListener(_syncFromController);
      _searchController.dispose();
    });
    return const ReadingSearchState();
  }

  Future<void> searchInBook(String query, {bool includeAll = false}) async {
    final reader = ref.read(readingProvider);
    return _searchController.search(ref.read(bookshelfNotifierProvider).book ?? reader.book, query, includeAll: includeAll);
  }

  Future<void> searchAllInBook() {
    final reader = ref.read(readingProvider);
    return _searchController.searchAll(ref.read(bookshelfNotifierProvider).book ?? reader.book);
  }

  Future<void> goToSearchResult(ReadingSearchResult result) async {
    final reader = ref.read(readingProvider);
    final book = ref.read(bookshelfNotifierProvider).book ?? reader.book;
    if (book == null) return;
    if (result.chapterIndex < 0 ||
        result.chapterIndex >= book.chapters.length) {
      return;
    }

    _searchController.activateResult(result);
    if (result.chapterIndex != ref.read(currentBookNotifierProvider).currentChapter) {
      await reader.goToChapter(result.chapterIndex);
    }
  }

  void clearSearch() {
    _searchController.reset();
    state = state.copyWith(sourceHighlightQuery: '');
  }

  void highlightSourceExcerpt(String excerpt) {
    final normalized = excerpt.trim();
    if (normalized.isEmpty) return;
    state = state.copyWith(sourceHighlightQuery: normalized);
  }

  void clearSourceHighlight() {
    if (state.sourceHighlightQuery.isEmpty) return;
    state = state.copyWith(sourceHighlightQuery: '');
  }
}

final readingSearchNotifierProvider =
    NotifierProvider<ReadingSearchNotifier, ReadingSearchState>(
  ReadingSearchNotifier.new,
);

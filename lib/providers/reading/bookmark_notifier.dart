import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/bookmarked_word.dart';
import '../../models/reading_bookmark.dart';
import '../../services/bookmark_service.dart';
import 'reading_provider_riverpod.dart';
import 'services_provider.dart';

@immutable
class BookmarkState {
  const BookmarkState({
    this.bookmarkedWords = const [],
    this.readingBookmarks = const [],
  });

  final List<BookmarkedWord> bookmarkedWords;
  final List<ReadingBookmark> readingBookmarks;

  BookmarkState copyWith({
    List<BookmarkedWord>? bookmarkedWords,
    List<ReadingBookmark>? readingBookmarks,
  }) {
    return BookmarkState(
      bookmarkedWords: bookmarkedWords ?? this.bookmarkedWords,
      readingBookmarks: readingBookmarks ?? this.readingBookmarks,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BookmarkState &&
        other.bookmarkedWords.length == bookmarkedWords.length &&
        other.readingBookmarks.length == readingBookmarks.length;
  }

  @override
  int get hashCode => Object.hash(bookmarkedWords.length, readingBookmarks.length);
}

class BookmarkNotifier extends Notifier<BookmarkState> {
  BookmarkService? get _bookmarkService => ref.read(bookmarkServiceProvider);

  @override
  BookmarkState build() {
    final reader = ref.watch(readingProvider);
    return BookmarkState(
      bookmarkedWords: reader.bookmarkedWords,
      readingBookmarks: reader.readingBookmarks,
    );
  }

  bool isBookmarked(String word) {
    final lower = word.toLowerCase().trim();
    return state.bookmarkedWords.any((b) => b.word.toLowerCase() == lower);
  }

  bool isCurrentPositionBookmarked() {
    final reader = ref.read(readingProvider);
    return state.readingBookmarks.any(
      (b) =>
          b.chapterIndex == reader.currentChapter &&
          (b.progress - reader.readingProgress).abs() < 0.01,
    );
  }

  void addBookmark(String word, String translation) {
    final reader = ref.read(readingProvider);
    final activeBookId = reader.activeBookId;
    if (activeBookId == null) return;
    final lower = word.toLowerCase().trim();
    if (state.bookmarkedWords.any((b) => b.word.toLowerCase() == lower)) return;

    String context = reader.selectedWordContext ?? '';
    if (context.isEmpty) {
      final result = reader.result;
      if (result != null) {
        for (final v in result.vocabulary) {
          if (v.word.toLowerCase() == lower) {
            context = v.context;
            break;
          }
        }
      }
    }

    final updated = [
      BookmarkedWord(
        word: word,
        translation: translation,
        context: context,
        addedAt: DateTime.now(),
        bookId: activeBookId,
      ),
      ...state.bookmarkedWords,
    ];
    _bookmarkService?.saveWordBookmarks(activeBookId, updated);
    state = state.copyWith(bookmarkedWords: updated);
  }

  void removeBookmark(String word) {
    final reader = ref.read(readingProvider);
    final activeBookId = reader.activeBookId;
    if (activeBookId == null) return;
    final lower = word.toLowerCase().trim();
    final updated = state.bookmarkedWords
        .where((b) => b.word.toLowerCase() != lower)
        .toList();
    _bookmarkService?.saveWordBookmarks(activeBookId, updated);
    state = state.copyWith(bookmarkedWords: updated);
  }

  void addReadingBookmark() {
    final reader = ref.read(readingProvider);
    final activeBookId = reader.activeBookId;
    if (activeBookId == null || isCurrentPositionBookmarked()) return;

    String excerpt = '';
    final result = reader.result;
    if (result != null) {
      final paragraphs = result.passageText.split(RegExp(r'\n\s*\n'));
      final idx =
          (reader.readingProgress * paragraphs.length).round().clamp(0, paragraphs.length - 1);
      excerpt = paragraphs[idx].trim();
      if (excerpt.length > 80) excerpt = '${excerpt.substring(0, 80)}...';
    }
    String chapterTitle =
        reader.book?.chapters[reader.currentChapter].title ?? '';

    final updated = [
      ReadingBookmark(
        chapterIndex: reader.currentChapter,
        progress: reader.readingProgress,
        chapterTitle: chapterTitle,
        excerpt: excerpt,
        createdAt: DateTime.now(),
        bookId: activeBookId,
      ),
      ...state.readingBookmarks,
    ];
    _bookmarkService?.saveReadingBookmarks(activeBookId, updated);
    state = state.copyWith(readingBookmarks: updated);
  }

  void removeReadingBookmark(int index) {
    final reader = ref.read(readingProvider);
    final activeBookId = reader.activeBookId;
    if (activeBookId == null ||
        index < 0 ||
        index >= state.readingBookmarks.length) {
      return;
    }
    final updated = List<ReadingBookmark>.from(state.readingBookmarks)
      ..removeAt(index);
    _bookmarkService?.saveReadingBookmarks(activeBookId, updated);
    state = state.copyWith(readingBookmarks: updated);
  }

  void goToReadingBookmark(ReadingBookmark bookmark) {
    final reader = ref.read(readingProvider);
    if (reader.book == null) return;
    if (bookmark.chapterIndex >= 0 &&
        bookmark.chapterIndex < reader.book!.chapters.length) {
      reader.goToChapter(bookmark.chapterIndex);
    }
  }
}

final bookmarkNotifierProvider =
    NotifierProvider<BookmarkNotifier, BookmarkState>(
  BookmarkNotifier.new,
);

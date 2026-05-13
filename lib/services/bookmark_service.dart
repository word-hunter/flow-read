import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/bookmarked_word.dart';
import '../models/reading_bookmark.dart';

class BookmarkService {
  late Box<String> _wordBox;
  late Box<String> _readingBox;

  Future<void> init() async {
    _wordBox = Hive.box<String>('word_bookmarks');
    _readingBox = Hive.box<String>('reading_bookmarks');
  }

  // --- Word Bookmarks ---

  List<BookmarkedWord> loadWordBookmarks(String bookId) {
    final json = _wordBox.get(bookId);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map(
            (e) => BookmarkedWord(
              word: e['word'] as String,
              translation: e['translation'] as String,
              context: e['context'] as String,
              addedAt: DateTime.parse(e['addedAt'] as String),
              bookId: e['bookId'] as String,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveWordBookmarks(
    String bookId,
    List<BookmarkedWord> bookmarks,
  ) async {
    final list = bookmarks
        .map(
          (b) => {
            'word': b.word,
            'translation': b.translation,
            'context': b.context,
            'addedAt': b.addedAt.toIso8601String(),
            'bookId': b.bookId,
          },
        )
        .toList();
    await _wordBox.put(bookId, jsonEncode(list));
  }

  Future<void> deleteWordBookmarks(String bookId) async {
    await _wordBox.delete(bookId);
  }

  // --- Reading Bookmarks ---

  List<ReadingBookmark> loadReadingBookmarks(String bookId) {
    final json = _readingBox.get(bookId);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map(
            (e) => ReadingBookmark(
              chapterIndex: e['chapterIndex'] as int,
              progress: (e['progress'] as num).toDouble(),
              chapterTitle: e['chapterTitle'] as String,
              excerpt: e['excerpt'] as String,
              createdAt: DateTime.parse(e['createdAt'] as String),
              bookId: e['bookId'] as String,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveReadingBookmarks(
    String bookId,
    List<ReadingBookmark> bookmarks,
  ) async {
    final list = bookmarks
        .map(
          (b) => {
            'chapterIndex': b.chapterIndex,
            'progress': b.progress,
            'chapterTitle': b.chapterTitle,
            'excerpt': b.excerpt,
            'createdAt': b.createdAt.toIso8601String(),
            'bookId': b.bookId,
          },
        )
        .toList();
    await _readingBox.put(bookId, jsonEncode(list));
  }

  Future<void> deleteReadingBookmarks(String bookId) async {
    await _readingBox.delete(bookId);
  }

  Future<void> close() async {
    await _wordBox.close();
    await _readingBox.close();
  }
}

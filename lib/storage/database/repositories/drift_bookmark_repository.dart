import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../dao/bookmark_dao.dart';
import '../../repositories/bookmark_repository.dart';
import '../../repositories/repository_language.dart';

final class DriftBookmarkRepository implements BookmarkRepository {
  DriftBookmarkRepository(
    this._dao, {
    required String languageCode,
    Map<String, String> initialWordBookmarks = const {},
    Map<String, String> initialReadingBookmarks = const {},
  }) : _languageCode = normalizeRepositoryLanguageCode(languageCode),
       _wordCache = Map.of(initialWordBookmarks),
       _readingCache = Map.of(initialReadingBookmarks);

  final BookmarkDao _dao;
  final String _languageCode;
  final Map<String, String> _wordCache;
  final Map<String, String> _readingCache;

  @override
  Future<void> init() async {
    final wordRows = await _dao.allWordBookmarksForLanguage(_languageCode);
    final readingRows = await _dao.allReadingBookmarksForLanguage(
      _languageCode,
    );
    _wordCache
      ..clear()
      ..addAll(encodedWordBookmarksByBook(wordRows));
    _readingCache
      ..clear()
      ..addAll(encodedReadingBookmarksByBook(readingRows));
  }

  @override
  String? getWordBookmarks(String bookId) => _wordCache[bookId];

  @override
  Future<void> putWordBookmarks(String bookId, String encodedBookmarks) async {
    final rows = _decodeList(encodedBookmarks);
    await _dao.deleteWordBookmarksByBook(bookId, _languageCode);
    for (var index = 0; index < rows.length; index += 1) {
      final item = rows[index];
      final word = item['word']?.toString() ?? '';
      if (word.isEmpty) continue;
      await _dao.insertWordBookmark(
        WordBookmarksCompanion.insert(
          id: _rowId('word', bookId, index),
          word: word,
          bookId: bookId,
          language: Value(_languageCode),
          translation: Value(item['translation']?.toString() ?? ''),
          context: Value(item['context']?.toString() ?? ''),
          addedAt: Value(item['addedAt']?.toString() ?? ''),
        ),
      );
    }
    _wordCache[bookId] = encodedBookmarks;
  }

  @override
  Future<void> deleteWordBookmarks(String bookId) async {
    await _dao.deleteWordBookmarksByBook(bookId, _languageCode);
    _wordCache.remove(bookId);
  }

  @override
  String? getReadingBookmarks(String bookId) => _readingCache[bookId];

  @override
  Future<void> putReadingBookmarks(
    String bookId,
    String encodedBookmarks,
  ) async {
    final rows = _decodeList(encodedBookmarks);
    await _dao.deleteReadingBookmarksByBook(bookId, _languageCode);
    for (var index = 0; index < rows.length; index += 1) {
      final item = rows[index];
      await _dao.insertReadingBookmark(
        ReadingBookmarksCompanion.insert(
          id: _rowId('reading', bookId, index),
          bookId: bookId,
          chapterIndex:
              int.tryParse(item['chapterIndex']?.toString() ?? '') ?? 0,
          progress: double.tryParse(item['progress']?.toString() ?? '') ?? 0,
          language: Value(_languageCode),
          chapterTitle: Value(item['chapterTitle']?.toString() ?? ''),
          excerpt: Value(item['excerpt']?.toString() ?? ''),
          createdAt: Value(item['createdAt']?.toString() ?? ''),
        ),
      );
    }
    _readingCache[bookId] = encodedBookmarks;
  }

  @override
  Future<void> deleteReadingBookmarks(String bookId) async {
    await _dao.deleteReadingBookmarksByBook(bookId, _languageCode);
    _readingCache.remove(bookId);
  }

  @override
  Future<void> close() async {}

  static Map<String, String> encodedWordBookmarksByBook(
    Iterable<WordBookmark> rows,
  ) {
    final grouped = <String, List<Map<String, Object?>>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.bookId, () => []).add({
        'word': row.word,
        'translation': row.translation,
        'context': row.context,
        'addedAt': row.addedAt,
        'bookId': row.bookId,
      });
    }
    return {
      for (final entry in grouped.entries) entry.key: jsonEncode(entry.value),
    };
  }

  static Map<String, String> encodedReadingBookmarksByBook(
    Iterable<ReadingBookmarkEntry> rows,
  ) {
    final grouped = <String, List<Map<String, Object?>>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.bookId, () => []).add({
        'chapterIndex': row.chapterIndex,
        'progress': row.progress,
        'chapterTitle': row.chapterTitle,
        'excerpt': row.excerpt,
        'createdAt': row.createdAt,
        'bookId': row.bookId,
      });
    }
    return {
      for (final entry in grouped.entries) entry.key: jsonEncode(entry.value),
    };
  }

  List<Map<String, Object?>> _decodeList(String encodedBookmarks) {
    final decoded = jsonDecode(encodedBookmarks);
    if (decoded is! Iterable) return const [];
    return decoded
        .whereType<Map>()
        .map(
          (item) => item.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        )
        .toList(growable: false);
  }

  String _rowId(String kind, String bookId, int index) {
    return '$_languageCode:$kind:$bookId:$index';
  }
}

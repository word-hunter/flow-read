import 'package:hive/hive.dart';

import '../hive_box_names.dart';
import 'hive_repository_box.dart';

abstract class BookmarkRepository {
  Future<void> init();
  String? getWordBookmarks(String bookId);
  Future<void> putWordBookmarks(String bookId, String encodedBookmarks);
  Future<void> deleteWordBookmarks(String bookId);
  String? getReadingBookmarks(String bookId);
  Future<void> putReadingBookmarks(String bookId, String encodedBookmarks);
  Future<void> deleteReadingBookmarks(String bookId);
  Future<void> close();
}

class HiveBookmarkRepository implements BookmarkRepository {
  HiveBookmarkRepository({
    Box<String>? wordBox,
    Box<String>? readingBox,
    String? languageCode,
  }) : _wordBox = wordBox,
       _readingBox = readingBox,
       _languageCode = activeHiveLanguageCode(languageCode);

  Box<String>? _wordBox;
  Box<String>? _readingBox;
  final String _languageCode;

  Box<String> get _wordStorage {
    return _wordBox ??
        requireOpenHiveBox<String>(
          HiveBoxNames.wordBookmarksFor(_languageCode),
        );
  }

  Box<String> get _readingStorage {
    return _readingBox ??
        requireOpenHiveBox<String>(
          HiveBoxNames.readingBookmarksFor(_languageCode),
        );
  }

  @override
  Future<void> init() async {
    _wordBox ??= requireOpenHiveBox<String>(
      HiveBoxNames.wordBookmarksFor(_languageCode),
    );
    _readingBox ??= requireOpenHiveBox<String>(
      HiveBoxNames.readingBookmarksFor(_languageCode),
    );
  }

  @override
  String? getWordBookmarks(String bookId) {
    return _wordStorage.get(bookId);
  }

  @override
  Future<void> putWordBookmarks(String bookId, String encodedBookmarks) async {
    await _wordStorage.put(bookId, encodedBookmarks);
  }

  @override
  Future<void> deleteWordBookmarks(String bookId) async {
    await _wordStorage.delete(bookId);
  }

  @override
  String? getReadingBookmarks(String bookId) {
    return _readingStorage.get(bookId);
  }

  @override
  Future<void> putReadingBookmarks(
    String bookId,
    String encodedBookmarks,
  ) async {
    await _readingStorage.put(bookId, encodedBookmarks);
  }

  @override
  Future<void> deleteReadingBookmarks(String bookId) async {
    await _readingStorage.delete(bookId);
  }

  @override
  Future<void> close() async {}
}

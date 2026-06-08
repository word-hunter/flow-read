import '../app_database.dart';
import '../dao/bookmark_dao.dart';

final class DriftBookmarkRepository {
  final BookmarkDao _dao;

  DriftBookmarkRepository(this._dao);

  Future<List<WordBookmark>> wordBookmarks(String bookId, String language) =>
      _dao.wordBookmarksForBook(bookId, language);

  Future<void> insertWordBookmark(WordBookmarksCompanion entry) =>
      _dao.insertWordBookmark(entry);

  Future<void> deleteWordBookmarksByBook(String bookId) =>
      _dao.deleteWordBookmarksByBook(bookId);

  Future<void> deleteWordBookmark(String id) => _dao.deleteWordBookmark(id);

  Future<List<ReadingBookmarkEntry>> readingBookmarks(
    String bookId,
    String language,
  ) =>
      _dao.readingBookmarksForBook(bookId, language);

  Future<void> insertReadingBookmark(ReadingBookmarksCompanion entry) =>
      _dao.insertReadingBookmark(entry);

  Future<void> deleteReadingBookmarksByBook(String bookId) =>
      _dao.deleteReadingBookmarksByBook(bookId);

  Future<void> deleteReadingBookmark(String id) =>
      _dao.deleteReadingBookmark(id);
}

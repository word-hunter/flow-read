import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'bookmark_dao.g.dart';

@DriftAccessor(tables: [WordBookmarks, ReadingBookmarks])
class BookmarkDao extends DatabaseAccessor<AppDatabase>
    with _$BookmarkDaoMixin {
  BookmarkDao(super.db);

  // ---- Word bookmarks ----

  Future<List<WordBookmark>> wordBookmarksForBook(
    String bookId,
    String language,
  ) {
    return (select(wordBookmarks)
          ..where(
            (b) => b.bookId.equals(bookId) & b.language.equals(language),
          )
          ..orderBy([(b) => OrderingTerm.asc(b.addedAt)]))
        .get();
  }

  Future<List<WordBookmark>> allWordBookmarksForLanguage(String language) {
    return (select(wordBookmarks)
          ..where((b) => b.language.equals(language))
          ..orderBy([
            (b) => OrderingTerm.asc(b.bookId),
            (b) => OrderingTerm.asc(b.addedAt),
          ]))
        .get();
  }

  Future<void> insertWordBookmark(WordBookmarksCompanion entry) =>
      into(wordBookmarks).insertOnConflictUpdate(entry);

  Future<void> deleteWordBookmarksByBook(String bookId, String language) =>
      (delete(wordBookmarks)..where(
            (b) => b.bookId.equals(bookId) & b.language.equals(language),
          ))
          .go();

  Future<void> deleteWordBookmarksForLanguage(String language) =>
      (delete(wordBookmarks)..where((b) => b.language.equals(language))).go();

  Future<void> deleteWordBookmark(String id) =>
      (delete(wordBookmarks)..where((b) => b.id.equals(id))).go();

  // ---- Reading bookmarks ----

  Future<List<ReadingBookmarkEntry>> readingBookmarksForBook(
    String bookId,
    String language,
  ) {
    return (select(readingBookmarks)
          ..where(
            (b) => b.bookId.equals(bookId) & b.language.equals(language),
          )
          ..orderBy([(b) => OrderingTerm.asc(b.createdAt)]))
        .get();
  }

  Future<List<ReadingBookmarkEntry>> allReadingBookmarksForLanguage(
    String language,
  ) {
    return (select(readingBookmarks)
          ..where((b) => b.language.equals(language))
          ..orderBy([
            (b) => OrderingTerm.asc(b.bookId),
            (b) => OrderingTerm.asc(b.createdAt),
          ]))
        .get();
  }

  Future<void> insertReadingBookmark(ReadingBookmarksCompanion entry) =>
      into(readingBookmarks).insertOnConflictUpdate(entry);

  Future<void> deleteReadingBookmarksByBook(String bookId, String language) =>
      (delete(readingBookmarks)..where(
            (b) => b.bookId.equals(bookId) & b.language.equals(language),
          ))
          .go();

  Future<void> deleteReadingBookmarksForLanguage(String language) => (delete(
    readingBookmarks,
  )..where((b) => b.language.equals(language))).go();

  Future<void> deleteReadingBookmark(String id) =>
      (delete(readingBookmarks)..where((b) => b.id.equals(id))).go();
}

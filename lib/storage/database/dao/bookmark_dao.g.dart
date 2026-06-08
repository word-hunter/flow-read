// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_dao.dart';

// ignore_for_file: type=lint
mixin _$BookmarkDaoMixin on DatabaseAccessor<AppDatabase> {
  $BookEntriesTable get bookEntries => attachedDatabase.bookEntries;
  $WordBookmarksTable get wordBookmarks => attachedDatabase.wordBookmarks;
  $ReadingBookmarksTable get readingBookmarks =>
      attachedDatabase.readingBookmarks;
  BookmarkDaoManager get managers => BookmarkDaoManager(this);
}

class BookmarkDaoManager {
  final _$BookmarkDaoMixin _db;
  BookmarkDaoManager(this._db);
  $$BookEntriesTableTableManager get bookEntries =>
      $$BookEntriesTableTableManager(_db.attachedDatabase, _db.bookEntries);
  $$WordBookmarksTableTableManager get wordBookmarks =>
      $$WordBookmarksTableTableManager(_db.attachedDatabase, _db.wordBookmarks);
  $$ReadingBookmarksTableTableManager get readingBookmarks =>
      $$ReadingBookmarksTableTableManager(
        _db.attachedDatabase,
        _db.readingBookmarks,
      );
}

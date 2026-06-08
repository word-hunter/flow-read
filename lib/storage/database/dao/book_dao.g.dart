// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_dao.dart';

// ignore_for_file: type=lint
mixin _$BookDaoMixin on DatabaseAccessor<AppDatabase> {
  $BookEntriesTable get bookEntries => attachedDatabase.bookEntries;
  BookDaoManager get managers => BookDaoManager(this);
}

class BookDaoManager {
  final _$BookDaoMixin _db;
  BookDaoManager(this._db);
  $$BookEntriesTableTableManager get bookEntries =>
      $$BookEntriesTableTableManager(_db.attachedDatabase, _db.bookEntries);
}

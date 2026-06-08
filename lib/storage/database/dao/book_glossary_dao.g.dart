// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_glossary_dao.dart';

// ignore_for_file: type=lint
mixin _$BookGlossaryDaoMixin on DatabaseAccessor<AppDatabase> {
  $BookEntriesTable get bookEntries => attachedDatabase.bookEntries;
  $BookGlossaryTable get bookGlossary => attachedDatabase.bookGlossary;
  BookGlossaryDaoManager get managers => BookGlossaryDaoManager(this);
}

class BookGlossaryDaoManager {
  final _$BookGlossaryDaoMixin _db;
  BookGlossaryDaoManager(this._db);
  $$BookEntriesTableTableManager get bookEntries =>
      $$BookEntriesTableTableManager(_db.attachedDatabase, _db.bookEntries);
  $$BookGlossaryTableTableManager get bookGlossary =>
      $$BookGlossaryTableTableManager(_db.attachedDatabase, _db.bookGlossary);
}

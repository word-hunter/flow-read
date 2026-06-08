// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_vocabulary_dao.dart';

// ignore_for_file: type=lint
mixin _$UserVocabularyDaoMixin on DatabaseAccessor<AppDatabase> {
  $BookEntriesTable get bookEntries => attachedDatabase.bookEntries;
  $UserVocabulariesTable get userVocabularies =>
      attachedDatabase.userVocabularies;
  UserVocabularyDaoManager get managers => UserVocabularyDaoManager(this);
}

class UserVocabularyDaoManager {
  final _$UserVocabularyDaoMixin _db;
  UserVocabularyDaoManager(this._db);
  $$BookEntriesTableTableManager get bookEntries =>
      $$BookEntriesTableTableManager(_db.attachedDatabase, _db.bookEntries);
  $$UserVocabulariesTableTableManager get userVocabularies =>
      $$UserVocabulariesTableTableManager(
        _db.attachedDatabase,
        _db.userVocabularies,
      );
}

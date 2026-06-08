// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_level_dao.dart';

// ignore_for_file: type=lint
mixin _$WordLevelDaoMixin on DatabaseAccessor<AppDatabase> {
  $WordLevelsTable get wordLevels => attachedDatabase.wordLevels;
  WordLevelDaoManager get managers => WordLevelDaoManager(this);
}

class WordLevelDaoManager {
  final _$WordLevelDaoMixin _db;
  WordLevelDaoManager(this._db);
  $$WordLevelsTableTableManager get wordLevels =>
      $$WordLevelsTableTableManager(_db.attachedDatabase, _db.wordLevels);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_context_dao.dart';

// ignore_for_file: type=lint
mixin _$WordContextDaoMixin on DatabaseAccessor<AppDatabase> {
  $WordContextsTable get wordContexts => attachedDatabase.wordContexts;
  WordContextDaoManager get managers => WordContextDaoManager(this);
}

class WordContextDaoManager {
  final _$WordContextDaoMixin _db;
  WordContextDaoManager(this._db);
  $$WordContextsTableTableManager get wordContexts =>
      $$WordContextsTableTableManager(_db.attachedDatabase, _db.wordContexts);
}

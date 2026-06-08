// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_config_dao.dart';

// ignore_for_file: type=lint
mixin _$ReadingConfigDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReadingConfigTable get readingConfig => attachedDatabase.readingConfig;
  ReadingConfigDaoManager get managers => ReadingConfigDaoManager(this);
}

class ReadingConfigDaoManager {
  final _$ReadingConfigDaoMixin _db;
  ReadingConfigDaoManager(this._db);
  $$ReadingConfigTableTableManager get readingConfig =>
      $$ReadingConfigTableTableManager(_db.attachedDatabase, _db.readingConfig);
}

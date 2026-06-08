// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_registry_dao.dart';

// ignore_for_file: type=lint
mixin _$CharacterRegistryDaoMixin on DatabaseAccessor<AppDatabase> {
  $CharacterRegistryTable get characterRegistry =>
      attachedDatabase.characterRegistry;
  CharacterRegistryDaoManager get managers => CharacterRegistryDaoManager(this);
}

class CharacterRegistryDaoManager {
  final _$CharacterRegistryDaoMixin _db;
  CharacterRegistryDaoManager(this._db);
  $$CharacterRegistryTableTableManager get characterRegistry =>
      $$CharacterRegistryTableTableManager(
        _db.attachedDatabase,
        _db.characterRegistry,
      );
}

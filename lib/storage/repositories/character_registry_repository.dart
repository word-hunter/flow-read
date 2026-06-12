import 'package:hive/hive.dart';

import '../hive_box_names.dart';
import 'hive_repository_box.dart';

abstract class CharacterRegistryRepository {
  Future<void> init();
  String? valueFor(String key);
  Future<void> putValue(String key, String value);
  Future<void> delete(String key);
  Future<void> close();
}

class HiveCharacterRegistryRepository implements CharacterRegistryRepository {
  HiveCharacterRegistryRepository({Box<String>? box}) : _box = box;

  Box<String>? _box;

  Box<String> get _storage {
    return _box ?? requireOpenHiveBox<String>(HiveBoxNames.characterRegistry);
  }

  @override
  Future<void> init() async {
    _box ??= requireOpenHiveBox<String>(HiveBoxNames.characterRegistry);
  }

  @override
  String? valueFor(String key) => _storage.get(key);

  @override
  Future<void> putValue(String key, String value) async {
    await _storage.put(key, value);
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key);
  }

  @override
  Future<void> close() async {}
}

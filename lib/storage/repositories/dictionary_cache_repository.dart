import 'package:hive/hive.dart';

import '../hive_box_names.dart';

abstract class DictionaryCacheRepository {
  Future<void> init();
  String? get(String key);
  Future<void> put(String key, String content);
  bool containsKey(String key);
  int get length;
  Iterable<dynamic> get keys;
  Future<void> delete(dynamic key);
  Future<void> clear();
}

class HiveDictionaryCacheRepository implements DictionaryCacheRepository {
  HiveDictionaryCacheRepository({Box<String>? box}) : _box = box;

  Box<String>? _box;

  Box<String> get _storage {
    return _box ?? Hive.box<String>(HiveBoxNames.dictionaryCache);
  }

  @override
  Future<void> init() async {
    if (_box != null) return;
    _box = Hive.isBoxOpen(HiveBoxNames.dictionaryCache)
        ? Hive.box<String>(HiveBoxNames.dictionaryCache)
        : await Hive.openBox<String>(HiveBoxNames.dictionaryCache);
  }

  @override
  String? get(String key) => _storage.get(key);

  @override
  Future<void> put(String key, String content) async {
    await _storage.put(key, content);
  }

  @override
  bool containsKey(String key) => _storage.containsKey(key);

  @override
  int get length => _storage.length;

  @override
  Iterable<dynamic> get keys => _storage.keys;

  @override
  Future<void> delete(dynamic key) async {
    await _storage.delete(key);
  }

  @override
  Future<void> clear() async {
    await _storage.clear();
  }
}

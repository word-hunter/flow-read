import 'package:hive/hive.dart';

import '../hive_box_names.dart';
import 'hive_repository_box.dart';

abstract class DictionaryCacheRepository {
  Future<void> init();
  String? get(String key);
  Future<void> put(String key, String content);
  bool containsKey(String key);
  int get length;
  Iterable<dynamic> get keys;
  Future<void> delete(dynamic key);
  Future<void> clear();
  Future<void> close();
}

class HiveDictionaryCacheRepository implements DictionaryCacheRepository {
  HiveDictionaryCacheRepository({Box<String>? box, String? languageCode})
    : _box = box,
      _languageCode = activeHiveLanguageCode(languageCode);

  Box<String>? _box;
  final String _languageCode;

  Box<String> get _storage {
    return _box ??
        requireOpenHiveBox<String>(
          HiveBoxNames.dictionaryCacheFor(_languageCode),
        );
  }

  @override
  Future<void> init() async {
    _box ??= requireOpenHiveBox<String>(
      HiveBoxNames.dictionaryCacheFor(_languageCode),
    );
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

  @override
  Future<void> close() async {}
}

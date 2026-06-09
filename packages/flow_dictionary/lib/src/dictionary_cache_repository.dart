import 'package:hive/hive.dart';

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
      _languageCode = _normalizeLang(languageCode);

  Box<String>? _box;
  final String _languageCode;

  static String _normalizeLang(String? code) {
    final c = code?.trim().toLowerCase() ?? '';
    return c.isEmpty ? 'en' : c;
  }

  static String _boxName(String lang) => 'dictionary_cache_$lang';

  Box<String> get _storage {
    return _box ?? requireOpenHiveBox<String>(_boxName(_languageCode));
  }

  static Box<T> requireOpenHiveBox<T>(String name) {
    if (!Hive.isBoxOpen(name)) {
      throw StateError('Hive box "$name" is not open');
    }
    return Hive.box<T>(name);
  }

  @override
  Future<void> init() async {
    _box ??= requireOpenHiveBox<String>(_boxName(_languageCode));
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

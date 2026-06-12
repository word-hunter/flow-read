import 'package:flow_dictionary/flow_dictionary.dart';

import '../dao/dictionary_cache_dao.dart';
import '../../repositories/hive_repository_box.dart';

final class DriftDictionaryCacheRepository
    implements DictionaryCacheRepository {
  DriftDictionaryCacheRepository(
    this._dao, {
    required String languageCode,
    Map<String, String> initialValues = const {},
  }) : _languageCode = activeHiveLanguageCode(languageCode),
       _cache = Map.of(initialValues);

  final DictionaryCacheDao _dao;
  final String _languageCode;
  final Map<String, String> _cache;

  @override
  Future<void> init() async {
    final values = await _dao.allValues(_languageCode);
    _cache
      ..clear()
      ..addAll(values);
  }

  @override
  String? get(String key) => _cache[key];

  @override
  Future<void> put(String key, String content) async {
    await _dao.putValue(key, _languageCode, content);
    _cache[key] = content;
  }

  @override
  bool containsKey(String key) => _cache.containsKey(key);

  @override
  int get length => _cache.length;

  @override
  Iterable<dynamic> get keys => _cache.keys;

  @override
  Future<void> delete(dynamic key) async {
    final stringKey = key.toString();
    await _dao.deleteByKey(stringKey, _languageCode);
    _cache.remove(stringKey);
  }

  @override
  Future<void> clear() async {
    await _dao.clearForLanguage(_languageCode);
    _cache.clear();
  }

  @override
  Future<void> close() async {}
}

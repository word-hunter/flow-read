import '../dao/dictionary_cache_dao.dart';

final class DriftDictionaryCacheRepository {
  final DictionaryCacheDao _dao;

  DriftDictionaryCacheRepository(this._dao);

  Future<String?> getValue(String key, String language) =>
      _dao.getValue(key, language);

  Future<void> putValue(String key, String language, String value) =>
      _dao.putValue(key, language, value);

  Future<bool> containsKey(String key, String language) =>
      _dao.containsKey(key, language);

  Future<int> count(String language) => _dao.countForLanguage(language);

  Future<void> deleteByKey(String key, String language) =>
      _dao.deleteByKey(key, language);

  Future<void> clearForLanguage(String language) =>
      _dao.clearForLanguage(language);
}

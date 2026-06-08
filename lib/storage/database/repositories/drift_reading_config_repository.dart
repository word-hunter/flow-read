import '../dao/reading_config_dao.dart';

final class DriftReadingConfigRepository {
  final ReadingConfigDao _dao;

  DriftReadingConfigRepository(this._dao);

  Future<String> valueFor(String key, String language) =>
      _dao.valueFor(key, language);

  Future<void> putValue(String key, String language, String value) =>
      _dao.putValue(key, language, value);

  Future<Map<String, String>> allValues(String language) =>
      _dao.allValues(language);

  Future<void> clearForLanguage(String language) =>
      _dao.clearForLanguage(language);
}

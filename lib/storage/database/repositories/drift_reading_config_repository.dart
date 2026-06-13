import '../dao/reading_config_dao.dart';
import '../../repositories/reading_config_repository.dart';
import '../../repositories/repository_language.dart';

final class DriftReadingConfigRepository implements ReadingConfigRepository {
  DriftReadingConfigRepository(
    this._dao, {
    String? languageCode,
    Map<String, String>? initialValues,
  }) : _languageCode = normalizeRepositoryLanguageCode(languageCode),
       _cache = Map<String, String>.of(initialValues ?? const {});

  final ReadingConfigDao _dao;
  final String _languageCode;
  Map<String, String> _cache;

  @override
  Future<void> init() async {
    _cache = await _dao.allValues(_languageCode);
  }

  @override
  String getString(String key, {required String defaultValue}) {
    return _cache[key] ?? defaultValue;
  }

  @override
  Future<void> putString(String key, String value) async {
    _cache[key] = value;
    await _dao.putValue(key, _languageCode, value);
  }

  Future<String> valueFor(String key, String language) =>
      _dao.valueFor(key, language);

  Future<void> putValue(String key, String language, String value) =>
      _dao.putValue(key, language, value);

  Future<Map<String, String>> allValues(String language) =>
      _dao.allValues(language);

  Future<void> clearForLanguage(String language) =>
      _dao.clearForLanguage(language);

  @override
  Future<void> close() async {}
}

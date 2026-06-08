import '../dao/settings_dao.dart';

final class DriftSettingsRepository {
  final SettingsDao _dao;

  DriftSettingsRepository(this._dao);

  Future<String> valueFor(String key) => _dao.valueFor(key);

  Future<void> putValue(String key, String value) => _dao.putValue(key, value);

  Future<void> removeValue(String key) => _dao.removeValue(key);

  Future<Map<String, String>> allEntries() => _dao.allEntries();

  Stream<String?> watchValue(String key) => _dao.watchValue(key);
}

import '../app_database.dart';
import '../dao/word_level_dao.dart';

final class DriftWordLevelRepository {
  final WordLevelDao _dao;

  DriftWordLevelRepository(this._dao);

  Future<List<WordLevelEntry>> allEntries() => _dao.allEntries();

  Future<bool> get hasEntries => _dao.hasEntries;

  Future<void> insertAll(List<WordLevelsCompanion> entries) =>
      _dao.insertAll(entries);

  Future<void> clear() => _dao.clear();
}

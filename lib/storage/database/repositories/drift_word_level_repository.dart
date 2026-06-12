import 'package:drift/drift.dart';

import '../../../models/word_level.dart';
import '../app_database.dart';
import '../dao/settings_dao.dart';
import '../dao/word_level_dao.dart';
import '../../repositories/word_level_repository.dart';

final class DriftWordLevelRepository implements WordLevelRepository {
  DriftWordLevelRepository(this._wordDao, this._settingsDao);

  static const _importedKey = 'word_levels_imported';

  final WordLevelDao _wordDao;
  final SettingsDao _settingsDao;
  final List<WordLevelInfo> _cache = [];
  bool _imported = false;

  @override
  Future<void> init() async {
    final entries = await _wordDao.allEntries();
    _cache
      ..clear()
      ..addAll(entries.map(infoFromEntry));
    _imported = await _settingsDao.valueFor(_importedKey) == 'true';
  }

  @override
  Iterable<WordLevelInfo> get values => _cache;

  @override
  bool get isNotEmpty => _cache.isNotEmpty;

  @override
  bool get imported => _imported;

  @override
  Future<void> addAll(Iterable<WordLevelInfo> entries) async {
    final list = entries.toList(growable: false);
    if (list.isEmpty) return;
    await _wordDao.insertAll(
      list.map(companionFromInfo).toList(growable: false),
    );
    _cache.addAll(list);
  }

  @override
  Future<void> markImported() async {
    await _settingsDao.putValue(_importedKey, 'true');
    _imported = true;
  }

  @override
  Future<void> close() async {}

  static WordLevelInfo infoFromEntry(WordLevelEntry entry) {
    return WordLevelInfo(
      word: entry.word,
      originForm: entry.originForm,
      levelIndex: entry.levelIndex,
    );
  }

  static WordLevelsCompanion companionFromInfo(WordLevelInfo info) {
    return WordLevelsCompanion.insert(
      word: info.word,
      levelIndex: info.levelIndex,
      originForm: Value(info.originForm),
    );
  }
}

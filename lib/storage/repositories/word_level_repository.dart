import 'package:hive/hive.dart';

import '../../models/word_level.dart';
import '../hive_box_names.dart';
import 'hive_repository_box.dart';

abstract class WordLevelRepository {
  Future<void> init();
  Iterable<WordLevelInfo> get values;
  bool get isNotEmpty;
  bool get imported;
  Future<void> addAll(Iterable<WordLevelInfo> entries);
  Future<void> markImported();
  Future<void> close();
}

class HiveWordLevelRepository implements WordLevelRepository {
  HiveWordLevelRepository({Box<WordLevelInfo>? wordBox, Box<dynamic>? metaBox})
    : _wordBox = wordBox,
      _metaBox = metaBox;

  static const _importedKey = 'word_levels_imported';

  Box<WordLevelInfo>? _wordBox;
  Box<dynamic>? _metaBox;

  Box<WordLevelInfo> get _wordStorage {
    return _wordBox ?? Hive.box<WordLevelInfo>(HiveBoxNames.wordLevels);
  }

  Box<dynamic> get _metaStorage {
    return _metaBox ?? Hive.box<dynamic>(HiveBoxNames.settings);
  }

  @override
  Future<void> init() async {
    _wordBox ??= requireOpenHiveBox<WordLevelInfo>(HiveBoxNames.wordLevels);
    _metaBox ??= requireOpenHiveBox<dynamic>(HiveBoxNames.settings);
  }

  @override
  Iterable<WordLevelInfo> get values => _wordStorage.values;

  @override
  bool get isNotEmpty => _wordStorage.isNotEmpty;

  @override
  bool get imported => _metaStorage.get(_importedKey) == 'true';

  @override
  Future<void> addAll(Iterable<WordLevelInfo> entries) async {
    await _wordStorage.addAll(entries);
  }

  @override
  Future<void> markImported() async {
    await _metaStorage.put(_importedKey, 'true');
  }

  @override
  Future<void> close() async {}
}

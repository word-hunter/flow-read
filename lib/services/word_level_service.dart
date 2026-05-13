import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';
import '../models/word_level.dart';

class WordLevelService {
  static const _boxName = 'word_levels';
  static const _importedKey = 'word_levels_imported';
  Box<WordLevelInfo>? _box;
  Box? _metaBox;
  final Map<String, LevelKey> _levelMap = {};

  Future<void> init() async {
    _box = Hive.box<WordLevelInfo>(_boxName);
    _metaBox = Hive.box('settings');

    if (_metaBox?.get(_importedKey) != 'true') {
      await _importBuiltinDict();
    }

    for (final info in _box!.values) {
      _levelMap[info.word] = info.level;
      _levelMap[info.originForm] = info.level;
    }
  }

  LevelKey getLevel(String word) {
    final lower = word.toLowerCase().trim();
    return _levelMap[lower] ?? LevelKey.other;
  }

  String? getOriginForm(String word) {
    final lower = word.toLowerCase().trim();
    final box = _box;
    if (box == null) return null;
    for (final info in box.values) {
      if (info.word == lower && info.originForm != lower) {
        return info.originForm;
      }
    }
    return null;
  }

  bool hasWord(String word) {
    return _levelMap.containsKey(word.toLowerCase().trim());
  }

  int get wordCount => _levelMap.length;

  Future<void> _importBuiltinDict() async {
    final box = _box;
    if (box == null) return;
    if (box.isNotEmpty) return;

    try {
      final content = await rootBundle.loadString('assets/dict/eng-dict.txt');
      final lines = content.split('\n');
      final batch = <WordLevelInfo>[];

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.trim().split('\t');
        if (parts.length < 3) continue;

        final word = parts[0].trim();
        final originForm = parts[1].trim();
        final levelStr = parts[2].trim();

        if (word.isEmpty) continue;

        final level = LevelKey.fromString(levelStr);

        batch.add(
          WordLevelInfo(
            word: word,
            originForm: originForm.isNotEmpty ? originForm : word,
            levelIndex: level.index,
          ),
        );
        _levelMap[word] = level;
        _levelMap[originForm.isNotEmpty ? originForm : word] = level;
      }

      await box.addAll(batch);
      await _metaBox?.put(_importedKey, 'true');
    } catch (e) {
      // Silently fail - dict import is best-effort
      await _metaBox?.put(_importedKey, 'true');
    }
  }
}

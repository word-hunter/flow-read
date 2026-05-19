import 'package:flutter/services.dart' show rootBundle;

import '../models/word_level.dart';
import '../storage/repositories/word_level_repository.dart';

typedef WordLevelAssetLoader = Future<String> Function(String assetPath);

class WordLevelService {
  WordLevelService({
    WordLevelRepository? repository,
    WordLevelAssetLoader? assetLoader,
  }) : _repository = repository ?? HiveWordLevelRepository(),
       _assetLoader = assetLoader ?? rootBundle.loadString;

  final WordLevelRepository _repository;
  final WordLevelAssetLoader _assetLoader;

  final Map<String, LevelKey> _levelMap = {};
  final Map<String, String> _originMap = {};

  Future<void> init() async {
    await _repository.init();
    _levelMap.clear();
    _originMap.clear();

    if (!_repository.imported) {
      await _importBuiltinDict();
    }

    for (final info in _repository.values) {
      _indexInfo(info);
    }
  }

  String canonicalForm(String word) {
    final lower = word.toLowerCase().trim();
    if (lower.isEmpty) return lower;
    return _originMap[lower] ?? _canonicalContraction(lower) ?? lower;
  }

  LevelKey getLevel(String word) {
    return _levelMap[canonicalForm(word)] ??
        _levelMap[word.toLowerCase().trim()] ??
        LevelKey.other;
  }

  String? getOriginForm(String word) {
    final lower = word.toLowerCase().trim();
    final origin = _originMap[lower];
    if (origin == null || origin == lower) return null;
    return origin;
  }

  bool hasWord(String word) {
    final lower = word.toLowerCase().trim();
    return _levelMap.containsKey(lower) ||
        _levelMap.containsKey(canonicalForm(lower));
  }

  int get wordCount => _levelMap.length;

  String? _canonicalContraction(String word) {
    const irregular = {
      "can't": 'can',
      'cannot': 'can',
      "won't": 'will',
      "shan't": 'shall',
      "ain't": 'be',
    };
    final irregularBase = irregular[word];
    if (irregularBase != null) return irregularBase;

    if (word.endsWith("n't") && word.length > 3) {
      final base = word.substring(0, word.length - 3);
      return _originMap[base] ?? base;
    }

    const suffixes = ["'re", "'ve", "'ll", "'d", "'m", "'s"];
    for (final suffix in suffixes) {
      if (word.endsWith(suffix) && word.length > suffix.length) {
        final base = word.substring(0, word.length - suffix.length);
        return _originMap[base] ?? base;
      }
    }
    return null;
  }

  Future<void> _importBuiltinDict() async {
    if (_repository.isNotEmpty) return;

    try {
      final content = await _assetLoader('assets/dict/eng-dict.txt');
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
      }

      await _repository.addAll(batch);
      await _repository.markImported();
    } catch (e) {
      // Silently fail - dict import is best-effort
      await _repository.markImported();
    }
  }

  void _indexInfo(WordLevelInfo info) {
    _levelMap[info.word] = info.level;
    _levelMap[info.originForm] = info.level;
    _originMap[info.word] = info.originForm;
    _originMap[info.originForm] = info.originForm;
  }

  Future<void> close() async {
    await _repository.close();
  }
}

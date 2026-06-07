import 'package:flutter/services.dart' show rootBundle;

import '../models/word_level.dart';
import '../storage/repositories/word_level_repository.dart';
import 'english_word_utils.dart';

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
  Future<void>? _initFuture;

  Future<void> init() async {
    if (_initFuture != null) return _initFuture;
    _initFuture = _doInit();
    return _initFuture;
  }

  Future<void> _doInit() async {
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
    final lower = normalizeEnglishApostrophes(word).toLowerCase().trim();
    if (lower.isEmpty) return lower;
    return _originMap[lower] ??
        canonicalEnglishContraction(
          lower,
          originFor: (base) => _originMap[base],
        ) ??
        lower;
  }

  LevelKey getLevel(String word) {
    return _levelMap[canonicalForm(word)] ??
        _levelMap[normalizeEnglishApostrophes(word).toLowerCase().trim()] ??
        LevelKey.other;
  }

  String? getOriginForm(String word) {
    final lower = normalizeEnglishApostrophes(word).toLowerCase().trim();
    final origin = _originMap[lower];
    if (origin == null || origin == lower) return null;
    return origin;
  }

  bool hasWord(String word) {
    final lower = normalizeEnglishApostrophes(word).toLowerCase().trim();
    return _levelMap.containsKey(lower) ||
        _levelMap.containsKey(canonicalForm(lower));
  }

  int get wordCount => _levelMap.length;

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
    final word = normalizeEnglishApostrophes(info.word).toLowerCase().trim();
    final origin = normalizeEnglishApostrophes(
      info.originForm,
    ).toLowerCase().trim();
    _levelMap[word] = info.level;
    _levelMap[origin] = info.level;
    _originMap[word] = origin;
    _originMap[origin] = origin;
  }

  Future<void> close() async {
    await _repository.close();
  }
}

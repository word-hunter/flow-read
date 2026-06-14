import 'package:flow_language/flow_language.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/word_level.dart';
import '../storage/repositories/word_level_repository.dart';

typedef WordLevelAssetLoader = Future<String> Function(String assetPath);

class WordLevelService {
  WordLevelService({
    required WordLevelRepository repository,
    required LanguageModule languageModule,
    WordLevelAssetLoader? assetLoader,
  }) : _repository = repository,
       _languageModule = languageModule,
       _assetLoader = assetLoader ?? rootBundle.loadString;

  final WordLevelRepository _repository;
  final LanguageModule _languageModule;
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
    final lower = _languageModule.canonicalize(word);
    if (lower.isEmpty) return lower;
    return _originMap[lower] ?? lower;
  }

  LevelKey getLevel(String word) {
    return _levelMap[canonicalForm(word)] ??
        _levelMap[_languageModule.canonicalize(word)] ??
        LevelKey.other;
  }

  String? getOriginForm(String word) {
    final lower = _languageModule.canonicalize(word);
    final origin = _originMap[lower];
    if (origin == null || origin == lower) return null;
    return origin;
  }

  bool hasWord(String word) {
    final lower = _languageModule.canonicalize(word);
    return _levelMap.containsKey(lower) ||
        _levelMap.containsKey(canonicalForm(lower));
  }

  int get wordCount => _levelMap.length;

  Map<String, String> get originMap => Map.unmodifiable(_originMap);

  Future<void> _importBuiltinDict() async {
    if (_repository.isNotEmpty) return;

    final assetPath = _languageModule.dictionaryAssetPath;
    if (assetPath == null) {
      await _repository.markImported();
      return;
    }

    try {
      final content = await _assetLoader(assetPath);
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
      await _repository.markImported();
    }
  }

  void _indexInfo(WordLevelInfo info) {
    final word = _languageModule.canonicalize(info.word);
    final origin = _languageModule.canonicalize(info.originForm);
    _levelMap[word] = info.level;
    _levelMap[origin] = info.level;
    _originMap[word] = origin;
    _originMap[origin] = origin;
  }

  Future<void> close() async {
    await _repository.close();
  }
}

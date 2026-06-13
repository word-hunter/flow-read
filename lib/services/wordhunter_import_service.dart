import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/word_context_example.dart';
import 'user_vocabulary_service.dart';
import 'word_context_service.dart';

class WordHunterImportResult {
  final int knownCount;
  final int learningCount;
  final int exampleCount;

  const WordHunterImportResult({
    required this.knownCount,
    required this.learningCount,
    required this.exampleCount,
  });
}

class WordHunterException implements Exception {
  final String message;
  const WordHunterException(this.message);
  @override
  String toString() => message;
}

class WordHunterImportService {
  WordHunterImportService({
    UserVocabularyService? vocabularyService,
    WordContextService? wordContextService,
  }) : _vocabularyService = vocabularyService ?? UserVocabularyService(),
       _wordContextService = wordContextService ?? WordContextService();

  final UserVocabularyService _vocabularyService;
  final WordContextService _wordContextService;

  Future<WordHunterImportResult> importFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const WordHunterException('Word Hunter 备份文件不存在');
    }
    late Map<String, dynamic> parsed;
    try {
      parsed = await compute(
        _parseSource,
        await file.readAsString(),
      );
    } catch (e) {
      debugPrint('[WordHunter] parse failed: $e');
      throw WordHunterException('Word Hunter 备份格式无效：$e');
    }
    return importPayload(parsed);
  }

  Future<WordHunterImportResult> importPayload(
    Map<String, dynamic> payload,
  ) async {
    final parsed = _normalizePayload(payload);
    final knownWords = (parsed['knownWords'] as List<dynamic>).cast<String>();
    final learningWords = (parsed['learningWords'] as List<dynamic>)
        .cast<String>();
    final contexts = (parsed['contexts'] as Map<String, dynamic>).map(
      (word, value) => MapEntry(
        word,
        (value as List<dynamic>)
            .whereType<Map>()
            .map((item) => WordContextExample.fromJson(_stringKeyMap(item)))
            .where((example) => example.text.isNotEmpty)
            .toList(),
      ),
    );

    if (knownWords.isEmpty && learningWords.isEmpty && contexts.isEmpty) {
      throw const WordHunterException('Word Hunter 备份中没有可导入的单词');
    }

    await Future.wait([
      _vocabularyService.init(),
      _wordContextService.init(),
    ]);

    final currentKnown = _vocabularyService.knownWords;
    await Future.wait(knownWords.map(_vocabularyService.setKnown));
    currentKnown.addAll(knownWords);

    final learningUpdates = <String>[];
    for (final word in learningWords) {
      if (!currentKnown.contains(word)) {
        learningUpdates.add(word);
      }
    }
    if (learningUpdates.isNotEmpty) {
      await Future.wait(learningUpdates.map(_vocabularyService.setLearning));
    }

    var exampleCount = 0;
    for (final entry in contexts.entries) {
      final existing = _wordContextService.examplesFor(entry.key);
      final merged = _mergeExamples(existing, entry.value);
      if (merged.isEmpty) continue;
      exampleCount += entry.value.length;
      await _wordContextService.saveExamples(
        entry.key,
        merged,
        merge: false,
      );
    }

    return WordHunterImportResult(
      knownCount: knownWords.length,
      learningCount: learningUpdates.length,
      exampleCount: exampleCount,
    );
  }
}

// ---- Parsing ----

Map<String, dynamic> _parseSource(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map) {
    throw const FormatException('根节点不是对象');
  }
  return _stringKeyMapStatic(decoded);
}

Map<String, dynamic> _normalizePayload(Map<String, dynamic> payload) {
  final knownWords = _extractWordSet(payload['known']);
  final contexts = _parseContexts(payload['context']);
  final learningWordSet = {
    ..._extractWordSet(payload['learning']),
    ..._extractWordSet(payload['learningWords']),
    ...contexts.keys,
  };
  final learningWords = learningWordSet
      .where((word) => !knownWords.contains(word))
      .toList();

  return {
    'knownWords': knownWords.toList()..sort(),
    'learningWords': learningWords..sort(),
    'contexts': contexts.map(
      (word, examples) =>
          MapEntry(word, examples.map((e) => e.toJson()).toList()),
    ),
  };
}

Set<String> _extractWordSet(dynamic value) {
  final words = <String>{};
  if (value is Map) {
    for (final key in value.keys) {
      final word = _normalizeWord(key.toString());
      if (word.isNotEmpty) words.add(word);
    }
  } else if (value is List) {
    for (final item in value) {
      if (item is String) {
        final word = _normalizeWord(item);
        if (word.isNotEmpty) words.add(word);
      } else if (item is Map) {
        final word = _normalizeWord(
          (item['word'] ?? item['text'] ?? '').toString(),
        );
        if (word.isNotEmpty) words.add(word);
      }
    }
  }
  return words;
}

Map<String, List<WordContextExample>> _parseContexts(dynamic value) {
  final result = <String, List<WordContextExample>>{};
  if (value is! Map) return result;

  for (final entry in value.entries) {
    final fallbackWord = _normalizeWord(entry.key.toString());
    if (fallbackWord.isEmpty) continue;

    final rawExamples = entry.value is List
        ? entry.value as List<dynamic>
        : <dynamic>[entry.value];
    for (final rawExample in rawExamples) {
      final example = _parseExample(rawExample, fallbackWord);
      if (example == null) continue;
      result.putIfAbsent(example.word, () => []).add(example);
    }
  }
  return result;
}

WordContextExample? _parseExample(dynamic value, String fallbackWord) {
  if (value is String) {
    final text = _normalizeText(value);
    if (text.isEmpty) return null;
    return WordContextExample(word: fallbackWord, text: text);
  }
  if (value is! Map) return null;

  final map = _stringKeyMapStatic(value);
  final word = _normalizeWord((map['word'] ?? fallbackWord).toString());
  final text = _normalizeText(
    (map['text'] ?? map['sentence'] ?? map['context'] ?? '').toString(),
  );
  if (word.isEmpty || text.isEmpty) return null;

  return WordContextExample(
    word: word,
    text: text,
    title: _normalizeText((map['title'] ?? '').toString()),
    url: (map['url'] ?? '').toString().trim(),
    favicon: (map['favicon'] ?? '').toString().trim(),
    createdAt: _parseTimestamp(map['timestamp']),
  );
}

DateTime? _parseTimestamp(dynamic value) {
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return DateTime.fromMillisecondsSinceEpoch(parsed);
    return DateTime.tryParse(value);
  }
  return null;
}

// ---- Shared helpers ----

List<WordContextExample> _mergeExamples(
  List<WordContextExample> existing,
  List<WordContextExample> incoming,
) {
  final result = <WordContextExample>[];
  final seen = <String>{};
  for (final example in [...existing, ...incoming]) {
    final key = '${example.text.trim()}|${example.url.trim()}';
    if (seen.add(key)) result.add(example);
  }
  return result;
}

Map<String, dynamic> _stringKeyMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
  throw const WordHunterException('备份数据格式无效');
}

Map<String, dynamic> _stringKeyMapStatic(Map value) {
  return value.map((k, v) => MapEntry(k.toString(), v));
}

String _normalizeWord(String word) => word.toLowerCase().trim();

String _normalizeText(String text) {
  return text.replaceAll(String.fromCharCode(0x00a0), ' ').trim();
}

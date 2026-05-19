import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/word_context_example.dart';
import '../storage/hive_box_names.dart';

class WordContextService {
  late Box<String> _box;

  Future<void> init() async {
    _box = Hive.box<String>(HiveBoxNames.wordContexts);
  }

  List<WordContextExample> examplesFor(String word) {
    final json = _box.get(_normalizeWord(word));
    if (json == null || json.isEmpty) return const [];
    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((item) => WordContextExample.fromJson(_asStringKeyMap(item)))
          .where((example) => example.text.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveExamples(
    String word,
    List<WordContextExample> examples, {
    bool merge = true,
  }) async {
    final normalized = _normalizeWord(word);
    if (normalized.isEmpty) return;

    final next = <WordContextExample>[
      if (merge) ...examplesFor(normalized),
      ...examples,
    ];
    final deduped = _dedupeExamples(next);
    if (deduped.isEmpty) return;

    await _box.put(
      normalized,
      jsonEncode(deduped.map((example) => example.toJson()).toList()),
    );
  }

  List<WordContextExample> _dedupeExamples(List<WordContextExample> examples) {
    final seen = <String>{};
    final result = <WordContextExample>[];
    for (final example in examples) {
      final key = '${example.text.trim()}|${example.url.trim()}';
      if (seen.add(key)) {
        result.add(example);
      }
    }
    return result;
  }

  Map<String, dynamic> _asStringKeyMap(Map value) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }

  String _normalizeWord(String word) => word.toLowerCase().trim();
}

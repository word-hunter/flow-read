import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'word_repository.dart';

class WordNetRepository implements WordRepository {
  static final Map<String, Map<String, dynamic>> _letterCache = {};
  static final Map<String, DictionaryEntry?> _resultCache = {};

  static final _alphaRe = RegExp(r'^[a-zA-Z]');

  @override
  Future<DictionaryEntry?> lookup(String word) async {
    final lower = word.toLowerCase().trim();
    if (lower.isEmpty) return null;

    if (_resultCache.containsKey(lower)) {
      return _resultCache[lower];
    }

    // Try exact match first
    final entry = await _lookupRaw(lower);
    if (entry != null) return entry;

    // Try lemmatized forms
    for (final lemma in _lemmatize(lower)) {
      if (_resultCache.containsKey(lemma)) {
        return _resultCache[lemma];
      }
      final lemmaEntry = await _lookupRaw(lemma);
      if (lemmaEntry != null) return lemmaEntry;
    }

    _resultCache[lower] = null;
    return null;
  }

  static List<String> _lemmatize(String word) {
    if (word.length < 4) return [];
    final forms = <String>[];

    if (word.endsWith('ing')) {
      final base = word.substring(0, word.length - 3);
      forms.add(base);
      if (base.length >= 2 && base[base.length - 1] == base[base.length - 2]) {
        forms.add(base.substring(0, base.length - 1));
      }
      forms.add(base + 'e');
    }
    if (word.endsWith('ed')) {
      final base = word.substring(0, word.length - 2);
      forms.add(base); // walked -> walk, glanced -> glanc
      forms.add(base + 'e'); // glanced -> glance
      if (base.length >= 2 && base[base.length - 1] == base[base.length - 2]) {
        forms.add(base.substring(0, base.length - 1)); // stopped -> stop
      }
    }
    if (word.endsWith('es') && !word.endsWith('sses')) {
      forms.add(word.substring(0, word.length - 2));
      forms.add('${word.substring(0, word.length - 2)}e');
    } else if (word.endsWith('s') && !word.endsWith('ss')) {
      forms.add(word.substring(0, word.length - 1));
    }
    if (word.endsWith('er')) {
      forms.add(word.substring(0, word.length - 2));
      forms.add(word.substring(0, word.length - 1));
    }
    if (word.endsWith('est')) {
      forms.add(word.substring(0, word.length - 3));
      forms.add(word.substring(0, word.length - 2));
    }
    if (word.endsWith('ly')) {
      forms.add(word.substring(0, word.length - 2));
    }

    return forms.where((f) => f.length >= 3).toList();
  }

  Future<DictionaryEntry?> _lookupRaw(String word) async {
    final firstLetter = word[0];
    if (!_alphaRe.hasMatch(word)) {
      return null;
    }

    final letterKey = firstLetter;
    Map<String, dynamic>? letterData = _letterCache[letterKey];

    if (letterData == null) {
      try {
        final jsonStr = await rootBundle.loadString(
          'assets/wordnet/wordnet_$letterKey.json',
        );
        letterData = jsonDecode(jsonStr) as Map<String, dynamic>;
        _letterCache[letterKey] = letterData;
      } catch (_) {
        // Asset load error — retry next time
        return null;
      }
    }

    final wordData = letterData[word];
    if (wordData == null) return null;

    if (wordData is! List) return null;
    final entry = _parseEntry(word, wordData);
    if (entry != null) {
      _resultCache[word] = entry;
    }
    return entry;
  }

  DictionaryEntry? _parseEntry(String word, List<dynamic> senses) {
    if (senses.isEmpty) return null;

    final posMap = <String, List<String>>{};
    final posExamples = <String, List<String>>{};

    for (final sense in senses) {
      final s = sense as Map<String, dynamic>;
      final pos = (s['pos'] is String) ? s['pos'] as String : '';
      final def = (s['def'] is String) ? s['def'] as String : '';
      final example = (s['example'] is String) ? s['example'] as String : '';

      if (pos.isEmpty || def.isEmpty) continue;

      posMap.putIfAbsent(pos, () => []);
      posMap[pos]!.add(def);

      if (example.isNotEmpty) {
        posExamples.putIfAbsent(pos, () => []);
        posExamples[pos]!.add(example);
      }
    }

    final meanings = <Meaning>[];
    for (final e in posMap.entries) {
      final definitions = <String>[];
      for (final def in e.value) {
        definitions.add(def);
      }
      final examples = posExamples[e.key];
      if (examples != null) {
        for (final ex in examples) {
          definitions.add('Example: $ex');
        }
      }
      meanings.add(Meaning(partOfSpeech: e.key, definitions: definitions));
    }

    if (meanings.isEmpty) return null;

    return DictionaryEntry(word: word, meanings: meanings);
  }
}

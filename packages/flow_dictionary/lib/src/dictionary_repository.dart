import 'dart:convert';
import 'package:http/http.dart' as http;
import 'word_repository.dart';

class DictionaryRepository implements WordRepository {
  static final Map<String, DictionaryEntry?> _cache = {};

  @override
  Future<DictionaryEntry?> lookup(
    String word, {
    String languageCode = 'en',
  }) async {
    if (languageCode != 'en') return null;
    final lower = word.toLowerCase().trim();
    if (lower.isEmpty) return null;

    if (_cache.containsKey(lower)) {
      return _cache[lower]?.copyWith(fromCache: true);
    }

    try {
      final uri = Uri.parse(
        'https://api.dictionaryapi.dev/api/v2/entries/en/$lower',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List<dynamic> && data.isNotEmpty) {
          final firstEntry = data.first;
          if (firstEntry is! Map<String, dynamic>) return null;
          final entry = parseEntry(firstEntry, word: lower);
          _cache[lower] = entry;
          return entry;
        }
        return null;
      }
      if (response.statusCode == 404) {
        _cache[lower] = null;
        return null;
      }
      throw DictionaryLookupException('HTTP ${response.statusCode}');
    } on DictionaryLookupException {
      rethrow;
    } catch (error) {
      throw DictionaryLookupException('请求失败或超时', cause: error);
    }
  }

  DictionaryEntry? parseEntry(Map<String, dynamic> json, {String? word}) {
    final meanings = <Meaning>[];

    final meaningsList = json['meanings'] as List<dynamic>?;
    if (meaningsList != null) {
      for (final m in meaningsList) {
        final partOfSpeech = m['partOfSpeech'] as String? ?? '';
        final definitions = <String>[];
        final examples = <String>[];
        final definitionsList = m['definitions'] as List<dynamic>?;
        if (definitionsList != null) {
          for (final d in definitionsList) {
            final def = d['definition'] as String?;
            if (def != null && def.isNotEmpty) {
              definitions.add(def);

              final example = d['example'] as String?;
              if (example != null && example.isNotEmpty) {
                examples.add(example);
              }
            }
          }
        }
        if (definitions.isNotEmpty || examples.isNotEmpty) {
          meanings.add(
            Meaning(
              partOfSpeech: partOfSpeech,
              definitions: definitions,
              examples: examples,
            ),
          );
        }
      }
    }

    final phonetic = json['phonetic'] as String?;
    final phonetics = json['phonetics'] as List<dynamic>?;
    String? phoneticText = phonetic;
    if (phoneticText == null && phonetics != null && phonetics.isNotEmpty) {
      phoneticText = phonetics[0]['text'] as String?;
    }

    final entryWord = json['word'] as String? ?? word ?? '';
    return DictionaryEntry(
      word: entryWord,
      phonetic: phoneticText,
      meanings: meanings,
      sourceName: 'Dictionary API',
      sourceUrl: entryWord.isEmpty
          ? null
          : 'https://api.dictionaryapi.dev/api/v2/entries/en/$entryWord',
    );
  }
}

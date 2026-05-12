import 'dart:convert';
import 'package:http/http.dart' as http;
import 'word_repository.dart';

class DictionaryRepository implements WordRepository {
  static final Map<String, DictionaryEntry?> _cache = {};

  @override
  Future<DictionaryEntry?> lookup(String word) async {
    final lower = word.toLowerCase().trim();
    if (lower.isEmpty) return null;

    if (_cache.containsKey(lower)) {
      return _cache[lower];
    }

    try {
      final uri = Uri.parse(
        'https://api.dictionaryapi.dev/api/v2/entries/en/$lower',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final entry = _parseEntry(data[0]);
          _cache[lower] = entry;
          return entry;
        }
      }
      if (response.statusCode == 404) {
        _cache[lower] = null;
        return null;
      }
    } catch (e) {
      // Network error — don't cache, allow retry
    }

    return null;
  }

  DictionaryEntry? _parseEntry(Map<String, dynamic> json) {
    final meanings = <Meaning>[];

    final meaningsList = json['meanings'] as List<dynamic>?;
    if (meaningsList != null) {
      for (final m in meaningsList) {
        final partOfSpeech = m['partOfSpeech'] as String? ?? '';
        final definitions = <String>[];
        final definitionsList = m['definitions'] as List<dynamic>?;
        if (definitionsList != null) {
          for (final d in definitionsList) {
            final def = d['definition'] as String?;
            if (def != null && def.isNotEmpty) {
              definitions.add(def);

              final example = d['example'] as String?;
              if (example != null && example.isNotEmpty) {
                definitions.add('Example: $example');
              }
            }
          }
        }
        if (definitions.isNotEmpty) {
          meanings.add(Meaning(partOfSpeech: partOfSpeech, definitions: definitions));
        }
      }
    }

    final phonetic = json['phonetic'] as String?;
    final phonetics = json['phonetics'] as List<dynamic>?;
    String? phoneticText = phonetic;
    if (phoneticText == null && phonetics != null && phonetics.isNotEmpty) {
      phoneticText = phonetics[0]['text'] as String?;
    }

    return DictionaryEntry(
      word: json['word'] as String? ?? '',
      phonetic: phoneticText,
      meanings: meanings,
    );
  }
}

import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'dictionary_cache_service.dart';
import 'word_repository.dart';

class LongmanRepository implements WordRepository {
  static const _name = 'Longman';
  static const _host = 'https://www.ldoceonline.com';
  static const _apiBase = '$_host/dictionary/';

  final DictionaryCacheService _cache;

  LongmanRepository(this._cache);

  @override
  Future<DictionaryEntry?> lookup(
    String word, {
    String languageCode = 'en',
  }) async {
    if (languageCode != 'en') return null;
    final lower = word.toLowerCase().trim();
    if (lower.isEmpty) return null;

    final cached = _cache.get(_name, lower, languageCode: languageCode);
    if (cached != null) {
      return parseHtml(lower, cached, fromCache: true);
    }

    try {
      final url = '$_apiBase${Uri.encodeComponent(lower.replaceAll(' ', '-'))}';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final rawHtml = response.body;
      await _cache.set(_name, lower, rawHtml, languageCode: languageCode);
      return parseHtml(lower, rawHtml);
    } catch (_) {
      return null;
    }
  }

  DictionaryEntry? parseHtml(
    String word,
    String rawHtml, {
    bool fromCache = false,
  }) {
    final document = parser.parse(rawHtml);
    final root = document.querySelector('.responsive_cell6');
    if (root == null) return null;

    _cleanElement(root);

    final meanings = <Meaning>[];
    String? phonetic;

    // Pronunciation
    final pronElement = root.querySelector('.PronCodes, .pron');
    if (pronElement != null) {
      phonetic = pronElement.text.trim();
    }
    if (phonetic == null) {
      final pronInfo = root.querySelector('.proninfo .pron');
      if (pronInfo != null) {
        phonetic = pronInfo.text.trim();
      }
    }

    // Parse dictionary entries
    final dictEntries = root.querySelectorAll('span.dictentry');
    for (final entry in dictEntries) {
      final posElement = entry.querySelector('.POS, .pos');
      final pos = posElement?.text.trim() ?? '';

      final senses = entry.querySelectorAll('.Sense');
      if (senses.isNotEmpty) {
        final definitions = <String>[];
        final examples = <String>[];
        for (final sense in senses) {
          final defElement = sense.querySelector('.DEF');
          if (defElement != null) {
            final text = defElement.text.trim();
            if (text.isNotEmpty) definitions.add(text);
          } else {
            final text = sense.text.trim();
            if (text.isNotEmpty) {
              definitions.add(text);
            }
          }

          final exampleElements = sense.querySelectorAll('.EXAMPLE');
          for (final ex in exampleElements) {
            final text = ex.text.trim();
            if (text.isNotEmpty) {
              examples.add(text);
            }
          }
        }
        if (definitions.isNotEmpty || examples.isNotEmpty) {
          meanings.add(
            Meaning(
              partOfSpeech: pos,
              definitions: definitions,
              examples: examples,
            ),
          );
        }
      }
    }

    // Fallback: try .entry_content or .dictionary divs
    if (meanings.isEmpty) {
      final dictContent = root.querySelector('.dictionary');
      if (dictContent != null) {
        final posBlocks = dictContent.querySelectorAll('.pos');
        for (final posBlock in posBlocks) {
          final pos = posBlock.text.trim();
          final parent = posBlock.parent;
          if (parent != null) {
            final definitions = <String>[];
            final defs = parent.querySelectorAll('.def, .definition');
            for (final d in defs) {
              final text = d.text.trim();
              if (text.isNotEmpty) definitions.add(text);
            }
            if (definitions.isNotEmpty) {
              meanings.add(
                Meaning(partOfSpeech: pos, definitions: definitions),
              );
            }
          }
        }
      }
    }

    final sourceUrl =
        '$_apiBase${Uri.encodeComponent(word.replaceAll(' ', '-'))}';

    return meanings.isEmpty && phonetic == null
        ? null
        : DictionaryEntry(
            word: word,
            phonetic: phonetic,
            meanings: meanings,
            sourceName: _name,
            sourceUrl: sourceUrl,
            htmlContent: root.innerHtml,
            fromCache: fromCache,
          );
  }

  void _cleanElement(dom.Element root) {
    final toRemove = [
      'script',
      'style',
      'noscript',
      'iframe',
      'input',
      'label',
      '.asset',
      '.assetlink',
      '.Thesref',
      '.etym',
      '.topslot-container',
      '.contentslot',
      'span[id^="ad_"][class^="am-"]',
    ];
    for (final selector in toRemove) {
      root.querySelectorAll(selector).forEach((e) => e.remove());
    }
  }
}

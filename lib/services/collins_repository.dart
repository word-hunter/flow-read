import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'dictionary_cache_service.dart';
import 'word_repository.dart';

class CollinsRepository implements WordRepository {
  static const _name = 'Collins';
  static const _host = 'https://www.collinsdictionary.com';
  static const _apiBase = '$_host/dictionary/english/';

  final DictionaryCacheService _cache;

  CollinsRepository(this._cache);

  @override
  Future<DictionaryEntry?> lookup(String word) async {
    final lower = word.toLowerCase().trim();
    if (lower.isEmpty) return null;

    final cached = _cache.get(_name, lower);
    if (cached != null) {
      return _parseEntry(lower, cached);
    }

    try {
      final url = '$_apiBase${Uri.encodeComponent(lower.replaceAll(' ', '-'))}';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final rawHtml = response.body;
      await _cache.set(_name, lower, rawHtml);
      return _parseEntry(lower, rawHtml);
    } catch (_) {
      return null;
    }
  }

  DictionaryEntry? _parseEntry(String word, String rawHtml) {
    final document = parser.parse(rawHtml);
    final root = document.querySelector('#main_content .res_cell_center');
    if (root == null) return null;

    _cleanElement(root);

    final meanings = <Meaning>[];
    String? phonetic;

    // Collect pronunciation from various sources
    final pronElements = root.querySelectorAll('.pron');
    if (pronElements.isNotEmpty) {
      final pronunciations = pronElements
          .map((e) => e.text.trim())
          .where((t) => t.isNotEmpty)
          .toSet();
      if (pronunciations.isNotEmpty) {
        phonetic = pronunciations.join(' | ');
      }
    }

    // Also check .mini_h2 .pron
    if (phonetic == null) {
      final miniPron = root.querySelector('.mini_h2 .pron');
      if (miniPron != null) {
        phonetic = miniPron.text.trim();
      }
    }

    // Parse dictionary entries (.cB blocks)
    final dictBlocks = root.querySelectorAll('.cB');
    for (final block in dictBlocks) {
      final posElement = block.querySelector('.gramGrp .pos, .gramGrp.pos');
      final pos = posElement?.text.trim() ?? '';

      final homBlocks = block.querySelectorAll('.hom');
      if (homBlocks.isNotEmpty) {
        for (final hom in homBlocks) {
          _extractMeaningFromHom(hom, pos, meanings);
        }
      } else {
        _extractMeaningFromBlock(block, pos, meanings);
      }
    }

    // Also try .dictionary blocks for additional entries
    if (meanings.isEmpty) {
      final dictBlocks2 = root.querySelectorAll('.dictionary .hom');
      for (final hom in dictBlocks2) {
        _extractMeaningFromHom(hom, '', meanings);
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
          );
  }

  void _extractMeaningFromHom(
    dom.Element hom,
    String basePos,
    List<Meaning> meanings,
  ) {
    final posElement = hom.querySelector('.gramGrp .pos, .gramGrp.pos');
    final pos = posElement?.text.trim() ?? basePos;

    final senses = hom.querySelectorAll('.sense');
    if (senses.isNotEmpty) {
      final definitions = <String>[];
      for (final sense in senses) {
        final defElement = sense.querySelector('.def');
        if (defElement != null) {
          definitions.add(defElement.text.trim());
        }

        final examples = sense.querySelectorAll(
          '.cit.type-example, .type-example .quote',
        );
        for (final ex in examples) {
          final text = ex.text.trim();
          if (text.isNotEmpty) {
            definitions.add('Example: $text');
          }
        }
      }
      if (definitions.isNotEmpty) {
        meanings.add(Meaning(partOfSpeech: pos, definitions: definitions));
      }
    } else {
      // Some entries use .def directly
      final defs = hom.querySelectorAll('.def');
      final definitions = <String>[];
      for (final d in defs) {
        definitions.add(d.text.trim());
      }
      if (definitions.isNotEmpty) {
        meanings.add(Meaning(partOfSpeech: pos, definitions: definitions));
      }
    }
  }

  void _extractMeaningFromBlock(
    dom.Element block,
    String basePos,
    List<Meaning> meanings,
  ) {
    final posElement = block.querySelector('.gramGrp .pos, .gramGrp.pos');
    final pos = posElement?.text.trim() ?? basePos;

    final defs = block.querySelectorAll('.def');
    final definitions = <String>[];
    for (final d in defs) {
      definitions.add(d.text.trim());
    }

    final examples = block.querySelectorAll('.cit.type-example');
    for (final ex in examples) {
      final text = ex.text.trim();
      if (text.isNotEmpty) {
        definitions.add('Example: $text');
      }
    }

    if (definitions.isNotEmpty) {
      meanings.add(Meaning(partOfSpeech: pos, definitions: definitions));
    }
  }

  void _cleanElement(dom.Element root) {
    final toRemove = [
      'script',
      'style',
      'noscript',
      'iframe',
      'input',
      'label',
      '.navigation',
      '.share-button',
      '.share-overlay',
      '.popup-overlay',
      '.cobuild-logo',
      '.socialButtons',
      '.mpuslot_b-container',
      '.copyright',
      '.cB-hook',
      '.beta',
      '.link_logo_information',
      '.type-thesaurus',
      '.extra-link',
      '.carousel-title',
      '.btmslot_a-container',
      '.pB-quiz',
      '.specialQuiz',
      '.new-from-collins',
      '.suggest_new_word_wrapper',
      '.miniWordle',
      '#videos',
      '.cB-n-w',
      '.cB-o',
      '[data-type-block="Word usage trends"]',
      '[data-type-block="Word lists"]',
    ];
    for (final selector in toRemove) {
      root.querySelectorAll(selector).forEach((e) => e.remove());
    }
  }
}

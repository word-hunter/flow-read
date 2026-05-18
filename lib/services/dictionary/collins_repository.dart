import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

import 'dictionary_cache_service.dart';
import 'word_repository.dart';

class CollinsRepository implements WordRepository {
  static const name = 'Collins';
  static const parserVersion = 'collins-html-v2';
  static const _cacheSource = '$name:$parserVersion';
  static const _legacyCacheSource = name;
  static const _host = 'https://www.collinsdictionary.com';
  static const _apiBase = '$_host/dictionary/english/';

  final DictionaryCacheService _cache;

  CollinsRepository(this._cache);

  @override
  Future<DictionaryEntry?> lookup(String word) async {
    final lower = word.toLowerCase().trim();
    if (lower.isEmpty) return null;

    final cached =
        _cache.get(_cacheSource, lower) ??
        _cache.get(_legacyCacheSource, lower);
    if (cached != null) {
      return parseHtml(lower, cached, fromCache: true);
    }

    try {
      final url = _sourceUrl(lower);
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final rawHtml = response.body;
      await _cache.set(_cacheSource, lower, rawHtml);
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
    final root =
        document.querySelector('#main_content .res_cell_center') ??
        document.querySelector('.res_cell_center') ??
        document.querySelector('main') ??
        document.body;
    if (root == null) return null;

    _cleanElement(root);

    final phonetic = _extractPhonetic(root);
    final meanings = <Meaning>[];
    final blocks = root.querySelectorAll('.cB, .dictionary .hom, .hom');

    if (blocks.isNotEmpty) {
      for (final block in blocks) {
        _extractMeaningFromBlock(block, meanings);
      }
    } else {
      _extractMeaningFromBlock(root, meanings);
    }

    final compacted = _dedupeMeanings(meanings);
    return compacted.isEmpty && phonetic == null
        ? null
        : DictionaryEntry(
            word: word,
            phonetic: phonetic,
            meanings: compacted,
            sourceName: name,
            sourceUrl: _sourceUrl(word),
            htmlContent: root.innerHtml,
            fromCache: fromCache,
            parserVersion: parserVersion,
          );
  }

  String _sourceUrl(String word) {
    return '$_apiBase${Uri.encodeComponent(word.replaceAll(' ', '-'))}';
  }

  String? _extractPhonetic(dom.Element root) {
    final pronunciations = <String>{};
    for (final selector in const [
      '.mini_h2 .pron',
      '.pron',
      '.pronunciation',
      '.ipa',
    ]) {
      for (final element in root.querySelectorAll(selector)) {
        final text = _cleanText(element.text);
        if (text.isNotEmpty) pronunciations.add(text);
      }
    }
    if (pronunciations.isEmpty) return null;
    return pronunciations.take(3).join(' | ');
  }

  void _extractMeaningFromBlock(dom.Element block, List<Meaning> meanings) {
    final pos = _cleanText(
      block.querySelector('.gramGrp .pos, .gramGrp.pos, .pos')?.text ?? '',
    );
    final senses = block.querySelectorAll('.sense');
    if (senses.isEmpty) {
      final definitions = _texts(block, '.def, .definition');
      final examples = _texts(
        block,
        '.cit.type-example, .type-example .quote, .quote',
      );
      if (definitions.isNotEmpty || examples.isNotEmpty) {
        meanings.add(
          Meaning(
            partOfSpeech: pos,
            definitions: definitions,
            examples: examples,
          ),
        );
      }
      return;
    }

    final definitions = <String>[];
    final examples = <String>[];
    for (final sense in senses) {
      definitions.addAll(_texts(sense, '.def, .definition'));
      examples.addAll(
        _texts(sense, '.cit.type-example, .type-example .quote, .quote'),
      );
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

  List<Meaning> _dedupeMeanings(List<Meaning> meanings) {
    final result = <Meaning>[];
    for (final meaning in meanings) {
      final definitions = _dedupe(meaning.definitions);
      final examples = _dedupe(meaning.examples);
      if (definitions.isEmpty && examples.isEmpty) continue;
      result.add(
        Meaning(
          partOfSpeech: meaning.partOfSpeech,
          definitions: definitions,
          examples: examples,
        ),
      );
    }
    return result;
  }

  List<String> _texts(dom.Element root, String selector) {
    return root
        .querySelectorAll(selector)
        .map((element) => _cleanText(element.text))
        .where((text) => text.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _dedupe(List<String> items) {
    final seen = <String>{};
    return [
      for (final item in items)
        if (seen.add(item)) item,
    ];
  }

  String _cleanText(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _cleanElement(dom.Element root) {
    final toRemove = [
      'script',
      'style',
      'noscript',
      'iframe',
      'input',
      'label',
      'form',
      'button',
      'svg',
      'canvas',
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
      '.type-scrabble',
      '.extra-link',
      '.carousel-title',
      '.btmslot_a-container',
      '.topslot-container',
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
      '[class*="slot"]',
      '[id*="ad_"]',
    ];
    for (final selector in toRemove) {
      root.querySelectorAll(selector).forEach((element) => element.remove());
    }
  }
}

import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

import 'dictionary_cache_service.dart';
import 'word_repository.dart';

class JpdbRepository implements WordRepository {
  static const name = 'JPDB';
  static const parserVersion = 'jpdb-html-v1';
  static const _cacheSource = '$name:$parserVersion';
  static const _host = 'https://jpdb.io';
  static const _searchBase = '$_host/search?q=';

  final DictionaryCacheService _cache;
  final http.Client? _httpClient;

  JpdbRepository(this._cache, {http.Client? httpClient})
    : _httpClient = httpClient;

  @override
  Future<DictionaryEntry?> lookup(
    String word, {
    String languageCode = 'en',
  }) async {
    if (languageCode != 'ja') return null;
    final query = word.trim();
    if (query.isEmpty) return null;

    final cached = _cache.get(_cacheSource, query, languageCode: languageCode);
    if (cached != null) {
      return _parseHtml(query, cached, fromCache: true);
    }

    try {
      final url = _sourceUrl(query);
      final uri = Uri.parse(url);
      final response = await (_httpClient?.get(uri) ?? http.get(uri)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw DictionaryLookupException('HTTP ${response.statusCode}');
      }

      final rawHtml = utf8.decode(response.bodyBytes, allowMalformed: true);
      await _cache.set(
        _cacheSource,
        query,
        rawHtml,
        languageCode: languageCode,
      );
      return _parseHtml(query, rawHtml);
    } on DictionaryLookupException {
      rethrow;
    } catch (error) {
      throw DictionaryLookupException('请求失败或超时', cause: error);
    }
  }

  DictionaryEntry? _parseHtml(
    String word,
    String rawHtml, {
    bool fromCache = false,
  }) {
    final document = parser.parse(rawHtml);
    final results = document.querySelectorAll('.result');
    if (results.isEmpty) return null;

    final meanings = <Meaning>[];
    String? phonetic;
    String? audioUrl;

    for (final result in results) {
      final isKanji = result.className.contains('kanji');

      if (!isKanji) {
        final parsed = _parseWordResult(result);
        if (parsed != null) {
          if (phonetic == null && parsed.reading.isNotEmpty) {
            phonetic = parsed.reading;
          }
          if (audioUrl == null && parsed.audioUrl != null) {
            audioUrl = parsed.audioUrl;
          }
          if (parsed.meanings.isNotEmpty) {
            meanings.add(parsed.meanings.first);
          }
        }
      } else {
        final parsed = _parseKanjiResult(word, result);
        if (parsed != null && parsed.meanings.isNotEmpty) {
          meanings.add(parsed.meanings.first);
        }
      }
    }

    if (meanings.isEmpty && phonetic == null) return null;

    return DictionaryEntry(
      word: word,
      phonetic: phonetic,
      meanings: meanings,
      sourceName: name,
      sourceUrl: _sourceUrl(word),
      audioUrl: audioUrl,
      fromCache: fromCache,
      parserVersion: parserVersion,
    );
  }

  _ParsedDefinition? _parseWordResult(dom.Element root) {
    String reading = '';
    final rtElements = root.querySelectorAll('.primary-spelling rt');
    for (final rt in rtElements) {
      reading += rt.text;
      rt.remove();
    }

    final pos = root.querySelector('.part-of-speech')?.text.trim() ?? '';

    final descriptionNodes = root.querySelectorAll('.description');
    final definitions = <String>[];
    for (final node in descriptionNodes) {
      final text = node.text
          .replaceAll(RegExp(r'^\d+\.?\s*'), '')
          .replaceAll('&#39;', "'")
          .replaceAll('&quot;', '"')
          .trim();
      if (text.isNotEmpty) {
        definitions.add(text);
      }
    }

    String? audioUrl;
    final audioElement = root.querySelector('.vocabulary-audio');
    final audioData = audioElement?.attributes['data-audio'];
    if (audioData != null && audioData.isNotEmpty) {
      final firstPath = audioData.split(',').first.trim();
      if (firstPath.isNotEmpty) {
        audioUrl = '$_host/static/v/$firstPath';
      }
    }

    if (definitions.isEmpty && reading.isEmpty) return null;

    return _ParsedDefinition(
      reading: reading,
      audioUrl: audioUrl,
      meanings: definitions.isEmpty
          ? []
          : [
              Meaning(
                partOfSpeech: pos,
                definitions: definitions,
              ),
            ],
    );
  }

  _ParsedDefinition? _parseKanjiResult(String word, dom.Element root) {
    final readingListNode = root.querySelector('.kanji-reading-list-common');
    final reading = readingListNode?.querySelector('a')?.text.trim() ?? '';

    final subsection = root.querySelector('.subsection');
    final meaningText = subsection?.text.trim() ?? '';

    if (meaningText.isEmpty && reading.isEmpty) return null;

    return _ParsedDefinition(
      reading: reading,
      meanings: meaningText.isEmpty
          ? []
          : [
              Meaning(
                partOfSpeech: 'Kanji',
                definitions: [meaningText],
              ),
            ],
    );
  }

  String _sourceUrl(String word) {
    return '$_searchBase${Uri.encodeComponent(word)}';
  }
}

class _ParsedDefinition {
  final String reading;
  final String? audioUrl;
  final List<Meaning> meanings;

  const _ParsedDefinition({
    required this.reading,
    this.audioUrl,
    required this.meanings,
  });
}

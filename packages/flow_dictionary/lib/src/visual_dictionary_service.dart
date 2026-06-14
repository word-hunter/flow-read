import 'dart:convert';

import 'package:http/http.dart' as http;

import 'dictionary_cache_service.dart';
import 'visual_definition.dart';

class VisualDictionaryService {
  static const _cacheSource = 'visual_dictionary:v1';
  static const _wikidataApi = 'https://www.wikidata.org/w/api.php';
  static const _commonsFilePath =
      'https://commons.wikimedia.org/wiki/Special:FilePath/';
  static const _wikidataEntityPage = 'https://www.wikidata.org/wiki/';
  static const _thumbnailWidth = 300;

  final DictionaryCacheService _cache;
  final http.Client? _httpClient;

  VisualDictionaryService(this._cache, {http.Client? httpClient})
    : _httpClient = httpClient;

  Future<VisualDefinition?> lookup(String word) async {
    final lower = word.toLowerCase().trim();
    if (lower.isEmpty) return null;

    final cached = _cache.get(_cacheSource, lower);
    if (cached != null) {
      if (cached == _emptyMarker) return null;
      try {
        return VisualDefinition.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        );
      } on Object {
        return null;
      }
    }

    try {
      final result = await _fetchVisualDefinition(lower);
      await _cache.set(
        _cacheSource,
        lower,
        result != null ? jsonEncode(result.toJson()) : _emptyMarker,
      );
      return result;
    } on Object {
      return null;
    }
  }

  Future<VisualDefinition?> _fetchVisualDefinition(String word) async {
    final result = await _lookupByWikipediaTitle(word);
    if (result != null) return result;
    return _lookupBySearch(word);
  }

  Future<VisualDefinition?> _lookupByWikipediaTitle(String word) async {
    final title = '${word[0].toUpperCase()}${word.substring(1)}';
    final uri = Uri.parse(_wikidataApi).replace(
      queryParameters: {
        'action': 'wbgetentities',
        'sites': 'enwiki',
        'titles': title,
        'props': 'claims|labels|descriptions',
        'languages': 'en',
        'format': 'json',
      },
    );

    final response = await _get(uri);
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final entities = body['entities'] as Map<String, dynamic>?;
    if (entities == null) return null;

    for (final entry in entities.entries) {
      final entityId = entry.key;
      if (entityId.startsWith('-')) continue;
      final parsed = _parseEntity(
        entityId,
        entry.value as Map<String, dynamic>,
        word,
      );
      if (parsed != null) return parsed;
    }
    return null;
  }

  Future<VisualDefinition?> _lookupBySearch(String word) async {
    final uri = Uri.parse(_wikidataApi).replace(
      queryParameters: {
        'action': 'wbsearchentities',
        'search': word,
        'language': 'en',
        'format': 'json',
        'limit': '5',
        'type': 'item',
      },
    );

    final response = await _get(uri);
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['search'];
    if (results is! List) return null;

    for (final r in results) {
      final entityId = (r as Map<String, dynamic>)['id'] as String?;
      if (entityId == null) continue;

      final desc = (r['description'] as String? ?? '').toLowerCase();
      if (_isNameOrPlaceDescription(desc)) continue;

      final entity = await _getEntity(entityId);
      if (entity == null) continue;

      final parsed = _parseEntity(entityId, entity, word);
      if (parsed != null) return parsed;
    }
    return null;
  }

  VisualDefinition? _parseEntity(
    String entityId,
    Map<String, dynamic> entity,
    String word,
  ) {
    final imageFile = _extractP18(entity);
    if (imageFile == null) return null;

    final label =
        (entity['labels'] as Map<String, dynamic>?)?['en']?['value']
            as String? ??
        word;
    final description =
        (entity['descriptions'] as Map<String, dynamic>?)?['en']?['value']
            as String?;

    return VisualDefinition(
      word: word,
      entityId: entityId,
      label: label,
      description: description,
      thumbnailUrl: _buildThumbnailUrl(imageFile),
      imageUrl: _buildFullImageUrl(imageFile),
      sourcePageUrl: '$_wikidataEntityPage$entityId',
      confidence: 1.0,
    );
  }

  Future<Map<String, dynamic>?> _getEntity(String entityId) async {
    final uri = Uri.parse(_wikidataApi).replace(
      queryParameters: {
        'action': 'wbgetentities',
        'ids': entityId,
        'props': 'claims|labels|descriptions',
        'languages': 'en',
        'format': 'json',
      },
    );

    final response = await _get(uri);
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['entities'] as Map<String, dynamic>?)?[entityId]
        as Map<String, dynamic>?;
  }

  String? _extractP18(Map<String, dynamic> entity) {
    final claims = entity['claims'] as Map<String, dynamic>?;
    if (claims == null) return null;

    final p18 = claims['P18'] as List<dynamic>?;
    if (p18 == null || p18.isEmpty) return null;

    final mainsnak =
        (p18.first as Map<String, dynamic>)['mainsnak']
            as Map<String, dynamic>?;
    if (mainsnak == null) return null;

    final datavalue = mainsnak['datavalue'] as Map<String, dynamic>?;
    return datavalue?['value'] as String?;
  }

  static bool _isNameOrPlaceDescription(String desc) {
    const markers = [
      'given name',
      'family name',
      'surname',
      'first name',
      'unisex name',
    ];
    for (final m in markers) {
      if (desc.contains(m)) return true;
    }
    return false;
  }

  String _buildThumbnailUrl(String filename) {
    final encoded = Uri.encodeComponent(filename.replaceAll(' ', '_'));
    return '$_commonsFilePath$encoded?width=$_thumbnailWidth';
  }

  String _buildFullImageUrl(String filename) {
    final encoded = Uri.encodeComponent(filename.replaceAll(' ', '_'));
    return '$_commonsFilePath$encoded';
  }

  static const _headers = {'User-Agent': 'FlowRead/1.0'};

  Future<http.Response> _get(Uri uri) async {
    final client = _httpClient;
    final future = client != null
        ? client.get(uri, headers: _headers)
        : http.get(uri, headers: _headers);
    return future.timeout(const Duration(seconds: 10));
  }

  static const _emptyMarker = '__empty__';
}

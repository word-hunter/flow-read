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
    final entities = await _searchEntities(word);
    if (entities.isEmpty) return null;

    for (final entity in entities) {
      final entityId = entity['id'] as String?;
      if (entityId == null) continue;

      final imageFile = await _getEntityImage(entityId);
      if (imageFile == null) continue;

      final label =
          (entity['label'] as String?) ?? word;
      final description = entity['description'] as String?;
      final matchScore = _matchScore(word, label);

      return VisualDefinition(
        word: word,
        entityId: entityId,
        label: label,
        description: description,
        thumbnailUrl: _buildThumbnailUrl(imageFile),
        imageUrl: _buildFullImageUrl(imageFile),
        sourcePageUrl: '$_wikidataEntityPage$entityId',
        confidence: matchScore,
      );
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> _searchEntities(String word) async {
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
    if (response.statusCode != 200) return [];

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['search'];
    if (results is! List) return [];
    return results.cast<Map<String, dynamic>>();
  }

  Future<String?> _getEntityImage(String entityId) async {
    final uri = Uri.parse(_wikidataApi).replace(
      queryParameters: {
        'action': 'wbgetentities',
        'ids': entityId,
        'props': 'claims',
        'format': 'json',
      },
    );

    final response = await _get(uri);
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final entities = body['entities'] as Map<String, dynamic>?;
    if (entities == null) return null;

    final entity = entities[entityId] as Map<String, dynamic>?;
    if (entity == null) return null;

    final claims = entity['claims'] as Map<String, dynamic>?;
    if (claims == null) return null;

    final p18 = claims['P18'] as List<dynamic>?;
    if (p18 == null || p18.isEmpty) return null;

    final mainsnak =
        (p18.first as Map<String, dynamic>)['mainsnak'] as Map<String, dynamic>?;
    if (mainsnak == null) return null;

    final datavalue = mainsnak['datavalue'] as Map<String, dynamic>?;
    return datavalue?['value'] as String?;
  }

  String _buildThumbnailUrl(String filename) {
    final encoded = Uri.encodeComponent(filename.replaceAll(' ', '_'));
    return '$_commonsFilePath$encoded?width=$_thumbnailWidth';
  }

  String _buildFullImageUrl(String filename) {
    final encoded = Uri.encodeComponent(filename.replaceAll(' ', '_'));
    return '$_commonsFilePath$encoded';
  }

  double _matchScore(String query, String label) {
    final q = query.toLowerCase();
    final l = label.toLowerCase();
    if (q == l) return 1.0;
    if (l.startsWith(q) || l.endsWith(q)) return 0.9;
    if (l.contains(q)) return 0.8;
    return 0.6;
  }

  Future<http.Response> _get(Uri uri) async {
    final client = _httpClient;
    final future = client != null ? client.get(uri) : http.get(uri);
    return future.timeout(const Duration(seconds: 10));
  }

  static const _emptyMarker = '__empty__';
}

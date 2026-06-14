@Tags(['network'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  const wikidataApi = 'https://www.wikidata.org/w/api.php';
  const testWord = 'raven';

  test('Wikidata search API reachable', () async {
    final uri = Uri.parse(wikidataApi).replace(
      queryParameters: {
        'action': 'wbsearchentities',
        'search': testWord,
        'language': 'en',
        'format': 'json',
        'limit': '3',
        'type': 'item',
      },
    );

    print('Request: $uri');

    final response = await http.get(uri).timeout(
      const Duration(seconds: 15),
    );

    print('Status: ${response.statusCode}');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['search'] as List<dynamic>;
    print('Results: ${results.length}');
    for (final r in results) {
      final m = r as Map<String, dynamic>;
      print('  ${m['id']} — ${m['label']} — ${m['description']}');
    }

    expect(response.statusCode, 200);
    expect(results, isNotEmpty);
  });

  test('Wikidata entity P18 image lookup', () async {
    final searchUri = Uri.parse(wikidataApi).replace(
      queryParameters: {
        'action': 'wbsearchentities',
        'search': testWord,
        'language': 'en',
        'format': 'json',
        'limit': '1',
        'type': 'item',
      },
    );

    final searchResponse = await http.get(searchUri).timeout(
      const Duration(seconds: 15),
    );
    final searchBody = jsonDecode(searchResponse.body) as Map<String, dynamic>;
    final entityId =
        (searchBody['search'] as List<dynamic>).first['id'] as String;
    print('Entity: $entityId');

    final entityUri = Uri.parse(wikidataApi).replace(
      queryParameters: {
        'action': 'wbgetentities',
        'ids': entityId,
        'props': 'claims',
        'format': 'json',
      },
    );

    print('Request: $entityUri');
    final entityResponse = await http.get(entityUri).timeout(
      const Duration(seconds: 15),
    );
    print('Status: ${entityResponse.statusCode}');

    final entityBody =
        jsonDecode(entityResponse.body) as Map<String, dynamic>;
    final entity =
        (entityBody['entities'] as Map<String, dynamic>)[entityId]
            as Map<String, dynamic>;
    final claims = entity['claims'] as Map<String, dynamic>;
    final p18 = claims['P18'] as List<dynamic>?;

    if (p18 != null && p18.isNotEmpty) {
      final filename = (p18.first as Map<String, dynamic>)['mainsnak']
          ['datavalue']['value'] as String;
      final encoded =
          Uri.encodeComponent(filename.replaceAll(' ', '_'));
      final thumbUrl =
          'https://commons.wikimedia.org/wiki/Special:FilePath/$encoded?width=300';
      print('Image filename: $filename');
      print('Thumbnail URL: $thumbUrl');
      expect(filename, isNotEmpty);
    } else {
      print('No P18 image claim found for $entityId');
    }

    expect(entityResponse.statusCode, 200);
  });
}

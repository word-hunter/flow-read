import 'dart:convert';
import 'dart:io';

import 'package:flow_read/models/reading_memory.dart';
import 'package:flow_read/services/reading_memory/reading_memory_inspector_web_server.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_memory_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serves the web inspector shell and live reading memory JSON', () async {
    final db = await AppDatabase.createInMemory();
    addTearDown(db.close);

    final repository = DriftReadingMemoryRepository(
      db.readingMemoryDao,
      languageCode: 'en',
    );
    await repository.init();
    await _seedMemory(repository);

    final server = ReadingMemoryInspectorWebServer(
      dao: db.readingMemoryDao,
      languageCode: 'en',
    );
    addTearDown(server.close);

    final baseUri = await server.start();
    final index = await _getText(baseUri, '/');
    expect(index, contains('Reading Memory Inspector'));
    expect(index, contains('/api/entities'));

    final overview = await _getJson(baseUri, '/api/overview');
    final counts = overview['counts'] as Map<String, dynamic>;
    expect(counts['sources'], 1);
    expect(counts['entities'], 1);
    expect(counts['evidences'], 1);
    expect(counts['events'], 1);

    final entities = await _getJson(baseUri, '/api/entities', {
      'query': 'reluc',
      'type': 'word',
      'mastery': 'learning',
    });
    final entityRows = entities['rows'] as List<dynamic>;
    expect(entityRows, hasLength(1));
    expect(entityRows.single['id'], 'entity:en:word:reluctant');

    final detail = await _getJson(baseUri, '/api/entity', {
      'id': 'entity:en:word:reluctant',
    });
    final detailBody = detail['detail'] as Map<String, dynamic>;
    expect(detailBody['entity']['displayText'], 'reluctant');
    expect(detailBody['evidences'], hasLength(1));

    final health = await _getJson(baseUri, '/api/health');
    expect(health['rows'], hasLength(5));
  });
}

Future<String> _getText(
  Uri baseUri,
  String path, [
  Map<String, String>? queryParameters,
]) async {
  final uri = baseUri.replace(
    path: path,
    queryParameters: queryParameters,
  );
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    expect(response.statusCode, HttpStatus.ok, reason: body);
    return body;
  } finally {
    client.close(force: true);
  }
}

Future<Map<String, dynamic>> _getJson(
  Uri baseUri,
  String path, [
  Map<String, String>? queryParameters,
]) async {
  final body = await _getText(baseUri, path, queryParameters);
  return jsonDecode(body) as Map<String, dynamic>;
}

Future<void> _seedMemory(DriftReadingMemoryRepository repository) async {
  final now = DateTime.utc(2026, 6, 17, 8);
  await repository.upsertSourceRecord(
    MemorySourceRecord(
      id: 'book:gatsby',
      sourceKind: SourceKind.book,
      titleSnapshot: 'The Great Gatsby',
      authorSnapshot: 'F. Scott Fitzgerald',
      languageCode: 'en',
      createdAt: now,
      updatedAt: now,
    ),
  );
  await repository.upsertEntity(
    MemoryKnowledgeEntity(
      id: 'entity:en:word:reluctant',
      languageCode: 'en',
      type: KnowledgeEntityType.word,
      canonicalKey: 'reluctant',
      displayText: 'reluctant',
      normalizedText: 'reluctant',
      masteryState: KnowledgeMasteryState.learning,
      createdAt: now,
      updatedAt: now.add(const Duration(minutes: 1)),
    ),
  );
  await repository.upsertEvidence(
    MemoryKnowledgeEvidence(
      id: 'evidence:reluctant',
      entityId: 'entity:en:word:reluctant',
      sourceId: 'book:gatsby',
      sourceKind: SourceKind.book,
      bookId: 'gatsby',
      chapterIndex: 2,
      locationLocator: 'chapter:2:sentence:12',
      shortExcerpt: 'He was reluctant to admit defeat.',
      sourceTitleSnapshot: 'The Great Gatsby',
      sourceAvailability: SourceAvailability.available,
      retentionPolicy: EvidenceRetentionPolicy.keepSnippet,
      createdAt: now.add(const Duration(minutes: 2)),
    ),
  );
  await repository.recordEvent(
    MemoryEvent(
      id: 'event:lookup:reluctant',
      type: MemoryEventType.lookup,
      languageCode: 'en',
      sourceId: 'book:gatsby',
      entityId: 'entity:en:word:reluctant',
      targetText: 'Reluctant',
      canonicalKey: 'reluctant',
      createdAt: now.add(const Duration(minutes: 3)),
    ),
  );
}

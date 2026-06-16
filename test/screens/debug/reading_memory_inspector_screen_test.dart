import 'package:flow_read/models/reading_memory.dart';
import 'package:flow_read/screens/debug/reading_memory_inspector_screen.dart';
import 'package:flow_read/services/reading_memory/reading_memory_inspector_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_memory_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows overview and filters entities', (tester) async {
    final db = await AppDatabase.createInMemory();
    addTearDown(db.close);

    final repository = DriftReadingMemoryRepository(
      db.readingMemoryDao,
      languageCode: 'en',
    );
    await _seedEntities(repository);

    await tester.pumpWidget(
      MaterialApp(
        home: ReadingMemoryInspectorView(
          service: ReadingMemoryInspectorService(
            dao: db.readingMemoryDao,
            languageCode: 'en',
          ),
          languageCode: 'en',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reading Memory Inspector'), findsOneWidget);
    expect(find.text('Entities'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);

    await tester.tap(find.text('实体'));
    await tester.pumpAndSettle();

    expect(find.text('reluctant'), findsOneWidget);
    expect(find.text('by and large'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('reading-memory-entity-search')),
      'reluc',
    );
    await tester.pumpAndSettle();

    expect(find.text('reluctant'), findsOneWidget);
    expect(find.text('by and large'), findsNothing);
  });
}

Future<void> _seedEntities(DriftReadingMemoryRepository repository) async {
  final now = DateTime.utc(2026, 6, 16, 8);
  await repository.upsertSourceRecord(
    MemorySourceRecord(
      id: 'book:gatsby',
      sourceKind: SourceKind.book,
      titleSnapshot: 'The Great Gatsby',
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
      updatedAt: now,
    ),
  );
  await repository.upsertEntity(
    MemoryKnowledgeEntity(
      id: 'entity:en:phrase:by-and-large',
      languageCode: 'en',
      type: KnowledgeEntityType.phrase,
      canonicalKey: 'by and large',
      displayText: 'by and large',
      normalizedText: 'by and large',
      createdAt: now,
      updatedAt: now,
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
      createdAt: now,
    ),
  );
}

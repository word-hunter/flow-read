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
    expect(find.text('来源'), findsOneWidget);
    expect(find.text('证据'), findsOneWidget);
    expect(find.text('事件'), findsOneWidget);
    expect(find.text('健康检查'), findsOneWidget);
    expect(find.text('issues: 0'), findsOneWidget);

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

    await tester.tap(find.text('来源'));
    await tester.pumpAndSettle();

    expect(find.text('The Great Gatsby'), findsOneWidget);
    expect(find.textContaining('book:gatsby'), findsOneWidget);
    await tester.tap(find.text('The Great Gatsby'));
    await tester.pumpAndSettle();

    expect(find.text('来源详情'), findsOneWidget);
    expect(find.text('关联实体'), findsOneWidget);
    expect(find.text('id: book:gatsby'), findsOneWidget);
    expect(find.text('id: entity:en:word:reluctant'), findsOneWidget);

    Navigator.of(tester.element(find.text('来源详情'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('证据'));
    await tester.pumpAndSettle();

    expect(find.text('He was reluctant to admit defeat.'), findsOneWidget);
    expect(find.textContaining('chapter:2:sentence:12'), findsOneWidget);

    await tester.tap(find.text('事件'));
    await tester.pumpAndSettle();

    expect(find.text('Reluctant'), findsOneWidget);
    expect(find.text('lookup'), findsOneWidget);

    await tester.tap(find.text('实体'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('reluctant'));
    await tester.pumpAndSettle();

    expect(find.text('实体详情'), findsOneWidget);
    expect(find.text('保存的解释'), findsOneWidget);
    expect(
      find.text('reluctant to do means unwilling to do something.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('复习候选'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('复习候选'), findsOneWidget);
    expect(find.text('question: cloze'), findsOneWidget);
    expect(find.text('reluctant'), findsWidgets);
  });
}

Future<void> _seedEntities(DriftReadingMemoryRepository repository) async {
  final now = DateTime.utc(2026, 6, 16, 8);
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
  await repository.upsertExplanation(
    MemoryKnowledgeExplanation(
      id: 'explanation:reluctant',
      entityId: 'entity:en:word:reluctant',
      explanation: 'reluctant to do means unwilling to do something.',
      source: ExplanationSource.ai,
      targetLanguage: 'zh',
      promptVersion: 'text-analysis-v1',
      createdAt: now.add(const Duration(minutes: 1)),
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
      sourceRefJson: '{"chapterIndex":2}',
      createdAt: now.add(const Duration(minutes: 3)),
    ),
  );
  await repository.upsertReviewCandidate(
    ReviewCandidate(
      id: 'candidate:reluctant',
      entityId: 'entity:en:word:reluctant',
      entityType: KnowledgeEntityType.word,
      targetText: 'reluctant',
      evidenceId: 'evidence:reluctant',
      explanationId: 'explanation:reluctant',
      suggestedQuestionType: 'cloze',
      priority: 0.8,
      status: ReviewCandidateStatus.pending,
      createdAt: now.add(const Duration(minutes: 4)),
      updatedAt: now.add(const Duration(minutes: 4)),
    ),
  );
}

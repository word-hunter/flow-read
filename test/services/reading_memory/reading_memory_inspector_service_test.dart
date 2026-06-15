import 'package:flow_read/models/reading_memory.dart';
import 'package:flow_read/services/reading_memory/reading_memory_inspector_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_memory_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftReadingMemoryRepository repository;
  late ReadingMemoryInspectorService inspector;

  setUp(() async {
    db = await AppDatabase.createInMemory();
    repository = DriftReadingMemoryRepository(
      db.readingMemoryDao,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 15, 12),
    );
    inspector = ReadingMemoryInspectorService(
      dao: db.readingMemoryDao,
      languageCode: 'en',
    );
    await repository.init();
  });

  tearDown(() async {
    await db.close();
  });

  test('builds a language-scoped overview for reading memory tables', () async {
    await _seedMemory(repository);

    final overview = await inspector.overview();

    expect(overview.languageCode, 'en');
    expect(overview.sourceCount, 2);
    expect(overview.entityCount, 2);
    expect(overview.explanationCount, 1);
    expect(overview.evidenceCount, 1);
    expect(overview.eventCount, 2);
    expect(overview.reviewCandidateCount, 1);
    expect(overview.entityCountsByType, {
      KnowledgeEntityType.word: 1,
      KnowledgeEntityType.phrase: 1,
    });
    expect(overview.entityCountsByMastery, {
      KnowledgeMasteryState.learning: 1,
      KnowledgeMasteryState.unknown: 1,
    });
    expect(overview.eventCountsByType, {
      MemoryEventType.lookup: 1,
      MemoryEventType.saveExplanation: 1,
    });
    expect(overview.sourceCountsByAvailability, {
      SourceAvailability.available: 1,
      SourceAvailability.deleted: 1,
    });

    final jaOverview = await inspector.overview(languageCode: 'ja');
    expect(jaOverview.sourceCount, 1);
    expect(jaOverview.entityCount, 1);
    expect(jaOverview.explanationCount, 1);
    expect(jaOverview.evidenceCount, 1);
    expect(jaOverview.eventCount, 1);
  });

  test('filters rows and aggregates entity detail for inspector UI', () async {
    await _seedMemory(repository);

    final entities = await inspector.entities(
      query: 'reluc',
      type: KnowledgeEntityType.word,
      masteryState: KnowledgeMasteryState.learning,
    );
    expect(entities.map((entity) => entity.id), [
      'entity:en:word:reluctant',
    ]);

    final sources = await inspector.sources(
      availability: SourceAvailability.deleted,
    );
    expect(sources.single.id, 'rss:article-1');

    final evidences = await inspector.evidences(
      sourceAvailability: SourceAvailability.available,
      query: 'admit',
    );
    expect(evidences.single.shortExcerpt, contains('admit defeat'));

    final events = await inspector.events(type: MemoryEventType.lookup);
    expect(events.single.canonicalKey, 'reluctant');

    final detail = await inspector.entityDetail('entity:en:word:reluctant');
    expect(detail, isNotNull);
    expect(detail!.entity.displayText, 'reluctant');
    expect(detail.explanations.single.source, ExplanationSource.ai);
    expect(detail.evidences.single.sourceTitleSnapshot, 'The Great Gatsby');
    expect(detail.recentEvents.map((event) => event.type), [
      MemoryEventType.saveExplanation,
      MemoryEventType.lookup,
    ]);
    expect(
      detail.reviewCandidates.single.status,
      ReviewCandidateStatus.pending,
    );
  });
}

Future<void> _seedMemory(DriftReadingMemoryRepository repository) async {
  final now = DateTime.utc(2026, 6, 15, 8);
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
  await repository.upsertSourceRecord(
    MemorySourceRecord(
      id: 'rss:article-1',
      sourceKind: SourceKind.rss,
      titleSnapshot: 'Article One',
      languageCode: 'en',
      availability: SourceAvailability.deleted,
      createdAt: now,
      updatedAt: now.add(const Duration(minutes: 1)),
      deletedAt: now.add(const Duration(minutes: 2)),
    ),
  );
  await repository.upsertSourceRecord(
    MemorySourceRecord(
      id: 'book:jp',
      sourceKind: SourceKind.book,
      titleSnapshot: 'Japanese Book',
      languageCode: 'ja',
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
      updatedAt: now.add(const Duration(minutes: 3)),
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
      updatedAt: now.add(const Duration(minutes: 2)),
    ),
  );
  await repository.upsertEntity(
    MemoryKnowledgeEntity(
      id: 'entity:ja:word:流れ',
      languageCode: 'ja',
      type: KnowledgeEntityType.word,
      canonicalKey: '流れ',
      displayText: '流れ',
      normalizedText: '流れ',
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
      createdAt: now.add(const Duration(minutes: 4)),
      updatedAt: now.add(const Duration(minutes: 4)),
    ),
  );
  await repository.upsertExplanation(
    MemoryKnowledgeExplanation(
      id: 'explanation:jp',
      entityId: 'entity:ja:word:流れ',
      explanation: 'flow',
      source: ExplanationSource.dictionary,
      targetLanguage: 'zh',
      createdAt: now,
      updatedAt: now,
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
      createdAt: now.add(const Duration(minutes: 5)),
    ),
  );
  await repository.upsertEvidence(
    MemoryKnowledgeEvidence(
      id: 'evidence:jp',
      entityId: 'entity:ja:word:流れ',
      sourceId: 'book:jp',
      sourceKind: SourceKind.book,
      shortExcerpt: '川の流れ。',
      sourceTitleSnapshot: 'Japanese Book',
      sourceAvailability: SourceAvailability.available,
      retentionPolicy: EvidenceRetentionPolicy.keepSnippet,
      createdAt: now,
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
      createdAt: now.add(const Duration(minutes: 6)),
    ),
  );
  await repository.recordEvent(
    MemoryEvent(
      id: 'event:save-explanation:reluctant',
      type: MemoryEventType.saveExplanation,
      languageCode: 'en',
      sourceId: 'book:gatsby',
      entityId: 'entity:en:word:reluctant',
      targetText: 'reluctant',
      canonicalKey: 'reluctant',
      metadataJson: '{"explanationId":"explanation:reluctant"}',
      createdAt: now.add(const Duration(minutes: 7)),
    ),
  );
  await repository.recordEvent(
    MemoryEvent(
      id: 'event:lookup:jp',
      type: MemoryEventType.lookup,
      languageCode: 'ja',
      sourceId: 'book:jp',
      entityId: 'entity:ja:word:流れ',
      targetText: '流れ',
      canonicalKey: '流れ',
      createdAt: now,
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
      createdAt: now.add(const Duration(minutes: 8)),
      updatedAt: now.add(const Duration(minutes: 8)),
    ),
  );
}

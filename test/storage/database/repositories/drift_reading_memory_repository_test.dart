import 'package:flow_read/models/reading_memory.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_memory_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftReadingMemoryRepository repository;

  setUp(() async {
    db = await AppDatabase.createInMemory();
    repository = DriftReadingMemoryRepository(
      db.readingMemoryDao,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 15, 9),
    );
    await repository.init();
  });

  tearDown(() async {
    await db.close();
  });

  test('stores source scope and long-term memory records', () async {
    final now = DateTime.utc(2026, 6, 15, 8);
    await repository.upsertSourceRecord(
      MemorySourceRecord(
        id: 'book:gatsby',
        sourceKind: SourceKind.book,
        titleSnapshot: 'The Great Gatsby',
        authorSnapshot: 'F. Scott Fitzgerald',
        languageCode: 'en',
        fingerprint: 'sha256:book',
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
        confidence: 0.8,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await repository.upsertExplanation(
      MemoryKnowledgeExplanation(
        id: 'explanation:1',
        entityId: 'entity:en:word:reluctant',
        explanation: 'reluctant to do means unwilling to do something.',
        source: ExplanationSource.ai,
        targetLanguage: 'zh',
        promptVersion: 'text-analysis-v1',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await repository.upsertEvidence(
      MemoryKnowledgeEvidence(
        id: 'evidence:1',
        entityId: 'entity:en:word:reluctant',
        sourceId: 'book:gatsby',
        sourceKind: SourceKind.book,
        bookId: 'gatsby',
        chapterIndex: 2,
        locationLocator: 'chapter:2:sentence:12',
        shortExcerpt: 'He was reluctant to admit defeat.',
        excerptHash: 'sha256:excerpt',
        sourceTitleSnapshot: 'The Great Gatsby',
        sourceAvailability: SourceAvailability.available,
        retentionPolicy: EvidenceRetentionPolicy.keepSnippet,
        createdAt: now,
      ),
    );

    final source = await repository.sourceRecord('book:gatsby');
    expect(source?.titleSnapshot, 'The Great Gatsby');
    expect(source?.sourceKind, SourceKind.book);

    final entity = await repository.entityByCanonical(
      languageCode: 'en',
      type: KnowledgeEntityType.word,
      canonicalKey: 'reluctant',
    );
    expect(entity?.masteryState, KnowledgeMasteryState.learning);

    final explanations = await repository.explanationsForEntity(
      'entity:en:word:reluctant',
    );
    expect(explanations.single.source, ExplanationSource.ai);

    final evidences = await repository.evidencesForEntity(
      'entity:en:word:reluctant',
    );
    expect(evidences.single.shortExcerpt, contains('reluctant'));
  });

  test('stores and clears source scope cache by source and type', () async {
    final now = DateTime.utc(2026, 6, 15, 8);
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

    await repository.upsertSourceScopeCache(
      SourceScopeCacheItem(
        id: 'cache:summary',
        sourceId: 'book:gatsby',
        cacheType: 'chapter_summary',
        payload: '{"chapter":1}',
        retentionPolicy: EvidenceRetentionPolicy.deleteWithSource,
        updatedAt: now,
      ),
    );
    await repository.upsertSourceScopeCache(
      SourceScopeCacheItem(
        id: 'cache:glossary',
        sourceId: 'book:gatsby',
        cacheType: 'glossary_cache',
        payload: '{"terms":[]}',
        retentionPolicy: EvidenceRetentionPolicy.keepMetadataOnly,
        updatedAt: now.add(const Duration(minutes: 1)),
      ),
    );

    final all = await repository.sourceScopeCacheForSource('book:gatsby');
    expect(all.map((item) => item.cacheType), [
      'glossary_cache',
      'chapter_summary',
    ]);

    final summaries = await repository.sourceScopeCacheForSource(
      'book:gatsby',
      cacheType: 'chapter_summary',
    );
    expect(summaries.single.payload, '{"chapter":1}');

    await repository.deleteSourceScopeCacheForSource(
      'book:gatsby',
      retentionPolicy: EvidenceRetentionPolicy.deleteWithSource,
    );
    final remaining = await repository.sourceScopeCacheForSource('book:gatsby');
    expect(remaining.single.cacheType, 'glossary_cache');
  });

  test('updates evidence retention state for a deleted source', () async {
    final now = DateTime.utc(2026, 6, 15, 8);
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
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repository.upsertEvidence(
      MemoryKnowledgeEvidence(
        id: 'evidence:1',
        entityId: 'entity:en:word:reluctant',
        sourceId: 'book:gatsby',
        sourceKind: SourceKind.book,
        bookId: 'gatsby',
        shortExcerpt: 'He was reluctant to admit defeat.',
        sourceTitleSnapshot: 'The Great Gatsby',
        sourceAvailability: SourceAvailability.available,
        retentionPolicy: EvidenceRetentionPolicy.keepSnippet,
        createdAt: now,
      ),
    );

    await repository.updateEvidencesForSource(
      sourceId: 'book:gatsby',
      sourceAvailability: SourceAvailability.deleted,
      retentionPolicy: EvidenceRetentionPolicy.keepMetadataOnly,
      clearShortExcerpt: true,
    );

    final evidences = await repository.evidencesForSource('book:gatsby');
    expect(evidences.single.sourceAvailability, SourceAvailability.deleted);
    expect(
      evidences.single.retentionPolicy,
      EvidenceRetentionPolicy.keepMetadataOnly,
    );
    expect(evidences.single.shortExcerpt, isEmpty);
  });

  test(
    'records events, review candidates, and source deletion state',
    () async {
      final now = DateTime.utc(2026, 6, 15, 8);
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
          createdAt: now,
          updatedAt: now,
        ),
      );

      await repository.recordEvent(
        MemoryEvent(
          id: 'event:lookup:1',
          type: MemoryEventType.lookup,
          languageCode: 'en',
          sourceId: 'book:gatsby',
          entityId: 'entity:en:word:reluctant',
          targetText: 'Reluctant',
          canonicalKey: 'reluctant',
          sourceRefJson: '{"chapterIndex":2}',
          createdAt: now,
        ),
      );
      await repository.recordEvent(
        MemoryEvent(
          id: 'event:mark-learning:1',
          type: MemoryEventType.markLearning,
          languageCode: 'en',
          sourceId: 'book:gatsby',
          entityId: 'entity:en:word:reluctant',
          targetText: 'Reluctant',
          canonicalKey: 'reluctant',
          metadataJson: '{"status":"learning"}',
          createdAt: now.add(const Duration(minutes: 1)),
        ),
      );

      await repository.upsertReviewCandidate(
        ReviewCandidate(
          id: 'candidate:1',
          entityId: 'entity:en:word:reluctant',
          entityType: KnowledgeEntityType.word,
          targetText: 'reluctant',
          suggestedQuestionType: 'cloze',
          priority: 0.7,
          status: ReviewCandidateStatus.pending,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final events = await repository.eventsForCanonical(
        languageCode: 'en',
        canonicalKey: 'reluctant',
      );
      expect(events.map((event) => event.type), [
        MemoryEventType.markLearning,
        MemoryEventType.lookup,
      ]);
      expect(
        await repository.eventCountForCanonical(
          languageCode: 'en',
          canonicalKey: 'reluctant',
          type: MemoryEventType.lookup,
        ),
        1,
      );

      await repository.updateSourceAvailability(
        sourceId: 'book:gatsby',
        availability: SourceAvailability.deleted,
        deletedAt: DateTime.utc(2026, 6, 15, 10),
      );

      final deletedSource = await repository.sourceRecord('book:gatsby');
      expect(deletedSource?.availability, SourceAvailability.deleted);
      expect(deletedSource?.deletedAt, DateTime.utc(2026, 6, 15, 10));
    },
  );
}

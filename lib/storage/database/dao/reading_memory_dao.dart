import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'reading_memory_dao.g.dart';

@DriftAccessor(
  tables: [
    SourceRecords,
    KnowledgeEntities,
    KnowledgeExplanations,
    KnowledgeEvidences,
    MemoryEvents,
    SourceScopeCache,
    ReviewCandidates,
  ],
)
class ReadingMemoryDao extends DatabaseAccessor<AppDatabase>
    with _$ReadingMemoryDaoMixin {
  ReadingMemoryDao(super.db);

  Future<void> upsertSourceRecord(SourceRecordsCompanion entry) {
    return into(sourceRecords).insertOnConflictUpdate(entry);
  }

  Future<SourceRecordEntry?> sourceRecord(String id) {
    final query = select(sourceRecords)..where((row) => row.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<void> updateSourceAvailability({
    required String sourceId,
    required String availability,
    required String updatedAt,
    String? deletedAt,
  }) {
    return (update(
      sourceRecords,
    )..where((row) => row.id.equals(sourceId))).write(
      SourceRecordsCompanion(
        availability: Value(availability),
        updatedAt: Value(updatedAt),
        deletedAt: Value(deletedAt),
      ),
    );
  }

  Future<void> upsertEntity(KnowledgeEntitiesCompanion entry) {
    return into(knowledgeEntities).insertOnConflictUpdate(entry);
  }

  Future<KnowledgeEntityEntry?> entityById(String id) {
    final query = select(knowledgeEntities)..where((row) => row.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<KnowledgeEntityEntry?> entityByCanonical({
    required String language,
    required String type,
    required String canonicalKey,
  }) {
    final query = select(knowledgeEntities)
      ..where(
        (row) =>
            row.language.equals(language) &
            row.type.equals(type) &
            row.canonicalKey.equals(canonicalKey),
      );
    return query.getSingleOrNull();
  }

  Future<void> upsertExplanation(KnowledgeExplanationsCompanion entry) {
    return into(knowledgeExplanations).insertOnConflictUpdate(entry);
  }

  Future<List<KnowledgeExplanationEntry>> explanationsForEntity(
    String entityId, {
    int limit = 20,
  }) {
    final query = select(knowledgeExplanations)
      ..where((row) => row.entityId.equals(entityId))
      ..orderBy([
        (row) => OrderingTerm(
          expression: row.createdAt,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<void> upsertEvidence(KnowledgeEvidencesCompanion entry) {
    return into(knowledgeEvidences).insertOnConflictUpdate(entry);
  }

  Future<List<KnowledgeEvidenceEntry>> evidencesForEntity(
    String entityId, {
    int limit = 20,
  }) {
    final query = select(knowledgeEvidences)
      ..where((row) => row.entityId.equals(entityId))
      ..orderBy([
        (row) => OrderingTerm(
          expression: row.createdAt,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<void> insertEvent(MemoryEventsCompanion entry) {
    return into(memoryEvents).insert(entry);
  }

  Future<List<MemoryEventEntry>> eventsForCanonical({
    required String language,
    required String canonicalKey,
    int limit = 20,
  }) {
    final query = select(memoryEvents)
      ..where(
        (row) =>
            row.language.equals(language) &
            row.canonicalKey.equals(canonicalKey),
      )
      ..orderBy([
        (row) => OrderingTerm(
          expression: row.createdAt,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<int> eventCountForCanonical({
    required String language,
    required String canonicalKey,
    String? eventType,
  }) async {
    final count = memoryEvents.id.count();
    final query = selectOnly(memoryEvents)..addColumns([count]);
    query.where(
      memoryEvents.language.equals(language) &
          memoryEvents.canonicalKey.equals(canonicalKey),
    );
    if (eventType != null) {
      query.where(memoryEvents.eventType.equals(eventType));
    }
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> upsertReviewCandidate(ReviewCandidatesCompanion entry) {
    return into(reviewCandidates).insertOnConflictUpdate(entry);
  }
}

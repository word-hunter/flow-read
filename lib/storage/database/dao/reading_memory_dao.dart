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

  Future<ReviewCandidateEntry?> reviewCandidateById(String id) {
    final query = select(reviewCandidates)..where((row) => row.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<List<ReviewCandidateEntry>> reviewCandidatesForEntity(
    String entityId, {
    String? status,
    int limit = 20,
  }) {
    final query = select(reviewCandidates)
      ..where((row) => row.entityId.equals(entityId));
    if (status != null) {
      query.where((row) => row.status.equals(status));
    }
    query
      ..orderBy([
        (row) => OrderingTerm(
          expression: row.priority,
          mode: OrderingMode.desc,
        ),
        (row) => OrderingTerm(
          expression: row.updatedAt,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<List<ReviewCandidateEntry>> reviewCandidatesByStatus({
    String? status,
    int limit = 50,
  }) {
    final query = select(reviewCandidates);
    if (status != null) {
      query.where((row) => row.status.equals(status));
    }
    query
      ..orderBy([
        (row) => OrderingTerm(
          expression: row.priority,
          mode: OrderingMode.desc,
        ),
        (row) => OrderingTerm(
          expression: row.updatedAt,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<int> inspectorSourceCount({required String language}) async {
    final count = sourceRecords.id.count();
    final query = selectOnly(sourceRecords)..addColumns([count]);
    query.where(sourceRecords.language.equals(language));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> inspectorEntityCount({required String language}) async {
    final count = knowledgeEntities.id.count();
    final query = selectOnly(knowledgeEntities)..addColumns([count]);
    query.where(knowledgeEntities.language.equals(language));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> inspectorExplanationCount({required String language}) async {
    final count = knowledgeExplanations.id.count();
    final query = selectOnly(knowledgeExplanations)..addColumns([count]);
    query.where(_hasLanguageEntity(knowledgeExplanations.entityId, language));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> inspectorEvidenceCount({required String language}) async {
    final count = knowledgeEvidences.id.count();
    final query = selectOnly(knowledgeEvidences)..addColumns([count]);
    query.where(_hasLanguageEntity(knowledgeEvidences.entityId, language));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> inspectorEventCount({required String language}) async {
    final count = memoryEvents.id.count();
    final query = selectOnly(memoryEvents)..addColumns([count]);
    query.where(memoryEvents.language.equals(language));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> inspectorReviewCandidateCount({
    required String language,
  }) async {
    final count = reviewCandidates.id.count();
    final query = selectOnly(reviewCandidates)..addColumns([count]);
    query.where(_hasLanguageEntity(reviewCandidates.entityId, language));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<Map<String, int>> inspectorEntityCountsByType({
    required String language,
  }) async {
    final count = knowledgeEntities.id.count();
    final query = selectOnly(knowledgeEntities)
      ..addColumns([knowledgeEntities.type, count])
      ..where(knowledgeEntities.language.equals(language))
      ..groupBy([knowledgeEntities.type]);
    final rows = await query.get();
    return {
      for (final row in rows)
        if (row.read(knowledgeEntities.type) != null)
          row.read(knowledgeEntities.type)!: row.read(count) ?? 0,
    };
  }

  Future<Map<String, int>> inspectorEntityCountsByMastery({
    required String language,
  }) async {
    final count = knowledgeEntities.id.count();
    final query = selectOnly(knowledgeEntities)
      ..addColumns([knowledgeEntities.masteryState, count])
      ..where(knowledgeEntities.language.equals(language))
      ..groupBy([knowledgeEntities.masteryState]);
    final rows = await query.get();
    return {
      for (final row in rows)
        if (row.read(knowledgeEntities.masteryState) != null)
          row.read(knowledgeEntities.masteryState)!: row.read(count) ?? 0,
    };
  }

  Future<Map<String, int>> inspectorEventCountsByType({
    required String language,
  }) async {
    final count = memoryEvents.id.count();
    final query = selectOnly(memoryEvents)
      ..addColumns([memoryEvents.eventType, count])
      ..where(memoryEvents.language.equals(language))
      ..groupBy([memoryEvents.eventType]);
    final rows = await query.get();
    return {
      for (final row in rows)
        if (row.read(memoryEvents.eventType) != null)
          row.read(memoryEvents.eventType)!: row.read(count) ?? 0,
    };
  }

  Future<Map<String, int>> inspectorSourceCountsByAvailability({
    required String language,
  }) async {
    final count = sourceRecords.id.count();
    final query = selectOnly(sourceRecords)
      ..addColumns([sourceRecords.availability, count])
      ..where(sourceRecords.language.equals(language))
      ..groupBy([sourceRecords.availability]);
    final rows = await query.get();
    return {
      for (final row in rows)
        if (row.read(sourceRecords.availability) != null)
          row.read(sourceRecords.availability)!: row.read(count) ?? 0,
    };
  }

  Future<List<SourceRecordEntry>> inspectorSources({
    required String language,
    String? sourceKind,
    String? availability,
    String? query,
    int limit = 50,
    int offset = 0,
  }) {
    final searchPattern = _searchPattern(query);
    final selectQuery = select(sourceRecords)
      ..where((row) {
        var predicate = row.language.equals(language);
        if (sourceKind != null) {
          predicate = predicate & row.sourceKind.equals(sourceKind);
        }
        if (availability != null) {
          predicate = predicate & row.availability.equals(availability);
        }
        if (searchPattern != null) {
          predicate =
              predicate &
              (row.id.like(searchPattern) |
                  row.titleSnapshot.like(searchPattern) |
                  row.authorSnapshot.like(searchPattern));
        }
        return predicate;
      })
      ..orderBy([
        (row) => OrderingTerm(
          expression: row.updatedAt,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit, offset: offset);
    return selectQuery.get();
  }

  Future<List<KnowledgeEntityEntry>> inspectorEntities({
    required String language,
    String? type,
    String? masteryState,
    String? query,
    int limit = 50,
    int offset = 0,
  }) {
    final searchPattern = _searchPattern(query);
    final selectQuery = select(knowledgeEntities)
      ..where((row) {
        var predicate = row.language.equals(language);
        if (type != null) {
          predicate = predicate & row.type.equals(type);
        }
        if (masteryState != null) {
          predicate = predicate & row.masteryState.equals(masteryState);
        }
        if (searchPattern != null) {
          predicate =
              predicate &
              (row.id.like(searchPattern) |
                  row.canonicalKey.like(searchPattern) |
                  row.displayText.like(searchPattern) |
                  row.normalizedText.like(searchPattern));
        }
        return predicate;
      })
      ..orderBy([
        (row) => OrderingTerm(
          expression: row.updatedAt,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit, offset: offset);
    return selectQuery.get();
  }

  Future<List<KnowledgeEvidenceEntry>> inspectorEvidences({
    required String language,
    String? sourceId,
    String? sourceKind,
    String? sourceAvailability,
    String? query,
    int limit = 50,
    int offset = 0,
  }) {
    final searchPattern = _searchPattern(query);
    final selectQuery = select(knowledgeEvidences)
      ..where((row) {
        var predicate = _hasLanguageEntity(row.entityId, language);
        if (sourceId != null) {
          predicate = predicate & row.sourceId.equals(sourceId);
        }
        if (sourceKind != null) {
          predicate = predicate & row.sourceKind.equals(sourceKind);
        }
        if (sourceAvailability != null) {
          predicate =
              predicate & row.sourceAvailability.equals(sourceAvailability);
        }
        if (searchPattern != null) {
          predicate =
              predicate &
              (row.shortExcerpt.like(searchPattern) |
                  row.sourceTitleSnapshot.like(searchPattern) |
                  row.locationLocator.like(searchPattern) |
                  row.bookId.like(searchPattern));
        }
        return predicate;
      })
      ..orderBy([
        (row) => OrderingTerm(
          expression: row.createdAt,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit, offset: offset);
    return selectQuery.get();
  }

  Future<List<MemoryEventEntry>> inspectorEvents({
    required String language,
    String? eventType,
    String? sourceId,
    String? query,
    int limit = 50,
    int offset = 0,
  }) {
    final searchPattern = _searchPattern(query);
    final selectQuery = select(memoryEvents)
      ..where((row) {
        var predicate = row.language.equals(language);
        if (eventType != null) {
          predicate = predicate & row.eventType.equals(eventType);
        }
        if (sourceId != null) {
          predicate = predicate & row.sourceId.equals(sourceId);
        }
        if (searchPattern != null) {
          predicate =
              predicate &
              (row.id.like(searchPattern) |
                  row.targetText.like(searchPattern) |
                  row.canonicalKey.like(searchPattern) |
                  row.sourceRefJson.like(searchPattern) |
                  row.metadataJson.like(searchPattern));
        }
        return predicate;
      })
      ..orderBy([
        (row) => OrderingTerm(
          expression: row.createdAt,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit, offset: offset);
    return selectQuery.get();
  }

  Future<List<MemoryEventEntry>> inspectorEventsForEntity(
    String entityId, {
    int limit = 20,
  }) {
    final query = select(memoryEvents)
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

  Future<List<ReviewCandidateEntry>> inspectorReviewCandidatesForEntity(
    String entityId, {
    int limit = 20,
  }) {
    final query = select(reviewCandidates)
      ..where((row) => row.entityId.equals(entityId))
      ..orderBy([
        (row) => OrderingTerm(
          expression: row.priority,
          mode: OrderingMode.desc,
        ),
        (row) => OrderingTerm(
          expression: row.updatedAt,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit);
    return query.get();
  }

  Expression<bool> _hasLanguageEntity(
    GeneratedColumn<String> entityId,
    String language,
  ) {
    final entityIds = selectOnly(knowledgeEntities)
      ..addColumns([knowledgeEntities.id])
      ..where(knowledgeEntities.language.equals(language));
    return entityId.isInQuery(entityIds);
  }

  static String? _searchPattern(String? query) {
    final trimmed = query?.trim().toLowerCase();
    if (trimmed == null || trimmed.isEmpty) return null;
    return '%$trimmed%';
  }
}

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

  Future<void> deleteSourceRecord(String sourceId) {
    return (delete(
      sourceRecords,
    )..where((row) => row.id.equals(sourceId))).go();
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

  Future<KnowledgeExplanationEntry?> explanationById(String id) {
    final query = select(knowledgeExplanations)
      ..where((row) => row.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<List<KnowledgeExplanationEntry>> explanationsForEntity(
    String entityId, {
    int limit = 20,
  }) {
    final query = select(knowledgeExplanations)
      ..where((row) => row.entityId.equals(entityId))
      ..orderBy([
        (row) =>
            OrderingTerm(expression: row.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<void> upsertEvidence(KnowledgeEvidencesCompanion entry) {
    return into(knowledgeEvidences).insertOnConflictUpdate(entry);
  }

  Future<KnowledgeEvidenceEntry?> evidenceById(String id) {
    final query = select(knowledgeEvidences)..where((row) => row.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<List<KnowledgeEvidenceEntry>> evidencesForEntity(
    String entityId, {
    int limit = 20,
  }) {
    final query = select(knowledgeEvidences)
      ..where((row) => row.entityId.equals(entityId))
      ..orderBy([
        (row) =>
            OrderingTerm(expression: row.createdAt, mode: OrderingMode.desc),
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
        (row) =>
            OrderingTerm(expression: row.createdAt, mode: OrderingMode.desc),
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

  Future<void> upsertSourceScopeCache(SourceScopeCacheCompanion entry) {
    return into(sourceScopeCache).insertOnConflictUpdate(entry);
  }

  Future<List<SourceScopeCacheEntry>> sourceScopeCacheForSource(
    String sourceId, {
    String? cacheType,
    int limit = 50,
  }) {
    final trimmedType = cacheType?.trim();
    final query = select(sourceScopeCache)
      ..where((row) {
        var predicate = row.sourceId.equals(sourceId);
        if (trimmedType != null && trimmedType.isNotEmpty) {
          predicate = predicate & row.cacheType.equals(trimmedType);
        }
        return predicate;
      })
      ..orderBy([
        (row) =>
            OrderingTerm(expression: row.updatedAt, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<void> deleteSourceScopeCacheForSource(
    String sourceId, {
    String? retentionPolicy,
  }) {
    final statement = delete(sourceScopeCache)
      ..where((row) {
        var predicate = row.sourceId.equals(sourceId);
        if (retentionPolicy != null) {
          predicate = predicate & row.retentionPolicy.equals(retentionPolicy);
        }
        return predicate;
      });
    return statement.go();
  }

  Future<List<KnowledgeEvidenceEntry>> evidencesForSource(
    String sourceId, {
    int limit = 50,
  }) {
    final query = select(knowledgeEvidences)
      ..where((row) => row.sourceId.equals(sourceId))
      ..orderBy([
        (row) =>
            OrderingTerm(expression: row.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<void> updateEvidencesForSource({
    required String sourceId,
    required String sourceAvailability,
    String? retentionPolicy,
    bool clearShortExcerpt = false,
  }) {
    return (update(
      knowledgeEvidences,
    )..where((row) => row.sourceId.equals(sourceId))).write(
      KnowledgeEvidencesCompanion(
        sourceAvailability: Value(sourceAvailability),
        retentionPolicy: retentionPolicy == null
            ? const Value.absent()
            : Value(retentionPolicy),
        shortExcerpt: clearShortExcerpt
            ? const Value('')
            : const Value.absent(),
      ),
    );
  }

  Future<void> deleteEvidencesForSource(String sourceId) {
    return (delete(
      knowledgeEvidences,
    )..where((row) => row.sourceId.equals(sourceId))).go();
  }

  Future<void> deleteEventsForSource(String sourceId) {
    return (delete(
      memoryEvents,
    )..where((row) => row.sourceId.equals(sourceId))).go();
  }

  Future<void> deleteReviewCandidatesForSourceEvidence(String sourceId) {
    final evidenceIds = selectOnly(knowledgeEvidences)
      ..addColumns([knowledgeEvidences.id])
      ..where(knowledgeEvidences.sourceId.equals(sourceId));
    return (delete(
      reviewCandidates,
    )..where((row) => row.evidenceId.isInQuery(evidenceIds))).go();
  }

  Future<List<String>> entityIdsWithOnlySourceEvidence(String sourceId) async {
    final entityIdsQuery = selectOnly(knowledgeEvidences)
      ..addColumns([knowledgeEvidences.entityId])
      ..where(knowledgeEvidences.sourceId.equals(sourceId))
      ..groupBy([knowledgeEvidences.entityId]);
    final rows = await entityIdsQuery.get();
    final entityIds = <String>[];
    for (final row in rows) {
      final entityId = row.read(knowledgeEvidences.entityId);
      if (entityId == null) continue;
      final total = await _evidenceCountForEntity(entityId);
      final fromSource = await _evidenceCountForEntity(
        entityId,
        sourceId: sourceId,
      );
      if (total > 0 && total == fromSource) {
        entityIds.add(entityId);
      }
    }
    return entityIds;
  }

  Future<void> deleteEntitiesById(Iterable<String> entityIds) {
    final ids = entityIds.toSet().toList(growable: false);
    if (ids.isEmpty) return Future.value();
    return (delete(knowledgeEntities)..where((row) => row.id.isIn(ids))).go();
  }

  Future<void> upsertReviewCandidate(ReviewCandidatesCompanion entry) {
    return into(reviewCandidates).insertOnConflictUpdate(entry);
  }

  Future<ReviewCandidateEntry?> reviewCandidateById(String id) {
    final query = select(reviewCandidates)..where((row) => row.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<void> updateReviewCandidateStatus({
    required String id,
    required String status,
    required String updatedAt,
  }) {
    return (update(reviewCandidates)..where((row) => row.id.equals(id))).write(
      ReviewCandidatesCompanion(
        status: Value(status),
        updatedAt: Value(updatedAt),
      ),
    );
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
        (row) =>
            OrderingTerm(expression: row.priority, mode: OrderingMode.desc),
        (row) =>
            OrderingTerm(expression: row.updatedAt, mode: OrderingMode.desc),
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
        (row) =>
            OrderingTerm(expression: row.priority, mode: OrderingMode.desc),
        (row) =>
            OrderingTerm(expression: row.updatedAt, mode: OrderingMode.desc),
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

  Future<int> inspectorReviewCandidateCount({required String language}) async {
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
        (row) =>
            OrderingTerm(expression: row.updatedAt, mode: OrderingMode.desc),
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
        (row) =>
            OrderingTerm(expression: row.updatedAt, mode: OrderingMode.desc),
      ])
      ..limit(limit, offset: offset);
    return selectQuery.get();
  }

  Future<List<KnowledgeEntityEntry>> inspectorEntitiesForSource({
    required String language,
    required String sourceId,
    int limit = 50,
  }) {
    final evidenceEntityIds = selectOnly(knowledgeEvidences)
      ..addColumns([knowledgeEvidences.entityId])
      ..where(knowledgeEvidences.sourceId.equals(sourceId));
    final eventEntityIds = selectOnly(memoryEvents)
      ..addColumns([memoryEvents.entityId])
      ..where(
        memoryEvents.sourceId.equals(sourceId) &
            memoryEvents.entityId.isNotNull(),
      );
    final query = select(knowledgeEntities)
      ..where(
        (row) =>
            row.language.equals(language) &
            (row.id.isInQuery(evidenceEntityIds) |
                row.id.isInQuery(eventEntityIds)),
      )
      ..orderBy([
        (row) =>
            OrderingTerm(expression: row.updatedAt, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    return query.get();
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
        (row) =>
            OrderingTerm(expression: row.createdAt, mode: OrderingMode.desc),
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
        (row) =>
            OrderingTerm(expression: row.createdAt, mode: OrderingMode.desc),
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
        (row) =>
            OrderingTerm(expression: row.createdAt, mode: OrderingMode.desc),
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
        (row) =>
            OrderingTerm(expression: row.priority, mode: OrderingMode.desc),
        (row) =>
            OrderingTerm(expression: row.updatedAt, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<int> inspectorOrphanEvidenceEntityCount({
    required String language,
  }) async {
    final count = knowledgeEvidences.id.count();
    final query = selectOnly(knowledgeEvidences)..addColumns([count]);
    query.where(_orphanEvidenceEntityPredicate(language));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<String>> inspectorOrphanEvidenceEntityIds({
    required String language,
    int limit = 20,
  }) async {
    final rows = await inspectorOrphanEvidenceEntityRows(
      language: language,
      limit: limit,
    );
    return rows.map((row) => row.id).toList(growable: false);
  }

  Future<List<KnowledgeEvidenceEntry>> inspectorOrphanEvidenceEntityRows({
    required String language,
    int limit = 20,
  }) {
    final query = select(knowledgeEvidences)
      ..where((row) => _orphanEvidenceEntityPredicate(language))
      ..orderBy([
        (row) =>
            OrderingTerm(expression: row.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<int> inspectorOrphanEventEntityCount({
    required String language,
  }) async {
    final count = memoryEvents.id.count();
    final query = selectOnly(memoryEvents)..addColumns([count]);
    query.where(_orphanEventEntityPredicate(language));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<String>> inspectorOrphanEventEntityIds({
    required String language,
    int limit = 20,
  }) async {
    final rows = await inspectorOrphanEventEntityRows(
      language: language,
      limit: limit,
    );
    return rows.map((row) => row.id).toList(growable: false);
  }

  Future<List<MemoryEventEntry>> inspectorOrphanEventEntityRows({
    required String language,
    int limit = 20,
  }) {
    final query = select(memoryEvents)
      ..where((row) => _orphanEventEntityPredicate(language))
      ..orderBy([
        (row) =>
            OrderingTerm(expression: row.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<int> inspectorMissingEvidenceSourceCount({
    required String language,
  }) async {
    final count = knowledgeEvidences.id.count();
    final query = selectOnly(knowledgeEvidences)..addColumns([count]);
    query.where(_missingEvidenceSourcePredicate(language));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<String>> inspectorMissingEvidenceSourceIds({
    required String language,
    int limit = 20,
  }) async {
    final rows = await inspectorMissingEvidenceSourceRows(
      language: language,
      limit: limit,
    );
    return rows.map((row) => row.id).toList(growable: false);
  }

  Future<List<KnowledgeEvidenceEntry>> inspectorMissingEvidenceSourceRows({
    required String language,
    int limit = 20,
  }) {
    final query = select(knowledgeEvidences)
      ..where((row) => _missingEvidenceSourcePredicate(language))
      ..orderBy([
        (row) =>
            OrderingTerm(expression: row.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<int> inspectorMissingEventSourceCount({
    required String language,
  }) async {
    final count = memoryEvents.id.count();
    final query = selectOnly(memoryEvents)..addColumns([count]);
    query.where(_missingEventSourcePredicate(language));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<String>> inspectorMissingEventSourceIds({
    required String language,
    int limit = 20,
  }) async {
    final rows = await inspectorMissingEventSourceRows(
      language: language,
      limit: limit,
    );
    return rows.map((row) => row.id).toList(growable: false);
  }

  Future<List<MemoryEventEntry>> inspectorMissingEventSourceRows({
    required String language,
    int limit = 20,
  }) {
    final query = select(memoryEvents)
      ..where((row) => _missingEventSourcePredicate(language))
      ..orderBy([
        (row) =>
            OrderingTerm(expression: row.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<int> inspectorDeletedSourceSnippetCount({
    required String language,
  }) async {
    final count = knowledgeEvidences.id.count();
    final query = selectOnly(knowledgeEvidences)..addColumns([count]);
    query.where(_deletedSourceSnippetPredicate(language));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<String>> inspectorDeletedSourceSnippetIds({
    required String language,
    int limit = 20,
  }) async {
    final rows = await inspectorDeletedSourceSnippetRows(
      language: language,
      limit: limit,
    );
    return rows.map((row) => row.id).toList(growable: false);
  }

  Future<List<KnowledgeEvidenceEntry>> inspectorDeletedSourceSnippetRows({
    required String language,
    int limit = 20,
  }) {
    final query = select(knowledgeEvidences)
      ..where((row) => _deletedSourceSnippetPredicate(language))
      ..orderBy([
        (row) =>
            OrderingTerm(expression: row.createdAt, mode: OrderingMode.desc),
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

  Expression<bool> _orphanEvidenceEntityPredicate(String language) {
    final entityIds = selectOnly(knowledgeEntities)
      ..addColumns([knowledgeEntities.id]);
    final sourceIds = selectOnly(sourceRecords)
      ..addColumns([sourceRecords.id])
      ..where(sourceRecords.language.equals(language));
    return knowledgeEvidences.entityId.isNotInQuery(entityIds) &
        knowledgeEvidences.sourceId.isInQuery(sourceIds);
  }

  Expression<bool> _orphanEventEntityPredicate(String language) {
    final entityIds = selectOnly(knowledgeEntities)
      ..addColumns([knowledgeEntities.id]);
    return memoryEvents.language.equals(language) &
        memoryEvents.entityId.isNotNull() &
        memoryEvents.entityId.isNotInQuery(entityIds);
  }

  Expression<bool> _missingEvidenceSourcePredicate(String language) {
    final entityIds = selectOnly(knowledgeEntities)
      ..addColumns([knowledgeEntities.id])
      ..where(knowledgeEntities.language.equals(language));
    final sourceIds = selectOnly(sourceRecords)..addColumns([sourceRecords.id]);
    return knowledgeEvidences.entityId.isInQuery(entityIds) &
        knowledgeEvidences.sourceId.isNotNull() &
        knowledgeEvidences.sourceId.isNotInQuery(sourceIds);
  }

  Expression<bool> _missingEventSourcePredicate(String language) {
    final sourceIds = selectOnly(sourceRecords)..addColumns([sourceRecords.id]);
    return memoryEvents.language.equals(language) &
        memoryEvents.sourceId.isNotNull() &
        memoryEvents.sourceId.isNotInQuery(sourceIds);
  }

  Expression<bool> _deletedSourceSnippetPredicate(String language) {
    return _hasLanguageEntity(knowledgeEvidences.entityId, language) &
        knowledgeEvidences.sourceAvailability.equals('deleted') &
        knowledgeEvidences.shortExcerpt.isNotValue('');
  }

  Future<int> _evidenceCountForEntity(
    String entityId, {
    String? sourceId,
  }) async {
    final count = knowledgeEvidences.id.count();
    final query = selectOnly(knowledgeEvidences)..addColumns([count]);
    query.where(knowledgeEvidences.entityId.equals(entityId));
    if (sourceId != null) {
      query.where(knowledgeEvidences.sourceId.equals(sourceId));
    }
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  static String? _searchPattern(String? query) {
    final trimmed = query?.trim().toLowerCase();
    if (trimmed == null || trimmed.isEmpty) return null;
    return '%$trimmed%';
  }
}

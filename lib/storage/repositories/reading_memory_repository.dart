import '../../models/reading_memory.dart';

abstract class ReadingMemoryRepository {
  Future<void> init();

  Future<void> upsertSourceRecord(MemorySourceRecord record);

  Future<MemorySourceRecord?> sourceRecord(String id);

  Future<void> updateSourceAvailability({
    required String sourceId,
    required SourceAvailability availability,
    DateTime? deletedAt,
  });

  Future<void> upsertEntity(MemoryKnowledgeEntity entity);

  Future<MemoryKnowledgeEntity?> entityById(String id);

  Future<MemoryKnowledgeEntity?> entityByCanonical({
    required String languageCode,
    required KnowledgeEntityType type,
    required String canonicalKey,
  });

  Future<void> upsertExplanation(MemoryKnowledgeExplanation explanation);

  Future<List<MemoryKnowledgeExplanation>> explanationsForEntity(
    String entityId, {
    int limit = 20,
  });

  Future<void> upsertEvidence(MemoryKnowledgeEvidence evidence);

  Future<List<MemoryKnowledgeEvidence>> evidencesForEntity(
    String entityId, {
    int limit = 20,
  });

  Future<void> recordEvent(MemoryEvent event);

  Future<List<MemoryEvent>> eventsForCanonical({
    required String languageCode,
    required String canonicalKey,
    int limit = 20,
  });

  Future<int> eventCountForCanonical({
    required String languageCode,
    required String canonicalKey,
    MemoryEventType? type,
  });

  Future<void> upsertSourceScopeCache(SourceScopeCacheItem item);

  Future<List<SourceScopeCacheItem>> sourceScopeCacheForSource(
    String sourceId, {
    String? cacheType,
    int limit = 50,
  });

  Future<void> deleteSourceScopeCacheForSource(
    String sourceId, {
    EvidenceRetentionPolicy? retentionPolicy,
  });

  Future<List<MemoryKnowledgeEvidence>> evidencesForSource(
    String sourceId, {
    int limit = 50,
  });

  Future<void> updateEvidencesForSource({
    required String sourceId,
    required SourceAvailability sourceAvailability,
    EvidenceRetentionPolicy? retentionPolicy,
    bool clearShortExcerpt = false,
  });

  Future<void> deleteEvidencesForSource(String sourceId);

  Future<void> deleteEventsForSource(String sourceId);

  Future<void> deleteReviewCandidatesForSourceEvidence(String sourceId);

  Future<List<String>> entityIdsWithOnlySourceEvidence(String sourceId);

  Future<void> deleteEntitiesById(Iterable<String> entityIds);

  Future<void> deleteSourceRecord(String sourceId);

  Future<void> upsertReviewCandidate(ReviewCandidate candidate);

  Future<ReviewCandidate?> reviewCandidateById(String id);

  Future<void> updateReviewCandidateStatus({
    required String id,
    required ReviewCandidateStatus status,
    required DateTime updatedAt,
  });

  Future<List<ReviewCandidate>> reviewCandidatesForEntity(
    String entityId, {
    ReviewCandidateStatus? status,
    int limit = 20,
  });

  Future<List<ReviewCandidate>> reviewCandidates({
    ReviewCandidateStatus? status,
    int limit = 50,
  });

  Future<void> close();
}

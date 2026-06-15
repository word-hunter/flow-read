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

  Future<void> upsertReviewCandidate(ReviewCandidate candidate);

  Future<ReviewCandidate?> reviewCandidateById(String id);

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

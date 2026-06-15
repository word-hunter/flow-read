import '../../models/reading_memory.dart';
import '../../storage/repositories/reading_memory_repository.dart';

class KnowledgeRetentionService {
  KnowledgeRetentionService({
    required ReadingMemoryRepository repository,
    DateTime Function()? clock,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now;

  final ReadingMemoryRepository _repository;
  final DateTime Function() _clock;

  Future<void> init() {
    return _repository.init();
  }

  Future<void> archiveSource(String sourceId) async {
    await _repository.updateSourceAvailability(
      sourceId: sourceId,
      availability: SourceAvailability.archived,
    );
    await _repository.updateEvidencesForSource(
      sourceId: sourceId,
      sourceAvailability: SourceAvailability.archived,
    );
  }

  Future<void> deleteSourceKeepLearningMemory(
    String sourceId, {
    EvidenceRetentionPolicy evidencePolicy =
        EvidenceRetentionPolicy.keepSnippet,
  }) async {
    if (evidencePolicy == EvidenceRetentionPolicy.deleteWithSource) {
      await deleteSourceAndRelatedMemory(sourceId);
      return;
    }

    await _repository.deleteSourceScopeCacheForSource(sourceId);
    await _repository.updateSourceAvailability(
      sourceId: sourceId,
      availability: SourceAvailability.deleted,
      deletedAt: _clock().toUtc(),
    );
    await _repository.updateEvidencesForSource(
      sourceId: sourceId,
      sourceAvailability: SourceAvailability.deleted,
      retentionPolicy: evidencePolicy,
      clearShortExcerpt:
          evidencePolicy == EvidenceRetentionPolicy.keepMetadataOnly,
    );
  }

  Future<void> deleteSourceAndRelatedMemory(String sourceId) async {
    final orphanedEntityIds = await _repository.entityIdsWithOnlySourceEvidence(
      sourceId,
    );
    await _repository.deleteReviewCandidatesForSourceEvidence(sourceId);
    await _repository.deleteEventsForSource(sourceId);
    await _repository.deleteEvidencesForSource(sourceId);
    await _repository.deleteEntitiesById(orphanedEntityIds);
    await _repository.deleteSourceScopeCacheForSource(sourceId);
    await _repository.deleteSourceRecord(sourceId);
  }
}

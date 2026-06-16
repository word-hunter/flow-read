import '../../models/reading_memory.dart';
import '../../storage/repositories/reading_memory_repository.dart';
import '../../storage/repositories/repository_language.dart';

class ReviewCandidateService {
  ReviewCandidateService({
    required ReadingMemoryRepository repository,
    String? languageCode,
    DateTime Function()? clock,
  }) : _repository = repository,
       _languageCode = normalizeRepositoryLanguageCode(languageCode),
       _clock = clock ?? DateTime.now;

  final ReadingMemoryRepository _repository;
  final String _languageCode;
  final DateTime Function() _clock;

  Future<void> init() {
    return _repository.init();
  }

  Future<ReviewCandidate?> ensureForSavedExplanation({
    required MemoryKnowledgeEntity entity,
    required MemoryKnowledgeExplanation explanation,
    MemoryKnowledgeEvidence? evidence,
  }) {
    return _ensureCandidate(
      id: _savedExplanationCandidateId(entity.id, explanation.id),
      entity: entity,
      explanationId: explanation.id,
      evidenceId: evidence?.id,
      suggestedQuestionType: _questionTypeFor(
        entity.type,
        hasEvidence: evidence != null,
      ),
      priority: _savedExplanationPriority(entity.type),
    );
  }

  Future<ReviewCandidate?> ensureForLearningEntity(
    MemoryKnowledgeEntity entity,
  ) async {
    if (entity.masteryState != KnowledgeMasteryState.learning) return null;
    return _ensureCandidate(
      id: _learningCandidateId(entity.id),
      entity: entity,
      suggestedQuestionType: _questionTypeFor(entity.type, hasEvidence: false),
      priority: _learningPriority(entity.type),
    );
  }

  Future<ReviewCandidate?> ensureForLookup({
    required MemoryKnowledgeEntity entity,
    MemoryKnowledgeEvidence? evidence,
    int minLookupCount = 2,
  }) async {
    final lookupCount = await _repository.eventCountForCanonical(
      languageCode: entity.languageCode,
      canonicalKey: entity.canonicalKey,
      type: MemoryEventType.lookup,
    );
    if (lookupCount < minLookupCount) return null;

    return _ensureCandidate(
      id: _lookupCandidateId(entity.id),
      entity: entity,
      evidenceId: evidence?.id,
      suggestedQuestionType: _questionTypeFor(
        entity.type,
        hasEvidence: evidence != null,
      ),
      priority: _lookupPriority(
        entity.type,
        lookupCount,
        hasEvidence: evidence != null,
      ),
    );
  }

  Future<List<ReviewCandidate>> pendingCandidates({int limit = 50}) {
    return _repository.reviewCandidates(
      status: ReviewCandidateStatus.pending,
      limit: limit,
    );
  }

  Future<void> acceptCandidate(String id) {
    return _updateStatus(id, ReviewCandidateStatus.accepted);
  }

  Future<void> dismissCandidate(String id) {
    return _updateStatus(id, ReviewCandidateStatus.dismissed);
  }

  Future<void> markCandidateConverted(String id) {
    return _updateStatus(id, ReviewCandidateStatus.converted);
  }

  Future<void> dismissCandidates(Iterable<String> ids) async {
    final uniqueIds = ids.where((id) => id.trim().isNotEmpty).toSet();
    for (final id in uniqueIds) {
      await dismissCandidate(id);
    }
  }

  Future<List<ReviewCandidate>> candidatesForEntity(
    String entityId, {
    ReviewCandidateStatus? status,
    int limit = 20,
  }) {
    return _repository.reviewCandidatesForEntity(
      entityId,
      status: status,
      limit: limit,
    );
  }

  Future<void> _updateStatus(
    String id,
    ReviewCandidateStatus status,
  ) async {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) return;
    final existing = await _repository.reviewCandidateById(trimmedId);
    if (existing == null || existing.status == status) return;
    await _repository.updateReviewCandidateStatus(
      id: trimmedId,
      status: status,
      updatedAt: _clock().toUtc(),
    );
  }

  Future<ReviewCandidate?> _ensureCandidate({
    required String id,
    required MemoryKnowledgeEntity entity,
    required String suggestedQuestionType,
    required double priority,
    String? explanationId,
    String? evidenceId,
  }) async {
    final existing = await _repository.reviewCandidateById(id);
    if (existing != null && existing.status != ReviewCandidateStatus.pending) {
      return existing;
    }

    final now = _clock().toUtc();
    final effectiveEvidenceId = evidenceId ?? existing?.evidenceId;
    final effectiveQuestionType =
        effectiveEvidenceId != null &&
            suggestedQuestionType == 'word_meaning' &&
            entity.type == KnowledgeEntityType.word
        ? _questionTypeFor(entity.type, hasEvidence: true)
        : suggestedQuestionType;
    final effectivePriority = existing != null && existing.priority > priority
        ? existing.priority
        : priority;
    final candidate = ReviewCandidate(
      id: id,
      entityId: entity.id,
      entityType: entity.type,
      targetText: entity.displayText,
      explanationId: explanationId ?? existing?.explanationId,
      evidenceId: effectiveEvidenceId,
      suggestedQuestionType: effectiveQuestionType,
      priority: effectivePriority,
      status: ReviewCandidateStatus.pending,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _repository.upsertReviewCandidate(candidate);
    return candidate;
  }

  String _savedExplanationCandidateId(String entityId, String explanationId) {
    return 'review_candidate:$_languageCode:$entityId:explanation:$explanationId';
  }

  String _learningCandidateId(String entityId) {
    return 'review_candidate:$_languageCode:$entityId:learning';
  }

  String _lookupCandidateId(String entityId) {
    return 'review_candidate:$_languageCode:$entityId:lookup';
  }

  String _questionTypeFor(
    KnowledgeEntityType type, {
    required bool hasEvidence,
  }) {
    return switch (type) {
      KnowledgeEntityType.word => hasEvidence ? 'fill_blank' : 'word_meaning',
      KnowledgeEntityType.phrase ||
      KnowledgeEntityType.pattern ||
      KnowledgeEntityType.grammar ||
      KnowledgeEntityType.sentence => 'fill_blank',
      KnowledgeEntityType.bookTerm ||
      KnowledgeEntityType.concept ||
      KnowledgeEntityType.character => 'recall_context',
    };
  }

  double _savedExplanationPriority(KnowledgeEntityType type) {
    return switch (type) {
      KnowledgeEntityType.word => 0.8,
      KnowledgeEntityType.phrase ||
      KnowledgeEntityType.pattern ||
      KnowledgeEntityType.grammar ||
      KnowledgeEntityType.sentence => 0.85,
      KnowledgeEntityType.bookTerm ||
      KnowledgeEntityType.concept ||
      KnowledgeEntityType.character => 0.7,
    };
  }

  double _learningPriority(KnowledgeEntityType type) {
    return switch (type) {
      KnowledgeEntityType.word => 0.65,
      KnowledgeEntityType.phrase ||
      KnowledgeEntityType.pattern ||
      KnowledgeEntityType.grammar ||
      KnowledgeEntityType.sentence => 0.7,
      KnowledgeEntityType.bookTerm ||
      KnowledgeEntityType.concept ||
      KnowledgeEntityType.character => 0.55,
    };
  }

  double _lookupPriority(
    KnowledgeEntityType type,
    int lookupCount, {
    required bool hasEvidence,
  }) {
    final base = switch (type) {
      KnowledgeEntityType.word => 0.6,
      KnowledgeEntityType.phrase ||
      KnowledgeEntityType.pattern ||
      KnowledgeEntityType.grammar ||
      KnowledgeEntityType.sentence => 0.65,
      KnowledgeEntityType.bookTerm ||
      KnowledgeEntityType.concept ||
      KnowledgeEntityType.character => 0.5,
    };
    final cappedLookupCount = lookupCount > 6 ? 6 : lookupCount;
    final repeatBoost = (cappedLookupCount - 2) * 0.03;
    final evidenceBoost = hasEvidence ? 0.05 : 0;
    return base + repeatBoost + evidenceBoost;
  }
}

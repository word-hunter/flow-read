import 'dart:convert';

import '../../models/learning_item.dart';
import '../../models/reading_memory.dart';
import '../../storage/repositories/reading_memory_repository.dart';
import '../../storage/repositories/repository_language.dart';
import '../learning_item_service.dart';

final class ReviewPromotionRule {
  const ReviewPromotionRule({
    required this.trigger,
    required this.entityTypes,
    required this.questionType,
    required this.minimumPriority,
    required this.description,
  });

  final String trigger;
  final List<KnowledgeEntityType> entityTypes;
  final String questionType;
  final double minimumPriority;
  final String description;
}

final class ReviewCandidateCleanupPolicy {
  const ReviewCandidateCleanupPolicy({
    this.minimumPriority = 0.5,
    this.staleAfter = const Duration(days: 90),
    this.stalePriorityCeiling = 0.7,
    this.maxPendingPerEntity = 2,
  });

  static const defaults = ReviewCandidateCleanupPolicy();

  final double minimumPriority;
  final Duration staleAfter;
  final double stalePriorityCeiling;
  final int maxPendingPerEntity;
}

final class ReviewCandidateCleanupResult {
  const ReviewCandidateCleanupResult({
    required this.lowPriorityDismissed,
    required this.staleDismissed,
    required this.duplicateDismissed,
    required this.totalDismissed,
  });

  final int lowPriorityDismissed;
  final int staleDismissed;
  final int duplicateDismissed;
  final int totalDismissed;

  bool get hasChanges => totalDismissed > 0;
}

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

  List<ReviewPromotionRule> promotionRules() {
    return const [
      ReviewPromotionRule(
        trigger: 'saved_explanation',
        entityTypes: [
          KnowledgeEntityType.word,
          KnowledgeEntityType.phrase,
          KnowledgeEntityType.pattern,
          KnowledgeEntityType.grammar,
          KnowledgeEntityType.sentence,
        ],
        questionType: 'word_meaning_or_fill_blank',
        minimumPriority: 0.8,
        description:
            'User-saved explanations become high priority review candidates.',
      ),
      ReviewPromotionRule(
        trigger: 'repeated_lookup',
        entityTypes: [
          KnowledgeEntityType.word,
          KnowledgeEntityType.phrase,
          KnowledgeEntityType.pattern,
          KnowledgeEntityType.grammar,
        ],
        questionType: 'fill_blank',
        minimumPriority: 0.6,
        description:
            'Repeated lookups promote evidence-backed context practice.',
      ),
      ReviewPromotionRule(
        trigger: 'marked_learning',
        entityTypes: [
          KnowledgeEntityType.word,
          KnowledgeEntityType.phrase,
          KnowledgeEntityType.pattern,
          KnowledgeEntityType.grammar,
        ],
        questionType: 'word_meaning_or_fill_blank',
        minimumPriority: 0.65,
        description:
            'Items explicitly marked as learning are queued for review.',
      ),
      ReviewPromotionRule(
        trigger: 'book_scope_memory',
        entityTypes: [
          KnowledgeEntityType.bookTerm,
          KnowledgeEntityType.concept,
          KnowledgeEntityType.character,
        ],
        questionType: 'recall_context',
        minimumPriority: 0.55,
        description:
            'Book-scoped concepts stay source-bound and use recall practice.',
      ),
    ];
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

  Future<ReviewCandidateCleanupResult> cleanupPendingCandidates({
    ReviewCandidateCleanupPolicy policy = ReviewCandidateCleanupPolicy.defaults,
    int scanLimit = 500,
  }) async {
    final pending = await _repository.reviewCandidates(
      status: ReviewCandidateStatus.pending,
      limit: scanLimit,
    );
    if (pending.isEmpty) {
      return const ReviewCandidateCleanupResult(
        lowPriorityDismissed: 0,
        staleDismissed: 0,
        duplicateDismissed: 0,
        totalDismissed: 0,
      );
    }

    final now = _clock().toUtc();
    final lowPriority = <String>{};
    final stale = <String>{};
    final duplicate = <String>{};

    final bestByDuplicateKey = <String, ReviewCandidate>{};
    for (final candidate in pending) {
      if (candidate.priority < policy.minimumPriority) {
        lowPriority.add(candidate.id);
      }
      if (candidate.priority <= policy.stalePriorityCeiling &&
          now.difference(candidate.updatedAt.toUtc()) > policy.staleAfter) {
        stale.add(candidate.id);
      }

      final key = _duplicateKey(candidate);
      final currentBest = bestByDuplicateKey[key];
      if (currentBest == null) {
        bestByDuplicateKey[key] = candidate;
      } else if (_isBetterCandidate(candidate, currentBest)) {
        duplicate.add(currentBest.id);
        bestByDuplicateKey[key] = candidate;
      } else {
        duplicate.add(candidate.id);
      }
    }

    if (policy.maxPendingPerEntity > 0) {
      final byEntity = <String, List<ReviewCandidate>>{};
      for (final candidate in pending) {
        if (lowPriority.contains(candidate.id) ||
            stale.contains(candidate.id) ||
            duplicate.contains(candidate.id)) {
          continue;
        }
        byEntity.putIfAbsent(candidate.entityId, () => []).add(candidate);
      }
      for (final candidates in byEntity.values) {
        candidates.sort(_candidateSort);
        for (final candidate in candidates.skip(policy.maxPendingPerEntity)) {
          duplicate.add(candidate.id);
        }
      }
    }

    final uniqueLowPriority = lowPriority;
    final uniqueStale = stale.difference(uniqueLowPriority);
    final uniqueDuplicate = duplicate
        .difference(uniqueLowPriority)
        .difference(uniqueStale);
    final dismissed = {
      ...uniqueLowPriority,
      ...uniqueStale,
      ...uniqueDuplicate,
    };
    for (final id in dismissed) {
      await dismissCandidate(id);
    }

    return ReviewCandidateCleanupResult(
      lowPriorityDismissed: uniqueLowPriority.length,
      staleDismissed: uniqueStale.length,
      duplicateDismissed: uniqueDuplicate.length,
      totalDismissed: dismissed.length,
    );
  }

  Future<void> acceptCandidate(String id) {
    return _updateStatus(id, ReviewCandidateStatus.accepted);
  }

  Future<LearningItemSaveResult?> acceptCandidateForReview(
    String id, {
    required LearningItemService learningItems,
  }) async {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) return null;

    var candidate = await _repository.reviewCandidateById(trimmedId);
    if (candidate == null ||
        candidate.status == ReviewCandidateStatus.dismissed ||
        candidate.status == ReviewCandidateStatus.converted) {
      return null;
    }

    if (candidate.status != ReviewCandidateStatus.accepted) {
      await _updateStatus(trimmedId, ReviewCandidateStatus.accepted);
      candidate = await _repository.reviewCandidateById(trimmedId) ?? candidate;
    }

    final draft = await _draftForCandidate(candidate);
    if (draft == null) return null;

    final result = await learningItems.saveDraft(draft);
    await markCandidateConverted(trimmedId);
    return result;
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

  Future<LearningItemDraft?> _draftForCandidate(
    ReviewCandidate candidate,
  ) async {
    final entity = await _repository.entityById(candidate.entityId);
    if (entity == null) return null;

    final explanation = await _explanationForCandidate(candidate);
    final evidence = await _evidenceForCandidate(candidate);
    final eventContext = await _eventContextForCandidate(entity, candidate);
    final type = _learningItemTypeFor(candidate);
    final targetText = _candidateTargetText(candidate, entity);
    if (targetText.isEmpty) return null;

    final sourceText = _firstNonEmpty([
      evidence?.shortExcerpt ?? '',
      eventContext?.sourceText ?? '',
      if (type == LearningItemType.sentence) targetText,
    ]);

    return LearningItemDraft(
      type: type,
      canonicalKey: _firstNonEmpty([entity.canonicalKey, targetText]),
      title: _preview(targetText),
      content: targetText,
      answer: _answerForCandidate(
        candidate: candidate,
        explanation: explanation,
        evidence: evidence,
      ),
      note: _noteForCandidate(
        candidate: candidate,
        explanation: explanation,
        evidence: evidence,
      ),
      sourceText: sourceText,
      source: _learningItemSourceFor(
        evidence: evidence,
        sourceRef: eventContext?.sourceRef,
      ),
      tags: _tagsForCandidate(candidate, type, explanation, evidence),
      metadata: _metadataForCandidate(
        candidate: candidate,
        entity: entity,
        explanation: explanation,
        evidence: evidence,
        sourceRef: eventContext?.sourceRef,
      ),
    );
  }

  Future<MemoryKnowledgeExplanation?> _explanationForCandidate(
    ReviewCandidate candidate,
  ) async {
    final explanationId = candidate.explanationId?.trim();
    if (explanationId == null || explanationId.isEmpty) return null;
    return _repository.explanationById(explanationId);
  }

  Future<MemoryKnowledgeEvidence?> _evidenceForCandidate(
    ReviewCandidate candidate,
  ) async {
    final evidenceId = candidate.evidenceId?.trim();
    if (evidenceId == null || evidenceId.isEmpty) return null;
    return _repository.evidenceById(evidenceId);
  }

  Future<_CandidateEventContext?> _eventContextForCandidate(
    MemoryKnowledgeEntity entity,
    ReviewCandidate candidate,
  ) async {
    final events = await _repository.eventsForCanonical(
      languageCode: entity.languageCode,
      canonicalKey: entity.canonicalKey,
      limit: 50,
    );

    for (final event in events) {
      if (event.entityId != null && event.entityId != entity.id) continue;
      final metadata = _decodeJsonObject(event.metadataJson);
      if (!_matchesCandidateEvent(candidate, event, metadata)) continue;

      final sourceRef = _decodeSourceRef(event.sourceRefJson);
      final sourceText = _jsonString(metadata, 'sentence');
      if (sourceRef != null || sourceText.isNotEmpty) {
        return _CandidateEventContext(
          sourceRef: sourceRef,
          sourceText: sourceText,
        );
      }
    }
    return null;
  }

  bool _matchesCandidateEvent(
    ReviewCandidate candidate,
    MemoryEvent event,
    Map<String, Object?> metadata,
  ) {
    final explanationId = candidate.explanationId?.trim();
    if (explanationId != null && explanationId.isNotEmpty) {
      return _jsonString(metadata, 'explanationId') == explanationId;
    }

    if (candidate.evidenceId != null) {
      return event.type == MemoryEventType.lookup;
    }

    return event.type == MemoryEventType.markLearning;
  }

  LearningItemType _learningItemTypeFor(ReviewCandidate candidate) {
    final questionType = candidate.suggestedQuestionType?.trim();
    if (questionType == 'word_meaning') return LearningItemType.word;

    return switch (candidate.entityType) {
      KnowledgeEntityType.word => LearningItemType.word,
      KnowledgeEntityType.sentence => LearningItemType.sentence,
      KnowledgeEntityType.grammar ||
      KnowledgeEntityType.pattern => LearningItemType.grammar,
      KnowledgeEntityType.phrase ||
      KnowledgeEntityType.bookTerm ||
      KnowledgeEntityType.concept ||
      KnowledgeEntityType.character => LearningItemType.expression,
    };
  }

  String _candidateTargetText(
    ReviewCandidate candidate,
    MemoryKnowledgeEntity entity,
  ) {
    return _firstNonEmpty([
      candidate.targetText,
      entity.displayText,
      entity.canonicalKey,
    ]);
  }

  String _answerForCandidate({
    required ReviewCandidate candidate,
    required MemoryKnowledgeExplanation? explanation,
    required MemoryKnowledgeEvidence? evidence,
  }) {
    final explanationText = explanation?.explanation.trim() ?? '';
    if (explanationText.isNotEmpty) return explanationText;

    if ((candidate.suggestedQuestionType ?? '').trim() == 'recall_context') {
      return '回忆它在当前来源中的身份、作用或上下文含义。';
    }
    if ((evidence?.shortExcerpt.trim() ?? '').isNotEmpty) {
      return '结合原文上下文复习这个条目。';
    }
    return '';
  }

  String _noteForCandidate({
    required ReviewCandidate candidate,
    required MemoryKnowledgeExplanation? explanation,
    required MemoryKnowledgeEvidence? evidence,
  }) {
    if (explanation != null) {
      return switch (explanation.source) {
        ExplanationSource.ai => 'AI 保存解释',
        ExplanationSource.user => '用户保存解释',
        ExplanationSource.dictionary => '词典解释',
        ExplanationSource.generated => '生成解释',
      };
    }
    if (evidence != null) return '重复查词候选';
    if ((candidate.suggestedQuestionType ?? '').trim() == 'word_meaning') {
      return '学习中词汇候选';
    }
    return '阅读记忆候选';
  }

  LearningItemSource _learningItemSourceFor({
    required MemoryKnowledgeEvidence? evidence,
    required MemorySourceRef? sourceRef,
  }) {
    if (evidence != null) {
      return LearningItemSource(
        bookId: _firstNonEmpty([
          evidence.bookId ?? '',
          evidence.sourceId ?? '',
        ]),
        bookTitle: _emptyToNull(evidence.sourceTitleSnapshot),
        chapterIndex: evidence.chapterIndex ?? -1,
        chapterTitle: evidence.sourceTitleSnapshot,
      );
    }

    if (sourceRef != null) {
      return LearningItemSource(
        bookId: _firstNonEmpty([sourceRef.bookId ?? '', sourceRef.sourceId]),
        bookTitle: _emptyToNull(sourceRef.sourceTitleSnapshot),
        chapterIndex: sourceRef.chapterIndex ?? -1,
        chapterTitle: sourceRef.sourceTitleSnapshot,
      );
    }

    return const LearningItemSource.unknown();
  }

  List<String> _tagsForCandidate(
    ReviewCandidate candidate,
    LearningItemType type,
    MemoryKnowledgeExplanation? explanation,
    MemoryKnowledgeEvidence? evidence,
  ) {
    return [
      'reading-memory',
      'review-candidate',
      type.name,
      if (explanation != null) 'saved-explanation',
      if (explanation?.source == ExplanationSource.ai) 'ai',
      if (evidence != null) 'evidence',
      if ((candidate.suggestedQuestionType ?? '').trim().isNotEmpty)
        candidate.suggestedQuestionType!.trim(),
    ];
  }

  Map<String, String> _metadataForCandidate({
    required ReviewCandidate candidate,
    required MemoryKnowledgeEntity entity,
    required MemoryKnowledgeExplanation? explanation,
    required MemoryKnowledgeEvidence? evidence,
    required MemorySourceRef? sourceRef,
  }) {
    final metadata = <String, String>{
      'createdFrom': 'reviewCandidate',
      'reviewCandidateId': candidate.id,
      'reviewCandidateEntityType': candidate.entityType.storageValue,
      'memoryEntityId': entity.id,
      if ((candidate.suggestedQuestionType ?? '').trim().isNotEmpty)
        'reviewCandidateQuestionType': candidate.suggestedQuestionType!.trim(),
      if (explanation != null) 'memoryExplanationId': explanation.id,
      if (evidence != null) 'memoryEvidenceId': evidence.id,
    };

    final sourceKind = evidence?.sourceKind ?? sourceRef?.sourceKind;
    if (sourceKind != null) metadata['sourceKind'] = sourceKind.storageValue;

    final sourceId = _firstNonEmpty([
      evidence?.sourceId ?? '',
      sourceRef?.sourceId ?? '',
    ]);
    if (sourceId.isNotEmpty) metadata['sourceId'] = sourceId;

    return metadata;
  }

  MemorySourceRef? _decodeSourceRef(String sourceRefJson) {
    final json = _decodeJsonObject(sourceRefJson);
    final sourceId = _jsonString(json, 'sourceId');
    if (sourceId.isEmpty) return null;

    final sourceKind = _jsonString(json, 'sourceKind');
    final availability = _jsonString(json, 'sourceAvailability');
    return MemorySourceRef(
      sourceId: sourceId,
      sourceKind: SourceKind.fromStorage(
        sourceKind.isEmpty ? SourceKind.manual.storageValue : sourceKind,
      ),
      sourceTitleSnapshot: _firstNonEmpty([
        _jsonString(json, 'sourceTitleSnapshot'),
        sourceId,
      ]),
      bookId: _emptyToNull(_jsonString(json, 'bookId')),
      chapterIndex: _jsonInt(json, 'chapterIndex'),
      locationLocator: _emptyToNull(_jsonString(json, 'locationLocator')),
      sourceAvailability: SourceAvailability.fromStorage(
        availability.isEmpty
            ? SourceAvailability.available.storageValue
            : availability,
      ),
    );
  }

  Map<String, Object?> _decodeJsonObject(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return const {};
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, Object?>) return decoded;
      if (decoded is Map) {
        return {
          for (final entry in decoded.entries)
            if (entry.key != null) entry.key.toString(): entry.value,
        };
      }
    } catch (_) {
      return const {};
    }
    return const {};
  }

  String _jsonString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) return '';
    return value.toString().trim();
  }

  int? _jsonInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _preview(String text, {int maxLength = 80}) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxLength) return normalized;
    return '${normalized.substring(0, maxLength).trim()}...';
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
    await _dismissPendingDuplicatesFor(candidate);
    return await _repository.reviewCandidateById(candidate.id) ?? candidate;
  }

  Future<void> _dismissPendingDuplicatesFor(ReviewCandidate candidate) async {
    final pending = await _repository.reviewCandidatesForEntity(
      candidate.entityId,
      status: ReviewCandidateStatus.pending,
      limit: 50,
    );
    final sameKey = pending
        .where((item) => _duplicateKey(item) == _duplicateKey(candidate))
        .toList();
    if (sameKey.length <= 1) return;

    sameKey.sort(_candidateSort);
    for (final duplicate in sameKey.skip(1)) {
      await _updateStatus(duplicate.id, ReviewCandidateStatus.dismissed);
    }
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

  String _duplicateKey(ReviewCandidate candidate) {
    return [
      candidate.entityId,
      candidate.entityType.storageValue,
      candidate.suggestedQuestionType?.trim() ?? '',
    ].join(':');
  }

  int _candidateSort(ReviewCandidate a, ReviewCandidate b) {
    if (_isBetterCandidate(a, b)) return -1;
    if (_isBetterCandidate(b, a)) return 1;
    return a.id.compareTo(b.id);
  }

  bool _isBetterCandidate(ReviewCandidate a, ReviewCandidate b) {
    if (a.priority != b.priority) return a.priority > b.priority;
    final updatedCompare = a.updatedAt.toUtc().compareTo(b.updatedAt.toUtc());
    if (updatedCompare != 0) return updatedCompare > 0;
    return a.createdAt.toUtc().isAfter(b.createdAt.toUtc());
  }
}

final class _CandidateEventContext {
  const _CandidateEventContext({
    required this.sourceRef,
    required this.sourceText,
  });

  final MemorySourceRef? sourceRef;
  final String sourceText;
}

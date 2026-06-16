import 'dart:convert';

import '../../models/learning_item.dart';
import '../../models/reading_memory.dart';
import '../../models/user_vocabulary.dart';
import '../../storage/repositories/reading_memory_repository.dart';
import '../../storage/repositories/repository_language.dart';
import 'reading_memory_ids.dart';
import 'review_candidate_service.dart';

class ReadingMemoryService {
  ReadingMemoryService({
    required ReadingMemoryRepository repository,
    String? languageCode,
    DateTime Function()? clock,
    ReviewCandidateService? reviewCandidates,
  }) : _repository = repository,
       _languageCode = normalizeRepositoryLanguageCode(languageCode),
       _clock = clock ?? DateTime.now,
       _reviewCandidates = reviewCandidates;

  final ReadingMemoryRepository _repository;
  final String _languageCode;
  final DateTime Function() _clock;
  final ReviewCandidateService? _reviewCandidates;
  int _sequence = 0;

  Future<void> init() {
    return _repository.init();
  }

  Future<MemoryEvent?> recordLookup({
    required String targetText,
    String? canonical,
    MemorySourceRef? sourceRef,
    String? sentence,
    String? languageCode,
  }) async {
    final normalized = _canonical(canonical ?? targetText);
    if (normalized.isEmpty) return null;

    final now = _now();
    final entity = await _ensureEntity(
      targetText: targetText,
      canonicalKey: normalized,
      type: KnowledgeEntityType.word,
      languageCode: languageCode,
      now: now,
    );
    await _upsertSourceRef(sourceRef, languageCode: languageCode, now: now);
    final excerpt = _trimmed(sentence);
    final event = MemoryEvent(
      id: _nextId('event:lookup', now),
      type: MemoryEventType.lookup,
      languageCode: _language(languageCode),
      sourceId: sourceRef?.sourceId,
      entityId: entity.id,
      targetText: targetText.trim(),
      canonicalKey: normalized,
      sourceRefJson: _encodeSourceRef(sourceRef),
      metadataJson: excerpt == null ? '{}' : jsonEncode({'sentence': excerpt}),
      createdAt: now,
    );
    await _repository.recordEvent(event);

    MemoryKnowledgeEvidence? evidence;
    if (sourceRef != null && excerpt != null) {
      evidence = MemoryKnowledgeEvidence(
        id: _nextId('evidence:lookup', now),
        entityId: entity.id,
        sourceId: sourceRef.sourceId,
        sourceKind: sourceRef.sourceKind,
        bookId: sourceRef.bookId,
        chapterIndex: sourceRef.chapterIndex,
        locationLocator: sourceRef.locationLocator,
        shortExcerpt: excerpt,
        sourceTitleSnapshot: sourceRef.sourceTitleSnapshot,
        sourceAvailability: sourceRef.sourceAvailability,
        retentionPolicy: EvidenceRetentionPolicy.keepSnippet,
        createdAt: now,
      );
      await _repository.upsertEvidence(evidence);
    }
    await _reviewCandidates?.ensureForLookup(
      entity: entity,
      evidence: evidence,
    );

    return event;
  }

  Future<MemoryEvent?> recordVocabularyStatus({
    required String targetText,
    required UserWordStatus? status,
    String? canonical,
    MemorySourceRef? sourceRef,
    String? languageCode,
  }) async {
    final normalized = _canonical(canonical ?? targetText);
    if (normalized.isEmpty) return null;

    final now = _now();
    final eventType = switch (status) {
      UserWordStatus.learning => MemoryEventType.markLearning,
      UserWordStatus.known => MemoryEventType.markKnown,
      null => MemoryEventType.markUnknown,
    };
    final entity = await _ensureEntity(
      targetText: targetText,
      canonicalKey: normalized,
      type: KnowledgeEntityType.word,
      masteryState: _masteryStateForStatus(status),
      languageCode: languageCode,
      now: now,
      preserveExistingMastery: false,
    );
    await _upsertSourceRef(sourceRef, languageCode: languageCode, now: now);

    final event = MemoryEvent(
      id: _nextId('event:${eventType.storageValue}', now),
      type: eventType,
      languageCode: _language(languageCode),
      sourceId: sourceRef?.sourceId,
      entityId: entity.id,
      targetText: targetText.trim(),
      canonicalKey: normalized,
      sourceRefJson: _encodeSourceRef(sourceRef),
      metadataJson: jsonEncode({'status': status?.name ?? 'unknown'}),
      createdAt: now,
    );
    await _repository.recordEvent(event);
    if (status == UserWordStatus.learning) {
      await _reviewCandidates?.ensureForLearningEntity(entity);
    }
    return event;
  }

  Future<MemoryKnowledgeExplanation?> saveExplanation({
    required String targetText,
    required String explanation,
    KnowledgeEntityType type = KnowledgeEntityType.word,
    ExplanationSource source = ExplanationSource.ai,
    MemorySourceRef? sourceRef,
    String? canonical,
    String? targetLanguage,
    String? promptVersion,
    String? languageCode,
  }) async {
    final normalized = _canonical(canonical ?? targetText);
    final trimmedExplanation = explanation.trim();
    if (normalized.isEmpty || trimmedExplanation.isEmpty) return null;

    final now = _now();
    final entity = await _ensureEntity(
      targetText: targetText,
      canonicalKey: normalized,
      type: type,
      languageCode: languageCode,
      now: now,
    );
    await _upsertSourceRef(sourceRef, languageCode: languageCode, now: now);

    final saved = MemoryKnowledgeExplanation(
      id: _nextId('explanation', now),
      entityId: entity.id,
      explanation: trimmedExplanation,
      source: source,
      targetLanguage: targetLanguage?.trim().toLowerCase() ?? 'zh',
      promptVersion: _trimmed(promptVersion),
      createdAt: now,
      updatedAt: now,
    );
    await _repository.upsertExplanation(saved);

    await _repository.recordEvent(
      MemoryEvent(
        id: _nextId('event:save_explanation', now),
        type: MemoryEventType.saveExplanation,
        languageCode: _language(languageCode),
        sourceId: sourceRef?.sourceId,
        entityId: entity.id,
        targetText: targetText.trim(),
        canonicalKey: normalized,
        sourceRefJson: _encodeSourceRef(sourceRef),
        metadataJson: jsonEncode({
          'explanationId': saved.id,
          'explanationSource': source.storageValue,
        }),
        createdAt: now,
      ),
    );
    await _reviewCandidates?.ensureForSavedExplanation(
      entity: entity,
      explanation: saved,
    );
    return saved;
  }

  Future<MemoryEvent?> recordLearningReview({
    required LearningItem item,
    required LearningReviewResult result,
    String? languageCode,
  }) async {
    if (item.type == LearningItemType.questionMistake) return null;

    final targetText = _learningItemTargetText(item);
    final canonical = _canonical(
      item.canonicalKey.trim().isNotEmpty ? item.canonicalKey : targetText,
    );
    if (targetText.isEmpty || canonical.isEmpty) return null;

    final type = _knowledgeTypeForLearningItem(item.type);
    final language = _language(languageCode);
    final existing = await _repository.entityByCanonical(
      languageCode: language,
      type: type,
      canonicalKey: canonical,
    );
    final now = _now();
    final masteryState = _masteryStateForReview(
      result: result,
      reviewCount: item.reviewCount,
      existing: existing?.masteryState,
    );
    final entity = await _ensureEntity(
      targetText: targetText,
      canonicalKey: canonical,
      type: type,
      masteryState: masteryState,
      languageCode: language,
      now: now,
      preserveExistingMastery: false,
    );
    final event = MemoryEvent(
      id: _nextId('event:${MemoryEventType.review.storageValue}', now),
      type: MemoryEventType.review,
      languageCode: language,
      entityId: entity.id,
      targetText: targetText,
      canonicalKey: canonical,
      sourceRefJson: '{}',
      metadataJson: jsonEncode({
        'learningItemId': item.id,
        'learningItemType': item.type.name,
        'reviewResult': result.name,
        'reviewCount': item.reviewCount,
        if (item.bookId.trim().isNotEmpty) 'bookId': item.bookId.trim(),
        if (item.chapterIndex >= 0) 'chapterIndex': item.chapterIndex,
      }),
      createdAt: now,
    );
    await _repository.recordEvent(event);
    return event;
  }

  Future<MemoryKnowledgeEntity> _ensureEntity({
    required String targetText,
    required String canonicalKey,
    required KnowledgeEntityType type,
    required DateTime now,
    String? languageCode,
    KnowledgeMasteryState masteryState = KnowledgeMasteryState.unknown,
    bool preserveExistingMastery = true,
  }) async {
    final language = _language(languageCode);
    final existing = await _repository.entityByCanonical(
      languageCode: language,
      type: type,
      canonicalKey: canonicalKey,
    );
    final entity = MemoryKnowledgeEntity(
      id:
          existing?.id ??
          ReadingMemoryIds.entity(
            languageCode: language,
            type: type,
            canonicalKey: canonicalKey,
          ),
      languageCode: language,
      type: type,
      canonicalKey: canonicalKey,
      displayText: existing?.displayText ?? targetText.trim(),
      normalizedText: canonicalKey,
      masteryState:
          preserveExistingMastery &&
              masteryState == KnowledgeMasteryState.unknown
          ? existing?.masteryState ?? masteryState
          : masteryState,
      confidence: existing?.confidence ?? 0,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      lastAccessedAt: now,
    );
    await _repository.upsertEntity(entity);
    return entity;
  }

  Future<void> _upsertSourceRef(
    MemorySourceRef? sourceRef, {
    required DateTime now,
    String? languageCode,
  }) async {
    if (sourceRef == null) return;
    final existing = await _repository.sourceRecord(sourceRef.sourceId);
    await _repository.upsertSourceRecord(
      MemorySourceRecord(
        id: sourceRef.sourceId,
        sourceKind: sourceRef.sourceKind,
        titleSnapshot: sourceRef.sourceTitleSnapshot,
        languageCode: _language(languageCode),
        availability: sourceRef.sourceAvailability,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        deletedAt: existing?.deletedAt,
      ),
    );
  }

  DateTime _now() => _clock().toUtc();

  String _nextId(String prefix, DateTime now) {
    _sequence += 1;
    return '$prefix:${now.microsecondsSinceEpoch}:$_sequence';
  }

  String _language(String? languageCode) {
    return normalizeRepositoryLanguageCode(languageCode ?? _languageCode);
  }

  String _canonical(String value) {
    return ReadingMemoryIds.normalizeCanonical(value);
  }

  static KnowledgeMasteryState _masteryStateForStatus(UserWordStatus? status) {
    return switch (status) {
      UserWordStatus.learning => KnowledgeMasteryState.learning,
      UserWordStatus.known => KnowledgeMasteryState.mastered,
      null => KnowledgeMasteryState.unknown,
    };
  }

  static KnowledgeMasteryState _masteryStateForReview({
    required LearningReviewResult result,
    required int reviewCount,
    KnowledgeMasteryState? existing,
  }) {
    return switch (result) {
      LearningReviewResult.forgotten ||
      LearningReviewResult.vague ||
      LearningReviewResult.missed => KnowledgeMasteryState.learning,
      LearningReviewResult.remembered =>
        reviewCount >= 2
            ? KnowledgeMasteryState.mastered
            : existing == KnowledgeMasteryState.mastered
            ? KnowledgeMasteryState.mastered
            : KnowledgeMasteryState.learning,
      LearningReviewResult.mastered => KnowledgeMasteryState.mastered,
      LearningReviewResult.newItem => existing ?? KnowledgeMasteryState.unknown,
    };
  }

  static KnowledgeEntityType _knowledgeTypeForLearningItem(
    LearningItemType type,
  ) {
    return switch (type) {
      LearningItemType.word => KnowledgeEntityType.word,
      LearningItemType.sentence => KnowledgeEntityType.sentence,
      LearningItemType.grammar => KnowledgeEntityType.grammar,
      LearningItemType.expression => KnowledgeEntityType.phrase,
      LearningItemType.questionMistake => KnowledgeEntityType.sentence,
    };
  }

  static String _learningItemTargetText(LearningItem item) {
    final content = item.content.trim();
    if (content.isNotEmpty) return content;
    return item.title.trim();
  }

  static String _encodeSourceRef(MemorySourceRef? sourceRef) {
    if (sourceRef == null) return '{}';
    return jsonEncode({
      'sourceId': sourceRef.sourceId,
      'sourceKind': sourceRef.sourceKind.storageValue,
      'sourceTitleSnapshot': sourceRef.sourceTitleSnapshot,
      if (sourceRef.bookId != null) 'bookId': sourceRef.bookId,
      if (sourceRef.chapterIndex != null)
        'chapterIndex': sourceRef.chapterIndex,
      if (sourceRef.locationLocator != null)
        'locationLocator': sourceRef.locationLocator,
      'sourceAvailability': sourceRef.sourceAvailability.storageValue,
    });
  }

  static String? _trimmed(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

import 'dart:convert';

import '../../models/reading_memory.dart';
import '../../models/user_vocabulary.dart';
import '../../storage/repositories/reading_memory_repository.dart';
import '../../storage/repositories/repository_language.dart';
import 'reading_memory_ids.dart';

class ReadingMemoryService {
  ReadingMemoryService({
    required ReadingMemoryRepository repository,
    String? languageCode,
    DateTime Function()? clock,
  }) : _repository = repository,
       _languageCode = normalizeRepositoryLanguageCode(languageCode),
       _clock = clock ?? DateTime.now;

  final ReadingMemoryRepository _repository;
  final String _languageCode;
  final DateTime Function() _clock;
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

    if (sourceRef != null && excerpt != null) {
      await _repository.upsertEvidence(
        MemoryKnowledgeEvidence(
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
        ),
      );
    }

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
    return saved;
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

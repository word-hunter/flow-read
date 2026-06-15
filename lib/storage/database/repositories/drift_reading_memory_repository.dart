import 'package:drift/drift.dart';

import '../../../models/reading_memory.dart';
import '../../repositories/reading_memory_repository.dart';
import '../../repositories/repository_language.dart';
import '../app_database.dart';
import '../dao/reading_memory_dao.dart';

final class DriftReadingMemoryRepository implements ReadingMemoryRepository {
  DriftReadingMemoryRepository(
    this._dao, {
    required String languageCode,
    DateTime Function()? clock,
  }) : _languageCode = normalizeRepositoryLanguageCode(languageCode),
       _clock = clock ?? DateTime.now;

  final ReadingMemoryDao _dao;
  final String _languageCode;
  final DateTime Function() _clock;

  @override
  Future<void> init() async {}

  @override
  Future<void> upsertSourceRecord(MemorySourceRecord record) {
    return _dao.upsertSourceRecord(
      SourceRecordsCompanion(
        id: Value(record.id),
        sourceKind: Value(record.sourceKind.storageValue),
        titleSnapshot: Value(record.titleSnapshot),
        authorSnapshot: Value(record.authorSnapshot),
        language: Value(_language(record.languageCode)),
        fingerprint: Value(record.fingerprint),
        availability: Value(record.availability.storageValue),
        createdAt: Value(_encodeDate(record.createdAt)),
        updatedAt: Value(_encodeDate(record.updatedAt)),
        deletedAt: Value(_encodeNullableDate(record.deletedAt)),
      ),
    );
  }

  @override
  Future<MemorySourceRecord?> sourceRecord(String id) async {
    final row = await _dao.sourceRecord(id);
    return row == null ? null : _sourceRecordFromEntry(row);
  }

  @override
  Future<void> updateSourceAvailability({
    required String sourceId,
    required SourceAvailability availability,
    DateTime? deletedAt,
  }) {
    return _dao.updateSourceAvailability(
      sourceId: sourceId,
      availability: availability.storageValue,
      updatedAt: _encodeDate(_clock().toUtc()),
      deletedAt: _encodeNullableDate(deletedAt),
    );
  }

  @override
  Future<void> upsertEntity(MemoryKnowledgeEntity entity) {
    return _dao.upsertEntity(
      KnowledgeEntitiesCompanion(
        id: Value(entity.id),
        language: Value(_language(entity.languageCode)),
        type: Value(entity.type.storageValue),
        canonicalKey: Value(entity.canonicalKey),
        displayText: Value(entity.displayText),
        normalizedText: Value(entity.normalizedText),
        masteryState: Value(entity.masteryState.storageValue),
        confidence: Value(entity.confidence),
        createdAt: Value(_encodeDate(entity.createdAt)),
        updatedAt: Value(_encodeDate(entity.updatedAt)),
        lastAccessedAt: Value(_encodeNullableDate(entity.lastAccessedAt)),
      ),
    );
  }

  @override
  Future<MemoryKnowledgeEntity?> entityById(String id) async {
    final row = await _dao.entityById(id);
    return row == null ? null : _entityFromEntry(row);
  }

  @override
  Future<MemoryKnowledgeEntity?> entityByCanonical({
    required String languageCode,
    required KnowledgeEntityType type,
    required String canonicalKey,
  }) async {
    final row = await _dao.entityByCanonical(
      language: _language(languageCode),
      type: type.storageValue,
      canonicalKey: canonicalKey,
    );
    return row == null ? null : _entityFromEntry(row);
  }

  @override
  Future<void> upsertExplanation(MemoryKnowledgeExplanation explanation) {
    return _dao.upsertExplanation(
      KnowledgeExplanationsCompanion(
        id: Value(explanation.id),
        entityId: Value(explanation.entityId),
        explanation: Value(explanation.explanation),
        explanationSource: Value(explanation.source.storageValue),
        targetLanguage: Value(explanation.targetLanguage),
        promptVersion: Value(explanation.promptVersion),
        createdAt: Value(_encodeDate(explanation.createdAt)),
        updatedAt: Value(_encodeDate(explanation.updatedAt)),
      ),
    );
  }

  @override
  Future<List<MemoryKnowledgeExplanation>> explanationsForEntity(
    String entityId, {
    int limit = 20,
  }) async {
    final rows = await _dao.explanationsForEntity(entityId, limit: limit);
    return rows.map(_explanationFromEntry).toList(growable: false);
  }

  @override
  Future<void> upsertEvidence(MemoryKnowledgeEvidence evidence) {
    return _dao.upsertEvidence(
      KnowledgeEvidencesCompanion(
        id: Value(evidence.id),
        entityId: Value(evidence.entityId),
        sourceId: Value(evidence.sourceId),
        sourceKind: Value(evidence.sourceKind.storageValue),
        bookId: Value(evidence.bookId),
        chapterIndex: Value(evidence.chapterIndex),
        locationLocator: Value(evidence.locationLocator),
        shortExcerpt: Value(evidence.shortExcerpt),
        excerptHash: Value(evidence.excerptHash),
        sourceTitleSnapshot: Value(evidence.sourceTitleSnapshot),
        sourceAvailability: Value(evidence.sourceAvailability.storageValue),
        retentionPolicy: Value(evidence.retentionPolicy.storageValue),
        createdAt: Value(_encodeDate(evidence.createdAt)),
      ),
    );
  }

  @override
  Future<List<MemoryKnowledgeEvidence>> evidencesForEntity(
    String entityId, {
    int limit = 20,
  }) async {
    final rows = await _dao.evidencesForEntity(entityId, limit: limit);
    return rows.map(_evidenceFromEntry).toList(growable: false);
  }

  @override
  Future<void> recordEvent(MemoryEvent event) {
    return _dao.insertEvent(
      MemoryEventsCompanion(
        id: Value(event.id),
        eventType: Value(event.type.storageValue),
        language: Value(_language(event.languageCode)),
        sourceId: Value(event.sourceId),
        entityId: Value(event.entityId),
        targetText: Value(event.targetText),
        canonicalKey: Value(event.canonicalKey),
        sourceRefJson: Value(event.sourceRefJson),
        metadataJson: Value(event.metadataJson),
        createdAt: Value(_encodeDate(event.createdAt)),
      ),
    );
  }

  @override
  Future<List<MemoryEvent>> eventsForCanonical({
    required String languageCode,
    required String canonicalKey,
    int limit = 20,
  }) async {
    final rows = await _dao.eventsForCanonical(
      language: _language(languageCode),
      canonicalKey: canonicalKey,
      limit: limit,
    );
    return rows.map(_eventFromEntry).toList(growable: false);
  }

  @override
  Future<int> eventCountForCanonical({
    required String languageCode,
    required String canonicalKey,
    MemoryEventType? type,
  }) {
    return _dao.eventCountForCanonical(
      language: _language(languageCode),
      canonicalKey: canonicalKey,
      eventType: type?.storageValue,
    );
  }

  @override
  Future<void> upsertReviewCandidate(ReviewCandidate candidate) {
    return _dao.upsertReviewCandidate(
      ReviewCandidatesCompanion(
        id: Value(candidate.id),
        entityId: Value(candidate.entityId),
        entityType: Value(candidate.entityType.storageValue),
        targetText: Value(candidate.targetText),
        explanationId: Value(candidate.explanationId),
        evidenceId: Value(candidate.evidenceId),
        suggestedQuestionType: Value(candidate.suggestedQuestionType),
        priority: Value(candidate.priority),
        status: Value(candidate.status.storageValue),
        createdAt: Value(_encodeDate(candidate.createdAt)),
        updatedAt: Value(_encodeDate(candidate.updatedAt)),
      ),
    );
  }

  @override
  Future<ReviewCandidate?> reviewCandidateById(String id) async {
    final row = await _dao.reviewCandidateById(id);
    return row == null ? null : _reviewCandidateFromEntry(row);
  }

  @override
  Future<List<ReviewCandidate>> reviewCandidatesForEntity(
    String entityId, {
    ReviewCandidateStatus? status,
    int limit = 20,
  }) async {
    final rows = await _dao.reviewCandidatesForEntity(
      entityId,
      status: status?.storageValue,
      limit: limit,
    );
    return rows.map(_reviewCandidateFromEntry).toList(growable: false);
  }

  @override
  Future<List<ReviewCandidate>> reviewCandidates({
    ReviewCandidateStatus? status,
    int limit = 50,
  }) async {
    final rows = await _dao.reviewCandidatesByStatus(
      status: status?.storageValue,
      limit: limit,
    );
    return rows.map(_reviewCandidateFromEntry).toList(growable: false);
  }

  @override
  Future<void> close() async {}

  String _language(String languageCode) {
    final normalized = normalizeRepositoryLanguageCode(languageCode);
    return normalized.isEmpty ? _languageCode : normalized;
  }

  static MemorySourceRecord _sourceRecordFromEntry(SourceRecordEntry row) {
    return MemorySourceRecord(
      id: row.id,
      sourceKind: SourceKind.fromStorage(row.sourceKind),
      titleSnapshot: row.titleSnapshot,
      authorSnapshot: row.authorSnapshot,
      languageCode: row.language,
      fingerprint: row.fingerprint,
      availability: SourceAvailability.fromStorage(row.availability),
      createdAt: _decodeDate(row.createdAt),
      updatedAt: _decodeDate(row.updatedAt),
      deletedAt: _decodeNullableDate(row.deletedAt),
    );
  }

  static MemoryKnowledgeEntity _entityFromEntry(KnowledgeEntityEntry row) {
    return MemoryKnowledgeEntity(
      id: row.id,
      languageCode: row.language,
      type: KnowledgeEntityType.fromStorage(row.type),
      canonicalKey: row.canonicalKey,
      displayText: row.displayText,
      normalizedText: row.normalizedText,
      masteryState: KnowledgeMasteryState.fromStorage(row.masteryState),
      confidence: row.confidence,
      createdAt: _decodeDate(row.createdAt),
      updatedAt: _decodeDate(row.updatedAt),
      lastAccessedAt: _decodeNullableDate(row.lastAccessedAt),
    );
  }

  static MemoryKnowledgeExplanation _explanationFromEntry(
    KnowledgeExplanationEntry row,
  ) {
    return MemoryKnowledgeExplanation(
      id: row.id,
      entityId: row.entityId,
      explanation: row.explanation,
      source: ExplanationSource.fromStorage(row.explanationSource),
      targetLanguage: row.targetLanguage,
      promptVersion: row.promptVersion,
      createdAt: _decodeDate(row.createdAt),
      updatedAt: _decodeDate(row.updatedAt),
    );
  }

  static MemoryKnowledgeEvidence _evidenceFromEntry(
    KnowledgeEvidenceEntry row,
  ) {
    return MemoryKnowledgeEvidence(
      id: row.id,
      entityId: row.entityId,
      sourceId: row.sourceId,
      sourceKind: SourceKind.fromStorage(row.sourceKind),
      bookId: row.bookId,
      chapterIndex: row.chapterIndex,
      locationLocator: row.locationLocator,
      shortExcerpt: row.shortExcerpt,
      excerptHash: row.excerptHash,
      sourceTitleSnapshot: row.sourceTitleSnapshot,
      sourceAvailability: SourceAvailability.fromStorage(
        row.sourceAvailability,
      ),
      retentionPolicy: EvidenceRetentionPolicy.fromStorage(
        row.retentionPolicy,
      ),
      createdAt: _decodeDate(row.createdAt),
    );
  }

  static MemoryEvent _eventFromEntry(MemoryEventEntry row) {
    return MemoryEvent(
      id: row.id,
      type: MemoryEventType.fromStorage(row.eventType),
      languageCode: row.language,
      sourceId: row.sourceId,
      entityId: row.entityId,
      targetText: row.targetText,
      canonicalKey: row.canonicalKey,
      sourceRefJson: row.sourceRefJson,
      metadataJson: row.metadataJson,
      createdAt: _decodeDate(row.createdAt),
    );
  }

  static ReviewCandidate _reviewCandidateFromEntry(ReviewCandidateEntry row) {
    return ReviewCandidate(
      id: row.id,
      entityId: row.entityId,
      entityType: KnowledgeEntityType.fromStorage(row.entityType),
      targetText: row.targetText,
      explanationId: row.explanationId,
      evidenceId: row.evidenceId,
      suggestedQuestionType: row.suggestedQuestionType,
      priority: row.priority,
      status: ReviewCandidateStatus.fromStorage(row.status),
      createdAt: _decodeDate(row.createdAt),
      updatedAt: _decodeDate(row.updatedAt),
    );
  }

  static String _encodeDate(DateTime value) {
    return value.toUtc().toIso8601String();
  }

  static String? _encodeNullableDate(DateTime? value) {
    return value == null ? null : _encodeDate(value);
  }

  static DateTime _decodeDate(String value) {
    return DateTime.parse(value).toUtc();
  }

  static DateTime? _decodeNullableDate(String? value) {
    return value == null ? null : _decodeDate(value);
  }
}

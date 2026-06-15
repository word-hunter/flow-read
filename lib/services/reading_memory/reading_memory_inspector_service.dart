import '../../models/reading_memory.dart';
import '../../storage/database/app_database.dart';
import '../../storage/database/dao/reading_memory_dao.dart';
import '../../storage/repositories/repository_language.dart';

final class ReadingMemoryInspectorOverview {
  const ReadingMemoryInspectorOverview({
    required this.languageCode,
    required this.sourceCount,
    required this.entityCount,
    required this.explanationCount,
    required this.evidenceCount,
    required this.eventCount,
    required this.reviewCandidateCount,
    required this.entityCountsByType,
    required this.entityCountsByMastery,
    required this.eventCountsByType,
    required this.sourceCountsByAvailability,
  });

  final String languageCode;
  final int sourceCount;
  final int entityCount;
  final int explanationCount;
  final int evidenceCount;
  final int eventCount;
  final int reviewCandidateCount;
  final Map<KnowledgeEntityType, int> entityCountsByType;
  final Map<KnowledgeMasteryState, int> entityCountsByMastery;
  final Map<MemoryEventType, int> eventCountsByType;
  final Map<SourceAvailability, int> sourceCountsByAvailability;
}

final class ReadingMemoryEntityDetail {
  const ReadingMemoryEntityDetail({
    required this.entity,
    required this.explanations,
    required this.evidences,
    required this.recentEvents,
    required this.reviewCandidates,
  });

  final MemoryKnowledgeEntity entity;
  final List<MemoryKnowledgeExplanation> explanations;
  final List<MemoryKnowledgeEvidence> evidences;
  final List<MemoryEvent> recentEvents;
  final List<ReviewCandidate> reviewCandidates;
}

class ReadingMemoryInspectorService {
  ReadingMemoryInspectorService({
    required ReadingMemoryDao dao,
    String? languageCode,
  }) : _dao = dao,
       _languageCode = normalizeRepositoryLanguageCode(languageCode);

  static const defaultLimit = 50;
  static const maxLimit = 200;

  final ReadingMemoryDao _dao;
  final String _languageCode;

  Future<ReadingMemoryInspectorOverview> overview({
    String? languageCode,
  }) async {
    final language = _language(languageCode);
    final counts = await Future.wait<int>([
      _dao.inspectorSourceCount(language: language),
      _dao.inspectorEntityCount(language: language),
      _dao.inspectorExplanationCount(language: language),
      _dao.inspectorEvidenceCount(language: language),
      _dao.inspectorEventCount(language: language),
      _dao.inspectorReviewCandidateCount(language: language),
    ]);
    final grouped = await Future.wait<Map<String, int>>([
      _dao.inspectorEntityCountsByType(language: language),
      _dao.inspectorEntityCountsByMastery(language: language),
      _dao.inspectorEventCountsByType(language: language),
      _dao.inspectorSourceCountsByAvailability(language: language),
    ]);

    return ReadingMemoryInspectorOverview(
      languageCode: language,
      sourceCount: counts[0],
      entityCount: counts[1],
      explanationCount: counts[2],
      evidenceCount: counts[3],
      eventCount: counts[4],
      reviewCandidateCount: counts[5],
      entityCountsByType: _mapEntityTypeCounts(grouped[0]),
      entityCountsByMastery: _mapMasteryCounts(grouped[1]),
      eventCountsByType: _mapEventTypeCounts(grouped[2]),
      sourceCountsByAvailability: _mapSourceAvailabilityCounts(grouped[3]),
    );
  }

  Future<List<MemorySourceRecord>> sources({
    SourceKind? sourceKind,
    SourceAvailability? availability,
    String? query,
    int limit = defaultLimit,
    int offset = 0,
    String? languageCode,
  }) async {
    final rows = await _dao.inspectorSources(
      language: _language(languageCode),
      sourceKind: sourceKind?.storageValue,
      availability: availability?.storageValue,
      query: query,
      limit: _limit(limit),
      offset: _offset(offset),
    );
    return rows.map(_sourceRecordFromEntry).toList(growable: false);
  }

  Future<List<MemoryKnowledgeEntity>> entities({
    KnowledgeEntityType? type,
    KnowledgeMasteryState? masteryState,
    String? query,
    int limit = defaultLimit,
    int offset = 0,
    String? languageCode,
  }) async {
    final rows = await _dao.inspectorEntities(
      language: _language(languageCode),
      type: type?.storageValue,
      masteryState: masteryState?.storageValue,
      query: query,
      limit: _limit(limit),
      offset: _offset(offset),
    );
    return rows.map(_entityFromEntry).toList(growable: false);
  }

  Future<List<MemoryKnowledgeEvidence>> evidences({
    String? sourceId,
    SourceKind? sourceKind,
    SourceAvailability? sourceAvailability,
    String? query,
    int limit = defaultLimit,
    int offset = 0,
    String? languageCode,
  }) async {
    final rows = await _dao.inspectorEvidences(
      language: _language(languageCode),
      sourceId: _trimmed(sourceId),
      sourceKind: sourceKind?.storageValue,
      sourceAvailability: sourceAvailability?.storageValue,
      query: query,
      limit: _limit(limit),
      offset: _offset(offset),
    );
    return rows.map(_evidenceFromEntry).toList(growable: false);
  }

  Future<List<MemoryEvent>> events({
    MemoryEventType? type,
    String? sourceId,
    String? query,
    int limit = defaultLimit,
    int offset = 0,
    String? languageCode,
  }) async {
    final rows = await _dao.inspectorEvents(
      language: _language(languageCode),
      eventType: type?.storageValue,
      sourceId: _trimmed(sourceId),
      query: query,
      limit: _limit(limit),
      offset: _offset(offset),
    );
    return rows.map(_eventFromEntry).toList(growable: false);
  }

  Future<ReadingMemoryEntityDetail?> entityDetail(
    String entityId, {
    int limit = 20,
  }) async {
    final entityRow = await _dao.entityById(entityId);
    if (entityRow == null) return null;
    final safeLimit = _limit(limit);
    final rows = await Future.wait<List<Object>>([
      _dao.explanationsForEntity(entityId, limit: safeLimit),
      _dao.evidencesForEntity(entityId, limit: safeLimit),
      _dao.inspectorEventsForEntity(entityId, limit: safeLimit),
      _dao.inspectorReviewCandidatesForEntity(entityId, limit: safeLimit),
    ]);

    return ReadingMemoryEntityDetail(
      entity: _entityFromEntry(entityRow),
      explanations: rows[0]
          .cast<KnowledgeExplanationEntry>()
          .map(_explanationFromEntry)
          .toList(growable: false),
      evidences: rows[1]
          .cast<KnowledgeEvidenceEntry>()
          .map(_evidenceFromEntry)
          .toList(growable: false),
      recentEvents: rows[2]
          .cast<MemoryEventEntry>()
          .map(_eventFromEntry)
          .toList(growable: false),
      reviewCandidates: rows[3]
          .cast<ReviewCandidateEntry>()
          .map(_reviewCandidateFromEntry)
          .toList(growable: false),
    );
  }

  String _language(String? languageCode) {
    return normalizeRepositoryLanguageCode(languageCode ?? _languageCode);
  }

  static int _limit(int value) {
    return value.clamp(1, maxLimit).toInt();
  }

  static int _offset(int value) {
    return value < 0 ? 0 : value;
  }

  static String? _trimmed(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static Map<KnowledgeEntityType, int> _mapEntityTypeCounts(
    Map<String, int> raw,
  ) {
    return {
      for (final entry in raw.entries)
        KnowledgeEntityType.fromStorage(entry.key): entry.value,
    };
  }

  static Map<KnowledgeMasteryState, int> _mapMasteryCounts(
    Map<String, int> raw,
  ) {
    return {
      for (final entry in raw.entries)
        KnowledgeMasteryState.fromStorage(entry.key): entry.value,
    };
  }

  static Map<MemoryEventType, int> _mapEventTypeCounts(Map<String, int> raw) {
    return {
      for (final entry in raw.entries)
        MemoryEventType.fromStorage(entry.key): entry.value,
    };
  }

  static Map<SourceAvailability, int> _mapSourceAvailabilityCounts(
    Map<String, int> raw,
  ) {
    return {
      for (final entry in raw.entries)
        SourceAvailability.fromStorage(entry.key): entry.value,
    };
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

  static DateTime _decodeDate(String value) {
    return DateTime.parse(value).toUtc();
  }

  static DateTime? _decodeNullableDate(String? value) {
    return value == null ? null : _decodeDate(value);
  }
}

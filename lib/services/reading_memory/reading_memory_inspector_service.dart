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

final class ReadingMemorySourceDetail {
  const ReadingMemorySourceDetail({
    required this.source,
    required this.entities,
    required this.evidences,
    required this.recentEvents,
  });

  final MemorySourceRecord source;
  final List<MemoryKnowledgeEntity> entities;
  final List<MemoryKnowledgeEvidence> evidences;
  final List<MemoryEvent> recentEvents;
}

final class ReadingMemoryHealthCheck {
  const ReadingMemoryHealthCheck({
    required this.code,
    required this.title,
    required this.description,
    required this.count,
    required this.sampleIds,
  });

  final String code;
  final String title;
  final String description;
  final int count;
  final List<String> sampleIds;

  bool get hasIssues => count > 0;
}

final class ReadingMemoryHealthCheckDetail {
  const ReadingMemoryHealthCheckDetail({
    required this.check,
    required this.issues,
  });

  final ReadingMemoryHealthCheck check;
  final List<ReadingMemoryHealthIssue> issues;
}

final class ReadingMemoryHealthIssue {
  const ReadingMemoryHealthIssue({
    required this.recordKind,
    required this.recordId,
    required this.summary,
    required this.fields,
  });

  final String recordKind;
  final String recordId;
  final String summary;
  final Map<String, String> fields;
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

  Future<ReadingMemorySourceDetail?> sourceDetail(
    String sourceId, {
    int limit = 20,
    String? languageCode,
  }) async {
    final language = _language(languageCode);
    final sourceRow = await _dao.sourceRecord(sourceId);
    if (sourceRow == null || sourceRow.language != language) return null;
    final safeLimit = _limit(limit);
    final rows = await Future.wait<List<Object>>([
      _dao.inspectorEntitiesForSource(
        language: language,
        sourceId: sourceId,
        limit: safeLimit,
      ),
      _dao.inspectorEvidences(
        language: language,
        sourceId: sourceId,
        limit: safeLimit,
      ),
      _dao.inspectorEvents(
        language: language,
        sourceId: sourceId,
        limit: safeLimit,
      ),
    ]);

    return ReadingMemorySourceDetail(
      source: _sourceRecordFromEntry(sourceRow),
      entities: rows[0]
          .cast<KnowledgeEntityEntry>()
          .map(_entityFromEntry)
          .toList(growable: false),
      evidences: rows[1]
          .cast<KnowledgeEvidenceEntry>()
          .map(_evidenceFromEntry)
          .toList(growable: false),
      recentEvents: rows[2]
          .cast<MemoryEventEntry>()
          .map(_eventFromEntry)
          .toList(growable: false),
    );
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

  Future<List<ReadingMemoryHealthCheck>> healthChecks({
    int sampleLimit = 5,
    String? languageCode,
  }) async {
    final language = _language(languageCode);
    final limit = _limit(sampleLimit);
    final counts = await Future.wait<int>([
      _dao.inspectorOrphanEvidenceEntityCount(language: language),
      _dao.inspectorOrphanEventEntityCount(language: language),
      _dao.inspectorMissingEvidenceSourceCount(language: language),
      _dao.inspectorMissingEventSourceCount(language: language),
      _dao.inspectorDeletedSourceSnippetCount(language: language),
    ]);
    final samples = await Future.wait<List<String>>([
      _dao.inspectorOrphanEvidenceEntityIds(
        language: language,
        limit: limit,
      ),
      _dao.inspectorOrphanEventEntityIds(
        language: language,
        limit: limit,
      ),
      _dao.inspectorMissingEvidenceSourceIds(
        language: language,
        limit: limit,
      ),
      _dao.inspectorMissingEventSourceIds(
        language: language,
        limit: limit,
      ),
      _dao.inspectorDeletedSourceSnippetIds(
        language: language,
        limit: limit,
      ),
    ]);

    return [
      ReadingMemoryHealthCheck(
        code: 'orphan_evidence_entity',
        title: '证据缺失实体',
        description: 'knowledge_evidences.entity_id 指向不存在的实体。',
        count: counts[0],
        sampleIds: samples[0],
      ),
      ReadingMemoryHealthCheck(
        code: 'orphan_event_entity',
        title: '事件缺失实体',
        description: 'memory_events.entity_id 指向不存在的实体。',
        count: counts[1],
        sampleIds: samples[1],
      ),
      ReadingMemoryHealthCheck(
        code: 'missing_evidence_source',
        title: '证据缺失来源',
        description: 'knowledge_evidences.source_id 指向不存在的来源记录。',
        count: counts[2],
        sampleIds: samples[2],
      ),
      ReadingMemoryHealthCheck(
        code: 'missing_event_source',
        title: '事件缺失来源',
        description: 'memory_events.source_id 指向不存在的来源记录。',
        count: counts[3],
        sampleIds: samples[3],
      ),
      ReadingMemoryHealthCheck(
        code: 'deleted_source_retains_snippet',
        title: '删除来源仍保留摘录',
        description: 'source_availability=deleted 的证据仍保留 short_excerpt。',
        count: counts[4],
        sampleIds: samples[4],
      ),
    ];
  }

  Future<ReadingMemoryHealthCheckDetail?> healthCheckDetail(
    String code, {
    int limit = 20,
    String? languageCode,
  }) async {
    final trimmedCode = code.trim();
    final language = _language(languageCode);
    final safeLimit = _limit(limit);
    final checks = await healthChecks(
      sampleLimit: safeLimit,
      languageCode: language,
    );
    final matching = checks.where((check) => check.code == trimmedCode);
    if (matching.isEmpty) return null;
    final check = matching.single;
    final issues = switch (trimmedCode) {
      'orphan_evidence_entity' =>
        (await _dao.inspectorOrphanEvidenceEntityRows(
          language: language,
          limit: safeLimit,
        )).map(
          (row) => _healthIssueFromEvidence(
            row,
            recordKind: 'evidence',
            summaryFallback: '证据缺失实体',
          ),
        ),
      'orphan_event_entity' =>
        (await _dao.inspectorOrphanEventEntityRows(
          language: language,
          limit: safeLimit,
        )).map(
          (row) => _healthIssueFromEvent(
            row,
            recordKind: 'event',
            summaryFallback: '事件缺失实体',
          ),
        ),
      'missing_evidence_source' =>
        (await _dao.inspectorMissingEvidenceSourceRows(
          language: language,
          limit: safeLimit,
        )).map(
          (row) => _healthIssueFromEvidence(
            row,
            recordKind: 'evidence',
            summaryFallback: '证据缺失来源',
          ),
        ),
      'missing_event_source' =>
        (await _dao.inspectorMissingEventSourceRows(
          language: language,
          limit: safeLimit,
        )).map(
          (row) => _healthIssueFromEvent(
            row,
            recordKind: 'event',
            summaryFallback: '事件缺失来源',
          ),
        ),
      'deleted_source_retains_snippet' =>
        (await _dao.inspectorDeletedSourceSnippetRows(
          language: language,
          limit: safeLimit,
        )).map(
          (row) => _healthIssueFromEvidence(
            row,
            recordKind: 'evidence',
            summaryFallback: '删除来源仍保留摘录',
          ),
        ),
      _ => const Iterable<ReadingMemoryHealthIssue>.empty(),
    };

    return ReadingMemoryHealthCheckDetail(
      check: check,
      issues: issues.toList(growable: false),
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

  static ReadingMemoryHealthIssue _healthIssueFromEvidence(
    KnowledgeEvidenceEntry row, {
    required String recordKind,
    required String summaryFallback,
  }) {
    return ReadingMemoryHealthIssue(
      recordKind: recordKind,
      recordId: row.id,
      summary: _firstNonEmpty([
        row.shortExcerpt,
        row.sourceTitleSnapshot,
      ], summaryFallback),
      fields: {
        'entityId': row.entityId,
        if (_hasText(row.sourceId)) 'sourceId': row.sourceId!,
        'sourceKind': row.sourceKind,
        'sourceAvailability': row.sourceAvailability,
        'retentionPolicy': row.retentionPolicy,
        if (_hasText(row.sourceTitleSnapshot))
          'sourceTitle': row.sourceTitleSnapshot,
        if (_hasText(row.locationLocator)) 'locator': row.locationLocator!,
        if (_hasText(row.bookId)) 'bookId': row.bookId!,
      },
    );
  }

  static ReadingMemoryHealthIssue _healthIssueFromEvent(
    MemoryEventEntry row, {
    required String recordKind,
    required String summaryFallback,
  }) {
    return ReadingMemoryHealthIssue(
      recordKind: recordKind,
      recordId: row.id,
      summary: _firstNonEmpty([
        row.targetText,
        row.canonicalKey,
      ], summaryFallback),
      fields: {
        'eventType': row.eventType,
        'language': row.language,
        if (_hasText(row.entityId)) 'entityId': row.entityId!,
        if (_hasText(row.sourceId)) 'sourceId': row.sourceId!,
        if (_hasText(row.canonicalKey)) 'canonicalKey': row.canonicalKey,
        if (_hasText(row.sourceRefJson)) 'sourceRef': row.sourceRefJson,
        if (_hasText(row.metadataJson)) 'metadata': row.metadataJson,
      },
    );
  }

  static String _firstNonEmpty(List<String?> values, String fallback) {
    for (final value in values) {
      if (_hasText(value)) return value!.trim();
    }
    return fallback;
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static DateTime _decodeDate(String value) {
    return DateTime.parse(value).toUtc();
  }

  static DateTime? _decodeNullableDate(String? value) {
    return value == null ? null : _decodeDate(value);
  }
}

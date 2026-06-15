import '../../models/reading_memory.dart';
import '../../storage/repositories/reading_memory_repository.dart';
import '../../storage/repositories/repository_language.dart';
import 'knowledge_retention_service.dart';
import 'reading_memory_ids.dart';

class SourceScopeService {
  SourceScopeService({
    required ReadingMemoryRepository repository,
    String? languageCode,
    DateTime Function()? clock,
  }) : _repository = repository,
       _languageCode = normalizeRepositoryLanguageCode(languageCode),
       _clock = clock ?? DateTime.now,
       _retention = KnowledgeRetentionService(
         repository: repository,
         clock: clock,
       );

  final ReadingMemoryRepository _repository;
  final String _languageCode;
  final DateTime Function() _clock;
  final KnowledgeRetentionService _retention;

  Future<void> init() {
    return _repository.init();
  }

  Future<MemorySourceRecord> upsertBookSource({
    required String bookId,
    required String title,
    String? author,
    String? fingerprint,
    String? languageCode,
  }) {
    return upsertSource(
      sourceId: ReadingMemoryIds.source(SourceKind.book, bookId),
      sourceKind: SourceKind.book,
      titleSnapshot: title,
      authorSnapshot: author,
      fingerprint: fingerprint,
      languageCode: languageCode,
    );
  }

  Future<MemorySourceRecord> upsertRssSource({
    required String articleId,
    required String title,
    String? author,
    String? fingerprint,
    String? languageCode,
  }) {
    return upsertSource(
      sourceId: ReadingMemoryIds.source(SourceKind.rss, articleId),
      sourceKind: SourceKind.rss,
      titleSnapshot: title,
      authorSnapshot: author,
      fingerprint: fingerprint,
      languageCode: languageCode,
    );
  }

  Future<MemorySourceRecord> upsertSource({
    required String sourceId,
    required SourceKind sourceKind,
    required String titleSnapshot,
    String? authorSnapshot,
    String? fingerprint,
    String? languageCode,
  }) async {
    final now = _clock().toUtc();
    final existing = await _repository.sourceRecord(sourceId);
    final record = MemorySourceRecord(
      id: sourceId,
      sourceKind: sourceKind,
      titleSnapshot: titleSnapshot.trim(),
      authorSnapshot: _trimOrNull(authorSnapshot),
      languageCode: normalizeRepositoryLanguageCode(
        languageCode ?? existing?.languageCode ?? _languageCode,
      ),
      fingerprint: _trimOrNull(fingerprint) ?? existing?.fingerprint,
      availability: existing?.availability ?? SourceAvailability.available,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      deletedAt: existing?.deletedAt,
    );
    await _repository.upsertSourceRecord(record);
    return record;
  }

  Future<SourceScopeCacheItem> upsertSourceScopeCache({
    required String sourceId,
    required String cacheType,
    required String payload,
    EvidenceRetentionPolicy retentionPolicy =
        EvidenceRetentionPolicy.deleteWithSource,
    String? cacheId,
  }) async {
    final item = SourceScopeCacheItem(
      id: _cacheId(sourceId: sourceId, cacheType: cacheType, cacheId: cacheId),
      sourceId: sourceId,
      cacheType: cacheType.trim(),
      payload: payload,
      retentionPolicy: retentionPolicy,
      updatedAt: _clock().toUtc(),
    );
    await _repository.upsertSourceScopeCache(item);
    return item;
  }

  Future<List<SourceScopeCacheItem>> sourceScopeCacheForSource(
    String sourceId, {
    String? cacheType,
    int limit = 50,
  }) {
    return _repository.sourceScopeCacheForSource(
      sourceId,
      cacheType: cacheType,
      limit: limit,
    );
  }

  Future<void> clearSourceScopeCache(
    String sourceId, {
    EvidenceRetentionPolicy? retentionPolicy,
  }) {
    return _repository.deleteSourceScopeCacheForSource(
      sourceId,
      retentionPolicy: retentionPolicy,
    );
  }

  Future<void> archiveSource(String sourceId) {
    return _retention.archiveSource(sourceId);
  }

  Future<void> deleteSourceKeepLearningMemory(
    String sourceId, {
    EvidenceRetentionPolicy evidencePolicy =
        EvidenceRetentionPolicy.keepSnippet,
  }) {
    return _retention.deleteSourceKeepLearningMemory(
      sourceId,
      evidencePolicy: evidencePolicy,
    );
  }

  Future<void> deleteSourceAndRelatedMemory(String sourceId) {
    return _retention.deleteSourceAndRelatedMemory(sourceId);
  }

  Future<void> deleteBookSourceKeepLearningMemory(
    String bookId, {
    EvidenceRetentionPolicy evidencePolicy =
        EvidenceRetentionPolicy.keepSnippet,
  }) {
    return deleteSourceKeepLearningMemory(
      ReadingMemoryIds.source(SourceKind.book, bookId),
      evidencePolicy: evidencePolicy,
    );
  }

  Future<void> deleteBookSourceAndRelatedMemory(String bookId) {
    return deleteSourceAndRelatedMemory(
      ReadingMemoryIds.source(SourceKind.book, bookId),
    );
  }

  static String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String _cacheId({
    required String sourceId,
    required String cacheType,
    String? cacheId,
  }) {
    final trimmedCacheId = cacheId?.trim();
    if (trimmedCacheId != null && trimmedCacheId.isNotEmpty) {
      return trimmedCacheId;
    }
    return [
      'source_scope_cache',
      Uri.encodeComponent(sourceId.trim()),
      Uri.encodeComponent(cacheType.trim()),
    ].join(':');
  }
}

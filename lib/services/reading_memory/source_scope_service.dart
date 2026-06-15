import '../../models/reading_memory.dart';
import '../../storage/repositories/reading_memory_repository.dart';
import '../../storage/repositories/repository_language.dart';
import 'reading_memory_ids.dart';

class SourceScopeService {
  SourceScopeService({
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

  Future<void> archiveSource(String sourceId) {
    return _repository.updateSourceAvailability(
      sourceId: sourceId,
      availability: SourceAvailability.archived,
    );
  }

  Future<void> deleteSourceKeepLearningMemory(String sourceId) {
    return _repository.updateSourceAvailability(
      sourceId: sourceId,
      availability: SourceAvailability.deleted,
      deletedAt: _clock().toUtc(),
    );
  }

  Future<void> deleteBookSourceKeepLearningMemory(String bookId) {
    return deleteSourceKeepLearningMemory(
      ReadingMemoryIds.source(SourceKind.book, bookId),
    );
  }

  static String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

import 'package:drift/drift.dart';

import '../../../models/user_vocabulary.dart' as models;
import '../app_database.dart';
import '../dao/user_vocabulary_dao.dart';
import '../../repositories/repository_language.dart';
import '../../repositories/user_vocabulary_repository.dart';

final class DriftUserVocabularyRepository implements UserVocabularyRepository {
  DriftUserVocabularyRepository(
    this._dao, {
    required String languageCode,
    Map<String, models.UserWordStatus> initialValues = const {},
  }) : _languageCode = normalizeRepositoryLanguageCode(languageCode),
       _cache = Map.of(initialValues);

  final UserVocabularyDao _dao;
  final String _languageCode;
  final Map<String, models.UserWordStatus> _cache;

  @override
  Future<void> init() async {
    final values = await _dao.allWords(_languageCode);
    _cache
      ..clear()
      ..addEntries(
        values.entries.map(
          (entry) => MapEntry(
            _normalize(entry.key),
            _statusFromName(entry.value),
          ),
        ),
      );
  }

  @override
  models.UserWordStatus? getStatus(String word) => _cache[_normalize(word)];

  @override
  Set<String> wordsWithStatus(models.UserWordStatus status) {
    return {
      for (final entry in _cache.entries)
        if (entry.value == status) entry.key,
    };
  }

  @override
  Map<String, models.UserWordStatus> get allWords => Map.unmodifiable(_cache);

  @override
  Future<void> setStatus(String word, models.UserWordStatus status) async {
    final canonical = _normalize(word);
    if (canonical.isEmpty) return;
    await _dao.upsert(
      UserVocabulariesCompanion.insert(
        id: _storageKey(canonical),
        canonical: canonical,
        status: status.name,
        language: Value(_languageCode),
      ),
    );
    _cache[canonical] = status;
  }

  @override
  Future<void> remove(String word) async {
    final canonical = _normalize(word);
    if (canonical.isEmpty) return;
    await _dao.deleteById(_storageKey(canonical));
    _cache.remove(canonical);
  }

  @override
  Future<void> close() async {}

  String _storageKey(String canonical) {
    return models.UserVocabularyKey(
      languageId: _languageCode,
      canonical: canonical,
    ).storageKey;
  }

  static String _normalize(String word) => word.toLowerCase().trim();

  static models.UserWordStatus _statusFromName(String value) {
    return value == models.UserWordStatus.learning.name
        ? models.UserWordStatus.learning
        : models.UserWordStatus.known;
  }
}

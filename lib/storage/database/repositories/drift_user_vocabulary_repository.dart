import '../app_database.dart';
import '../dao/user_vocabulary_dao.dart';

final class DriftUserVocabularyRepository {
  final UserVocabularyDao _dao;

  DriftUserVocabularyRepository(this._dao);

  Future<UserVocabulary?> entryFor(String id) => _dao.entryFor(id);

  Future<List<UserVocabulary>> wordsWithStatus(String language, String status) =>
      _dao.wordsWithStatus(language, status);

  Future<Map<String, String>> allWords(String language) =>
      _dao.allWords(language);

  Future<void> upsert(UserVocabulariesCompanion entry) => _dao.upsert(entry);

  Future<void> deleteById(String id) => _dao.deleteById(id);

  Future<void> clearForLanguage(String language) =>
      _dao.clearForLanguage(language);
}

import '../dao/word_context_dao.dart';

final class DriftWordContextRepository {
  final WordContextDao _dao;

  DriftWordContextRepository(this._dao);

  Future<String?> dataFor(String word, String language) =>
      _dao.dataFor(word, language);

  Future<void> putData(String word, String language, String data) =>
      _dao.putData(word, language, data);

  Future<void> deleteByWord(String word, String language) =>
      _dao.deleteByWord(word, language);

  Future<void> clearForLanguage(String language) =>
      _dao.clearForLanguage(language);
}

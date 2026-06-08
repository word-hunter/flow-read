import '../dao/reading_time_dao.dart';

final class DriftReadingTimeRepository {
  final ReadingTimeDao _dao;

  DriftReadingTimeRepository(this._dao);

  Future<int> secondsFor(String key, String language) =>
      _dao.secondsFor(key, language);

  Future<void> putSeconds(String key, String language, int seconds) =>
      _dao.putSeconds(key, language, seconds);

  Future<int> totalSeconds(String language) =>
      _dao.totalSecondsForLanguage(language);
}

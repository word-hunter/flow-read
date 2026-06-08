import '../app_database.dart';
import '../dao/learning_analytics_dao.dart';

final class DriftLearningAnalyticsRepository {
  final LearningAnalyticsDao _dao;

  DriftLearningAnalyticsRepository(this._dao);

  Future<int> valueFor(String key, String language) =>
      _dao.valueFor(key, language);

  Future<void> putValue(String key, String language, int value) =>
      _dao.putValue(key, language, value);

  Future<List<LearningAnalyticsEntry>> allForLanguage(String language) =>
      _dao.allForLanguage(language);
}

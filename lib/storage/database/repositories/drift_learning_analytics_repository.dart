import '../dao/learning_analytics_dao.dart';
import '../../repositories/hive_repository_box.dart';
import '../../repositories/learning_analytics_repository.dart';

final class DriftLearningAnalyticsRepository
    implements LearningAnalyticsRepository {
  DriftLearningAnalyticsRepository(
    this._dao, {
    required String languageCode,
    Map<String, int> initialValues = const {},
  }) : _languageCode = activeHiveLanguageCode(languageCode),
       _cache = Map.of(initialValues);

  final LearningAnalyticsDao _dao;
  final String _languageCode;
  final Map<String, int> _cache;

  @override
  Future<void> init() async {
    final values = await _dao.allValues(_languageCode);
    _cache
      ..clear()
      ..addAll(values);
  }

  @override
  int countFor(String key) => _cache[key] ?? 0;

  @override
  Iterable<String> get keys => _cache.keys;

  @override
  Future<void> putCount(String key, int count) async {
    await _dao.putValue(key, _languageCode, count);
    _cache[key] = count;
  }

  @override
  Future<void> close() async {}
}

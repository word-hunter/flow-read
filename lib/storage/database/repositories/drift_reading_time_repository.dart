import '../dao/reading_time_dao.dart';
import '../../repositories/hive_repository_box.dart';
import '../../repositories/reading_time_repository.dart';

final class DriftReadingTimeRepository implements ReadingTimeRepository {
  DriftReadingTimeRepository(
    this._dao, {
    required String languageCode,
    Map<String, int> initialValues = const {},
  }) : _languageCode = activeHiveLanguageCode(languageCode),
       _cache = Map.of(initialValues);

  final ReadingTimeDao _dao;
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
  int secondsFor(String key) => _cache[key] ?? 0;

  @override
  Future<void> putSeconds(String key, int seconds) async {
    await _dao.putSeconds(key, _languageCode, seconds);
    _cache[key] = seconds;
  }

  @override
  Future<void> close() async {}
}

import 'package:hive/hive.dart';

import '../hive_box_names.dart';
import 'hive_repository_box.dart';

abstract class LearningAnalyticsRepository {
  Future<void> init();
  int countFor(String key);
  Iterable<String> get keys;
  Future<void> putCount(String key, int count);
  Future<void> close();
}

class HiveLearningAnalyticsRepository implements LearningAnalyticsRepository {
  HiveLearningAnalyticsRepository({Box<int>? box, String? languageCode})
    : _box = box,
      _languageCode = activeHiveLanguageCode(languageCode);

  Box<int>? _box;
  final String _languageCode;

  Box<int> get _storage {
    return _box ??
        requireOpenHiveBox<int>(
          HiveBoxNames.learningAnalyticsFor(_languageCode),
        );
  }

  @override
  Future<void> init() async {
    _box ??= requireOpenHiveBox<int>(
      HiveBoxNames.learningAnalyticsFor(_languageCode),
    );
  }

  @override
  int countFor(String key) {
    return _storage.get(key, defaultValue: 0) ?? 0;
  }

  @override
  Iterable<String> get keys => _storage.keys.map((key) => key.toString());

  @override
  Future<void> putCount(String key, int count) async {
    await _storage.put(key, count);
  }

  @override
  Future<void> close() async {}
}

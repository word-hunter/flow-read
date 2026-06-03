import 'package:hive/hive.dart';

import '../hive_box_names.dart';
import 'hive_repository_box.dart';

abstract class ReadingTimeRepository {
  Future<void> init();
  int secondsFor(String key);
  Future<void> putSeconds(String key, int seconds);
  Future<void> close();
}

class HiveReadingTimeRepository implements ReadingTimeRepository {
  HiveReadingTimeRepository({Box<int>? box, String? languageCode})
    : _box = box,
      _languageCode = activeHiveLanguageCode(languageCode);

  Box<int>? _box;
  final String _languageCode;

  Box<int> get _storage =>
      _box ??
      requireOpenHiveBox<int>(HiveBoxNames.readingTimeFor(_languageCode));

  @override
  Future<void> init() async {
    _box ??= requireOpenHiveBox<int>(
      HiveBoxNames.readingTimeFor(_languageCode),
    );
  }

  @override
  int secondsFor(String key) {
    return _storage.get(key, defaultValue: 0) ?? 0;
  }

  @override
  Future<void> putSeconds(String key, int seconds) async {
    await _storage.put(key, seconds);
  }

  @override
  Future<void> close() async {}
}

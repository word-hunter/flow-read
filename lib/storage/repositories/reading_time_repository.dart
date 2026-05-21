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
  HiveReadingTimeRepository({Box<int>? box}) : _box = box;

  Box<int>? _box;

  Box<int> get _storage =>
      _box ?? requireOpenHiveBox<int>(HiveBoxNames.readingTime);

  @override
  Future<void> init() async {
    _box ??= requireOpenHiveBox<int>(HiveBoxNames.readingTime);
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

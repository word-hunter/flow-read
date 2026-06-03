import 'package:hive/hive.dart';

import '../hive_box_names.dart';
import 'hive_repository_box.dart';

abstract class ReadingConfigRepository {
  Future<void> init();
  String getString(String key, {required String defaultValue});
  Future<void> putString(String key, String value);
  Future<void> close();
}

class HiveReadingConfigRepository implements ReadingConfigRepository {
  HiveReadingConfigRepository({Box<String>? box, String? languageCode})
    : _box = box,
      _languageCode = activeHiveLanguageCode(languageCode);

  Box<String>? _box;
  final String _languageCode;

  Box<String> get _storage =>
      _box ??
      requireOpenHiveBox<String>(HiveBoxNames.readingConfigFor(_languageCode));

  @override
  Future<void> init() async {
    _box ??= requireOpenHiveBox<String>(
      HiveBoxNames.readingConfigFor(_languageCode),
    );
  }

  @override
  String getString(String key, {required String defaultValue}) {
    return _storage.get(key, defaultValue: defaultValue) ?? defaultValue;
  }

  @override
  Future<void> putString(String key, String value) async {
    await _storage.put(key, value);
  }

  @override
  Future<void> close() async {}
}

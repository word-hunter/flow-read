import 'package:hive/hive.dart';

import '../../storage/hive_box_names.dart';

class DictionaryCacheService {
  Box<String>? _box;

  static const int _maxEntries = 500;

  Future<void> init() async {
    _box = await Hive.openBox<String>(HiveBoxNames.dictionaryCache);
  }

  String? get(String source, String word) {
    return _box?.get('${source}_$word');
  }

  Future<void> set(String source, String word, String content) async {
    final box = _box;
    if (box == null) return;

    final key = '${source}_$word';
    await box.put(key, content);

    if (box.length > _maxEntries) {
      final keysToRemove = box.keys.take(box.length - _maxEntries).toList();
      for (final k in keysToRemove) {
        await box.delete(k);
      }
    }
  }

  bool hasWord(String source, String word) {
    return _box?.containsKey('${source}_$word') ?? false;
  }

  Future<void> clear() async {
    await _box?.clear();
  }
}

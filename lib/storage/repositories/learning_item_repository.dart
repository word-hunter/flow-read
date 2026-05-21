import 'package:hive/hive.dart';

import '../../models/learning_item.dart';
import '../hive_box_names.dart';
import 'hive_repository_box.dart';

abstract class LearningItemRepository {
  Future<void> init();
  Iterable<LearningItem> get values;
  Iterable<dynamic> get keys;
  int get length;
  LearningItem? get(dynamic key);
  Future<void> put(String id, LearningItem item);
  Future<void> delete(String id);
  Future<void> deleteAll(Iterable<dynamic> keys);
  Future<void> clear();
  Future<void> close();
}

class HiveLearningItemRepository implements LearningItemRepository {
  HiveLearningItemRepository({Box<LearningItem>? box}) : _box = box;

  Box<LearningItem>? _box;

  Box<LearningItem> get _storage {
    return _box ?? requireOpenHiveBox<LearningItem>(HiveBoxNames.learningItems);
  }

  @override
  Future<void> init() async {
    _box ??= requireOpenHiveBox<LearningItem>(HiveBoxNames.learningItems);
  }

  @override
  Iterable<LearningItem> get values => _storage.values;

  @override
  Iterable<dynamic> get keys => _storage.keys;

  @override
  int get length => _storage.length;

  @override
  LearningItem? get(dynamic key) => _storage.get(key);

  @override
  Future<void> put(String id, LearningItem item) async {
    await _storage.put(id, item);
  }

  @override
  Future<void> delete(String id) async {
    await _storage.delete(id);
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    await _storage.deleteAll(keys);
  }

  @override
  Future<void> clear() async {
    await _storage.clear();
  }

  @override
  Future<void> close() async {}
}

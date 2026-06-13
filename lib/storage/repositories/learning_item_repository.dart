import '../../models/learning_item.dart';

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

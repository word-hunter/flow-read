abstract class DictionaryCacheRepository {
  Future<void> init();
  String? get(String key);
  Future<void> put(String key, String content);
  bool containsKey(String key);
  int get length;
  Iterable<dynamic> get keys;
  Future<void> delete(dynamic key);
  Future<void> clear();
  Future<void> close();
}

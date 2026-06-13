abstract class LearningAnalyticsRepository {
  Future<void> init();
  int countFor(String key);
  Iterable<String> get keys;
  Future<void> putCount(String key, int count);
  Future<void> close();
}

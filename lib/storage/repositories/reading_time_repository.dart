abstract class ReadingTimeRepository {
  Future<void> init();
  int secondsFor(String key);
  Future<void> putSeconds(String key, int seconds);
  Future<void> close();
}

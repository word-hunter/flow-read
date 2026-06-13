abstract class ReadingConfigRepository {
  Future<void> init();
  String getString(String key, {required String defaultValue});
  Future<void> putString(String key, String value);
  Future<void> close();
}

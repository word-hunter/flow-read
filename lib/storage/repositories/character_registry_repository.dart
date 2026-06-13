abstract class CharacterRegistryRepository {
  Future<void> init();
  String? valueFor(String key);
  Future<void> putValue(String key, String value);
  Future<void> delete(String key);
  Future<void> close();
}

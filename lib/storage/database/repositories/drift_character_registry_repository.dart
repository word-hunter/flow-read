import '../dao/character_registry_dao.dart';
import '../../repositories/character_registry_repository.dart';

final class DriftCharacterRegistryRepository
    implements CharacterRegistryRepository {
  DriftCharacterRegistryRepository(
    this._dao, {
    Map<String, String> initialValues = const {},
  }) : _cache = Map.of(initialValues);

  final CharacterRegistryDao _dao;
  final Map<String, String> _cache;

  @override
  Future<void> init() async {
    final values = await _dao.allEntries();
    _cache
      ..clear()
      ..addAll(values);
  }

  @override
  String? valueFor(String key) => _cache[key];

  @override
  Future<void> putValue(String key, String value) async {
    await _dao.putValue(key, value);
    _cache[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    await _dao.deleteByKey(key);
    _cache.remove(key);
  }

  @override
  Future<void> close() async {}
}

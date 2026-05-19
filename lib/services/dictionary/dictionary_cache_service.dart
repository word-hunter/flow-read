import '../../storage/repositories/dictionary_cache_repository.dart';

class DictionaryCacheService {
  DictionaryCacheService({DictionaryCacheRepository? repository})
    : _repository = repository ?? HiveDictionaryCacheRepository();

  final DictionaryCacheRepository _repository;
  bool _initialized = false;

  static const int _maxEntries = 500;

  Future<void> init() async {
    await _repository.init();
    _initialized = true;
  }

  String? get(String source, String word) {
    if (!_initialized) return null;
    return _repository.get(_cacheKey(source, word));
  }

  Future<void> set(String source, String word, String content) async {
    if (!_initialized) return;

    await _repository.put(_cacheKey(source, word), content);

    if (_repository.length > _maxEntries) {
      final keysToRemove = _repository.keys
          .take(_repository.length - _maxEntries)
          .toList();
      for (final k in keysToRemove) {
        await _repository.delete(k);
      }
    }
  }

  bool hasWord(String source, String word) {
    if (!_initialized) return false;
    return _repository.containsKey(_cacheKey(source, word));
  }

  Future<void> clear() async {
    if (!_initialized) return;
    await _repository.clear();
  }

  String _cacheKey(String source, String word) => '${source}_$word';
}

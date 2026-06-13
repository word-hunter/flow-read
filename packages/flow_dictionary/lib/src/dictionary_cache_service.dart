import 'dictionary_cache_repository.dart';

String _normalizeLanguageCode(String? code) {
  final c = code?.trim().toLowerCase() ?? '';
  return c.isEmpty ? 'en' : c;
}

class DictionaryCacheService {
  DictionaryCacheService({
    required DictionaryCacheRepository repository,
    String? languageCode,
  }) : languageCode = _normalizeLanguageCode(languageCode),
       _repository = repository;

  final String languageCode;
  final DictionaryCacheRepository _repository;
  bool _initialized = false;

  static const int _maxEntries = 500;

  Future<void> init() async {
    await _repository.init();
    _initialized = true;
  }

  String? get(String source, String word, {String languageCode = 'en'}) {
    if (!_initialized) return null;
    return _repository.get(_cacheKey(source, word));
  }

  int get entryCount => _initialized ? _repository.length : 0;

  Future<void> set(
    String source,
    String word,
    String content, {
    String languageCode = 'en',
  }) async {
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

  bool hasWord(String source, String word, {String languageCode = 'en'}) {
    if (!_initialized) return false;
    return _repository.containsKey(_cacheKey(source, word));
  }

  Future<void> clear() async {
    if (!_initialized) return;
    await _repository.clear();
  }

  String _cacheKey(String source, String word) => '${source}_$word';
}

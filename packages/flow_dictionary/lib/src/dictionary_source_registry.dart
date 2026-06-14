import 'collins_repository.dart';
import 'dictionary_cache_service.dart';
import 'dictionary_manager_service.dart';
import 'dictionary_repository.dart';
import 'dictionary_source_config.dart';
import 'jpdb_repository.dart';
import 'longman_repository.dart';
import 'word_repository.dart';
import 'wordnet_repository.dart';

class DictionarySourceRegistry {
  DictionarySourceRegistry({required DictionaryCacheService cache})
    : _cache = cache;

  final DictionaryCacheService _cache;
  late final List<DictionarySourceAdapter> _adapters = List.unmodifiable([
    for (final source in _sources)
      DictionarySourceAdapter(
        type: source.type,
        repository: source.createRepository(_cache),
      ),
  ]);

  static final List<_DictionarySourceRegistration> _sources = List.unmodifiable(
    [
      _DictionarySourceRegistration(
        type: DictionarySourceType.collins,
        createRepository: (cache) => CollinsRepository(cache),
      ),
      _DictionarySourceRegistration(
        type: DictionarySourceType.wordNet,
        createRepository: (_) => WordNetRepository(),
      ),
      _DictionarySourceRegistration(
        type: DictionarySourceType.dictionaryApi,
        createRepository: (_) => DictionaryRepository(),
      ),
      _DictionarySourceRegistration(
        type: DictionarySourceType.longman,
        createRepository: (cache) => LongmanRepository(cache),
      ),
      _DictionarySourceRegistration(
        type: DictionarySourceType.jpdb,
        createRepository: (cache) => JpdbRepository(cache),
      ),
    ],
  );

  static final List<DictionarySourceType> sourceTypes = List.unmodifiable([
    for (final source in _sources) source.type,
  ]);

  Future<void> init() => _cache.init();

  List<DictionarySourceAdapter> adapters() => _adapters;

  Map<DictionarySourceType, WordRepository> repositories() => {
    for (final adapter in _adapters) adapter.type: adapter.repository,
  };
}

typedef _DictionaryRepositoryFactory =
    WordRepository Function(DictionaryCacheService cache);

class _DictionarySourceRegistration {
  const _DictionarySourceRegistration({
    required this.type,
    required this.createRepository,
  });

  final DictionarySourceType type;
  final _DictionaryRepositoryFactory createRepository;
}

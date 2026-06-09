import 'dictionary_source_config.dart';
import 'word_repository.dart';

class DictionarySourceAdapter {
  final DictionarySourceType type;
  final WordRepository repository;

  const DictionarySourceAdapter({required this.type, required this.repository});
}

class DictionaryManagerService implements WordRepository {
  final List<DictionarySourceConfig> _configs;
  final Map<DictionarySourceType, WordRepository> _repositories;

  DictionaryManagerService({
    required List<DictionarySourceConfig> configs,
    required List<DictionarySourceAdapter> sources,
  }) : _configs = List.unmodifiable(configs),
       _repositories = {
         for (final source in sources) source.type: source.repository,
       };

  List<DictionarySourceConfig> get activeSources => _configs
      .where((config) => config.enabled)
      .where((config) => _repositories.containsKey(config.type))
      .toList(growable: false);

  List<DictionarySourceConfig> activeSourcesFor(String languageCode) =>
      activeSources
          .where((config) => config.supportsLanguage(languageCode))
          .toList(growable: false);

  @override
  Future<DictionaryEntry?> lookup(
    String word, {
    String languageCode = 'en',
  }) async {
    final query = word.toLowerCase().trim();
    if (query.isEmpty) return null;

    final failures = <String>[];
    final sources = activeSourcesFor(languageCode);
    if (sources.isEmpty) {
      return DictionaryEntry(
        word: query,
        meanings: const [],
        errorMessage: '未启用支持 $languageCode 的词典来源',
      );
    }

    for (final config in sources) {
      final repository = _repositories[config.type];
      if (repository == null) continue;

      try {
        final entry = await repository.lookup(
          query,
          languageCode: languageCode,
        );
        if (entry == null || entry.isEmpty) continue;
        return entry.copyWith(
          sourceName: entry.sourceName ?? config.type.label,
          errorMessage: _mergeErrors(entry.errorMessage, failures),
        );
      } catch (error) {
        failures.add('${config.type.label}: $error');
      }
    }

    if (failures.isNotEmpty) {
      return DictionaryEntry(
        word: query,
        meanings: const [],
        errorMessage: failures.join('\n'),
      );
    }
    return null;
  }

  String? _mergeErrors(String? entryError, List<String> failures) {
    final messages = <String>[
      ...failures,
      if (entryError != null && entryError.trim().isNotEmpty) entryError.trim(),
    ];
    if (messages.isEmpty) return null;
    return messages.join('\n');
  }
}

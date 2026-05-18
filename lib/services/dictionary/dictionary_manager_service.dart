import 'dictionary_source_config.dart';
import '../settings_service.dart';
import 'word_repository.dart';

class DictionarySourceAdapter {
  final DictionarySourceType type;
  final WordRepository repository;

  const DictionarySourceAdapter({required this.type, required this.repository});
}

class DictionaryManagerService implements WordRepository {
  final SettingsService _settings;
  final Map<DictionarySourceType, WordRepository> _repositories;

  DictionaryManagerService({
    required SettingsService settings,
    required List<DictionarySourceAdapter> sources,
  }) : _settings = settings,
       _repositories = {
         for (final source in sources) source.type: source.repository,
       };

  List<DictionarySourceConfig> get activeSources => _settings.dictionarySources
      .where((config) => config.enabled)
      .where((config) => _repositories.containsKey(config.type))
      .toList(growable: false);

  @override
  Future<DictionaryEntry?> lookup(String word) async {
    final query = word.toLowerCase().trim();
    if (query.isEmpty) return null;

    final failures = <String>[];
    final sources = activeSources;
    if (sources.isEmpty) {
      return DictionaryEntry(
        word: query,
        meanings: const [],
        errorMessage: '未启用词典来源',
      );
    }

    for (final config in sources) {
      final repository = _repositories[config.type];
      if (repository == null) continue;

      try {
        final entry = await repository.lookup(query);
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

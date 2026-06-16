import 'dart:async';

import 'dictionary_source_config.dart';
import 'word_repository.dart';

class DictionarySourceAdapter {
  final DictionarySourceType type;
  final WordRepository repository;

  const DictionarySourceAdapter({required this.type, required this.repository});
}

class DictionaryManagerService implements WordRepository {
  static const defaultSourceTimeout = Duration(seconds: 6);

  final List<DictionarySourceConfig> _configs;
  final Map<DictionarySourceType, WordRepository> _repositories;
  final Duration _sourceTimeout;

  DictionaryManagerService({
    required List<DictionarySourceConfig> configs,
    required List<DictionarySourceAdapter> sources,
    Duration sourceTimeout = defaultSourceTimeout,
  }) : _configs = List.unmodifiable(configs),
       _repositories = {
         for (final source in sources) source.type: source.repository,
       },
       _sourceTimeout = sourceTimeout;

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
        final entry = await _lookupSource(
          config,
          repository,
          query,
          languageCode: languageCode,
        );
        if (entry == null || entry.isEmpty) continue;
        return entry.copyWith(
          sourceName: entry.sourceName ?? config.type.label,
          errorMessage: _mergeErrors(
            entry.errorMessage,
            failures,
            isLocalFallback: failures.isNotEmpty && !config.type.online,
          ),
        );
      } catch (error) {
        failures.add('${config.type.label}: ${_formatError(error)}');
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

  String? _mergeErrors(
    String? entryError,
    List<String> failures, {
    required bool isLocalFallback,
  }) {
    final messages = <String>[
      if (isLocalFallback) '在线词典请求失败，可重试。已先显示本地 WordNet 释义。',
      ...failures,
      if (entryError != null && entryError.trim().isNotEmpty) entryError.trim(),
    ];
    if (messages.isEmpty) return null;
    return messages.join('\n');
  }

  Future<DictionaryEntry?> _lookupSource(
    DictionarySourceConfig config,
    WordRepository repository,
    String query, {
    required String languageCode,
  }) {
    final lookup = repository.lookup(query, languageCode: languageCode);
    if (!config.type.online) return lookup;
    return lookup.timeout(_sourceTimeout);
  }

  String _formatError(Object error) {
    if (error is TimeoutException) return '请求超时';
    if (error is DictionaryLookupException) return error.message;
    final text = error.toString().trim();
    if (text.isEmpty) return '未知错误';
    return text;
  }
}

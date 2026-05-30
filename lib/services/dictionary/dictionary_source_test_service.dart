import 'dictionary_source_config.dart';
import 'word_repository.dart';

enum DictionarySourceTestStatus { hit, noResult, failed }

class DictionarySourceTestResult {
  const DictionarySourceTestResult({
    required this.type,
    required this.word,
    required this.status,
    required this.elapsed,
    this.fromCache = false,
    this.message,
  });

  final DictionarySourceType type;
  final String word;
  final DictionarySourceTestStatus status;
  final Duration elapsed;
  final bool fromCache;
  final String? message;
}

class DictionarySourceTestService {
  const DictionarySourceTestService({required this.repositories});

  final Map<DictionarySourceType, WordRepository> repositories;

  Future<Map<DictionarySourceType, DictionarySourceTestResult>> testSources(
    Iterable<DictionarySourceType> types,
    String word,
  ) async {
    final results = <DictionarySourceType, DictionarySourceTestResult>{};
    for (final type in types) {
      results[type] = await testSource(type, word);
    }
    return results;
  }

  Future<DictionarySourceTestResult> testSource(
    DictionarySourceType type,
    String word,
  ) async {
    final query = _normalizeWord(word);
    final stopwatch = Stopwatch()..start();
    try {
      final repository = repositories[type];
      if (repository == null) {
        stopwatch.stop();
        return DictionarySourceTestResult(
          type: type,
          word: query,
          status: DictionarySourceTestStatus.failed,
          elapsed: stopwatch.elapsed,
          message: '来源未配置',
        );
      }

      final entry = await repository.lookup(query);
      stopwatch.stop();
      if (entry != null && !entry.isEmpty) {
        return DictionarySourceTestResult(
          type: type,
          word: query,
          status: DictionarySourceTestStatus.hit,
          elapsed: stopwatch.elapsed,
          fromCache: entry.fromCache,
        );
      }
      return DictionarySourceTestResult(
        type: type,
        word: query,
        status: DictionarySourceTestStatus.noResult,
        elapsed: stopwatch.elapsed,
      );
    } catch (error) {
      stopwatch.stop();
      return DictionarySourceTestResult(
        type: type,
        word: query,
        status: DictionarySourceTestStatus.failed,
        elapsed: stopwatch.elapsed,
        message: _formatError(error),
      );
    }
  }

  String _normalizeWord(String word) {
    final query = word.trim().toLowerCase();
    return query.isEmpty ? 'flow' : query;
  }

  String _formatError(Object error) {
    final text = error.toString().trim();
    if (text.isEmpty) return '未知错误';
    return text.length <= 80 ? text : '${text.substring(0, 80)}...';
  }
}

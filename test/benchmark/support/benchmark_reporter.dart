import 'dart:convert';
import 'dart:io';

import 'benchmark_runner.dart';

class BenchmarkReporter {
  static const resultsPath = '.benchmark/current-run.jsonl';

  static void report(String key, BenchmarkResult result) {
    final dir = Directory('.benchmark');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final line = jsonEncode({
      'key': key,
      'iterations': result.iterations,
      'warmup': result.warmup,
      'mean_ms': result.meanMs,
      'median_ms': result.medianMs,
      'min_ms': result.minMs,
      'max_ms': result.maxMs,
      'p90_ms': result.p90Ms,
      'p99_ms': result.p99Ms,
      'stddev_ms': result.stddevMs,
    });

    final file = File(resultsPath);
    if (file.existsSync()) {
      file.writeAsStringSync('$line\n', mode: FileMode.append);
    } else {
      file.writeAsStringSync('$line\n');
    }
  }

  static void clearRun() {
    final file = File(resultsPath);
    if (file.existsSync()) file.deleteSync();
  }

  static List<Map<String, dynamic>> loadCurrentRun() {
    final file = File(resultsPath);
    if (!file.existsSync()) return [];
    return file
        .readAsLinesSync()
        .where((l) => l.trim().isNotEmpty)
        .map((l) => jsonDecode(l) as Map<String, dynamic>)
        .toList();
  }
}

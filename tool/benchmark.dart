import 'dart:convert';
import 'dart:io';

import '../test/benchmark/support/benchmark_reporter.dart';

const _benchmarkDir = '.benchmark';
const _historyPath = '.benchmark/history/records.jsonl';
const _baselinePath = '.benchmark/baseline.json';
const _dataJsPath = '.benchmark/data.js';
const _assetsDir = 'tool/benchmark_assets';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.first == '--help' || args.first == '-h') {
    _printUsage();
    return;
  }

  try {
    switch (args.first) {
      case 'run':
        await _run();
      case 'baseline-lock':
        _baselineLock();
      case 'baseline-reset':
        _baselineReset();
      case 'baseline-show':
        _baselineShow();
      case 'trend':
        _trend(args.skip(1).toList());
      case 'open':
        await _open();
      default:
        throw _UsageException('Unknown command: ${args.first}');
    }
  } on _UsageException catch (e) {
    stderr.writeln('Error: ${e.message}');
    exitCode = 1;
  }
}

void _printUsage() {
  stdout.writeln('''
Flow Read Benchmark Tool

Usage: dart run tool/benchmark.dart <command> [options]

Commands:
  run                 Run benchmarks, save results, generate report
  baseline-lock       Lock current baseline (prevent auto-update)
  baseline-reset      Reset baseline
  baseline-show       Show baseline entries
  open                Open benchmark report in browser (starts local server)
  trend [options]     Show historical trend in terminal

Trend options:
  --file <id>         Filter by file ID
  --bench <name>      Filter by benchmark name
  --last <n>          Show last N records (default: 10)
''');
}

Future<void> _run() async {
  stdout.writeln('Running benchmark suite...\n');

  final testDir = Directory('.benchmark-test-files');
  final epubNames = <String>[];
  if (testDir.existsSync()) {
    epubNames.addAll(
      testDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.epub'))
          .map((f) {
            final name = f.uri.pathSegments.last.replaceAll('.epub', '');
            final sizeMb = (f.lengthSync() / (1024 * 1024)).toStringAsFixed(1);
            return '  $name ($sizeMb MB)';
          }),
    );
  }

  if (epubNames.isEmpty) {
    stdout.writeln('No EPUB files found in .benchmark-test-files/');
    stdout.writeln('Put EPUB files there and run again.');
    return;
  }

  stdout.writeln('Test files found:');
  for (final name in epubNames) {
    stdout.writeln(name);
  }

  final currentRunFile = File(BenchmarkReporter.resultsPath);
  if (currentRunFile.existsSync()) currentRunFile.deleteSync();

  stdout.writeln('\nRunning benchmarks...\n');

  final process = await Process.start(
    'flutter',
    ['test', 'test/benchmark/', '--tags', 'benchmark', '--concurrency=1'],
    workingDirectory: Directory.current.path,
  );

  var testCount = 0;
  var passedCount = 0;
  var skippedCount = 0;

  await for (final line
      in process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
    final trimmed = line.trim();
    if (trimmed.startsWith('+') || trimmed.startsWith('~')) continue;
    if (trimmed.startsWith('00:')) {
      testCount++;
      if (trimmed.contains(' Skip')) {
        skippedCount++;
      } else if (trimmed.contains(' +')) {
        passedCount++;
      }
    }
    stdout.writeln('  $trimmed');
  }

  final exitCode = await process.exitCode;
  final stderrOutput = await process.stderr.transform(utf8.decoder).join();

  if (exitCode != 0) {
    if (stderrOutput.isNotEmpty) stderr.write(stderrOutput);
    throw _UsageException('Benchmark tests failed with exit code $exitCode');
  }

  stdout.writeln(
    '\nTests: $testCount total, $passedCount passed, $skippedCount skipped',
  );

  final results = BenchmarkReporter.loadCurrentRun();
  if (results.isEmpty) {
    stdout.writeln('No benchmark results collected.');
    return;
  }

  stdout.writeln('Computing scores...');
  _maybeUpdateBaseline(results);
  final record = _buildRecord(results);

  _saveHistory(record);

  stdout.writeln('Generating report...');
  _copyAssets();
  _generateDataJs();

  stdout.writeln('\nReport: $_benchmarkDir/');
  stdout.writeln('Open with: dart run tool/benchmark.dart open');
  stdout.writeln('Total score: ${record['total_score']}');

  if (record['regressions'] != null &&
      (record['regressions'] as List).isNotEmpty) {
    stdout.writeln('Regressions detected:');
    for (final r in record['regressions'] as List) {
      stdout.writeln('  ⚠️  $r');
    }
  }
}

Map<String, dynamic> _buildRecord(List<Map<String, dynamic>> results) {
  final baseline = _loadBaseline();
  final fileData = <String, Map<String, dynamic>>{};
  var totalWeightedScore = 0.0;
  var totalWeight = 0.0;
  final regressions = <String>[];

  for (final r in results) {
    final key = r['key'] as String;
    final keyParts = _splitBenchmarkKey(key);
    final fileId = keyParts[0];
    final bench = keyParts[1];
    final medianMs = (r['median_ms'] as num?)?.toDouble() ??
        (r['mean_ms'] as num).toDouble();

    final baselineMs = baseline[key];
    double score = 100.0;
    if (baselineMs != null && baselineMs > 0 && medianMs > baselineMs) {
      final ratio = (medianMs - baselineMs) / baselineMs;
      if (ratio > 0.05) {
        score = (100 - ratio * 100).clamp(0, 100).toDouble();
      }
      if (score < 70) {
        regressions.add(
          '$key: score ${score.toStringAsFixed(0)} (${medianMs.toStringAsFixed(0)}ms vs baseline ${baselineMs.toStringAsFixed(0)}ms)',
        );
      }
    }

    fileData.putIfAbsent(
      fileId,
      () => <String, dynamic>{
        'items': <String, dynamic>{},
      },
    );
    (fileData[fileId]!['items'] as Map)[bench] = {
      'mean_ms': r['mean_ms'],
      'median_ms': r['median_ms'],
      'p90_ms': r['p90_ms'],
      'score': score,
      'baseline_ms': baselineMs,
    };
  }

  for (final entry in fileData.entries) {
    final items = entry.value['items'] as Map<String, dynamic>;
    var fileScore = 0.0;
    var itemCount = 0;
    for (final item in items.values) {
      fileScore += (item as Map)['score'] as double;
      itemCount++;
    }
    final avgScore = itemCount > 0 ? fileScore / itemCount : 100.0;
    entry.value['score'] = avgScore;

    const fileWeights = <String, double>{};
    final weight = fileWeights[entry.key] ?? 1.0;
    totalWeightedScore += avgScore * weight;
    totalWeight += weight;
  }

  return {
    'ts': DateTime.now().toUtc().toIso8601String(),
    'total_score': totalWeight > 0
        ? (totalWeightedScore / totalWeight).toStringAsFixed(1)
        : '100.0',
    'files': fileData,
    'regressions': regressions,
  };
}

void _copyAssets() {
  final src = Directory(_assetsDir);
  if (!src.existsSync()) return;

  final dst = Directory(_benchmarkDir);
  if (!dst.existsSync()) dst.createSync(recursive: true);

  for (final file in src.listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    file.copySync('${dst.path}/$name');
  }
}

void _generateDataJs() {
  final baseline = _loadBaseline();
  final historyLines = <String>[];
  final historyFile = File(_historyPath);
  if (historyFile.existsSync()) {
    historyLines.addAll(
      historyFile.readAsLinesSync().where((l) => l.trim().isNotEmpty),
    );
  }

  final buf = StringBuffer();
  buf.writeln('window.__BENCHMARK_DATA__ = {');
  buf.writeln('  baselines: ${jsonEncode(baseline)},');
  buf.writeln('  history: [${historyLines.join(',')}],');
  buf.writeln(
    '  meta: { generated_at: "${DateTime.now().toUtc().toIso8601String()}" }',
  );
  buf.writeln('};');

  File(_dataJsPath).writeAsStringSync(buf.toString());
}

void _saveHistory(Map<String, dynamic> record) {
  final dir = Directory('.benchmark/history');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  final line = jsonEncode({
    'ts': record['ts'],
    'total_score': record['total_score'],
    'files': record['files'],
  });

  final file = File(_historyPath);
  if (file.existsSync()) {
    file.writeAsStringSync('$line\n', mode: FileMode.append);
  } else {
    file.writeAsStringSync('$line\n');
  }
}

void _maybeUpdateBaseline(List<Map<String, dynamic>> results) {
  final resultMeans = _resultMeansByKey(results);
  final resultMedians = _resultMediansByKey(results);
  if (resultMeans.isEmpty) return;

  final file = File(_baselinePath);
  if (!file.existsSync()) {
    stdout.writeln(
      'No baseline found. Creating initial baseline from current run...',
    );
    _writeBaselineJson({
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'locked': false,
      'entries': resultMeans.map(
        (k, v) => MapEntry(k, {
          'mean_ms': v,
          'median_ms': resultMedians[k],
          'weight': 1.0,
        }),
      ),
    });
    return;
  }

  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final entries =
      json['entries'] as Map<String, dynamic>? ?? <String, dynamic>{};
  json['entries'] = entries;

  final missingKeys =
      resultMeans.keys.where((key) => !entries.containsKey(key)).toList()
        ..sort();
  if (missingKeys.isEmpty) return;

  if (json['locked'] == true) {
    stdout.writeln(
      'Baseline locked. ${missingKeys.length} new benchmark entries were not added.',
    );
    return;
  }

  final firstHistoryMeans = _firstHistoryMeansForKeys(missingKeys.toSet());
  for (final key in missingKeys) {
    entries[key] = {
      'mean_ms': firstHistoryMeans[key] ?? resultMeans[key]!,
      'median_ms': resultMedians[key],
      'weight': 1.0,
    };
  }
  json['updated_at'] = DateTime.now().toUtc().toIso8601String();

  _writeBaselineJson(json);
  stdout.writeln('Added ${missingKeys.length} new baseline entries.');
}

void _writeBaselineJson(Map<String, dynamic> json) {
  final dir = Directory(_benchmarkDir);
  if (!dir.existsSync()) dir.createSync(recursive: true);
  File(_baselinePath).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(json),
  );
}

Map<String, double> _resultMeansByKey(List<Map<String, dynamic>> results) {
  return {
    for (final r in results)
      r['key'] as String: (r['mean_ms'] as num).toDouble(),
  };
}

Map<String, double> _resultMediansByKey(List<Map<String, dynamic>> results) {
  return {
    for (final r in results)
      r['key'] as String: (r['median_ms'] as num?)?.toDouble() ??
          (r['mean_ms'] as num).toDouble(),
  };
}

Map<String, double> _firstHistoryMeansForKeys(Set<String> keys) {
  final file = File(_historyPath);
  if (!file.existsSync() || keys.isEmpty) return {};

  final means = <String, double>{};
  final remaining = keys.toSet();
  for (final line in file.readAsLinesSync()) {
    if (line.trim().isEmpty) continue;
    final record = jsonDecode(line) as Map<String, dynamic>;
    final files = record['files'] as Map<String, dynamic>? ?? {};

    for (final key in remaining.toList()) {
      final parts = _splitBenchmarkKey(key);
      final fileData = files[parts[0]] as Map<String, dynamic>?;
      final items = fileData?['items'] as Map<String, dynamic>?;
      final item = items?[parts[1]] as Map<String, dynamic>?;
      final meanMs = item?['mean_ms'];
      if (meanMs is num) {
        means[key] = meanMs.toDouble();
        remaining.remove(key);
      }
    }
    if (remaining.isEmpty) break;
  }
  return means;
}

List<String> _splitBenchmarkKey(String key) {
  final parts = key.split(':');
  return [parts.first, parts.skip(1).join(':')];
}

Map<String, double> _loadBaseline() {
  final file = File(_baselinePath);
  if (!file.existsSync()) return {};
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final entries = json['entries'] as Map<String, dynamic>? ?? {};
  return entries.map((k, v) {
    final e = v as Map<String, dynamic>;
    final median = e['median_ms'];
    final mean = e['mean_ms'] as num;
    return MapEntry(k, (median is num ? median : mean).toDouble());
  });
}

void _baselineLock() {
  final file = File(_baselinePath);
  if (!file.existsSync()) {
    throw _UsageException('No baseline exists. Run benchmarks first.');
  }
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  json['locked'] = true;
  File(_baselinePath).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(json),
  );
  stdout.writeln('Baseline locked.');
}

void _baselineReset() {
  final file = File(_baselinePath);
  if (file.existsSync()) {
    file.deleteSync();
    stdout.writeln('Baseline deleted.');
  } else {
    stdout.writeln('No baseline found.');
  }
}

void _baselineShow() {
  final baseline = _loadBaseline();
  if (baseline.isEmpty) {
    stdout.writeln('No baseline entries.');
    return;
  }
  final file = File(_baselinePath);
  var locked = false;
  if (file.existsSync()) {
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    locked = json['locked'] == true;
  }
  stdout.writeln('Baseline${locked ? ' (LOCKED)' : ''}:');
  final sortedKeys = baseline.keys.toList()..sort();
  for (final key in sortedKeys) {
    stdout.writeln(
      '  ${key.padRight(50)} ${baseline[key]!.toStringAsFixed(1).padLeft(8)}ms',
    );
  }
}

void _trend(List<String> args) {
  String? fileId;
  String? benchName;
  var last = 10;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--file':
        fileId = args[++i];
      case '--bench':
        benchName = args[++i];
      case '--last':
        last = int.tryParse(args[++i]) ?? 10;
      default:
        throw _UsageException('Unknown option: ${args[i]}');
    }
  }

  final file = File(_historyPath);
  if (!file.existsSync()) {
    stdout.writeln('No history found.');
    return;
  }

  final lines = file
      .readAsLinesSync()
      .where((l) => l.trim().isNotEmpty)
      .toList();
  final records = lines.take(last).toList().reversed.toList();

  for (final line in records) {
    final r = jsonDecode(line) as Map<String, dynamic>;
    stdout.writeln('${r['ts']}  Total: ${r['total_score']}');
    final files = r['files'] as Map<String, dynamic>;
    for (final f in files.entries) {
      if (fileId != null && f.key != fileId) continue;
      final fd = f.value as Map<String, dynamic>;
      if (benchName != null) {
        final items = fd['items'] as Map<String, dynamic>? ?? {};
        for (final item in items.entries) {
          final im = item.value as Map<String, dynamic>;
          stdout.writeln(
            '  ${f.key}:${item.key}  score=${(im['score'] as num).toStringAsFixed(0)}  ${(im['mean_ms'] as num).toStringAsFixed(0)}ms',
          );
        }
      } else {
        stdout.writeln(
          '  ${f.key}  score=${(fd['score'] as num).toStringAsFixed(1)}',
        );
      }
    }
  }
}

Future<void> _open() async {
  _ensureReport();

  final dir = Directory(_benchmarkDir).absolute;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final port = server.port;

  stdout.writeln('Benchmark report server started at http://localhost:$port');
  stdout.writeln('Press Ctrl+C to stop.\n');

  // Open browser
  try {
    if (Platform.isMacOS) {
      await Process.run('open', ['http://localhost:$port']);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', ['http://localhost:$port']);
    } else if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', 'http://localhost:$port']);
    }
  } catch (_) {}

  await for (final request in server) {
    try {
      final path = request.uri.path == '/' ? '/index.html' : request.uri.path;
      final file = File('${dir.path}$path');

      if (file.existsSync() && !file.path.contains('..')) {
        final ext = path.split('.').last;
        final contentType = _contentType(ext);
        request.response
          ..headers.contentType = contentType
          ..add(file.readAsBytesSync());
      } else {
        request.response.statusCode = 404;
      }
    } catch (_) {
      request.response.statusCode = 500;
    }
    await request.response.close();
  }
}

void _ensureReport() {
  final indexFile = File('$_benchmarkDir/index.html');
  if (!indexFile.existsSync()) {
    final historyFile = File(_historyPath);
    if (!historyFile.existsSync()) {
      throw _UsageException(
        'No benchmark history found. Run "dart run tool/benchmark.dart run" first.',
      );
    }
    stdout.writeln('Generating report from existing history...');
    _copyAssets();
    _generateDataJs();
  }
}

ContentType _contentType(String ext) {
  switch (ext) {
    case 'html':
      return ContentType.html;
    case 'css':
      return ContentType('text', 'css', charset: 'utf-8');
    case 'js':
      return ContentType('application', 'javascript', charset: 'utf-8');
    case 'json':
      return ContentType.json;
    case 'png':
      return ContentType('image', 'png');
    case 'svg':
      return ContentType('image', 'svg+xml');
    default:
      return ContentType.text;
  }
}

class _UsageException implements Exception {
  final String message;
  const _UsageException(this.message);
}

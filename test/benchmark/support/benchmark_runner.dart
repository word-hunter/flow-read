import 'dart:async';
import 'dart:developer';
import 'dart:math';

class BenchmarkResult {
  final String name;
  final int iterations;
  final int warmup;
  final List<double> timingsMs;
  final double minMs;
  final double maxMs;
  final double meanMs;
  final double medianMs;
  final double p90Ms;
  final double p99Ms;
  final double stddevMs;
  final double? baselineMeanMs;
  final double score;

  const BenchmarkResult({
    required this.name,
    required this.iterations,
    required this.warmup,
    required this.timingsMs,
    required this.minMs,
    required this.maxMs,
    required this.meanMs,
    required this.medianMs,
    required this.p90Ms,
    required this.p99Ms,
    required this.stddevMs,
    this.baselineMeanMs,
    this.score = 100.0,
  });
}

BenchmarkResult runBenchmark({
  required String name,
  required FutureOr<void> Function() fn,
  int iterations = 30,
  int warmup = 5,
  bool verbose = true,
}) {
  final timingsMs = <double>[];

  // Warmup
  for (var i = 0; i < warmup; i++) {
    final task = TimelineTask(filterKey: '$name:warmup $i');
    task.start('$name:warmup $i');
    fn();
    task.finish();
  }

  // Timed iterations
  final stopwatch = Stopwatch();
  for (var i = 0; i < iterations; i++) {
    final task = TimelineTask(filterKey: '$name:$i');
    task.start('$name:$i');
    stopwatch.start();
    fn();
    stopwatch.stop();
    task.finish();
    final elapsedMs = stopwatch.elapsedMicroseconds / 1000.0;
    stopwatch.reset();
    timingsMs.add(elapsedMs);
    if (verbose) {
      // ignore: avoid_print
      print('    [$name] iter ${i + 1}/$iterations  ${elapsedMs.toStringAsFixed(0)}ms');
    }
  }

  timingsMs.sort();
  final n = timingsMs.length;

  return BenchmarkResult(
    name: name,
    iterations: n,
    warmup: warmup,
    timingsMs: List.unmodifiable(timingsMs),
    minMs: timingsMs.first,
    maxMs: timingsMs.last,
    meanMs: timingsMs.reduce((a, b) => a + b) / n,
    medianMs: _percentile(timingsMs, 0.5),
    p90Ms: _percentile(timingsMs, 0.9),
    p99Ms: _percentile(timingsMs, 0.99),
    stddevMs: _stddev(timingsMs),
  );
}

Future<BenchmarkResult> runBenchmarkAsync({
  required String name,
  required FutureOr<void> Function() fn,
  int iterations = 30,
  int warmup = 5,
  bool verbose = true,
}) async {
  final timingsMs = <double>[];

  for (var i = 0; i < warmup; i++) {
    final task = TimelineTask(filterKey: '$name:warmup $i');
    task.start('$name:warmup $i');
    await fn();
    task.finish();
  }

  final stopwatch = Stopwatch();
  for (var i = 0; i < iterations; i++) {
    final task = TimelineTask(filterKey: '$name:$i');
    task.start('$name:$i');
    stopwatch.start();
    await fn();
    stopwatch.stop();
    task.finish();
    final elapsedMs = stopwatch.elapsedMicroseconds / 1000.0;
    stopwatch.reset();
    timingsMs.add(elapsedMs);
    if (verbose) {
      // ignore: avoid_print
      print('    [$name] iter ${i + 1}/$iterations  ${elapsedMs.toStringAsFixed(0)}ms');
    }
  }

  timingsMs.sort();
  final n = timingsMs.length;

  return BenchmarkResult(
    name: name,
    iterations: n,
    warmup: warmup,
    timingsMs: List.unmodifiable(timingsMs),
    minMs: timingsMs.first,
    maxMs: timingsMs.last,
    meanMs: timingsMs.reduce((a, b) => a + b) / n,
    medianMs: _percentile(timingsMs, 0.5),
    p90Ms: _percentile(timingsMs, 0.9),
    p99Ms: _percentile(timingsMs, 0.99),
    stddevMs: _stddev(timingsMs),
  );
}

double _percentile(List<double> sorted, double p) {
  if (sorted.isEmpty) return 0;
  final index = (p * (sorted.length - 1)).round().clamp(0, sorted.length - 1);
  return sorted[index];
}

double _stddev(List<double> values) {
  if (values.length < 2) return 0;
  final mean = values.reduce((a, b) => a + b) / values.length;
  final variance =
      values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
          (values.length - 1);
  return sqrt(variance);
}

import 'benchmark_baseline.dart';
import 'benchmark_history.dart';
import 'benchmark_runner.dart';

class BenchmarkSuiteResult {
  final double totalScore;
  final Map<String, FileScore> fileScores;
  final String details;
  final List<String> warnings;
  final List<String> errors;

  const BenchmarkSuiteResult({
    required this.totalScore,
    required this.fileScores,
    required this.details,
    this.warnings = const [],
    this.errors = const [],
  });
}

class FileScore {
  final double score;
  final Map<String, double> itemScores;

  const FileScore({required this.score, required this.itemScores});
}

class BenchmarkScoreCalculator {
  final Baseline baseline;
  final Map<String, double> fileWeights;

  BenchmarkScoreCalculator({
    Baseline? baseline,
    this.fileWeights = const {},
  }) : baseline = baseline ?? Baseline.load();

  double computeItemScore(
    BenchmarkResult result,
    String key, {
    double? weight,
  }) {
    return baseline.computeScore(result, key, weight: weight);
  }

  FileScore computeFileScore(
    Map<String, BenchmarkResult> results,
    String fileId,
    double fileWeight,
  ) {
    var weightedSum = 0.0;
    var totalWeight = 0.0;
    final itemScores = <String, double>{};

    for (final entry in results.entries) {
      final key = '$fileId:${entry.key}';
      final entryWeight =
          baseline.entryFor(key)?.weight ?? 1.0;
      final score = computeItemScore(entry.value, key, weight: entryWeight);
      itemScores[key] = score;
      weightedSum += score * entryWeight;
      totalWeight += entryWeight;
    }

    final fileScore = totalWeight > 0 ? weightedSum / totalWeight : 100.0;
    return FileScore(score: fileScore, itemScores: itemScores);
  }

  BenchmarkSuiteResult computeSuite(
    Map<String, Map<String, BenchmarkResult>> allResults,
    Map<String, double> fileWeights,
  ) {
    var totalWeightedSum = 0.0;
    var totalWeight = 0.0;
    final fileScores = <String, FileScore>{};
    final warnings = <String>[];
    final errors = <String>[];

    for (final fileEntry in allResults.entries) {
      final fileId = fileEntry.key;
      final results = fileEntry.value;
      final fWeight = fileWeights[fileId] ?? 1.0;
      final fileScore = computeFileScore(results, fileId, fWeight);

      fileScores[fileId] = fileScore;
      totalWeightedSum += fileScore.score * fWeight;
      totalWeight += fWeight;

      for (final itemEntry in fileScore.itemScores.entries) {
        final s = itemEntry.value;
        if (s < 50) {
          errors.add('$fileId:${itemEntry.key} severely regressed (score: ${s.toStringAsFixed(1)})');
        }
      }

      if (fileScore.score < 70) {
        errors.add('$fileId severely regressed (file score: ${fileScore.score.toStringAsFixed(1)})');
      }
    }

    final totalScore = totalWeight > 0 ? totalWeightedSum / totalWeight : 100.0;

    if (totalScore < 85) {
      errors.add('Total score ${totalScore.toStringAsFixed(1)} < 85 — regression detected');
    } else if (totalScore < 90) {
      warnings.add('Total score ${totalScore.toStringAsFixed(1)} — below 90 threshold');
    }

    final details = _formatReport(fileScores, allResults, totalScore,
        warnings, errors, fileWeights);

    return BenchmarkSuiteResult(
      totalScore: totalScore,
      fileScores: fileScores,
      details: details,
      warnings: warnings,
      errors: errors,
    );
  }

  String _formatReport(
    Map<String, FileScore> fileScores,
    Map<String, Map<String, BenchmarkResult>> allResults,
    double totalScore,
    List<String> warnings,
    List<String> errors,
    Map<String, double> fileWeights,
  ) {
    final buf = StringBuffer();

    for (final fileEntry in allResults.entries) {
      final fileId = fileEntry.key;
      final results = fileEntry.value;
      final fScore = fileScores[fileId];
      final weight = fileWeights[fileId] ?? 1.0;

      buf.writeln('── $fileId ── weight: $weight ── SCORE: ${fScore?.score.toStringAsFixed(1) ?? 'N/A'} ──');
      buf.writeln();

      for (final resultEntry in results.entries) {
        final key = resultEntry.key;
        final r = resultEntry.value;
        final baselineEntry = baseline.entryFor('$fileId:$key');
        final itemScore = fScore?.itemScores['$fileId:$key'] ?? 100.0;

        final baselineStr = baselineEntry != null
            ? 'baseline: ${baselineEntry.meanMs.toStringAsFixed(0)}ms, '
            : 'no baseline';
        final deltaStr = baselineEntry != null
            ? '${((r.meanMs - baselineEntry.meanMs) / baselineEntry.meanMs * 100).toStringAsFixed(1)}%'
            : 'N/A';
        final trendIcon = baselineEntry != null && r.meanMs <= baselineEntry.meanMs
            ? '+'
            : (itemScore >= 90 ? '~' : '-');
        final scoreLabel = itemScore >= 100 ? '  100' : itemScore.toStringAsFixed(1).padLeft(5);

        buf.writeln(
          '  ${key.padRight(28)} ${r.meanMs.toStringAsFixed(0).padLeft(6)}ms  '
          '($baselineStr$deltaStr)  $trendIcon  $scoreLabel',
        );
      }
      buf.writeln();
    }

    buf.writeln('═' * 72);
    buf.writeln('  TOTAL SCORE: ${totalScore.toStringAsFixed(1)}');

    if (warnings.isNotEmpty) {
      buf.writeln('  Warnings:');
      for (final w in warnings) {
        buf.writeln('    ⚠️  $w');
      }
    }
    if (errors.isNotEmpty) {
      buf.writeln('  Errors:');
      for (final e in errors) {
        buf.writeln('    ❌ $e');
      }
    }
    buf.writeln('═' * 72);

    return buf.toString();
  }
}

void expectBenchmarkScore(
  BenchmarkSuiteResult suite, {
  int minTotalScore = 70,
}) {
  BenchmarkHistory.append(
    BenchmarkRecord(
      ts: DateTime.now().toUtc().toIso8601String(),
      totalScore: suite.totalScore,
      files: suite.fileScores.map(
        (k, v) => MapEntry(k, {
          'score': v.score,
          'items': v.itemScores,
        }),
      ),
    ),
  );

  if (suite.totalScore < minTotalScore) {
    throw Exception(
      'Benchmark regression: total score ${suite.totalScore.toStringAsFixed(1)} < $minTotalScore\n'
      '${suite.details}',
    );
  }
}

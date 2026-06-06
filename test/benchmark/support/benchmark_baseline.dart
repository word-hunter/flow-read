import 'dart:convert';
import 'dart:io';

import 'benchmark_runner.dart';

class BaselineEntry {
  final double meanMs;
  final double? medianMs;
  final double weight;

  const BaselineEntry({required this.meanMs, this.medianMs, this.weight = 1.0});

  double get comparisonMs => medianMs ?? meanMs;

  factory BaselineEntry.fromJson(Map<String, dynamic> json) {
    return BaselineEntry(
      meanMs: (json['mean_ms'] as num).toDouble(),
      medianMs: (json['median_ms'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'mean_ms': meanMs,
    'median_ms': medianMs,
    'weight': weight,
  };
}

class Baseline {
  final Map<String, BaselineEntry> entries;
  final String? createdAt;
  final String? commit;
  final bool locked;

  const Baseline({
    required this.entries,
    this.createdAt,
    this.commit,
    this.locked = false,
  });

  static const _baselinePath = 'test/benchmark/.history/baseline.json';

  factory Baseline.load() {
    final file = File(_baselinePath);
    if (!file.existsSync()) {
      return const Baseline(entries: {});
    }
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final entriesJson = json['entries'] as Map<String, dynamic>? ?? {};
    final entries = <String, BaselineEntry>{};
    for (final entry in entriesJson.entries) {
      entries[entry.key] =
          BaselineEntry.fromJson(entry.value as Map<String, dynamic>);
    }
    return Baseline(
      entries: entries,
      createdAt: json['created_at'] as String?,
      commit: json['commit'] as String?,
      locked: json['locked'] == true,
    );
  }

  void save() {
    final dir = Directory('test/benchmark/.history');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final json = {
      'created_at': createdAt ?? DateTime.now().toUtc().toIso8601String(),
      'commit': commit,
      'locked': locked,
      'entries': entries.map((k, v) => MapEntry(k, v.toJson())),
    };
    File(_baselinePath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(json),
    );
  }

  BaselineEntry? entryFor(String key) => entries[key];

  double computeScore(BenchmarkResult result, String key, {double? weight}) {
    final entry = entries[key];
    if (entry == null) return 100.0;
    final baselineMs = entry.comparisonMs;
    final currentMs = result.medianMs;
    if (currentMs <= baselineMs) return 100.0;
    final ratio = (currentMs - baselineMs) / baselineMs;
    if (ratio <= 0.05) return 100.0;
    final w = weight ?? entry.weight;
    return (100 - ratio * 100 * w).clamp(0, 100).toDouble();
  }
}

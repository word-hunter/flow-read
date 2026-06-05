import 'dart:convert';
import 'dart:io';

class BenchmarkRecord {
  final String ts;
  final String? commit;
  final double totalScore;
  final Map<String, dynamic> files;

  const BenchmarkRecord({
    required this.ts,
    this.commit,
    required this.totalScore,
    required this.files,
  });

  factory BenchmarkRecord.fromJson(Map<String, dynamic> json) {
    return BenchmarkRecord(
      ts: json['ts'] as String,
      commit: json['commit'] as String?,
      totalScore: (json['total_score'] as num).toDouble(),
      files: json['files'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() => {
    'ts': ts,
    if (commit != null) 'commit': commit,
    'total_score': totalScore,
    'files': files,
  };
}

class BenchmarkHistory {
  static const _recordsPath = 'test/benchmark/.history/records.jsonl';

  static void append(BenchmarkRecord record) {
    final dir = Directory('test/benchmark/.history');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final file = File(_recordsPath);
    final line = jsonEncode(record.toJson());
    if (file.existsSync()) {
      file.writeAsStringSync('$line\n', mode: FileMode.append);
    } else {
      file.writeAsStringSync('$line\n');
    }
  }

  static List<BenchmarkRecord> loadAll() {
    final file = File(_recordsPath);
    if (!file.existsSync()) return [];
    final lines = file.readAsLinesSync();
    return lines
        .where((line) => line.trim().isNotEmpty)
        .map((line) => BenchmarkRecord.fromJson(
              jsonDecode(line) as Map<String, dynamic>,
            ))
        .toList();
  }

  static List<BenchmarkRecord> loadLast(int n) {
    final all = loadAll();
    if (all.length <= n) return all;
    return all.sublist(all.length - n);
  }
}

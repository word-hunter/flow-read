// ignore_for_file: avoid_print

import 'dart:io';

import 'package:epub_reader_core/epub_reader_core.dart' as core;
import 'package:flow_read/services/epub_service.dart';

void main() {
  final testDir = Directory('.benchmark-test-files');
  if (!testDir.existsSync()) {
    stderr.writeln('No .benchmark-test-files/ directory');
    exit(1);
  }

  final epubs = testDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.epub'))
      .toList();

  if (epubs.isEmpty) {
    stderr.writeln('No EPUB files found in .benchmark-test-files/');
    exit(1);
  }

  for (final epub in epubs) {
    final name = epub.uri.pathSegments.last;
    final sizeMb = (epub.lengthSync() / (1024 * 1024)).toStringAsFixed(1);
    print('═' * 60);
    print('File: $name ($sizeMb MB)\n');

    final bytes = epub.readAsBytesSync();
    core.ParsedEpubBook? cachedParsed;
    final coldProfile = _ProfileCollector();

    // ========== STAGE 1: Raw parse (ZIP + XML + text) ==========
    print('=== Cold parse ===');
    var sw = Stopwatch()..start();
    cachedParsed = core.EpubParser.parseBytesSync(
      bytes,
      onProfile: coldProfile.add,
    );
    sw.stop();
    final rawParseMs = sw.elapsedMilliseconds;
    print(
      '  Raw parse (ZIP+XML+text)  : ${rawParseMs}ms  (${(rawParseMs / rawParseMs * 100).toStringAsFixed(0)}%)',
    );
    coldProfile.printSummary(rawParseMs);

    // ========== STAGE 2: Convert to Book model ==========
    sw.reset();
    sw.start();
    final book = EpubService.fromParsed(cachedParsed);
    sw.stop();
    final convertMs = sw.elapsedMilliseconds;
    print(
      '  Convert to Book model     : ${convertMs}ms  (${(convertMs / rawParseMs * 100).toStringAsFixed(0)}% of raw parse)',
    );

    // ========== STAGE 3: Traverse all text ==========
    sw.reset();
    sw.start();
    for (final ch in cachedParsed.chapters) {
      ch.plainText;
      for (final block in ch.blocks) {
        if (block is core.ParsedTextBlock) {
          for (final span in block.spans) {
            span.text;
          }
        }
      }
    }
    sw.stop();
    final traverseMs = sw.elapsedMilliseconds;
    print('  Traverse all text         : ${traverseMs}ms');

    final totalCold = rawParseMs + convertMs;
    print('  ─────────────────────────');
    print('  Total cold               : ${totalCold}ms');
    print('  Chapters                 : ${cachedParsed.chapters.length}');
    print('  Book chapters            : ${book.chapters.length}');

    // ========== STAGE 4: Second raw parse (warm) ==========
    print('\n=== Warm parse (same bytes, second run) ===');
    final warmProfile = _ProfileCollector();
    sw
      ..reset()
      ..start();
    core.EpubParser.parseBytesSync(bytes, onProfile: warmProfile.add);
    sw.stop();
    final warmParseMs = sw.elapsedMilliseconds;
    print('  Raw parse                 : ${warmParseMs}ms');
    warmProfile.printSummary(warmParseMs);

    // ========== STAGE 5: Traverse cached (warm) ==========
    sw
      ..reset()
      ..start();
    for (var i = 0; i < 5; i++) {
      for (final ch in cachedParsed.chapters) {
        ch.plainText;
        for (final block in ch.blocks) {
          if (block is core.ParsedTextBlock) {
            for (final span in block.spans) {
              span.text;
            }
          }
        }
      }
    }
    sw.stop();
    final warmTraverseMs = sw.elapsedMilliseconds ~/ 5;
    print('  Traverse (x5 avg)         : ${warmTraverseMs}ms');

    // ========== Summary ==========
    print('\n=== Summary ===');
    print(
      '  Cold bottleneck: raw parse takes ${rawParseMs}ms (${(rawParseMs / totalCold * 100).toStringAsFixed(0)}% of total)',
    );
    print(
      '  Warm speedup:    raw parse is ~${(warmParseMs.toDouble() / rawParseMs * 100).toStringAsFixed(0)}% of cold parse',
    );
    print('  Traverse warm:   ${warmTraverseMs}ms per traversal');
    print(
      '  Convert:         ${convertMs}ms (converting ${book.chapters.length} Book chapters)',
    );
    print('');
  }
}

class _ProfileCollector {
  final _stages = <String, _StageStats>{};

  void add(core.EpubParseProfileEvent event) {
    (_stages[event.stage] ??= _StageStats()).add(event.elapsed);
  }

  void printSummary(int totalMs) {
    if (_stages.isEmpty || totalMs <= 0) return;
    final entries = _stages.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));
    print('  Parser stage profile:');
    for (final entry in entries.take(10)) {
      final stats = entry.value;
      final percent = stats.total.inMicroseconds / (totalMs * 1000) * 100;
      final avgUs = stats.total.inMicroseconds ~/ stats.count;
      final value = stats.total.inMilliseconds > 0
          ? '${stats.total.inMilliseconds}ms'
          : '${stats.total.inMicroseconds}us';
      final avg = avgUs >= 1000 ? '${avgUs ~/ 1000}ms' : '${avgUs}us';
      print(
        '    ${entry.key.padRight(24)} $value  ${percent.toStringAsFixed(1).padLeft(5)}%  calls=${stats.count} avg=$avg',
      );
    }
  }
}

class _StageStats {
  var total = Duration.zero;
  var count = 0;

  void add(Duration elapsed) {
    total += elapsed;
    count += 1;
  }
}

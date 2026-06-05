import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flow_read/models/book.dart';
import 'package:flow_read/services/epub_service.dart';
import 'package:flow_read/services/reading_search_service.dart';

import 'support/benchmark_reporter.dart';
import 'support/benchmark_runner.dart';
import 'support/test_epub_registry.dart';

void main() {
  final registry = TestEpubRegistry.load();

  for (final epub in registry.files) {
    if (!epub.fileExists()) continue;

    Book? cachedBook;

    setUp(() {
      try {
        cachedBook ??= EpubService.parseBytesSync(
          File(epub.path).readAsBytesSync(),
        );
      } catch (e, st) {
        _failWithDetail('parse', epub.label, e, st);
      }
    });

    test('full_text_search [${epub.label}]', () async {
      final book = cachedBook!;

      // Preflight check
      try {
        final stream = ReadingSearchService.search(book, 'the', limit: 1);
        await stream.drain<Object?>();
      } catch (e, st) {
        _failWithDetail('full_text_search:preflight', epub.label, e, st);
      }

      BenchmarkResult? result;
      try {
        result = await runBenchmarkAsync(
          name: 'full_text_search',
          iterations: 3,
          warmup: 1,
          fn: () async {
            final stream = ReadingSearchService.search(book, 'the', limit: 50);
            await stream.drain<Object?>();
          },
        );
      } catch (e, st) {
        _failWithDetail('full_text_search', epub.label, e, st);
      }

      BenchmarkReporter.report(
        '${epub.id}:full_text_search',
        result,
      );
    },
      timeout: const Timeout(Duration(minutes: 5)),
      tags: ['benchmark'],
    );
  }
}

Never _failWithDetail(String key, String label, Object e, StackTrace st) {
  // ignore: avoid_print
  print('');
  // ignore: avoid_print
  print('═' * 72);
  // ignore: avoid_print
  print('  BENCHMARK ERROR: $key');
  // ignore: avoid_print
  print('  EPUB         : $label');
  // ignore: avoid_print
  print('  Error        : $e');
  // ignore: avoid_print
  print('  Stack trace  :');
  for (final line in st.toString().split('\n')) {
    // ignore: avoid_print
    print('    $line');
  }
  // ignore: avoid_print
  print('═' * 72);
  // ignore: avoid_print
  print('');
  throw Exception('Benchmark failed: $key - $e');
}

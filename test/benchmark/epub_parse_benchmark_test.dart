import 'dart:io';

import 'package:epub_reader_core/epub_reader_core.dart' as core;
import 'package:flutter_test/flutter_test.dart';

import 'support/benchmark_reporter.dart';
import 'support/benchmark_runner.dart';
import 'support/test_epub_registry.dart';

void main() {
  final registry = TestEpubRegistry.load();

  for (final epub in registry.files) {
    group('EPUB Parse [${epub.label}]', () {
      if (!epub.fileExists()) return;

      core.ParsedEpubBook? cachedParsedBook;

      setUp(() {
        cachedParsedBook ??= () {
          final bytes = File(epub.path).readAsBytesSync();
          return core.EpubParser.parseBytesSync(bytes);
        }();
      });

      test('epub_parse_cold', () {
        BenchmarkResult? result;
        try {
          result = runBenchmark(
            name: '${epub.id}:epub_parse_cold',
            iterations: 5,
            warmup: 1,
            fn: () {
              final bytes = File(epub.path).readAsBytesSync();
              final parsed = core.EpubParser.parseBytesSync(bytes);
              _traverseParsedBook(parsed);
            },
          );
        } catch (e, st) {
          _failWithDetail('${epub.id}:epub_parse_cold', epub.label, e, st);
        }
        BenchmarkReporter.report('${epub.id}:epub_parse_cold', result);
      }, tags: ['benchmark'], timeout: const Timeout(Duration(minutes: 10)));

      test('epub_parse_warm', () {
        final book = cachedParsedBook!;

        BenchmarkResult? result;
        try {
          result = runBenchmark(
            name: '${epub.id}:epub_parse_warm',
            iterations: 10,
            warmup: 2,
            fn: () => _traverseParsedBook(book),
          );
        } catch (e, st) {
          _failWithDetail('${epub.id}:epub_parse_warm', epub.label, e, st);
        }
        BenchmarkReporter.report('${epub.id}:epub_parse_warm', result);
      }, tags: ['benchmark'], timeout: const Timeout(Duration(minutes: 10)));
    });
  }
}

void _traverseParsedBook(core.ParsedEpubBook parsed) {
  for (final ch in parsed.chapters) {
    final _ = ch.plainText;
    for (final block in ch.blocks) {
      if (block is core.ParsedTextBlock) {
        for (final span in block.spans) {
          final _ = span.text;
        }
      }
    }
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

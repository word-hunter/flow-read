import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flow_read/models/book.dart';
import 'package:flow_read/services/analysis_service.dart';
import 'package:flow_read/services/epub_service.dart';

import 'support/benchmark_reporter.dart';
import 'support/benchmark_runner.dart';
import 'support/test_epub_registry.dart';
import 'support/top_words.dart';

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

    for (final vocab in vocabularyProfiles) {
      final userVocab = createFakeVocabForProfile(vocab);

      test('chapter_analysis [${epub.label}] [$vocab]', () {
        final book = cachedBook!;
        if (book.chapters.isEmpty) return;

        final chapters = book.chapters.take(5).toList();

        BenchmarkResult? result;
        try {
          result = runBenchmark(
            name: 'chapter_analysis:$vocab',
            iterations: 10,
            warmup: 2,
            fn: () {
              for (final chapter in chapters) {
                AnalysisService.analyzeChapter(
                  chapter.title,
                  chapter.plainText,
                  userVocab,
                );
              }
            },
          );
        } catch (e, st) {
          _failWithDetail('chapter_analysis:$vocab', epub.label, e, st);
        }

        BenchmarkReporter.report(
          '${epub.id}:chapter_analysis:$vocab',
          result,
        );
      }, tags: ['benchmark']);
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

import 'dart:convert';
import 'dart:io';

import 'package:flow_read/models/book.dart';
import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/models/chapter.dart';
import 'package:flow_read/providers/reading/bookshelf_notifier.dart';
import 'package:flow_read/providers/reading/current_book_notifier.dart';
import 'package:flow_read/providers/reading/services_provider.dart';
import 'package:flow_read/providers/reading/vocabulary_notifier.dart';
import 'package:flow_read/services/app_logger.dart';
import 'package:flow_read/services/book_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'switchToBook does not construct assistant controller while opening',
    () async {
      final metadata = _metadata(
        id: 'book-1',
        title: 'Parsed Book',
        sourcePath: '/tmp/parsed-book.epub',
      );
      final currentBook = _RecordingCurrentBookNotifier();
      final parserCalls = <String>[];

      final container = ProviderContainer(
        overrides: [
          bookServiceProvider.overrideWithValue(_FakeBookService([metadata])),
          epubBookParserProvider.overrideWithValue((path) async {
            parserCalls.add(path);
            return _book(title: 'Parsed Book');
          }),
          currentBookNotifierProvider.overrideWith(() => currentBook),
          vocabularyNotifierProvider.overrideWith(_NoopVocabularyNotifier.new),
          aiAssistantControllerProvider.overrideWith((ref) {
            throw StateError(
              'assistant controller should not be constructed during book open',
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      final opened = await container
          .read(bookshelfNotifierProvider.notifier)
          .switchToBook('book-1');

      expect(opened, isTrue);
      expect(parserCalls, ['/tmp/parsed-book.epub']);
      expect(container.read(bookshelfNotifierProvider).activeBookId, 'book-1');
      expect(
        container.read(bookshelfNotifierProvider).book?.title,
        'Parsed Book',
      );
      expect(
        container.read(bookCacheProvider).get('book-1')?.title,
        'Parsed Book',
      );
      expect(currentBook._invalidations, 1);
      expect(currentBook._chapterSelections, [0]);
    },
  );

  test(
    'switchToBook logs parser failures with stack and file diagnostics',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'flow_read_open_book_log_test_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final sourceFile = File('${tempDir.path}/book.epub');
      await sourceFile.writeAsBytes([1, 2, 3]);
      final logger = AppLogger(
        logDirectoryProvider: () async => tempDir,
        includeDebugProvider: () => true,
        clock: () => DateTime(2026, 6, 12, 9),
      );
      final metadata = _metadata(
        id: 'book-1',
        title: 'Broken Book',
        sourcePath: sourceFile.path,
      );

      final container = ProviderContainer(
        overrides: [
          appLoggerProvider.overrideWithValue(logger),
          bookServiceProvider.overrideWithValue(_FakeBookService([metadata])),
          epubBookParserProvider.overrideWithValue((_) async {
            throw StateError('parser failed');
          }),
          currentBookNotifierProvider.overrideWith(
            _RecordingCurrentBookNotifier.new,
          ),
          vocabularyNotifierProvider.overrideWith(_NoopVocabularyNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      final opened = await container
          .read(bookshelfNotifierProvider.notifier)
          .switchToBook('book-1');
      await logger.drain();

      expect(opened, isFalse);
      expect(
        container.read(bookshelfNotifierProvider).errorMessage,
        '打开书籍失败：无法读取书籍文件。详情已写入诊断日志。',
      );

      final logFile = File('${tempDir.path}/flow_read-2026-06-12.log');
      final entries = await logFile.readAsLines().then(
        (lines) => lines
            .map((line) => jsonDecode(line) as Map<String, dynamic>)
            .toList(),
      );
      final entry = entries.single;
      expect(entry['event'], 'book.open_failed');
      expect(entry['source'], 'bookshelf_notifier');
      expect(entry['errorType'], 'StateError');
      expect(entry['stackTrace'], isNotNull);
      final metadataLog = entry['metadata'] as Map<String, dynamic>;
      expect(metadataLog['bookId'], 'book-1');
      expect(metadataLog['sourcePathDiagnostics'], {
        'present': true,
        'exists': true,
        'sizeBytes': 3,
      });
    },
  );
}

Book _book({required String title}) {
  return Book(
    title: title,
    author: 'Author',
    language: 'en',
    chapters: const [
      Chapter(title: 'Chapter One', plainText: 'A first chapter.', rawHtml: ''),
    ],
  );
}

BookMetadata _metadata({
  required String id,
  required String title,
  required String sourcePath,
}) {
  return BookMetadata(
    id: id,
    title: title,
    author: 'Author',
    sourcePath: sourcePath,
    sourceLanguage: 'en',
    totalChapters: 1,
  );
}

class _FakeBookService extends BookService {
  _FakeBookService(this._books);

  final List<BookMetadata> _books;

  @override
  List<BookMetadata> get books => _books;

  @override
  Future<BookMetadata?> updateProgress(
    String id,
    int currentChapter,
    double chapterProgress, {
    double? chapterScrollOffset,
  }) async {
    return null;
  }
}

class _RecordingCurrentBookNotifier extends CurrentBookNotifier {
  int _invalidations = 0;
  final List<int> _chapterSelections = [];

  @override
  CurrentBookState build() => const CurrentBookState();

  @override
  void invalidateChapterAnalysisCache() {
    _invalidations += 1;
  }

  @override
  Future<void> goToChapter(int index) async {
    _chapterSelections.add(index);
  }
}

class _NoopVocabularyNotifier extends VocabularyNotifier {
  @override
  VocabularyState build() => const VocabularyState();

  @override
  Future<bool> tryUseCachedDifficulty(BookMetadata meta) async => false;
}

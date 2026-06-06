import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/services/book_service.dart';
import 'package:flow_read/services/epub_import_source.dart';
import 'package:flow_read/services/epub_parse_worker.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_test_storage.dart';

void main() {
  late Directory tempDir;
  late Directory documentsDir;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_import_test_');
    await openFlowReadTestBoxes();
    documentsDir = await Directory('${tempDir.path}/documents').create();
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test('imports EPUB bytes through the internal book source copy', () async {
    final provider = ReadingProvider()
      ..setBookService(
        BookService(documentsDirectoryProvider: () async => documentsDir),
      );
    await provider.init();

    final bytes = _buildEpub();
    await provider.importBookFromBytes(bytes: bytes, fileName: 'cloud.epub');

    expect(provider.errorMessage, isNull);
    expect(provider.book?.title, 'Fixture Book');
    expect(provider.allBooks, hasLength(1));

    final metadata = provider.allBooks.single;
    expect(metadata.sourceLanguage, 'en');
    expect(metadata.languageConfidence, 0.9);
    expect(metadata.effectiveSourceLanguage, 'en');
    expect(metadata.sourcePath, startsWith('${documentsDir.path}/books/'));
    expect(metadata.sourcePath, endsWith('.epub'));
    expect(await File(metadata.sourcePath).readAsBytes(), bytes);
  });

  test('prefers book explanation language over global setting', () async {
    final settings = SettingsService();
    await settings.init();
    await settings.setTargetExplanationLanguage('en');
    final provider = ReadingProvider()
      ..setBookService(
        BookService(documentsDirectoryProvider: () async => documentsDir),
      )
      ..setSettings(settings);
    await provider.init();

    await provider.importBookFromBytes(
      bytes: _buildEpub(),
      fileName: 'language.epub',
    );

    final imported = provider.allBooks.single;
    expect(provider.effectiveTargetExplanationLanguage, 'en');

    await booksBox().put(
      imported.id,
      imported.copyWith(targetExplanationLanguage: 'zh'),
    );

    expect(provider.effectiveTargetExplanationLanguage, 'zh');
  });

  test('keeps path imports as an internal book source copy', () async {
    final provider = ReadingProvider()
      ..setBookService(
        BookService(documentsDirectoryProvider: () async => documentsDir),
      );
    await provider.init();

    final bytes = _buildEpub();
    final pickedFile = File('${tempDir.path}/picked.epub');
    await pickedFile.writeAsBytes(bytes);

    await provider.importBook(pickedFile.path);

    expect(provider.errorMessage, isNull);
    final metadata = provider.allBooks.single;
    expect(metadata.sourcePath, isNot(pickedFile.path));
    expect(metadata.sourcePath, startsWith('${documentsDir.path}/books/'));
    expect(await File(metadata.sourcePath).readAsBytes(), bytes);
  });

  test(
    'imports EPUB streams without requiring an external file path',
    () async {
      final provider = ReadingProvider()
        ..setBookService(
          BookService(documentsDirectoryProvider: () async => documentsDir),
        );
      await provider.init();

      final bytes = _buildEpub();
      await provider.importBookFromSource(
        EpubImportSource.stream(
          Stream<List<int>>.fromIterable([
            bytes.sublist(0, 20),
            bytes.sublist(20),
          ]),
          fileName: 'stream.epub',
        ),
      );

      expect(provider.errorMessage, isNull);
      expect(provider.allBooks.single.sourcePath, contains('/books/'));
      expect(
        await File(provider.allBooks.single.sourcePath).readAsBytes(),
        bytes,
      );
    },
  );

  test('updates import UI state from real parser progress events', () async {
    final provider = ReadingProvider()
      ..setBookService(
        BookService(documentsDirectoryProvider: () async => documentsDir),
      );
    await provider.init();

    final stages = <String>[];
    final progressValues = <double>[];
    provider.importProgressNotifier.addListener(() {
      final state = provider.importProgressNotifier.value;
      if (state.stage.isNotEmpty) {
        stages.add(state.stage);
      }
      final progress = state.progress;
      if (progress != null) {
        progressValues.add(progress);
      }
    });

    await provider.importBookFromBytes(
      bytes: _buildEpub(),
      fileName: 'progress.epub',
    );

    expect(stages, contains('正在读取书籍信息...'));
    expect(stages, contains('正在解析 EPUB 内容...'));
    expect(stages, contains('解析完成'));
    expect(stages, isNot(anyElement(contains('Chapter One'))));
    expect(stages, isNot(anyElement(contains('Fixture Author'))));
    expect(progressValues, anyElement(greaterThan(0.18)));
    expect(progressValues, contains(0.72));
  });

  testWidgets('reveals import cancellation after ten seconds', (tester) async {
    final bookService = _StallingBookService();
    final provider = ReadingProvider()..setBookService(bookService);
    addTearDown(provider.dispose);
    await provider.init();
    var globalNotifications = 0;
    var importNotifications = 0;
    provider.addListener(() => globalNotifications += 1);
    provider.importProgressNotifier.addListener(() {
      importNotifications += 1;
    });

    final importFuture = provider.importBookFromBytes(
      bytes: Uint8List(0),
      fileName: 'slow.epub',
    );

    expect(provider.isImportingBook, isTrue);
    expect(provider.canCancelImport, isFalse);
    expect(globalNotifications, 1);
    expect(importNotifications, 1);

    await tester.pump(const Duration(seconds: 9));
    expect(provider.canCancelImport, isFalse);
    expect(globalNotifications, 1);
    expect(importNotifications, 1);

    await tester.pump(const Duration(seconds: 1));
    expect(provider.canCancelImport, isTrue);
    expect(globalNotifications, 1);
    expect(importNotifications, 2);

    provider.cancelImport();
    expect(provider.isCancellingImport, isTrue);
    expect(globalNotifications, 1);
    expect(importNotifications, 3);

    bookService.completeCancelled();
    await tester.pump();
    final result = await importFuture;

    expect(result, BookImportResult.cancelled);
    expect(provider.isImportingBook, isFalse);
    expect(globalNotifications, 2);
  });

  test('reloads restored progress for the previously active book id', () async {
    final provider = ReadingProvider()
      ..setBookService(
        BookService(documentsDirectoryProvider: () async => documentsDir),
      );
    await provider.init();
    await provider.importBookFromBytes(
      bytes: _buildEpub(),
      fileName: 'same.epub',
    );

    final imported = provider.allBooks.single;
    await booksBox().put(
      imported.id,
      imported.copyWith(chapterProgress: 0.42, chapterScrollOffset: 260),
    );

    await provider.reloadAfterBackupRestore();
    expect(provider.activeBookId, isNull);
    expect(provider.book, isNull);

    await provider.switchToBook(imported.id);

    expect(provider.errorMessage, isNull);
    expect(provider.activeBookId, imported.id);
    expect(provider.readingProgress, moreOrLessEquals(0.42));
    expect(provider.readingScrollOffset, 260);
  });

  test(
    'relinks a restored missing book when importing the same EPUB',
    () async {
      final provider = ReadingProvider()
        ..setBookService(
          BookService(documentsDirectoryProvider: () async => documentsDir),
        );
      await provider.init();
      await booksBox().put(
        'restored-book',
        const BookMetadata(
          id: 'restored-book',
          title: 'Fixture Book',
          author: 'Fixture Author',
          sourcePath: '/missing/fixture.epub',
          totalChapters: 1,
          currentChapter: 0,
          chapterProgress: 0.42,
          chapterScrollOffset: 260,
        ),
      );
      await provider.reloadAfterBackupRestore();

      await provider.importBookFromBytes(
        bytes: _buildEpub(),
        fileName: 'same.epub',
      );

      expect(provider.allBooks, hasLength(1));
      expect(provider.allBooks.single.id, 'restored-book');
      expect(provider.activeBookId, 'restored-book');
      expect(provider.readingProgress, moreOrLessEquals(0.42));
      expect(provider.readingScrollOffset, 260);
      expect(await File(provider.allBooks.single.sourcePath).exists(), isTrue);
    },
  );

  test(
    'reports an open failure when the restored source file is missing',
    () async {
      final provider = ReadingProvider()
        ..setBookService(
          BookService(documentsDirectoryProvider: () async => documentsDir),
        );
      await provider.init();
      await booksBox().put(
        'missing-book',
        const BookMetadata(
          id: 'missing-book',
          title: 'Missing Book',
          author: 'Author',
          sourcePath: '/missing/restored.epub',
          totalChapters: 1,
        ),
      );
      await provider.reloadAfterBackupRestore();

      final opened = await provider.switchToBook('missing-book');

      expect(opened, isFalse);
      expect(provider.isReading, isFalse);
      expect(provider.book, isNull);
      expect(provider.errorMessage, contains('打开书籍失败'));
    },
  );

  test(
    'returns a placeholder cover before book file storage is ready',
    () async {
      final directoryReady = Completer<Directory>();
      final provider = ReadingProvider()
        ..setBookService(
          BookService(documentsDirectoryProvider: () => directoryReady.future),
        );
      await booksBox().put(
        'early-book',
        const BookMetadata(
          id: 'early-book',
          title: 'Early Book',
          author: 'Author',
          sourcePath: '/tmp/early.epub',
          totalChapters: 1,
        ),
      );

      final initFuture = provider.init();

      expect(provider.allBooks.single.id, 'early-book');
      expect(provider.getCoverBytes('early-book'), isNull);

      directoryReady.complete(documentsDir);
      await initFuture;
    },
  );

  test(
    'does not repeat difficulty parsing for a missing restored source',
    () async {
      final provider = ReadingProvider()
        ..setBookService(
          BookService(documentsDirectoryProvider: () async => documentsDir),
        );
      await provider.init();
      await booksBox().put(
        'missing-source',
        const BookMetadata(
          id: 'missing-source',
          title: 'Missing Source',
          author: 'Author',
          sourcePath: '/missing/book.epub',
          totalChapters: 1,
        ),
      );
      await provider.reloadAfterBackupRestore();

      var notifications = 0;
      provider.addListener(() => notifications += 1);

      await provider.ensureBookDifficulties(provider.allBooks);
      final afterFirstAttempt = notifications;
      await provider.ensureBookDifficulties(provider.allBooks);

      expect(afterFirstAttempt, greaterThan(0));
      expect(notifications, afterFirstAttempt);
      expect(provider.isLoadingBookDifficulties, isFalse);
    },
  );
}

class _StallingBookService extends BookService {
  _StallingBookService()
    : super(documentsDirectoryProvider: Directory.systemTemp.createTemp);

  final Completer<String> _saveSource = Completer<String>();

  @override
  List<BookMetadata> get books => const [];

  @override
  Future<void> init() async {}

  @override
  Future<String> saveSource(String bookId, EpubImportSource source) {
    return _saveSource.future;
  }

  void completeCancelled() {
    if (!_saveSource.isCompleted) {
      _saveSource.completeError(const EpubParseCancelledException());
    }
  }
}

Uint8List _buildEpub() {
  final archive = Archive();

  void addString(String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  addString('META-INF/container.xml', '''
      <?xml version="1.0"?>
      <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
        <rootfiles>
          <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
        </rootfiles>
      </container>
    ''');

  addString('OEBPS/content.opf', '''
      <?xml version="1.0" encoding="UTF-8"?>
      <package xmlns="http://www.idpf.org/2007/opf" unique-identifier="bookid" version="3.0">
        <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
          <dc:title>Fixture Book</dc:title>
          <dc:creator>Fixture Author</dc:creator>
          <dc:language>en-US</dc:language>
        </metadata>
        <manifest>
          <item id="chapter1" href="Text/chapter1.xhtml" media-type="application/xhtml+xml"/>
        </manifest>
        <spine>
          <itemref idref="chapter1"/>
        </spine>
      </package>
    ''');

  addString('OEBPS/Text/chapter1.xhtml', '''
      <html xmlns="http://www.w3.org/1999/xhtml">
        <head><title>Chapter One</title></head>
        <body>
          <p>Reading creates a steady flow of useful vocabulary.</p>
        </body>
      </html>
    ''');

  return ZipEncoder().encodeBytes(archive);
}

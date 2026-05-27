import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/services/book_service.dart';
import 'package:flow_read/services/epub_import_source.dart';
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
    expect(metadata.sourcePath, startsWith('${documentsDir.path}/books/'));
    expect(metadata.sourcePath, endsWith('.epub'));
    expect(await File(metadata.sourcePath).readAsBytes(), bytes);
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

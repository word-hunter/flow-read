import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flow_read/services/backup_archive.dart' as archive;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('magic bytes detection', () {
    test('recognises zip header', () {
      expect(
        archive.isZipFileHeader(Uint8List.fromList([0x50, 0x4B, 0x03, 0x04])),
        isTrue,
      );
    });

    test('rejects empty input', () {
      expect(archive.isZipFileHeader(Uint8List(0)), isFalse);
    });

    test('rejects json header', () {
      expect(
        archive.isZipFileHeader(utf8.encode('{"a":1}')),
        isFalse,
      );
    });

    test('rejects random bytes', () {
      expect(
        archive.isZipFileHeader(Uint8List.fromList([0x00, 0x01, 0x02, 0x03])),
        isFalse,
      );
    });
  });

  group('bookId path encoding', () {
    test('encodes simple id', () {
      expect(archive.encodeBookId('book-1'), 'book-1');
    });

    test('encodes id with spaces', () {
      expect(archive.encodeBookId('my book'), 'my%20book');
    });

    test('encodes id with Chinese', () {
      expect(archive.encodeBookId('书籍'), '%E4%B9%A6%E7%B1%8D');
    });

    test('entry paths use encoded id', () {
      final path = archive.bookSourceEntryPath('my book');
      expect(path, 'books/my%20book/source.epub');
    });
  });

  group('manifest build', () {
    test('builds manifest with books and covers', () {
      final manifest = archive.buildManifest(
        appId: 'flow_read',
        formatVersion: 1,
        createdAt: DateTime.utc(2026, 5, 27, 10, 0),
        bookIds: ['book-1'],
        bookHasCover: {'book-1': true},
      );

      expect(manifest['app'], 'flow_read');
      expect(manifest['formatVersion'], 1);
      expect(manifest['createdAt'], '2026-05-27T10:00:00.000Z');
      expect(manifest['dataPath'], 'data/app.json');
      expect(manifest['books']['book-1']['source'], contains('source.epub'));
      expect(manifest['books']['book-1']['cover'], contains('cover.png'));
    });

    test('builds manifest without cover', () {
      final manifest = archive.buildManifest(
        appId: 'flow_read',
        formatVersion: 1,
        createdAt: DateTime.utc(2026, 5, 27),
        bookIds: ['book-1'],
        bookHasCover: {'book-1': false},
      );

      expect(manifest['books']['book-1']['cover'], isNull);
    });

    test('builds manifest with empty books', () {
      final manifest = archive.buildManifest(
        appId: 'flow_read',
        formatVersion: 1,
        createdAt: DateTime.utc(2026, 5, 27),
        bookIds: [],
        bookHasCover: {},
      );

      expect(manifest['books'], isEmpty);
    });
  });

  group('manifest validation', () {
    test('valid manifest passes', () {
      final manifest = archive.buildManifest(
        appId: 'flow_read',
        formatVersion: 1,
        createdAt: DateTime.utc(2026, 5, 27),
        bookIds: ['book-1'],
        bookHasCover: {},
      );
      expect(
        () => archive.validateManifest(manifest, 'flow_read'),
        returnsNormally,
      );
    });

    test('wrong app id fails', () {
      final manifest = archive.buildManifest(
        appId: 'other_app',
        formatVersion: 1,
        createdAt: DateTime.utc(2026, 5, 27),
        bookIds: [],
        bookHasCover: {},
      );
      expect(
        () => archive.validateManifest(manifest, 'flow_read'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Flow Read'),
        )),
      );
    });

    test('format version too high fails', () {
      final manifest = archive.buildManifest(
        appId: 'flow_read',
        formatVersion: 999,
        createdAt: DateTime.utc(2026, 5, 27),
        bookIds: [],
        bookHasCover: {},
      );
      expect(
        () => archive.validateManifest(manifest, 'flow_read'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('过新'),
        )),
      );
    });

    test('missing format version fails', () {
      final manifest = <String, dynamic>{
        'app': 'flow_read',
        'dataPath': 'data/app.json',
        'books': {},
      };
      expect(
        () => archive.validateManifest(manifest, 'flow_read'),
        throwsA(isA<FormatException>()),
      );
    });

    test('missing dataPath fails', () {
      final manifest = <String, dynamic>{
        'app': 'flow_read',
        'formatVersion': 1,
        'books': {},
      };
      expect(
        () => archive.validateManifest(manifest, 'flow_read'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('数据路径'),
        )),
      );
    });

    test('missing books fails', () {
      final manifest = <String, dynamic>{
        'app': 'flow_read',
        'formatVersion': 1,
        'dataPath': 'data/app.json',
      };
      expect(
        () => archive.validateManifest(manifest, 'flow_read'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('书籍索引'),
        )),
      );
    });

    test('absolute entry path fails', () {
      final manifest = <String, dynamic>{
        'app': 'flow_read',
        'formatVersion': 1,
        'dataPath': '/absolute/data/app.json',
        'books': {},
      };
      expect(
        () => archive.validateManifest(manifest, 'flow_read'),
        throwsA(isA<FormatException>()),
      );
    });

    test('path traversal in entry path fails', () {
      final manifest = <String, dynamic>{
        'app': 'flow_read',
        'formatVersion': 1,
        'dataPath': '../data/app.json',
        'books': {},
      };
      expect(
        () => archive.validateManifest(manifest, 'flow_read'),
        throwsA(isA<FormatException>()),
      );
    });

    test('book source missing fails', () {
      final manifest = <String, dynamic>{
        'app': 'flow_read',
        'formatVersion': 1,
        'dataPath': 'data/app.json',
        'books': {
          'book-1': {},
        },
      };
      expect(
        () => archive.validateManifest(manifest, 'flow_read'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('源文件'),
        )),
      );
    });
  });

  group('data payload', () {
    test('builds data payload', () {
      final boxes = <String, dynamic>{
        'books': {'entries': []},
        'settings': {'entries': []},
      };
      final data = archive.buildDataPayload(
        schemaVersion: 1,
        boxes: boxes,
      );
      expect(data['schemaVersion'], 1);
      expect(data['boxes'], boxes);
      expect(data.containsKey('app'), isFalse);
      expect(data.containsKey('createdAt'), isFalse);
      expect(data.containsKey('files'), isFalse);
    });
  });

  group('data schema validation', () {
    test('valid data passes', () {
      final data = archive.buildDataPayload(schemaVersion: 1, boxes: {});
      expect(
        () => archive.validateDataSchema(data, 1),
        returnsNormally,
      );
    });

    test('schema version too high fails', () {
      final data = archive.buildDataPayload(schemaVersion: 999, boxes: {});
      expect(
        () => archive.validateDataSchema(data, 1),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('过新'),
        )),
      );
    });

    test('missing schema version fails', () {
      expect(
        () => archive.validateDataSchema({'boxes': {}}, 1),
        throwsA(isA<FormatException>()),
      );
    });

    test('missing boxes fails', () {
      expect(
        () => archive.validateDataSchema(
          {'schemaVersion': 1},
          1,
        ),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('缺失'),
        )),
      );
    });
  });

  group('zip encode/decode round-trip', () {
    test('encodes and decodes zip with all entry types', () {
      final manifestJson = jsonEncode({
        'app': 'flow_read',
        'formatVersion': 1,
        'createdAt': '2026-05-27T10:00:00.000Z',
        'dataPath': 'data/app.json',
        'books': {
          'book-1': {'source': 'books/book-1/source.epub'},
        },
      });

      final dataJson = jsonEncode({
        'schemaVersion': 1,
        'boxes': {'books': {'entries': []}},
      });

      final sourceBytes = utf8.encode('epub content');
      final coverBytes = Uint8List.fromList([1, 2, 3, 4]);

      final entries = <String, Map<String, dynamic>>{
        'books/book-1/source.epub': {
          'bytes': sourceBytes,
          'compress': false,
        },
        'books/book-1/cover.png': {
          'bytes': coverBytes,
          'compress': false,
        },
      };

      final zipBytes = archive.encodeZipArchive({
        'manifestJson': manifestJson,
        'dataJson': dataJson,
        'entries': entries,
      });

      expect(zipBytes, isNotEmpty);

      final decoded = archive.decodeZipArchive(zipBytes);
      expect(decoded['manifestJson'], manifestJson);
      expect(decoded['dataJson'], dataJson);

      final decodedEntries = decoded['entryBytes'] as Map<String, dynamic>;
      expect(
        decodedEntries['books/book-1/source.epub'],
        sourceBytes,
      );
      expect(
        decodedEntries['books/book-1/cover.png'],
        coverBytes,
      );
    });

    test('encode rejects manifest.json in custom entries', () {
      final entries = <String, Map<String, dynamic>>{
        'manifest.json': {
          'bytes': utf8.encode('malicious'),
          'compress': false,
        },
      };
      final zipBytes = archive.encodeZipArchive({
        'manifestJson': '{"app":"flow_read"}',
        'dataJson': '{"schemaVersion":1,"boxes":{}}',
        'entries': entries,
      });

      final decoded = archive.decodeZipArchive(zipBytes);
      expect(decoded['manifestJson'], isNot('malicious'));
    });

    test('decode throws on missing manifest.json', () {
      final testArchive = Archive();
      testArchive.addFile(ArchiveFile.bytes(
        'data/app.json',
        utf8.encode('{"schemaVersion":1,"boxes":{}}'),
      ));
      final zipBytes = ZipEncoder().encodeBytes(testArchive);

      expect(
        () => archive.decodeZipArchive(zipBytes),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('manifest.json'),
        )),
      );
    });

    test('decode throws on missing data/app.json', () {
      final testArchive = Archive();
      testArchive.addFile(ArchiveFile.bytes(
        'manifest.json',
        utf8.encode('{"app":"flow_read"}'),
      ));
      final zipBytes = ZipEncoder().encodeBytes(testArchive);

      expect(
        () => archive.decodeZipArchive(zipBytes),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('data/app.json'),
        )),
      );
    });

    test('decode returns empty entryBytes when no extra files', () {
      final zipBytes = archive.encodeZipArchive(<String, dynamic>{
        'manifestJson': '{"app":"flow_read"}',
        'dataJson': '{"schemaVersion":1,"boxes":{}}',
        'entries': <String, Map<String, dynamic>>{},
      });

      final decoded = archive.decodeZipArchive(zipBytes);
      final entryBytes = decoded['entryBytes'] as Map<String, dynamic>;
      expect(entryBytes, isEmpty);
    });
  });

  group('manifest book ids extraction', () {
    test('extracts book ids from manifest', () {
      final manifest = archive.buildManifest(
        appId: 'flow_read',
        formatVersion: 1,
        createdAt: DateTime.utc(2026, 5, 27),
        bookIds: ['book-1', 'book-2'],
        bookHasCover: {},
      );

      final ids = archive.manifestBookIds(manifest);
      expect(ids, {'book-1', 'book-2'});
    });

    test('returns empty set when manifest has no books key', () {
      expect(archive.manifestBookIds({}), isEmpty);
    });
  });
}

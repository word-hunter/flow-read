import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flow_read/services/app_logger.dart';
import 'package:flow_read/services/diagnostic_export_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late Directory logDir;
  late Directory exportDir;
  late DateTime now;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'flow_read_diagnostic_export_test_',
    );
    logDir = Directory('${tempDir.path}/logs');
    exportDir = Directory('${tempDir.path}/exports');
    now = DateTime.utc(2026, 6, 2, 8, 30);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('exports sanitized app info and logs into a zip archive', () async {
    final logger = AppLogger(
      logDirectoryProvider: () async => logDir,
      includeDebugProvider: () => true,
      clock: () => now,
    );
    logger.event(
      'diagnostic.sample',
      level: AppLogLevel.warning,
      source: 'diagnostic_test',
      metadata: {
        'apiKey': 'sk-secret-value',
        'localPath': '/Users/example/private/book.epub',
      },
      error: StateError('private failure'),
    );
    await logger.drain();

    final service = DiagnosticExportService(
      logger: logger,
      tempDirectoryProvider: () async => exportDir,
      clock: () => now,
    );

    final path = await service.export();
    final archive = ZipDecoder().decodeBytes(await File(path).readAsBytes());
    final names = archive.files.map((file) => file.name).toSet();

    expect(names, contains('app_info.json'));
    expect(names, contains('logs/flow_read-2026-06-02.log'));
    expect(path, endsWith('.zip'));

    final appInfo =
        jsonDecode(utf8.decode(_bytesFor(archive.findFile('app_info.json')!)))
            as Map<String, dynamic>;
    expect(appInfo['exportType'], 'diagnostic');
    expect(appInfo['appName'], 'Flow Read');

    final appInfoJson = jsonEncode(appInfo);
    expect(appInfoJson, isNot(contains('apiKey')));
    expect(appInfoJson, isNot(contains('/Users/')));
    expect(appInfoJson, isNot(contains('bookmark')));

    final logText = utf8.decode(
      _bytesFor(archive.findFile('logs/flow_read-2026-06-02.log')!),
    );
    expect(logText, contains('<redacted>'));
    expect(logText, contains('<local_path>'));
    expect(logText, isNot(contains('sk-secret-value')));
    expect(logText, isNot(contains('/Users/example')));
  });

  test('uses Drift counts in diagnostic app stats', () async {
    final db = await AppDatabase.createInMemory();
    addTearDown(db.close);

    await db.bookDao.upsert(
      BookEntriesCompanion.insert(
        id: 'book-1',
        title: 'Book',
        sourcePath: '/tmp/book.epub',
        language: const Value('en'),
      ),
    );
    await db.userVocabularyDao.upsert(
      UserVocabulariesCompanion.insert(
        id: 'en_flow',
        language: const Value('en'),
        canonical: 'flow',
        status: 'known',
      ),
    );
    await db.rssDao.insertSubscription(
      RssSubscriptionsCompanion.insert(
        id: 'rss-1',
        url: 'https://example.com/rss.xml',
        title: const Value('Example'),
      ),
    );
    await db.learningItemDao.upsert(
      LearningItemsCompanion.insert(
        id: 'learning-1',
        language: const Value('en'),
        type: 'word',
        nextReviewAt: DateTime.utc(2026, 6, 13).toIso8601String(),
      ),
    );
    await db.dictionaryCacheDao.putValue('flow', 'en', '{"word":"flow"}');

    final service = DiagnosticExportService(
      logger: AppLogger(
        logDirectoryProvider: () async => logDir,
        clock: () => now,
      ),
      tempDirectoryProvider: () async => exportDir,
      clock: () => now,
      database: db,
    );

    final archive = ZipDecoder().decodeBytes(
      await service.buildArchive(),
    );
    final appInfo =
        jsonDecode(utf8.decode(_bytesFor(archive.findFile('app_info.json')!)))
            as Map<String, dynamic>;
    final appStats = appInfo['appStats'] as Map<String, dynamic>;

    expect(appStats['bookCount'], 1);
    expect(appStats['vocabularyCount'], 1);
    expect(appStats['rssSubscriptionCount'], 1);
    expect(appStats['learningItemCount'], 1);
    expect(appStats['dictionaryCacheCount'], 1);
  });
}

Uint8List _bytesFor(ArchiveFile file) {
  return file.content;
}

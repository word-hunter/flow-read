import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/models/reader_font.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/migration.dart';
import 'package:flow_read/storage/hive_box_names.dart';
import 'package:flow_read/storage/storage_migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import '../support/hive_test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_hive_to_drift_test_');
    await Hive.openBox<dynamic>(HiveBoxNames.settings);
    await Hive.openBox<BookMetadata>(HiveBoxNames.booksFor('en'));
    await Hive.openBox<String>(HiveBoxNames.readingConfigFor('en'));
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test('migrates Hive reading config into Drift', () async {
    final hiveConfig = readingConfigBox();
    await hiveConfig.put('fontSize', '19');
    await hiveConfig.put('fontFamily', ReaderFonts.literata);
    final db = await createTestAppDatabase();

    final result = await HiveToDriftMigration(db).migrateAll('en');

    expect(await db.readingConfigDao.valueFor('fontSize', 'en'), '19');
    expect(
      await db.readingConfigDao.valueFor('fontFamily', 'en'),
      ReaderFonts.literata,
    );
    expect(result.skipped, isFalse);
    expect(result.scannedRows['reading_config'], 2);
    expect(result.totalScannedRows, greaterThanOrEqualTo(2));
    expect(
      await db.settingsDao.valueFor(HiveToDriftMigration.completedAtKey),
      isNotEmpty,
    );
    expect(
      await db.settingsDao.valueFor(
        HiveToDriftMigration.sourceSchemaVersionKey,
      ),
      StorageSchema.currentVersion.toString(),
    );
  });

  test(
    'does not overwrite Drift reading config with stale Hive values',
    () async {
      final hiveConfig = readingConfigBox();
      await hiveConfig.put('fontSize', '16');
      await hiveConfig.put('lineHeight', '2.4');
      final db = await createTestAppDatabase();
      await db.readingConfigDao.putValue('fontSize', 'en', '22');

      await HiveToDriftMigration(db).migrateAll('en');

      expect(await db.readingConfigDao.valueFor('fontSize', 'en'), '22');
      expect(await db.readingConfigDao.valueFor('lineHeight', 'en'), '2.4');
    },
  );

  test(
    'skips subsequent migration after completion marker is written',
    () async {
      await booksBox().put(
        'book-1',
        const BookMetadata(
          id: 'book-1',
          title: 'Hive title',
          author: 'Author',
          sourcePath: '/tmp/book.epub',
        ),
      );
      final db = await createTestAppDatabase();
      final migration = HiveToDriftMigration(db);

      final first = await migration.migrateAll('en');
      await db.bookDao.upsert(
        BookEntriesCompanion.insert(
          id: 'book-1',
          title: 'Drift title',
          sourcePath: '/tmp/current.epub',
          language: const Value('en'),
        ),
      );
      await booksBox().put(
        'book-1',
        const BookMetadata(
          id: 'book-1',
          title: 'Stale Hive title',
          author: 'Author',
          sourcePath: '/tmp/stale.epub',
        ),
      );

      final second = await migration.migrateAll('en');

      expect(first.skipped, isFalse);
      expect(second.skipped, isTrue);
      expect(second.scannedRows, isEmpty);
      expect((await db.bookDao.getById('book-1'))!.title, 'Drift title');
    },
  );

  test(
    'defers legacy RSS article status ids without creating orphan rows',
    () async {
      await settingsBox().put('rss_read_articles', '["article-1"]');
      final db = await createTestAppDatabase();
      await db.customStatement('PRAGMA foreign_keys = ON');

      final result = await HiveToDriftMigration(db).migrateAll('en');

      expect(result.scannedRows['rss_articles'], 1);
      expect(await db.rssDao.readArticleIds(), isEmpty);
      expect(
        await db.settingsDao.valueFor(HiveToDriftMigration.completedAtKey),
        isNotEmpty,
      );
    },
  );
}

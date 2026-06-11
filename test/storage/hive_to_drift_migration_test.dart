import 'dart:io';

import 'package:flow_read/models/reader_font.dart';
import 'package:flow_read/storage/database/migration.dart';
import 'package:flow_read/storage/hive_box_names.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import '../support/hive_test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_hive_to_drift_test_');
    await Hive.openBox<dynamic>(HiveBoxNames.settings);
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

    await HiveToDriftMigration(db).migrateAll('en');

    expect(await db.readingConfigDao.valueFor('fontSize', 'en'), '19');
    expect(
      await db.readingConfigDao.valueFor('fontFamily', 'en'),
      ReaderFonts.literata,
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
}

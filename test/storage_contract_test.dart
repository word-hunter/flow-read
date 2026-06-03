import 'dart:io';

import 'package:flow_read/services/backup_service.dart';
import 'package:flow_read/storage/hive_box_names.dart';
import 'package:flow_read/storage/hive_type_ids.dart';
import 'package:flow_read/storage/storage_migrations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_storage_test_');
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test('Hive box and type id contracts stay explicit', () {
    final backupDataBoxes = BackupService.backupDataBoxNames;

    expect(
      HiveBoxNames.bootstrapBoxes.toSet(),
      hasLength(HiveBoxNames.bootstrapBoxes.length),
    );
    expect(backupDataBoxes.toSet(), hasLength(backupDataBoxes.length));
    expect(backupDataBoxes, everyElement(isIn(HiveBoxNames.bootstrapBoxes)));
    expect(backupDataBoxes, contains(HiveBoxNames.learningAnalyticsFor('en')));
    expect(backupDataBoxes, isNot(contains(HiveBoxNames.wordLevels)));
    expect(
      backupDataBoxes,
      isNot(contains(HiveBoxNames.dictionaryCacheFor('en'))),
    );

    expect(HiveTypeIds.reserved, hasLength(7));
  });

  test('storage migrations persist the current schema version', () async {
    await openFlowReadTestBoxes();

    await runStorageMigrations();

    expect(
      settingsBox().get(StorageSchema.versionKey),
      StorageSchema.currentVersion,
    );
  });
}

import 'dart:io';

import 'package:flow_read/services/backup_service.dart';
import 'package:flow_read/storage/legacy_backup_box_names.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initTestStorage('flow_read_storage_test_');
  });

  tearDown(() async {
    await disposeTestStorage(tempDir);
  });

  test('legacy backup box keys stay explicit and unique', () {
    final backupDataBoxes = BackupService.backupDataBoxNames;

    expect(
      LegacyBackupBoxNames.bootstrapBoxes.toSet(),
      hasLength(LegacyBackupBoxNames.bootstrapBoxes.length),
    );
    expect(backupDataBoxes.toSet(), hasLength(backupDataBoxes.length));
    expect(
      backupDataBoxes,
      everyElement(isIn(LegacyBackupBoxNames.bootstrapBoxes)),
    );
    expect(
      backupDataBoxes,
      contains(LegacyBackupBoxNames.learningAnalyticsFor('en')),
    );
    expect(backupDataBoxes, isNot(contains(LegacyBackupBoxNames.wordLevels)));
    expect(
      LegacyBackupBoxNames.bootstrapBoxes,
      contains(LegacyBackupBoxNames.bookGlossary),
    );
    expect(backupDataBoxes, contains(LegacyBackupBoxNames.bookGlossary));
    expect(
      LegacyBackupBoxNames.bootstrapBoxes,
      contains(LegacyBackupBoxNames.characterRegistry),
    );
    expect(backupDataBoxes, contains(LegacyBackupBoxNames.characterRegistry));
    expect(
      backupDataBoxes,
      isNot(contains(LegacyBackupBoxNames.dictionaryCacheFor('en'))),
    );
    expect(backupDataBoxes, isNot(contains('ai_usage_events')));
  });

  test('Drift storage opens with the current schema version', () async {
    final db = await createTestAppDatabase();

    expect(db.schemaVersion, 3);
    expect(await db.settingsDao.allEntries(), isEmpty);
  });
}

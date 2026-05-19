import 'dart:io';

import 'package:flow_read/storage/hive_box_names.dart';
import 'package:flow_read/storage/hive_type_ids.dart';
import 'package:flow_read/storage/storage_migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('flow_read_storage_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Hive box and type id contracts stay explicit', () {
    expect(
      HiveBoxNames.bootstrapBoxes.toSet(),
      hasLength(HiveBoxNames.bootstrapBoxes.length),
    );
    expect(
      HiveBoxNames.backupIncludedBoxes.toSet(),
      hasLength(HiveBoxNames.backupIncludedBoxes.length),
    );
    expect(
      HiveBoxNames.backupIncludedBoxes,
      everyElement(isIn(HiveBoxNames.bootstrapBoxes)),
    );
    expect(
      HiveBoxNames.backupIncludedBoxes,
      isNot(contains(HiveBoxNames.wordLevels)),
    );

    expect(HiveTypeIds.reserved, hasLength(7));
  });

  test('storage migrations persist the current schema version', () async {
    await Hive.openBox(HiveBoxNames.settings);

    await runStorageMigrations();

    expect(
      Hive.box(HiveBoxNames.settings).get(StorageSchema.versionKey),
      StorageSchema.currentVersion,
    );
  });
}

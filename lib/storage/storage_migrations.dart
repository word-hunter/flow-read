import 'package:hive/hive.dart';

import 'hive_box_names.dart';

class StorageSchema {
  const StorageSchema._();

  static const currentVersion = 1;
  static const versionKey = 'flow_read_storage_schema_version';
}

Future<void> runStorageMigrations() async {
  final settings = Hive.box(HiveBoxNames.settings);
  final rawVersion = settings.get(StorageSchema.versionKey);
  final storedVersion = rawVersion is int
      ? rawVersion
      : int.tryParse(rawVersion?.toString() ?? '');

  if (storedVersion == null || storedVersion < StorageSchema.currentVersion) {
    await settings.put(StorageSchema.versionKey, StorageSchema.currentVersion);
  }
}

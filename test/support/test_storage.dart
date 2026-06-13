import 'dart:io';

import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/dao/settings_dao.dart';

final List<AppDatabase> _openTestDatabases = [];

Future<AppDatabase> createTestAppDatabase() async {
  final db = await AppDatabase.createInMemory();
  _openTestDatabases.add(db);
  return db;
}

Future<SettingsService> createTestSettingsService() async {
  final db = await createTestAppDatabase();
  final service = SettingsService(SettingsDao(db));
  await service.init();
  return service;
}

Future<Directory> initTestStorage(String prefix) {
  return Directory.systemTemp.createTemp(prefix);
}

Future<void> openFlowReadTestStorage() async {}

Future<void> disposeTestStorage(Directory tempDir) async {
  final databases = _openTestDatabases.reversed.toList();
  _openTestDatabases.clear();
  for (final db in databases) {
    await db.close();
  }
  if (await tempDir.exists()) {
    await tempDir.delete(recursive: true);
  }
}

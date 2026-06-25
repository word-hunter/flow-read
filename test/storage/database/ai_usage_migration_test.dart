import 'dart:io';

import 'package:drift/native.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'schema 2 database keeps settings while adding ai usage table',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'flow_read_ai_usage_migration_',
      );
      final dbFile = File('${tempDir.path}/flow_read.db');

      final raw = sqlite.sqlite3.open(dbFile.path);
      try {
        raw
          ..execute('''
          CREATE TABLE settings (
            "key" TEXT NOT NULL PRIMARY KEY,
            value TEXT NOT NULL DEFAULT ''
          );
        ''')
          ..execute(
            "INSERT INTO settings (key, value) VALUES ('probe', 'kept');",
          )
          ..execute('PRAGMA user_version = 2;');
      } finally {
        raw.close();
      }

      final database = AppDatabase.forTesting(NativeDatabase(dbFile));
      try {
        expect(await database.settingsDao.valueFor('probe'), 'kept');
        final aiUsageTable = await database
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table' "
              "AND name = 'ai_usage_events'",
            )
            .getSingleOrNull();
        expect(aiUsageTable?.read<String>('name'), 'ai_usage_events');
      } finally {
        await database.close();
        await tempDir.delete(recursive: true);
      }
    },
  );
}

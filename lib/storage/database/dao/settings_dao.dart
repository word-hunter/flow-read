import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<String> valueFor(String key) async {
    final q = select(settings)..where((r) => r.key.equals(key));
    final result = await q.map((r) => r.value).getSingleOrNull();
    return result ?? '';
  }

  Future<void> putValue(String key, String value) =>
      into(settings).insertOnConflictUpdate(
        SettingsCompanion.insert(key: key, value: Value(value)),
      );

  Future<void> removeValue(String key) =>
      (delete(settings)..where((r) => r.key.equals(key))).go();

  Future<Map<String, String>> allEntries() async {
    final rows = await select(settings).get();
    return {for (final r in rows) r.key: r.value};
  }

  Stream<String?> watchValue(String key) {
    final q = select(settings)..where((r) => r.key.equals(key));
    return q.map((r) => r.value).watchSingleOrNull();
  }
}

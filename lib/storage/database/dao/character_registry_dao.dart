import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'character_registry_dao.g.dart';

@DriftAccessor(tables: [CharacterRegistry])
class CharacterRegistryDao extends DatabaseAccessor<AppDatabase>
    with _$CharacterRegistryDaoMixin {
  CharacterRegistryDao(super.db);

  Future<String> valueFor(String key) async {
    final q = select(characterRegistry)..where((r) => r.key.equals(key));
    final result = await q.map((r) => r.value).getSingleOrNull();
    return result ?? '';
  }

  Future<void> putValue(String key, String value) =>
      into(characterRegistry).insertOnConflictUpdate(
        CharacterRegistryCompanion.insert(key: key, value: Value(value)),
      );

  Future<void> deleteByKey(String key) =>
      (delete(characterRegistry)..where((r) => r.key.equals(key))).go();

  Future<Map<String, String>> allEntries() async {
    final rows = await select(characterRegistry).get();
    return {for (final r in rows) r.key: r.value};
  }

  Future<void> clear() => delete(characterRegistry).go();
}

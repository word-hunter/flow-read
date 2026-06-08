import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'reading_config_dao.g.dart';

@DriftAccessor(tables: [ReadingConfig])
class ReadingConfigDao extends DatabaseAccessor<AppDatabase>
    with _$ReadingConfigDaoMixin {
  ReadingConfigDao(super.db);

  Future<String> valueFor(String key, String language) async {
    final q = select(readingConfig)
      ..where((r) => r.key.equals(key) & r.language.equals(language));
    final result = await q.map((r) => r.value).getSingleOrNull();
    return result ?? '';
  }

  Future<void> putValue(String key, String language, String value) =>
      into(readingConfig).insertOnConflictUpdate(
        ReadingConfigCompanion.insert(
          key: key,
          language: Value(language),
          value: Value(value),
        ),
      );

  Future<Map<String, String>> allValues(String language) async {
    final rows = await (select(readingConfig)
          ..where((r) => r.language.equals(language)))
        .get();
    return {for (final r in rows) r.key: r.value};
  }

  Future<void> clearForLanguage(String language) =>
      (delete(readingConfig)..where((r) => r.language.equals(language))).go();
}

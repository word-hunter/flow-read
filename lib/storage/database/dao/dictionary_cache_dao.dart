import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'dictionary_cache_dao.g.dart';

@DriftAccessor(tables: [DictionaryCache])
class DictionaryCacheDao extends DatabaseAccessor<AppDatabase>
    with _$DictionaryCacheDaoMixin {
  DictionaryCacheDao(super.db);

  Future<String?> getValue(String key, String language) {
    final q = select(dictionaryCache)
      ..where((r) => r.key.equals(key) & r.language.equals(language));
    return q.map((r) => r.value).getSingleOrNull();
  }

  Future<void> putValue(String key, String language, String value) =>
      into(dictionaryCache).insertOnConflictUpdate(
        DictionaryCacheCompanion.insert(
          key: key,
          language: Value(language),
          value: value,
        ),
      );

  Future<Map<String, String>> allValues(String language) async {
    final rows =
        await (select(dictionaryCache)
              ..where((r) => r.language.equals(language))
              ..orderBy([(r) => OrderingTerm.asc(r.createdAt)]))
            .get();
    return {
      for (final row in rows) row.key: row.value,
    };
  }

  Future<bool> containsKey(String key, String language) async {
    final result =
        await (selectOnly(dictionaryCache)
              ..addColumns([dictionaryCache.key])
              ..where(
                dictionaryCache.key.equals(key) &
                    dictionaryCache.language.equals(language),
              ))
            .map((r) => r.read(dictionaryCache.key))
            .getSingleOrNull();
    return result != null;
  }

  Future<int> countForLanguage(String language) {
    return (selectOnly(dictionaryCache)
          ..addColumns([dictionaryCache.key])
          ..where(dictionaryCache.language.equals(language)))
        .map((r) => r.read(dictionaryCache.key))
        .get()
        .then((rows) => rows.length);
  }

  Future<void> deleteByKey(String key, String language) =>
      (delete(dictionaryCache)..where(
            (r) => r.key.equals(key) & r.language.equals(language),
          ))
          .go();

  Future<void> clearForLanguage(String language) =>
      (delete(dictionaryCache)..where((r) => r.language.equals(language))).go();
}

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'word_level_dao.g.dart';

@DriftAccessor(tables: [WordLevels])
class WordLevelDao extends DatabaseAccessor<AppDatabase>
    with _$WordLevelDaoMixin {
  WordLevelDao(super.db);

  Future<List<WordLevelEntry>> allEntries() => select(wordLevels).get();

  Future<bool> get hasEntries async {
    final count = await (selectOnly(wordLevels)
          ..addColumns([wordLevels.word]))
        .map((r) => r.read(wordLevels.word))
        .getSingleOrNull();
    return count != null;
  }

  Future<void> insertAll(List<WordLevelsCompanion> entries) =>
      batch((b) {
        b.insertAllOnConflictUpdate(wordLevels, entries);
      });

  Future<void> clear() => delete(wordLevels).go();
}

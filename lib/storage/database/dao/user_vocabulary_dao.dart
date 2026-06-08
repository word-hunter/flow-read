import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'user_vocabulary_dao.g.dart';

@DriftAccessor(tables: [UserVocabularies])
class UserVocabularyDao extends DatabaseAccessor<AppDatabase>
    with _$UserVocabularyDaoMixin {
  UserVocabularyDao(super.db);

  Future<UserVocabulary?> entryFor(String id) {
    final q = select(userVocabularies)..where((r) => r.id.equals(id));
    return q.getSingleOrNull();
  }

  Future<List<UserVocabulary>> wordsWithStatus(
    String language,
    String status,
  ) =>
      (select(userVocabularies)
            ..where(
              (r) => r.language.equals(language) & r.status.equals(status),
            ))
          .get();

  Future<Map<String, String>> allWords(String language) async {
    final rows = await (select(userVocabularies)
          ..where((r) => r.language.equals(language)))
        .get();
    return {for (final r in rows) r.canonical: r.status};
  }

  Future<void> upsert(UserVocabulariesCompanion entry) =>
      into(userVocabularies).insertOnConflictUpdate(entry);

  Future<void> deleteById(String id) =>
      (delete(userVocabularies)..where((r) => r.id.equals(id))).go();

  Future<void> clearForLanguage(String language) =>
      (delete(userVocabularies)..where((r) => r.language.equals(language)))
          .go();
}

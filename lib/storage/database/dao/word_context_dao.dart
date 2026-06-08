import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'word_context_dao.g.dart';

@DriftAccessor(tables: [WordContexts])
class WordContextDao extends DatabaseAccessor<AppDatabase>
    with _$WordContextDaoMixin {
  WordContextDao(super.db);

  Future<String?> dataFor(String word, String language) {
    final q = select(wordContexts)
      ..where((r) => r.word.equals(word) & r.language.equals(language));
    return q.map((r) => r.data).getSingleOrNull();
  }

  Future<void> putData(String word, String language, String data) =>
      into(wordContexts).insertOnConflictUpdate(
        WordContextsCompanion.insert(
          word: word,
          language: Value(language),
          data: data,
        ),
      );

  Future<void> deleteByWord(String word, String language) =>
      (delete(wordContexts)
            ..where(
              (r) => r.word.equals(word) & r.language.equals(language),
            ))
          .go();

  Future<void> clearForLanguage(String language) =>
      (delete(wordContexts)..where((r) => r.language.equals(language))).go();
}

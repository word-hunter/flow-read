import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'book_glossary_dao.g.dart';

@DriftAccessor(tables: [BookGlossary])
class BookGlossaryDao extends DatabaseAccessor<AppDatabase>
    with _$BookGlossaryDaoMixin {
  BookGlossaryDao(super.db);

  Future<List<BookGlossaryEntry>> allEntries() =>
      (select(bookGlossary)..orderBy([(r) => OrderingTerm.asc(r.word)])).get();

  Future<List<BookGlossaryEntry>> entriesForBook(String bookId) =>
      (select(bookGlossary)
            ..where((r) => r.bookId.equals(bookId))
            ..orderBy([(r) => OrderingTerm.asc(r.word)]))
          .get();

  Future<BookGlossaryEntry?> entryFor(String id) {
    final q = select(bookGlossary)..where((r) => r.id.equals(id));
    return q.getSingleOrNull();
  }

  Future<List<BookGlossaryEntry>> findByWord(String bookId, String word) =>
      (select(
        bookGlossary,
      )..where((r) => r.bookId.equals(bookId) & r.word.equals(word))).get();

  Future<void> upsert(BookGlossaryCompanion entry) =>
      into(bookGlossary).insertOnConflictUpdate(entry);

  Future<void> updateLastAccessed(String id) {
    final now = DateTime.now().toUtc().toIso8601String();
    return (update(bookGlossary)..where((r) => r.id.equals(id))).write(
      BookGlossaryCompanion(lastAccessedAt: Value(now)),
    );
  }

  Future<void> deleteById(String id) =>
      (delete(bookGlossary)..where((r) => r.id.equals(id))).go();

  Future<void> deleteAllForBook(String bookId) =>
      (delete(bookGlossary)..where((r) => r.bookId.equals(bookId))).go();

  Future<void> deleteAll() => delete(bookGlossary).go();
}

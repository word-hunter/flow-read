import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'book_dao.g.dart';

@DriftAccessor(tables: [BookEntries])
class BookDao extends DatabaseAccessor<AppDatabase> with _$BookDaoMixin {
  BookDao(super.db);

  Future<List<BookEntry>> allBooks(String language) =>
      (select(bookEntries)..where((b) => b.language.equals(language))).get();

  Future<List<BookEntry>> recentlyReadBooks(String language, {int limit = 20}) {
    final q = select(bookEntries)
      ..where((b) => b.language.equals(language) & b.lastReadAt.isNotNull())
      ..orderBy([(b) => OrderingTerm.desc(b.lastReadAt)])
      ..limit(limit);
    return q.get();
  }

  Future<BookEntry?> getById(String id) {
    final q = select(bookEntries)..where((b) => b.id.equals(id));
    return q.getSingleOrNull();
  }

  Stream<BookEntry?> watchById(String id) {
    final q = select(bookEntries)..where((b) => b.id.equals(id));
    return q.watchSingleOrNull();
  }

  Future<void> upsert(BookEntriesCompanion entry) =>
      into(bookEntries).insertOnConflictUpdate(entry);

  Future<void> deleteById(String id) =>
      (delete(bookEntries)..where((b) => b.id.equals(id))).go();

  Future<void> deleteAll() => delete(bookEntries).go();

  Stream<List<BookEntry>> watchAll(String language) =>
      (select(bookEntries)..where((b) => b.language.equals(language))).watch();
}

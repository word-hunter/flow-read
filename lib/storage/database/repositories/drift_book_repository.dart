import '../app_database.dart';
import '../dao/book_dao.dart';

final class DriftBookRepository {
  final BookDao _dao;

  DriftBookRepository(this._dao);

  Future<List<BookEntry>> allBooks(String language) => _dao.allBooks(language);

  Future<BookEntry?> getById(String id) => _dao.getById(id);

  Future<List<BookEntry>> recentlyRead(String language, {int limit = 20}) =>
      _dao.recentlyReadBooks(language, limit: limit);

  Future<void> upsert(BookEntriesCompanion entry) => _dao.upsert(entry);

  Future<void> deleteById(String id) => _dao.deleteById(id);

  Stream<List<BookEntry>> watchAll(String language) => _dao.watchAll(language);

  Stream<BookEntry?> watchById(String id) => _dao.watchById(id);
}

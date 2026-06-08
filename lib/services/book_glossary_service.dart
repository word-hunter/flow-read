import 'package:drift/drift.dart';

import '../models/book_glossary_entry.dart' as model;
import '../storage/database/app_database.dart';
import '../storage/database/dao/book_glossary_dao.dart';

final class BookGlossaryService {
  final BookGlossaryDao _dao;

  BookGlossaryService(this._dao);

  Future<model.BookGlossaryEntry?> getEntry({
    required String bookId,
    required String word,
    String? canonicalForm,
  }) async {
    final id = model.BookGlossaryEntry.buildId(
      bookId: bookId,
      word: word.toLowerCase().trim(),
      canonicalForm: canonicalForm?.toLowerCase().trim(),
    );
    final row = await _dao.entryFor(id);
    return row?.let(_toModel);
  }

  Future<void> saveEntry(model.BookGlossaryEntry entry) async {
    await _dao.upsert(
      BookGlossaryCompanion.insert(
        id: entry.id,
        bookId: entry.bookId,
        word: entry.word,
        canonicalForm: Value(entry.canonicalForm),
        explanation: Value(entry.explanation),
        sourceContext: Value(entry.sourceContext),
        createdAt: Value(entry.createdAt.toUtc().toIso8601String()),
        lastAccessedAt: Value(DateTime.now().toUtc().toIso8601String()),
      ),
    );
  }

  Future<void> saveAll(List<model.BookGlossaryEntry> entries) async {
    if (entries.isEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    for (final entry in entries) {
      await _dao.upsert(
        BookGlossaryCompanion.insert(
          id: entry.id,
          bookId: entry.bookId,
          word: entry.word,
          canonicalForm: Value(entry.canonicalForm),
          explanation: Value(entry.explanation),
          sourceContext: Value(entry.sourceContext),
          createdAt: Value(entry.createdAt.toUtc().toIso8601String()),
          lastAccessedAt: Value(now),
        ),
      );
    }
  }

  Future<List<model.BookGlossaryEntry>> getBookGlossary(String bookId) async {
    final rows = await _dao.entriesForBook(bookId);
    return rows.map(_toModel).toList();
  }

  Future<void> clearBookGlossary(String bookId) async {
    await _dao.deleteAllForBook(bookId);
  }

  model.BookGlossaryEntry _toModel(BookGlossaryEntry row) {
    return model.BookGlossaryEntry(
      id: row.id,
      bookId: row.bookId,
      word: row.word,
      canonicalForm: row.canonicalForm,
      explanation: row.explanation,
      sourceContext: row.sourceContext,
      createdAt: DateTime.tryParse(row.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      lastAccessedAt: row.lastAccessedAt?.let(DateTime.tryParse),
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T it) transform) => transform(this);
}

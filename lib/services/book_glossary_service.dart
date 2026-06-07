import 'package:hive/hive.dart';

import '../models/book_glossary_entry.dart';
import '../storage/hive_box_names.dart';

class BookGlossaryService {
  Box<BookGlossaryEntry> get _box =>
      Hive.box<BookGlossaryEntry>(HiveBoxNames.bookGlossary);

  BookGlossaryEntry? getEntry({
    required String bookId,
    required String word,
    String? canonicalForm,
  }) {
    final id = BookGlossaryEntry.buildId(
      bookId: bookId,
      word: word.toLowerCase().trim(),
      canonicalForm: canonicalForm?.toLowerCase().trim(),
    );
    return _box.get(id);
  }

  Future<void> saveEntry(BookGlossaryEntry entry) async {
    final touched = BookGlossaryEntry(
      id: entry.id,
      bookId: entry.bookId,
      word: entry.word,
      canonicalForm: entry.canonicalForm,
      explanation: entry.explanation,
      sourceContext: entry.sourceContext,
      createdAt: entry.createdAt,
      lastAccessedAt: DateTime.now(),
    );
    await _box.put(touched.id, touched);
  }

  Future<void> saveAll(List<BookGlossaryEntry> entries) async {
    final now = DateTime.now();
    await _box.putAll({
      for (final entry in entries)
        entry.id: BookGlossaryEntry(
          id: entry.id,
          bookId: entry.bookId,
          word: entry.word,
          canonicalForm: entry.canonicalForm,
          explanation: entry.explanation,
          sourceContext: entry.sourceContext,
          createdAt: entry.createdAt,
          lastAccessedAt: now,
        ),
    });
  }

  List<BookGlossaryEntry> getBookGlossary(String bookId) {
    return _box.values.where((entry) => entry.bookId == bookId).toList();
  }

  Future<void> clearBookGlossary(String bookId) async {
    final keys = <dynamic>[];
    for (final entry in _box.values) {
      if (entry.bookId == bookId) {
        keys.add(entry.id);
      }
    }
    await _box.deleteAll(keys);
  }
}

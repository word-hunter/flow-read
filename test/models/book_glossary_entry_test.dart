import 'dart:io';

import 'package:flow_read/models/book_glossary_entry.dart';
import 'package:flow_read/storage/hive_box_names.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import '../support/hive_test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_book_glossary_test_');
    await openFlowReadTestBoxes();
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test('builds stable ids and round-trips through JSON', () {
    final createdAt = DateTime.utc(2026, 6, 6);
    final entry = BookGlossaryEntry.create(
      bookId: 'book-1',
      word: 'Godswood',
      canonicalForm: 'Godswood',
      explanation: 'A sacred grove within the story world.',
      sourceContext: 'The godswood was silent.',
      createdAt: createdAt,
    );

    expect(
      entry.id,
      BookGlossaryEntry.buildId(
        bookId: 'book-1',
        word: 'godswood',
        canonicalForm: 'godswood',
      ),
    );

    final restored = BookGlossaryEntry.fromJson(entry.toJson());
    expect(restored.id, entry.id);
    expect(restored.word, 'Godswood');
    expect(restored.createdAt, createdAt);
  });

  test('persists in the global book glossary Hive box', () async {
    final box = Hive.box<BookGlossaryEntry>(HiveBoxNames.bookGlossary);
    final entry = BookGlossaryEntry.create(
      bookId: 'book-1',
      word: 'flow',
      explanation: 'Movement in context.',
      createdAt: DateTime.utc(2026, 6, 6),
    );

    await box.put(entry.id, entry);

    expect(box.get(entry.id)?.explanation, 'Movement in context.');
  });
}

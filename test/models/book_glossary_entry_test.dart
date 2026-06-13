import 'dart:io';

import 'package:flow_read/models/book_glossary_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initTestStorage('flow_read_book_glossary_test_');
    await openFlowReadTestStorage();
  });

  tearDown(() async {
    await disposeTestStorage(tempDir);
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
}

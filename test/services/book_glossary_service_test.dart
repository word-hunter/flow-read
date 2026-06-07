import 'dart:io';

import 'package:flow_read/models/book_glossary_entry.dart';
import 'package:flow_read/services/book_glossary_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/hive_test_storage.dart';

void main() {
  late Directory tempDir;
  late BookGlossaryService service;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_glossary_service_test_');
    await openFlowReadTestBoxes();
    service = BookGlossaryService();
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test('getEntry returns null when no entry exists', () {
    expect(
      service.getEntry(bookId: 'book-1', word: 'godswood'),
      isNull,
    );
  });

  test('saveEntry persists and getEntry retrieves', () async {
    final entry = BookGlossaryEntry.create(
      bookId: 'book-1',
      word: 'Godswood',
      explanation: 'A sacred grove.',
      sourceContext: 'The godswood was silent.',
      createdAt: DateTime.utc(2026, 6, 1),
    );

    await service.saveEntry(entry);

    final retrieved = service.getEntry(bookId: 'book-1', word: 'godswood');
    expect(retrieved, isNotNull);
    expect(retrieved!.explanation, 'A sacred grove.');
    expect(retrieved.sourceContext, 'The godswood was silent.');
    expect(retrieved.lastAccessedAt, isNotNull);
  });

  test('getEntry with canonicalForm matches correctly', () {
    final entry = BookGlossaryEntry.create(
      bookId: 'book-2',
      word: 'Dumbledore',
      canonicalForm: 'dumbledore',
      explanation: 'Headmaster of Hogwarts.',
      createdAt: DateTime.utc(2026, 6, 1),
    );

    service.saveEntry(entry);

    final retrieved = service.getEntry(
      bookId: 'book-2',
      word: 'Dumbledore',
      canonicalForm: 'dumbledore',
    );
    expect(retrieved, isNotNull);
    expect(retrieved!.canonicalForm, 'dumbledore');
  });

  test('getEntry returns null for different book', () async {
    await service.saveEntry(
      BookGlossaryEntry.create(
        bookId: 'book-a',
        word: 'flow',
        explanation: 'A movement.',
        createdAt: DateTime.utc(2026, 6, 1),
      ),
    );

    expect(
      service.getEntry(bookId: 'book-b', word: 'flow'),
      isNull,
    );
  });

  test('saveAll persists multiple entries', () async {
    final entries = [
      BookGlossaryEntry.create(
        bookId: 'book-3',
        word: 'godswood',
        explanation: 'Sacred grove.',
        createdAt: DateTime.utc(2026, 6, 1),
      ),
      BookGlossaryEntry.create(
        bookId: 'book-3',
        word: 'weirwood',
        explanation: 'Ancient tree.',
        createdAt: DateTime.utc(2026, 6, 1),
      ),
    ];

    await service.saveAll(entries);

    expect(service.getEntry(bookId: 'book-3', word: 'godswood'), isNotNull);
    expect(service.getEntry(bookId: 'book-3', word: 'weirwood'), isNotNull);
  });

  test('getBookGlossary returns all entries for a book', () async {
    await service.saveEntry(
      BookGlossaryEntry.create(
        bookId: 'book-gl',
        word: 'word1',
        explanation: 'First word.',
        createdAt: DateTime.utc(2026, 6, 1),
      ),
    );
    await service.saveEntry(
      BookGlossaryEntry.create(
        bookId: 'book-gl',
        word: 'word2',
        explanation: 'Second word.',
        createdAt: DateTime.utc(2026, 6, 1),
      ),
    );
    await service.saveEntry(
      BookGlossaryEntry.create(
        bookId: 'other-book',
        word: 'word3',
        explanation: 'Other book word.',
        createdAt: DateTime.utc(2026, 6, 1),
      ),
    );

    final glossary = service.getBookGlossary('book-gl');
    expect(glossary, hasLength(2));
  });

  test('clearBookGlossary removes entries for a book only', () async {
    await service.saveEntry(
      BookGlossaryEntry.create(
        bookId: 'book-clr',
        word: 'word-a',
        explanation: 'A.',
        createdAt: DateTime.utc(2026, 6, 1),
      ),
    );
    await service.saveEntry(
      BookGlossaryEntry.create(
        bookId: 'book-keep',
        word: 'word-b',
        explanation: 'B.',
        createdAt: DateTime.utc(2026, 6, 1),
      ),
    );

    await service.clearBookGlossary('book-clr');

    expect(service.getEntry(bookId: 'book-clr', word: 'word-a'), isNull);
    expect(service.getEntry(bookId: 'book-keep', word: 'word-b'), isNotNull);
  });

  test('getEntry matches regardless of word casing', () {
    final entry = BookGlossaryEntry.create(
      bookId: 'book-case',
      word: 'Godswood',
      explanation: 'Capitalized.',
      createdAt: DateTime.utc(2026, 6, 1),
    );

    service.saveEntry(entry);

    expect(
      service.getEntry(bookId: 'book-case', word: 'godswood'),
      isNotNull,
    );
    expect(
      service.getEntry(bookId: 'book-case', word: 'GODSWOOD'),
      isNotNull,
    );
    expect(
      service.getEntry(bookId: 'book-case', word: 'Godswood'),
      isNotNull,
    );
  });
}

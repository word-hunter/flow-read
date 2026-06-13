import 'dart:io';

import 'package:flow_read/models/book.dart';
import 'package:flow_read/models/chapter.dart';
import 'package:flow_read/services/learning_analytics_service.dart';
import 'package:flow_read/services/reading_insight_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_learning_analytics_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_storage.dart';

Chapter _chapter(String title, String text) {
  return Chapter(title: title, plainText: text, rawHtml: '');
}

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late LearningAnalyticsService analytics;
  late ReadingInsightService service;

  setUp(() async {
    tempDir = await initTestStorage('flow_read_insight_test_');
    db = await createTestAppDatabase();
    analytics = LearningAnalyticsService(
      repository: DriftLearningAnalyticsRepository(
        db.learningAnalyticsDao,
        languageCode: 'en',
      ),
    );
    await analytics.init();
    service = ReadingInsightService(analytics: analytics);
  });

  tearDown(() async {
    await disposeTestStorage(tempDir);
  });

  test('returns empty profile when no lookups recorded', () {
    final book = Book(
      title: 'Test',
      author: 'Author',
      chapters: [_chapter('Ch1', 'hello world foo bar')],
    );

    final profile = service.compute(bookId: 'book-1', book: book);

    expect(profile.isEmpty, isTrue);
    expect(profile.lookupDensity, 0);
    expect(profile.recheckRate, 0);
  });

  test('computes lookup density correctly', () async {
    await analytics.recordLookup(
      bookId: 'book-1',
      chapterIndex: 0,
      word: 'hello',
    );
    await analytics.recordLookup(
      bookId: 'book-1',
      chapterIndex: 0,
      word: 'world',
    );

    final book = Book(
      title: 'Test',
      author: 'Author',
      chapters: [_chapter('Ch1', 'hello world foo bar baz qux')],
    );

    final profile = service.compute(bookId: 'book-1', book: book);

    expect(profile.lookupDensity, greaterThan(0));
    expect(profile.lookupDensity, closeTo(2.0 / 6 * 1000, 0.1));
    expect(profile.recheckRate, 0);
  });

  test('computes recheck rate from repeated lookups', () async {
    await analytics.recordLookup(
      bookId: 'book-r',
      chapterIndex: 0,
      word: 'hello',
    );
    await analytics.recordLookup(
      bookId: 'book-r',
      chapterIndex: 0,
      word: 'hello',
    );
    await analytics.recordLookup(
      bookId: 'book-r',
      chapterIndex: 0,
      word: 'hello',
    );
    await analytics.recordLookup(
      bookId: 'book-r',
      chapterIndex: 0,
      word: 'world',
    );

    final book = Book(
      title: 'Test',
      author: 'Author',
      chapters: [_chapter('Ch1', 'hello world foo bar')],
    );

    final profile = service.compute(bookId: 'book-r', book: book);

    expect(profile.recheckRate, greaterThan(0));
    expect(profile.isEmpty, isFalse);
  });

  test('aggregates lookups across multiple chapters', () async {
    await analytics.recordLookup(
      bookId: 'book-m',
      chapterIndex: 0,
      word: 'alpha',
    );
    await analytics.recordLookup(
      bookId: 'book-m',
      chapterIndex: 1,
      word: 'beta',
    );

    final book = Book(
      title: 'Multi',
      author: 'Author',
      chapters: [
        _chapter('Ch1', 'alpha one two'),
        _chapter('Ch2', 'beta three four'),
      ],
    );

    final profile = service.compute(bookId: 'book-m', book: book);

    expect(profile.lookupDensity, closeTo(2.0 / 6 * 1000, 0.1));
  });

  test('handles book with no chapters', () {
    final book = Book(
      title: 'Empty',
      author: 'Author',
      chapters: const [],
    );

    final profile = service.compute(bookId: 'book-e', book: book);

    expect(profile.isEmpty, isTrue);
    expect(profile.lookupDensity, 0);
  });

  test('learningFocusSummary includes density and recheck rate', () async {
    await analytics.recordLookup(
      bookId: 'book-f',
      chapterIndex: 0,
      word: 'word1',
    );
    await analytics.recordLookup(
      bookId: 'book-f',
      chapterIndex: 0,
      word: 'word1',
    );
    await analytics.recordLookup(
      bookId: 'book-f',
      chapterIndex: 0,
      word: 'word2',
    );

    final book = Book(
      title: 'Focus',
      author: 'Author',
      chapters: [
        _chapter('Ch1', 'this is a short passage with some words in it'),
      ],
    );

    final profile = service.compute(bookId: 'book-f', book: book);

    final summary = profile.learningFocusSummary;
    expect(summary, contains('Lookup density'));
    expect(summary, contains('Recheck rate'));
    expect(summary.length, lessThanOrEqualTo(800));
  });

  test('learningFocusSummary is empty for empty profile', () {
    final book = Book(
      title: 'Empty',
      author: 'Author',
      chapters: [_chapter('Ch1', 'some text')],
    );

    final profile = service.compute(bookId: 'book-g', book: book);
    final summary = profile.learningFocusSummary;

    expect(summary, isEmpty);
  });
}

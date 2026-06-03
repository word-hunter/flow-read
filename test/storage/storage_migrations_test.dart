import 'dart:io';

import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/models/learning_item.dart';
import 'package:flow_read/storage/hive_box_names.dart';
import 'package:flow_read/storage/storage_migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import '../support/hive_test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_storage_migration_test_');
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test('migrates v1 language scoped boxes into the English view', () async {
    final settings = await Hive.openBox<dynamic>(HiveBoxNames.settings);
    final oldBooks = await Hive.openBox<BookMetadata>(HiveBoxNames.books);
    final oldVocabulary = await Hive.openBox<String>(
      HiveBoxNames.userVocabulary,
    );
    final oldWordBookmarks = await Hive.openBox<String>(
      HiveBoxNames.wordBookmarks,
    );
    final oldWordContexts = await Hive.openBox<String>(
      HiveBoxNames.wordContexts,
    );
    final oldReadingBookmarks = await Hive.openBox<String>(
      HiveBoxNames.readingBookmarks,
    );
    final oldReadingConfig = await Hive.openBox<String>(
      HiveBoxNames.readingConfig,
    );
    final oldReadingTime = await Hive.openBox<int>(HiveBoxNames.readingTime);
    final oldLearningItems = await Hive.openBox<LearningItem>(
      HiveBoxNames.learningItems,
    );
    final oldLearningAnalytics = await Hive.openBox<int>(
      HiveBoxNames.learningAnalytics,
    );

    const book = BookMetadata(
      id: 'book-1',
      title: 'Flow',
      author: 'Author',
      sourcePath: '/books/flow.epub',
      totalChapters: 1,
    );
    await oldBooks.put(book.id, book);
    await oldVocabulary.put('flow', 'known');
    await oldWordBookmarks.put('book-1', '[word]');
    await oldWordContexts.put('flow', '[context]');
    await oldReadingBookmarks.put('book-1', '[bookmark]');
    await oldReadingConfig.put('fontSize', '18');
    await oldReadingTime.put('book-1', 42);
    final createdAt = DateTime.utc(2026, 6, 3);
    await oldLearningItems.put(
      'item-1',
      LearningItem(
        id: 'item-1',
        type: LearningItemType.word,
        canonicalKey: 'flow',
        title: 'flow',
        content: 'flow',
        answer: '',
        note: '',
        sourceText: 'A steady flow.',
        bookId: 'book-1',
        chapterIndex: 0,
        chapterTitle: 'Flow',
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );
    await oldLearningAnalytics.put('lookups', 3);

    await runStorageMigrations();

    expect(settings.get(StorageSchema.versionKey), 2);
    expect(settings.get(HiveBoxNames.activeSourceLanguageKey), 'en');
    expect(
      Hive.box<BookMetadata>(HiveBoxNames.booksFor('en')).get('book-1')?.title,
      'Flow',
    );
    expect(
      Hive.box<String>(HiveBoxNames.userVocabularyFor('en')).get('flow'),
      'known',
    );
    expect(
      Hive.box<String>(HiveBoxNames.wordBookmarksFor('en')).get('book-1'),
      '[word]',
    );
    expect(
      Hive.box<String>(HiveBoxNames.wordContextsFor('en')).get('flow'),
      '[context]',
    );
    expect(
      Hive.box<String>(HiveBoxNames.readingBookmarksFor('en')).get('book-1'),
      '[bookmark]',
    );
    expect(
      Hive.box<String>(HiveBoxNames.readingConfigFor('en')).get('fontSize'),
      '18',
    );
    expect(Hive.box<int>(HiveBoxNames.readingTimeFor('en')).get('book-1'), 42);
    expect(
      Hive.box<LearningItem>(
        HiveBoxNames.learningItemsFor('en'),
      ).get('item-1')?.canonicalKey,
      'flow',
    );
    expect(
      Hive.box<int>(HiveBoxNames.learningAnalyticsFor('en')).get('lookups'),
      3,
    );

    expect(v1BooksBox().get('book-1')?.title, book.title);
    expect(v1UserVocabularyBox().get('flow'), 'known');
  });

  test(
    'migration can run repeatedly without duplicating or deleting v1 data',
    () async {
      await Hive.openBox<dynamic>(HiveBoxNames.settings);
      final oldVocabulary = await Hive.openBox<String>(
        HiveBoxNames.userVocabulary,
      );
      await oldVocabulary.put('flow', 'known');

      await runStorageMigrations();
      await runStorageMigrations();

      expect(
        Hive.box<String>(HiveBoxNames.userVocabularyFor('en')).get('flow'),
        'known',
      );
      expect(oldVocabulary.get('flow'), 'known');
    },
  );
}

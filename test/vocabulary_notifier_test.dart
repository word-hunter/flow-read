import 'dart:io';

import 'package:flow_read/models/book_difficulty.dart';
import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/providers/reading/bookshelf_notifier.dart';
import 'package:flow_read/providers/reading/services_provider.dart';
import 'package:flow_read/providers/reading/vocabulary_notifier.dart';
import 'package:flow_read/services/book_service.dart';
import 'package:flow_read/services/word_level_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_vocabulary_notifier_test_');
    await openFlowReadTestBoxes();
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test('active book difficulty falls back to cached shelf rating', () async {
    final documentsDir = await Directory('${tempDir.path}/documents').create();
    final bookService = BookService(
      documentsDirectoryProvider: () async => documentsDir,
    );
    await bookService.init();
    final wordLevelService = WordLevelService(assetLoader: (_) async => '');
    await wordLevelService.init();
    await bookService.addBook(
      BookMetadata(
        id: 'book-1',
        title: 'Fixture',
        author: 'Author',
        sourcePath: '/imports/fixture.epub',
        difficultyRatingJson: _rating(BookDifficultyLevel.l4).toJson(),
      ),
    );

    final bookshelf = _FakeBookshelfNotifier();
    final container = ProviderContainer(
      overrides: [
        bookServiceProvider.overrideWithValue(bookService),
        wordLevelServiceProvider.overrideWithValue(wordLevelService),
        bookshelfNotifierProvider.overrideWith(() => bookshelf),
      ],
    );
    addTearDown(container.dispose);

    final vocabulary = container.read(vocabularyNotifierProvider.notifier);
    expect(
      vocabulary.difficultyForBook('book-1')?.level,
      BookDifficultyLevel.l4,
    );

    bookshelf.setActiveBook('book-1');

    expect(
      vocabulary.difficultyForBook('book-1')?.level,
      BookDifficultyLevel.l4,
    );
  });
}

class _FakeBookshelfNotifier extends BookshelfNotifier {
  @override
  BookshelfState build() {
    return BookshelfState(books: ref.read(bookServiceProvider).books);
  }

  void setActiveBook(String bookId) {
    state = state.copyWith(activeBookId: bookId);
  }
}

BookDifficultyRating _rating(BookDifficultyLevel level) {
  return BookDifficultyRating(
    studyWordCount: 120,
    masteredWordCount: 40,
    userKnownWordCount: 1000,
    learningWordCount: 8,
    newWordCount: 22,
    weightedNewWordCount: 26,
    newWordToKnownRatio: 0.08,
    score: 60,
    level: level,
  );
}

import 'dart:io';

import 'package:flow_read/models/book.dart';
import 'package:flow_read/models/book_difficulty.dart';
import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/models/chapter.dart';
import 'package:flow_read/providers/reading/current_book_notifier.dart';
import 'package:flow_read/providers/reading/bookshelf_notifier.dart';
import 'package:flow_read/providers/reading/services_provider.dart';
import 'package:flow_read/providers/reading/vocabulary_notifier.dart';
import 'package:flow_read/services/book_service.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/services/word_level_service.dart';
import 'package:flow_read/providers/settings_provider.dart';
import 'package:flow_read/storage/repositories/book_metadata_repository.dart';
import 'package:flow_read/storage/repositories/user_vocabulary_repository.dart';
import 'package:flow_read/storage/repositories/word_level_repository.dart';
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
      repository: HiveBookMetadataRepository(),
      documentsDirectoryProvider: () async => documentsDir,
    );
    await bookService.init();
    final wordLevelService = WordLevelService(
      repository: HiveWordLevelRepository(),
      assetLoader: (_) async => '',
    );
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

  test(
    'marking a lemma known refreshes current chapter word highlights',
    () async {
      final settings = await createTestSettingsService();
      final userVocabulary = UserVocabularyService(
        repository: HiveUserVocabularyRepository(),
      );
      await userVocabulary.init();
      final wordLevelService = WordLevelService(
        repository: HiveWordLevelRepository(),
        assetLoader: (_) async =>
            'reassemble\treassemble\to\n'
            'reassembling\treassemble\to\n',
      );
      await wordLevelService.init();
      final book = Book(
        title: 'Fixture',
        author: 'Author',
        language: 'en',
        chapters: const [
          Chapter(
            title: 'Chapter 1',
            plainText: 'They kept reassembling the device.',
            rawHtml: '',
          ),
        ],
      );
      final bookshelf = _ReaderBookshelfNotifier(book);
      final bookService = _NoopBookService(
        books: [
          const BookMetadata(
            id: 'book-1',
            title: 'Fixture',
            author: 'Author',
            sourcePath: '/imports/fixture.epub',
            sourceLanguage: 'en',
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith((ref) => settings),
          bookServiceProvider.overrideWithValue(bookService),
          userVocabularyServiceProvider.overrideWithValue(userVocabulary),
          wordLevelServiceProvider.overrideWithValue(wordLevelService),
          bookshelfNotifierProvider.overrideWith(() => bookshelf),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(currentBookNotifierProvider.notifier)
          .reanalyzeCurrentChapter();
      expect(
        container
            .read(currentBookNotifierProvider)
            .result
            ?.vocabulary
            .map((item) => item.word),
        contains('reassemble'),
      );

      await container
          .read(vocabularyNotifierProvider.notifier)
          .markWordKnown('reassemble');

      final refreshed = container.read(currentBookNotifierProvider).result;
      expect(refreshed?.knownWords, contains('reassemble'));
      expect(
        refreshed?.vocabulary.map((item) => item.word),
        isNot(contains('reassemble')),
      );
    },
  );
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

class _ReaderBookshelfNotifier extends BookshelfNotifier {
  _ReaderBookshelfNotifier(this._book);

  final Book _book;

  @override
  BookshelfState build() {
    return BookshelfState(activeBookId: 'book-1', book: _book);
  }
}

class _NoopBookService extends BookService {
  _NoopBookService({required List<BookMetadata> books})
    : _books = books,
      super(repository: HiveBookMetadataRepository());

  final List<BookMetadata> _books;

  @override
  List<BookMetadata> get books => _books;
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

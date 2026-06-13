import 'package:flow_read/models/book.dart';
import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/models/chapter.dart';
import 'package:flow_read/models/user_vocabulary.dart';
import 'package:flow_read/models/word_level.dart';
import 'package:flow_read/providers/reading/bookshelf_notifier.dart';
import 'package:flow_read/providers/reading/current_book_notifier.dart';
import 'package:flow_read/providers/reading/services_provider.dart';
import 'package:flow_read/providers/settings_provider.dart';
import 'package:flow_read/services/book_service.dart';
import 'package:flow_read/services/reading_time_service.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/services/word_level_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/dao/settings_dao.dart';
import 'package:flow_read/storage/repositories/book_metadata_repository.dart';
import 'package:flow_read/storage/repositories/reading_time_repository.dart';
import 'package:flow_read/storage/repositories/user_vocabulary_repository.dart';
import 'package:flow_read/storage/repositories/word_level_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('updateReadingProgress skips nearly identical scroll positions', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var notifications = 0;
    final subscription = container.listen<CurrentBookState>(
      currentBookNotifierProvider,
      (_, _) => notifications += 1,
    );
    addTearDown(subscription.close);

    final notifier = container.read(currentBookNotifierProvider.notifier);
    notifier.updateReadingProgress(0.25, scrollOffset: 100);

    expect(notifications, 1);
    expect(container.read(currentBookNotifierProvider).readingProgress, 0.25);
    expect(
      container.read(currentBookNotifierProvider).readingScrollOffset,
      100,
    );

    notifier.updateReadingProgress(0.2501, scrollOffset: 100.2);

    expect(notifications, 1);
    expect(container.read(currentBookNotifierProvider).readingProgress, 0.25);
    expect(
      container.read(currentBookNotifierProvider).readingScrollOffset,
      100,
    );

    notifier.updateReadingProgress(0.26, scrollOffset: 120);

    expect(notifications, 2);
    expect(container.read(currentBookNotifierProvider).readingProgress, 0.26);
    expect(
      container.read(currentBookNotifierProvider).readingScrollOffset,
      120,
    );
  });

  testWidgets(
    'goToChapter analyzes first chapter when current index is unchanged',
    (tester) async {
      final db = await AppDatabase.createInMemory();
      addTearDown(db.close);
      final settings = SettingsService(SettingsDao(db));
      await settings.init();
      settings.activeSourceLanguage = 'zh';
      final userVocabulary = UserVocabularyService(
        repository: _MemoryUserVocabularyRepository(),
      );
      await userVocabulary.init();
      final wordLevels = WordLevelService(
        repository: _MemoryWordLevelRepository(),
        assetLoader: (_) async => '',
      );
      await wordLevels.init();
      final bookshelf = _FakeBookshelfNotifier(
        _book(title: '三国演义', chapterTitle: '第一回', text: '滚滚长江东逝水。'),
      );

      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith((ref) => settings),
          bookshelfNotifierProvider.overrideWith(() => bookshelf),
          bookServiceProvider.overrideWithValue(
            _NoopBookService(
              books: [_metadata(id: 'book-1', title: '三国演义')],
            ),
          ),
          userVocabularyServiceProvider.overrideWithValue(userVocabulary),
          wordLevelServiceProvider.overrideWithValue(wordLevels),
        ],
      );
      addTearDown(container.dispose);

      await container.read(currentBookNotifierProvider.notifier).goToChapter(0);
      await _pumpUntilAnalysisReady(tester, container);

      final result = container.read(currentBookNotifierProvider).result;
      expect(result, isNotNull);
      expect(result!.title, '第一回');
      expect(result.passageText, '滚滚长江东逝水。');
    },
  );

  testWidgets('invalidating chapter analysis clears stale result', (
    tester,
  ) async {
    final db = await AppDatabase.createInMemory();
    addTearDown(db.close);
    final settings = SettingsService(SettingsDao(db));
    await settings.init();
    final userVocabulary = UserVocabularyService(
      repository: _MemoryUserVocabularyRepository(),
    );
    await userVocabulary.init();
    final wordLevels = WordLevelService(
      repository: _MemoryWordLevelRepository(),
      assetLoader: (_) async => '',
    );
    await wordLevels.init();
    final bookshelf = _FakeBookshelfNotifier(
      _book(
        title: 'First Book',
        chapterTitle: 'Old Chapter',
        text: 'Old text.',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith((ref) => settings),
        bookshelfNotifierProvider.overrideWith(() => bookshelf),
        bookServiceProvider.overrideWithValue(_NoopBookService()),
        userVocabularyServiceProvider.overrideWithValue(userVocabulary),
        wordLevelServiceProvider.overrideWithValue(wordLevels),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(currentBookNotifierProvider.notifier);

    await notifier.goToChapter(0);
    await _pumpUntilAnalysisReady(tester, container);
    expect(
      container.read(currentBookNotifierProvider).result?.title,
      'Old Chapter',
    );

    bookshelf.setBook(
      _book(
        title: 'Second Book',
        chapterTitle: 'New Chapter',
        text: 'New text.',
      ),
      bookId: 'book-2',
    );
    notifier.invalidateChapterAnalysisCache();

    expect(container.read(currentBookNotifierProvider).result, isNull);

    await notifier.goToChapter(0);
    await _pumpUntilAnalysisReady(tester, container);

    expect(
      container.read(currentBookNotifierProvider).result?.title,
      'New Chapter',
    );
  });

  test(
    'exitReader refreshes bookshelf books with latest read metadata',
    () async {
      final clock = _MutableClock(DateTime.utc(2026, 6, 11, 9));
      final repository = _MemoryBookMetadataRepository([
        _metadata(
          id: 'book-1',
          title: 'Old Book',
          lastReadAt: DateTime.utc(2026, 6, 10, 20),
        ),
        _metadata(
          id: 'book-2',
          title: 'New Book',
          lastReadAt: DateTime.utc(2026, 6, 10, 19),
        ),
      ]);
      final bookService = BookService(
        repository: repository,
        clock: clock.now,
      );
      final bookshelf = _FakeBookshelfNotifier(
        _book(
          title: 'New Book',
          chapterTitle: 'Chapter One',
          text: 'New text.',
        ),
        initialBookId: 'book-2',
        initialBooks: bookService.books,
      );

      final container = ProviderContainer(
        overrides: [
          bookshelfNotifierProvider.overrideWith(() => bookshelf),
          bookServiceProvider.overrideWithValue(bookService),
          readingTimeServiceProvider.overrideWithValue(
            ReadingTimeService(repository: _NoopReadingTimeRepository()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(currentBookNotifierProvider.notifier);
      notifier.updateReadingProgress(0.4, scrollOffset: 180);
      await notifier.exitReader();

      final books = container.read(bookshelfNotifierProvider).books;
      final sortedByRecent = [...books]
        ..sort(
          (a, b) => (b.lastReadAt?.millisecondsSinceEpoch ?? 0).compareTo(
            a.lastReadAt?.millisecondsSinceEpoch ?? 0,
          ),
        );
      final updated = repository.get('book-2');

      expect(sortedByRecent.first.id, 'book-2');
      expect(updated?.lastReadAt, clock.now());
      expect(updated?.chapterProgress, 0.4);
      expect(updated?.chapterScrollOffset, 180);
    },
  );
}

Future<void> _pumpUntilAnalysisReady(
  WidgetTester tester,
  ProviderContainer container,
) async {
  for (var i = 0; i < 10; i += 1) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    if (container.read(currentBookNotifierProvider).result != null) {
      return;
    }
  }
}

Book _book({
  required String title,
  required String chapterTitle,
  required String text,
}) {
  return Book(
    title: title,
    author: 'Author',
    language: 'zh',
    chapters: [
      Chapter(title: chapterTitle, plainText: text, rawHtml: ''),
    ],
  );
}

BookMetadata _metadata({
  required String id,
  required String title,
  DateTime? lastReadAt,
}) {
  return BookMetadata(
    id: id,
    title: title,
    author: 'Author',
    sourcePath: '',
    sourceLanguage: 'zh',
    totalChapters: 2,
    lastReadAt: lastReadAt,
  );
}

class _FakeBookshelfNotifier extends BookshelfNotifier {
  _FakeBookshelfNotifier(
    this._initialBook, {
    this.initialBookId = 'book-1',
    this.initialBooks = const [],
  });

  final Book _initialBook;
  final String initialBookId;
  final List<BookMetadata> initialBooks;

  @override
  BookshelfState build() {
    return BookshelfState(
      activeBookId: initialBookId,
      book: _initialBook,
      books: initialBooks,
    );
  }

  void setBook(Book book, {required String bookId}) {
    state = state.copyWith(activeBookId: bookId, book: book);
  }
}

class _NoopBookService extends BookService {
  _NoopBookService({List<BookMetadata> books = const []})
    : _books = books,
      super(repository: _MemoryBookMetadataRepository(books));

  final List<BookMetadata> _books;

  @override
  List<BookMetadata> get books => _books;

  @override
  Future<BookMetadata?> updateProgress(
    String id,
    int currentChapter,
    double chapterProgress, {
    double? chapterScrollOffset,
  }) async {
    return null;
  }
}

class _MemoryBookMetadataRepository implements BookMetadataRepository {
  _MemoryBookMetadataRepository(Iterable<BookMetadata> books) {
    for (final book in books) {
      _books[book.id] = book;
    }
  }

  final Map<String, BookMetadata> _books = {};

  @override
  Future<void> init() async {}

  @override
  Iterable<BookMetadata> get values => _books.values;

  @override
  BookMetadata? get(String id) => _books[id];

  @override
  Future<void> put(String id, BookMetadata metadata) async {
    _books[id] = metadata;
  }

  @override
  Future<void> delete(String id) async {
    _books.remove(id);
  }

  @override
  Future<void> close() async {}
}

class _NoopReadingTimeRepository implements ReadingTimeRepository {
  @override
  Future<void> init() async {}

  @override
  int secondsFor(String key) => 0;

  @override
  Future<void> putSeconds(String key, int seconds) async {}

  @override
  Future<void> close() async {}
}

class _MutableClock {
  _MutableClock(this.value);

  DateTime value;

  DateTime now() => value;
}

class _MemoryUserVocabularyRepository implements UserVocabularyRepository {
  final Map<String, UserWordStatus> _words = {};

  @override
  Future<void> init() async {}

  @override
  UserWordStatus? getStatus(String word) => _words[word];

  @override
  Set<String> wordsWithStatus(UserWordStatus status) => _words.entries
      .where((entry) => entry.value == status)
      .map((entry) => entry.key)
      .toSet();

  @override
  Map<String, UserWordStatus> get allWords => Map.unmodifiable(_words);

  @override
  Future<void> setStatus(String word, UserWordStatus status) async {
    _words[word] = status;
  }

  @override
  Future<void> remove(String word) async {
    _words.remove(word);
  }

  @override
  Future<void> close() async {}
}

class _MemoryWordLevelRepository implements WordLevelRepository {
  final List<WordLevelInfo> _values = [];
  bool _imported = false;

  @override
  Future<void> init() async {}

  @override
  Iterable<WordLevelInfo> get values => _values;

  @override
  bool get isNotEmpty => _values.isNotEmpty;

  @override
  bool get imported => _imported;

  @override
  Future<void> addAll(Iterable<WordLevelInfo> entries) async {
    _values.addAll(entries);
  }

  @override
  Future<void> markImported() async {
    _imported = true;
  }

  @override
  Future<void> close() async {}
}

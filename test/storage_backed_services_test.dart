import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flow_dictionary/flow_dictionary.dart';
import 'package:flow_language/english/english.dart';
import 'package:flow_read/models/book_difficulty.dart';
import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/models/bookmarked_word.dart';
import 'package:flow_read/models/reader_font.dart';
import 'package:flow_read/models/reading_bookmark.dart';
import 'package:flow_read/models/user_vocabulary.dart';
import 'package:flow_read/models/word_level.dart';
import 'package:flow_read/models/word_context_example.dart';
import 'package:flow_read/services/book_service.dart';
import 'package:flow_read/services/bookmark_service.dart';
import 'package:flow_read/services/epub_import_source.dart';
import 'package:flow_read/services/reading_config_service.dart';
import 'package:flow_read/services/reading_time_service.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/services/word_level_service.dart';
import 'package:flow_read/services/word_context_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_book_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_bookmark_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_dictionary_cache_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_config_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_time_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_rss_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_user_vocabulary_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_word_context_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_word_level_repository.dart';
import 'package:flow_rss/flow_rss.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_storage.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;

  setUp(() async {
    tempDir = await initTestStorage('flow_read_storage_services_test_');
    db = await createTestAppDatabase();
  });

  tearDown(() async {
    await disposeTestStorage(tempDir);
  });

  test('user vocabulary persists normalized word status', () async {
    final service = UserVocabularyService(
      repository: _userVocabularyRepository(db),
    );
    await service.init();
    final emptySignature = service.revisionSignature;

    await service.setKnown(' Flow ');
    await service.setLearning('Migrating');
    final populatedSignature = service.revisionSignature;

    expect(service.getStatus('flow'), UserWordStatus.known);
    expect(service.getStatus(' migrating '), UserWordStatus.learning);
    expect(service.knownWords, contains('flow'));
    expect(service.learningWords, contains('migrating'));
    final entry = await db.userVocabularyDao.entryFor('en_flow');
    expect(entry?.status, UserWordStatus.known.name);
    expect(entry?.language, 'en');
    expect(entry?.canonical, 'flow');
    expect(populatedSignature, isNot(emptySignature));

    await service.setUnknown('FLOW');

    expect(service.getStatus('flow'), isNull);
    expect(service.revisionSignature, isNot(populatedSignature));
  });

  test('user vocabulary can read and write isolated languages', () async {
    final english = UserVocabularyService(
      repository: _userVocabularyRepository(db, languageCode: 'en'),
      languageCode: 'en',
    );
    await english.init();
    final japanese = UserVocabularyService(
      repository: _userVocabularyRepository(db, languageCode: 'ja'),
      languageCode: 'ja',
    );
    await japanese.init();

    await english.setKnown('flow');
    await japanese.setLearning('flow');

    expect(english.getStatus('flow'), UserWordStatus.known);
    expect(japanese.getStatus('flow'), UserWordStatus.learning);
    expect(await db.userVocabularyDao.entryFor('en_flow'), isNotNull);
    expect(await db.userVocabularyDao.entryFor('ja_flow'), isNotNull);
  });

  test('reading config persists clamped display settings', () async {
    final service = ReadingConfigService(
      repository: _readingConfigRepository(db),
    );
    await service.init();

    await service.setFontSize(30);
    await service.setLineHeight(1);
    await service.setFontFamily(ReaderFonts.literata);
    await service.setTheme('sepia');

    final reloaded = ReadingConfigService(
      repository: _readingConfigRepository(db),
    );
    await reloaded.init();

    expect(reloaded.fontSize, 24);
    expect(reloaded.lineHeight, 1.4);
    expect(reloaded.fontFamily, ReaderFonts.literata);
    expect(reloaded.theme, 'sepia');

    await reloaded.setFontFamily('Unsupported Font');

    final sanitized = ReadingConfigService(
      repository: _readingConfigRepository(db),
    );
    await sanitized.init();

    expect(sanitized.fontFamily, ReaderFonts.defaultFamily);
  });

  test(
    'reading time accumulates global, weekly, book, and chapter seconds',
    () async {
      var now = DateTime.utc(2026, 5, 19, 8);
      final service = ReadingTimeService(
        repository: _readingTimeRepository(db),
        clock: () => now,
      );
      await service.init();

      service.start('book-1', 2);
      now = now.add(const Duration(seconds: 125));
      expect(service.todaySeconds, 125);
      await service.stop();

      expect(service.totalSeconds, 125);
      expect(service.secondsForBook('book-1'), 125);
      expect(service.secondsForChapter('book-1', 2), 125);
      expect(service.todaySeconds, 125);
      expect(service.secondsForWeek(now), 125);
      expect(service.secondsByDayForWeek(now), [0, 125, 0, 0, 0, 0, 0]);
      expect(service.secondsForMonth(now), 125);
      expect(service.secondsByDayForMonth(now)[18], 125);
      expect(service.displayText, '2 分钟');

      final reloaded = ReadingTimeService(
        repository: _readingTimeRepository(db),
        clock: () => now,
      );
      await reloaded.init();

      expect(reloaded.totalSeconds, 125);
      expect(reloaded.secondsForBook('book-1'), 125);
      expect(reloaded.secondsForChapter('book-1', 2), 125);
      expect(reloaded.todaySeconds, 125);
      expect(reloaded.secondsForWeek(now), 125);
      expect(reloaded.secondsByDayForWeek(now), [0, 125, 0, 0, 0, 0, 0]);
      expect(reloaded.secondsForMonth(now), 125);
      expect(reloaded.secondsByDayForMonth(now)[18], 125);
    },
  );

  test('word context examples are merged and deduplicated', () async {
    final service = WordContextService(
      repository: _wordContextRepository(db),
    );
    await service.init();

    await service.saveExamples(' Flow ', const [
      WordContextExample(
        word: 'flow',
        text: 'A steady flow of ideas.',
        title: 'Book',
        url: 'file:///book',
      ),
      WordContextExample(
        word: 'flow',
        text: 'A steady flow of ideas.',
        title: 'Duplicate',
        url: 'file:///book',
      ),
    ]);

    final reloaded = WordContextService(
      repository: _wordContextRepository(db),
    );
    await reloaded.init();
    final examples = reloaded.examplesFor('flow');

    expect(examples, hasLength(1));
    expect(examples.single.title, 'Book');
  });

  test(
    'book metadata persists while file artifacts stay service-owned',
    () async {
      final documentsDir = await Directory(
        '${tempDir.path}/documents',
      ).create();
      var now = DateTime.utc(2026, 5, 19, 11);
      final service = BookService(
        repository: _bookRepository(db),
        documentsDirectoryProvider: () async => documentsDir,
        clock: () => now,
      );
      await service.init();

      await service.addBook(
        const BookMetadata(
          id: 'book-1',
          title: 'Flow',
          author: 'Author',
          sourcePath: '/imports/flow.epub',
          totalChapters: 4,
        ),
      );
      await service.saveCover('book-1', Uint8List.fromList([1, 2, 3]));
      final sourcePath = await service.saveSource(
        'book-1',
        EpubImportSource.bytes(
          Uint8List.fromList([4, 5, 6]),
          fileName: 'flow.epub',
        ),
      );
      final sourceFile = File(sourcePath);
      expect(sourcePath, '${documentsDir.path}/books/book-1.epub');
      expect(await sourceFile.readAsBytes(), Uint8List.fromList([4, 5, 6]));

      await service.updateDifficultyCache(
        id: 'book-1',
        studyWords: {'reading', 'flow'},
        rating: const BookDifficultyRating(
          studyWordCount: 2,
          masteredWordCount: 1,
          userKnownWordCount: 10,
          learningWordCount: 0,
          newWordCount: 1,
          weightedNewWordCount: 1,
          newWordToKnownRatio: 0.1,
          score: 40,
          level: BookDifficultyLevel.l3,
        ),
        vocabularySignature: 'vocab-v1',
        computedAt: now,
      );
      await service.renameBook('book-1', 'Flow Updated');
      now = DateTime.utc(2026, 5, 19, 12);
      await service.updateProgress('book-1', 1, 0.5, chapterScrollOffset: 420);

      final reloaded = BookService(
        repository: _bookRepository(db),
        documentsDirectoryProvider: () async {
          return documentsDir;
        },
      );
      await reloaded.init();
      final book = reloaded.books.single;

      expect(book.title, 'Flow Updated');
      expect(book.currentChapter, 1);
      expect(book.chapterProgress, 0.5);
      expect(book.chapterScrollOffset, 420);
      expect(book.globalProgress, 0.375);
      expect(book.lastReadAt, now);
      expect(book.difficultyStudyWords, ['flow', 'reading']);
      expect(book.difficultyRating?.level, BookDifficultyLevel.l3);
      expect(book.difficultyVocabularySignature, 'vocab-v1');
      expect(reloaded.loadCover('book-1'), Uint8List.fromList([1, 2, 3]));

      await reloaded.removeBook('book-1');

      expect(reloaded.books, isEmpty);
      expect(
        File('${documentsDir.path}/books/book-1_cover.png').existsSync(),
        isFalse,
      );
      expect(sourceFile.existsSync(), isFalse);
    },
  );

  test('book source save initializes file access lazily', () async {
    final documentsDir = await Directory('${tempDir.path}/documents').create();
    var documentsDirectoryReads = 0;
    final service = BookService(
      repository: _bookRepository(db),
      documentsDirectoryProvider: () async {
        documentsDirectoryReads += 1;
        return documentsDir;
      },
    );

    final sourcePath = await service.saveSource(
      'book-1',
      EpubImportSource.bytes(
        Uint8List.fromList([4, 5, 6]),
        fileName: 'flow.epub',
      ),
    );

    expect(sourcePath, '${documentsDir.path}/books/book-1.epub');
    expect(await File(sourcePath).readAsBytes(), Uint8List.fromList([4, 5, 6]));
    expect(documentsDirectoryReads, 1);

    final coverPath = await service.saveCover(
      'book-1',
      Uint8List.fromList([1, 2, 3]),
    );

    expect(coverPath, '${documentsDir.path}/books/book-1_cover.png');
    expect(documentsDirectoryReads, 1);
  });

  test('book cover loading falls back to persisted cover path', () async {
    final documentsDir = await Directory('${tempDir.path}/documents').create();
    final legacyCoverDir = await Directory(
      '${tempDir.path}/legacy-covers',
    ).create();
    final legacyCoverFile = File('${legacyCoverDir.path}/book-cover.png');
    final legacyCoverBytes = Uint8List.fromList([9, 8, 7, 6]);
    await legacyCoverFile.writeAsBytes(legacyCoverBytes);

    final service = BookService(
      repository: _bookRepository(db),
      documentsDirectoryProvider: () async => documentsDir,
    );
    await service.init();
    await service.addBook(
      BookMetadata(
        id: 'book-1',
        title: 'Flow',
        author: 'Author',
        sourcePath: '/imports/flow.epub',
        coverPath: legacyCoverFile.path,
      ),
    );

    expect(service.loadCover('book-1'), legacyCoverBytes);
  });

  test('bookmarks persist word and reading bookmark payloads', () async {
    final service = BookmarkService(repository: _bookmarkRepository(db));
    await service.init();

    await service.saveWordBookmarks('book-1', [
      BookmarkedWord(
        word: 'flow',
        translation: '流动',
        context: 'A steady flow of ideas.',
        addedAt: DateTime.utc(2026, 5, 19, 9),
        bookId: 'book-1',
      ),
    ]);
    await service.saveReadingBookmarks('book-1', [
      ReadingBookmark(
        chapterIndex: 2,
        progress: 0.42,
        chapterTitle: 'Chapter 3',
        excerpt: 'A bookmarked paragraph.',
        createdAt: DateTime.utc(2026, 5, 19, 10),
        bookId: 'book-1',
      ),
    ]);

    final reloaded = BookmarkService(repository: _bookmarkRepository(db));
    await reloaded.init();

    expect(reloaded.loadWordBookmarks('book-1').single.word, 'flow');
    expect(reloaded.loadReadingBookmarks('book-1').single.progress, 0.42);

    await reloaded.deleteWordBookmarks('book-1');
    await reloaded.deleteReadingBookmarks('book-1');

    expect(reloaded.loadWordBookmarks('book-1'), isEmpty);
    expect(reloaded.loadReadingBookmarks('book-1'), isEmpty);
  });

  test(
    'dictionary cache persists entries and prunes oldest overflow',
    () async {
      final cache = DictionaryCacheService(
        repository: _dictionaryCacheRepository(db),
      );
      await cache.init();

      await cache.set('Collins', 'flow', '<html>flow</html>');

      expect(cache.get('Collins', 'flow'), '<html>flow</html>');
      expect(cache.hasWord('Collins', 'flow'), isTrue);
      expect(cache.entryCount, 1);

      for (var index = 0; index < 501; index += 1) {
        await cache.set('Longman', 'word$index', 'entry$index');
      }

      expect(cache.hasWord('Collins', 'flow'), isFalse);
      expect(cache.hasWord('Longman', 'word500'), isTrue);
      expect(cache.entryCount, 500);

      await cache.clear();

      expect(cache.hasWord('Longman', 'word500'), isFalse);
      expect(cache.entryCount, 0);
    },
  );

  test('rss service loads subscriptions and persists read state', () async {
    const betaUrl = 'https://b.example/rss.xml';
    const alphaUrl = 'https://a.example/rss.xml';
    final alphaId = DriftRssRepository.subscriptionIdForUrl(alphaUrl);
    await db.rssDao.insertSubscription(
      RssSubscriptionsCompanion.insert(
        id: DriftRssRepository.subscriptionIdForUrl(betaUrl),
        url: betaUrl,
        title: const Value('Beta'),
      ),
    );
    await db.rssDao.insertSubscription(
      RssSubscriptionsCompanion.insert(
        id: alphaId,
        url: alphaUrl,
        title: const Value('Alpha'),
      ),
    );
    await db.rssDao.upsertArticles([
      RssArticlesCompanion.insert(
        id: 'article-1',
        subscriptionId: alphaId,
        feedUrl: alphaUrl,
        title: 'Article 1',
        isRead: true,
        isFavorite: false,
        isReadLater: false,
      ),
      RssArticlesCompanion.insert(
        id: 'article-2',
        subscriptionId: alphaId,
        feedUrl: alphaUrl,
        title: 'Article 2',
        isRead: false,
        isFavorite: false,
        isReadLater: false,
      ),
      RssArticlesCompanion.insert(
        id: 'article-3',
        subscriptionId: alphaId,
        feedUrl: alphaUrl,
        title: 'Article 3',
        isRead: false,
        isFavorite: false,
        isReadLater: false,
      ),
    ]);

    final service = RssService(repository: DriftRssRepository(db.rssDao));
    await service.init();

    expect(service.subscriptions.map((s) => s.title), ['Alpha', 'Beta']);

    await service.markAsRead('article-2');
    var ids = await db.rssDao.readArticleIds();

    expect(ids, containsAll(['article-1', 'article-2']));

    await service.markAsUnread('article-1');
    ids = await db.rssDao.readArticleIds();

    expect(ids, isNot(contains('article-1')));
    expect(ids, contains('article-2'));

    await service.setArticleFavorite('article-2', true);
    await service.setArticleReadLater('article-3', true);

    final favoriteIds = await db.rssDao.favoriteArticleIds();
    final readLaterIds = await db.rssDao.readLaterArticleIds();

    expect(favoriteIds, {'article-2'});
    expect(readLaterIds, {'article-3'});

    await service.setArticleFavorite('article-2', false);
    await service.setArticleReadLater('article-3', false);

    expect(await db.rssDao.favoriteArticleIds(), isEmpty);
    expect(await db.rssDao.readLaterArticleIds(), isEmpty);
  });

  test(
    'word levels import built-in dictionary through storage boundary',
    () async {
      final service = WordLevelService(
        repository: _wordLevelRepository(db),
        assetLoader: (_) async => 'flow\tflow\t4\nmigrating\tmigrate\t6\n',
        languageModule: const EnglishLanguageModule(),
      );
      await service.init();

      expect(await db.settingsDao.valueFor('word_levels_imported'), 'true');
      expect(await db.wordLevelDao.allEntries(), hasLength(2));
      expect(service.canonicalForm('Migrating'), 'migrate');
      expect(service.getLevel('flow'), LevelKey.cet4);
      expect(service.getLevel('migrating'), LevelKey.cet6);
      expect(service.getOriginForm('migrating'), 'migrate');
      expect(service.hasWord('migrate'), isTrue);
    },
  );

  test('word levels normalize contractions with curly apostrophes', () async {
    final service = WordLevelService(
      repository: _wordLevelRepository(db),
      assetLoader: (_) async =>
          'did\tdo\tp\nwas\tbe\tp\nhad\thave\tp\nwould\twould\tm\n'
          'should\tshould\tm\nthey\tthey\tp\nwe\twe\tp\nit\tit\tp\n',
      languageModule: const EnglishLanguageModule(),
    );
    await service.init();

    expect(service.canonicalForm('didn\u2019t'), 'do');
    expect(service.canonicalForm('isn\u2019t'), 'is');
    expect(service.canonicalForm('wasn\u2019t'), 'be');
    expect(service.canonicalForm('Wouldn\u2019t'), 'would');
    expect(service.canonicalForm('hadn\u2019t'), 'have');
    expect(service.canonicalForm('shouldn\u2019t\u2019ve'), 'should');
    expect(service.canonicalForm('They\u02BCve'), 'they');
    expect(service.canonicalForm('We\uFF07ll'), 'we');
    expect(service.canonicalForm('It\u00B4s'), 'it');
  });

  test(
    'word levels index existing persisted entries without asset import',
    () async {
      await db.settingsDao.putValue('word_levels_imported', 'true');
      await db.wordLevelDao.insertAll([
        DriftWordLevelRepository.companionFromInfo(
          const WordLevelInfo(
            word: 'running',
            originForm: 'run',
            levelIndex: 5,
          ),
        ),
      ]);

      final service = WordLevelService(repository: _wordLevelRepository(db), languageModule: const EnglishLanguageModule());
      await service.init();

      expect(service.canonicalForm('Running'), 'run');
      expect(service.getLevel('run'), LevelKey.gre);
      expect(service.getOriginForm('running'), 'run');
      expect(service.wordCount, 2);
    },
  );
}

DriftUserVocabularyRepository _userVocabularyRepository(
  AppDatabase db, {
  String languageCode = 'en',
}) {
  return DriftUserVocabularyRepository(
    db.userVocabularyDao,
    languageCode: languageCode,
  );
}

DriftReadingConfigRepository _readingConfigRepository(AppDatabase db) {
  return DriftReadingConfigRepository(db.readingConfigDao, languageCode: 'en');
}

DriftReadingTimeRepository _readingTimeRepository(AppDatabase db) {
  return DriftReadingTimeRepository(db.readingTimeDao, languageCode: 'en');
}

DriftWordContextRepository _wordContextRepository(AppDatabase db) {
  return DriftWordContextRepository(db.wordContextDao, languageCode: 'en');
}

DriftBookRepository _bookRepository(AppDatabase db) {
  return DriftBookRepository(db.bookDao, languageCode: 'en');
}

DriftBookmarkRepository _bookmarkRepository(AppDatabase db) {
  return DriftBookmarkRepository(db.bookmarkDao, languageCode: 'en');
}

DriftDictionaryCacheRepository _dictionaryCacheRepository(AppDatabase db) {
  return DriftDictionaryCacheRepository(
    db.dictionaryCacheDao,
    languageCode: 'en',
  );
}

DriftWordLevelRepository _wordLevelRepository(AppDatabase db) {
  return DriftWordLevelRepository(db.wordLevelDao, db.settingsDao);
}

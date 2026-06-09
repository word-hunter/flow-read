import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flow_read/models/book_difficulty.dart';
import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/models/bookmarked_word.dart';
import 'package:flow_read/models/reader_font.dart';
import 'package:flow_read/models/reading_bookmark.dart';
import 'package:flow_rss/flow_rss.dart';
import 'package:flow_read/models/user_vocabulary.dart';
import 'package:flow_read/models/word_level.dart';
import 'package:flow_read/models/word_context_example.dart';
import 'package:flow_read/services/book_service.dart';
import 'package:flow_read/services/bookmark_service.dart';
import 'package:flow_dictionary/flow_dictionary.dart';
import 'package:flow_read/services/epub_import_source.dart';
import 'package:flow_read/services/reading_config_service.dart';
import 'package:flow_read/services/reading_time_service.dart';
import 'package:flow_rss/flow_rss.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/services/word_level_service.dart';
import 'package:flow_read/services/word_context_service.dart';
import 'package:flow_read/storage/hive_box_names.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/hive_test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_storage_services_test_');
    await openFlowReadTestBoxes();
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test('user vocabulary persists normalized word status', () async {
    final service = UserVocabularyService();
    await service.init();
    final emptySignature = service.revisionSignature;

    await service.setKnown(' Flow ');
    await service.setLearning('Migrating');
    final populatedSignature = service.revisionSignature;

    expect(service.getStatus('flow'), UserWordStatus.known);
    expect(service.getStatus(' migrating '), UserWordStatus.learning);
    expect(service.knownWords, contains('flow'));
    expect(service.learningWords, contains('migrating'));
    expect(userVocabularyBox().containsKey('en_flow'), isTrue);
    expect(userVocabularyBox().containsKey('flow'), isFalse);
    final entryJson =
        jsonDecode(userVocabularyBox().get('en_flow')!) as Map<String, dynamic>;
    expect(entryJson['status'], 'known');
    expect(entryJson['key'], containsPair('languageId', 'en'));
    expect(entryJson['key'], containsPair('canonical', 'flow'));
    expect(populatedSignature, isNot(emptySignature));

    await service.setUnknown('FLOW');

    expect(service.getStatus('flow'), isNull);
    expect(service.revisionSignature, isNot(populatedSignature));
  });

  test('user vocabulary can read and write isolated language boxes', () async {
    await Hive.openBox<String>(HiveBoxNames.userVocabularyFor('ja'));

    final english = UserVocabularyService(languageCode: 'en');
    await english.init();
    final japanese = UserVocabularyService(languageCode: 'ja');
    await japanese.init();

    await english.setKnown('flow');
    await japanese.setLearning('flow');

    expect(english.getStatus('flow'), UserWordStatus.known);
    expect(japanese.getStatus('flow'), UserWordStatus.learning);
    expect(userVocabularyBox().containsKey('en_flow'), isTrue);
    expect(
      userVocabularyBox(languageCode: 'ja').containsKey('ja_flow'),
      isTrue,
    );
  });

  test('user vocabulary migrates legacy bare word keys on init', () async {
    await userVocabularyBox().put('flow', 'known');
    await userVocabularyBox().put('migrating', 'learning');

    final service = UserVocabularyService();
    await service.init();

    expect(service.getStatus('flow'), UserWordStatus.known);
    expect(service.getStatus('migrating'), UserWordStatus.learning);
    expect(service.knownWords, contains('flow'));
    expect(service.learningWords, contains('migrating'));
    expect(userVocabularyBox().containsKey('flow'), isFalse);
    expect(userVocabularyBox().containsKey('migrating'), isFalse);
    expect(userVocabularyBox().containsKey('en_flow'), isTrue);
    expect(userVocabularyBox().containsKey('en_migrating'), isTrue);
  });

  test('reading config persists clamped display settings', () async {
    final service = ReadingConfigService();
    await service.init();

    await service.setFontSize(30);
    await service.setLineHeight(1);
    await service.setFontFamily(ReaderFonts.literata);
    await service.setTheme('sepia');

    final reloaded = ReadingConfigService();
    await reloaded.init();

    expect(reloaded.fontSize, 24);
    expect(reloaded.lineHeight, 1.4);
    expect(reloaded.fontFamily, ReaderFonts.literata);
    expect(reloaded.theme, 'sepia');

    await reloaded.setFontFamily('Unsupported Font');

    final sanitized = ReadingConfigService();
    await sanitized.init();

    expect(sanitized.fontFamily, ReaderFonts.defaultFamily);
  });

  test(
    'reading time accumulates global, weekly, book, and chapter seconds',
    () async {
      var now = DateTime.utc(2026, 5, 19, 8);
      final service = ReadingTimeService(clock: () => now);
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

      final reloaded = ReadingTimeService(clock: () => now);
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
    final service = WordContextService();
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

    final reloaded = WordContextService();
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

  test('book cover loading falls back to persisted cover path', () async {
    final documentsDir = await Directory('${tempDir.path}/documents').create();
    final legacyCoverDir = await Directory(
      '${tempDir.path}/legacy-covers',
    ).create();
    final legacyCoverFile = File('${legacyCoverDir.path}/book-cover.png');
    final legacyCoverBytes = Uint8List.fromList([9, 8, 7, 6]);
    await legacyCoverFile.writeAsBytes(legacyCoverBytes);

    final service = BookService(
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
    final service = BookmarkService();
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

    final reloaded = BookmarkService();
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
      final cache = DictionaryCacheService();
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
    await rssSubscriptionsBox().add(
      RssFeedSubscription(url: 'https://b.example/rss.xml', title: 'Beta'),
    );
    await rssSubscriptionsBox().add(
      RssFeedSubscription(url: 'https://a.example/rss.xml', title: 'Alpha'),
    );
    await settingsBox().put('rss_read_articles', jsonEncode(['article-1']));

    final service = RssService();
    await service.init();

    expect(service.subscriptions.map((s) => s.title), ['Alpha', 'Beta']);

    await service.markAsRead('article-2');
    var ids =
        (jsonDecode(settingsBox().get('rss_read_articles') as String)
                as List<dynamic>)
            .cast<String>();

    expect(ids, containsAll(['article-1', 'article-2']));

    await service.markAsUnread('article-1');
    ids =
        (jsonDecode(settingsBox().get('rss_read_articles') as String)
                as List<dynamic>)
            .cast<String>();

    expect(ids, isNot(contains('article-1')));
    expect(ids, contains('article-2'));

    await service.setArticleFavorite('article-2', true);
    await service.setArticleReadLater('article-3', true);

    final favoriteIds =
        (jsonDecode(settingsBox().get('rss_favorite_articles') as String)
                as List<dynamic>)
            .cast<String>();
    final readLaterIds =
        (jsonDecode(settingsBox().get('rss_read_later_articles') as String)
                as List<dynamic>)
            .cast<String>();

    expect(favoriteIds, ['article-2']);
    expect(readLaterIds, ['article-3']);

    await service.setArticleFavorite('article-2', false);
    await service.setArticleReadLater('article-3', false);

    expect(
      (jsonDecode(settingsBox().get('rss_favorite_articles') as String)
              as List<dynamic>)
          .cast<String>(),
      isEmpty,
    );
    expect(
      (jsonDecode(settingsBox().get('rss_read_later_articles') as String)
              as List<dynamic>)
          .cast<String>(),
      isEmpty,
    );
  });

  test(
    'word levels import built-in dictionary through storage boundary',
    () async {
      final service = WordLevelService(
        assetLoader: (_) async => 'flow\tflow\t4\nmigrating\tmigrate\t6\n',
      );
      await service.init();

      expect(settingsBox().get('word_levels_imported'), 'true');
      expect(wordLevelsBox().length, 2);
      expect(service.canonicalForm('Migrating'), 'migrate');
      expect(service.getLevel('flow'), LevelKey.cet4);
      expect(service.getLevel('migrating'), LevelKey.cet6);
      expect(service.getOriginForm('migrating'), 'migrate');
      expect(service.hasWord('migrate'), isTrue);
    },
  );

  test('word levels normalize contractions with curly apostrophes', () async {
    final service = WordLevelService(
      assetLoader: (_) async =>
          'did\tdo\tp\nwas\tbe\tp\nhad\thave\tp\nwould\twould\tm\n'
          'should\tshould\tm\nthey\tthey\tp\nwe\twe\tp\nit\tit\tp\n',
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
      await settingsBox().put('word_levels_imported', 'true');
      await wordLevelsBox().add(
        const WordLevelInfo(word: 'running', originForm: 'run', levelIndex: 5),
      );

      final service = WordLevelService();
      await service.init();

      expect(service.canonicalForm('Running'), 'run');
      expect(service.getLevel('run'), LevelKey.gre);
      expect(service.getOriginForm('running'), 'run');
      expect(service.wordCount, 2);
    },
  );
}

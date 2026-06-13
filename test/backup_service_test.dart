import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flow_read/models/book_difficulty.dart';
import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/models/learning_item.dart';
import 'package:flow_read/services/backup_archive.dart' as archive;
import 'package:flow_read/services/backup_service.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/services/word_context_service.dart';
import 'package:flow_read/services/wordhunter_import_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_book_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_learning_item_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_user_vocabulary_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_word_context_repository.dart';
import 'package:flow_read/storage/hive_box_names.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_test_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory documentsDir;
  late AppDatabase db;
  late SettingsService settings;
  late BackupService backup;

  setUp(() async {
    tempDir = await initHiveTestStorage(
      'flow_read_backup_test_',
      hivePathSuffix: 'hive',
    );
    await openFlowReadTestBoxes();
    documentsDir = await Directory('${tempDir.path}/documents').create();

    db = await createTestAppDatabase();
    settings = SettingsService(db.settingsDao);
    await settings.init();
    backup = BackupService(
      settings,
      database: db,
      documentsDirectoryProvider: () async => documentsDir,
      wordHunterImportServiceFactory: () => _driftWordHunterImportService(db),
    );
  });

  tearDown(() async {
    backup.dispose();
    await disposeHiveTestStorage(tempDir);
  });

  test('exports Drift data to .flow.bak and imports it back', () async {
    final book = BookMetadata(
      id: 'book-1',
      title: 'Test Book',
      author: 'Author',
      sourcePath: '/books/test.epub',
      totalChapters: 3,
      currentChapter: 1,
      chapterProgress: 0.4,
      chapterScrollOffset: 320,
      lastReadAt: DateTime.utc(2026, 5, 15, 8, 30),
      difficultyStudyWords: const ['flow', 'reading'],
      difficultyRatingJson: const BookDifficultyRating(
        studyWordCount: 2,
        masteredWordCount: 1,
        userKnownWordCount: 20,
        learningWordCount: 0,
        newWordCount: 1,
        weightedNewWordCount: 1,
        newWordToKnownRatio: 0.05,
        score: 20,
        level: BookDifficultyLevel.l2,
      ).toJson(),
      difficultyVocabularySignature: 'vocab-v1',
      difficultyComputedAt: DateTime.utc(2026, 5, 15, 8, 31),
    );

    final epubFile = File('${tempDir.path}/test.epub');
    await epubFile.writeAsString('mock epub content');

    await db.bookDao.upsert(
      DriftBookRepository.companionFromMetadata(
        book.copyWith(sourcePath: epubFile.path),
        languageCode: 'en',
      ),
    );
    await db.userVocabularyDao.upsert(
      UserVocabulariesCompanion.insert(
        id: 'en_flow',
        canonical: 'flow',
        status: 'known',
        language: const Value('en'),
      ),
    );
    await db.readingConfigDao.putValue('fontSize', 'en', '18.0');
    await db.readingTimeDao.putSeconds('_global_', 'en', 120);
    await db.learningAnalyticsDao.putValue('20260515', 'en', 7);
    await dictionaryCacheBox().put('flow', '{"word":"flow"}');
    await db.wordContextDao.putData(
      'flow',
      'en',
      '[{"word":"flow","text":"A steady flow of ideas."}]',
    );
    await db.learningItemDao.upsert(
      DriftLearningItemRepository.companionFromItem(
        LearningItem(
          id: 'learning-1',
          type: LearningItemType.word,
          canonicalKey: 'flow',
          title: 'flow',
          content: 'flow',
          answer: 'movement',
          note: '',
          sourceText: 'A steady flow of ideas.',
          bookId: 'book-1',
          chapterIndex: 1,
          chapterTitle: 'Chapter 2',
          createdAt: DateTime.utc(2026, 5, 15, 8, 45),
          updatedAt: DateTime.utc(2026, 5, 15, 8, 45),
        ),
        languageCode: 'en',
      ),
    );
    await db.rssDao.insertSubscription(
      RssSubscriptionsCompanion.insert(
        id: 'rss-1',
        url: 'https://example.com/rss.xml',
        title: const Value('Example'),
        lastFetchedAt: const Value('2026-05-15T00:00:00.000Z'),
      ),
    );
    await settings.setAIProvider('openai');
    await settings.setAIModel('reader-model');
    await settings.setApiKey('secret-key');
    await settings.setBackupFolderPath(
      '/private/backups',
      bookmark: 'bookmark',
    );
    await db.settingsDao.putValue('rss_read_articles', jsonEncode(['a1']));

    await backup.exportNow(folderPath: '${tempDir.path}/backups');

    final backupDir = Directory('${tempDir.path}/backups');
    final bakFiles = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.flow.bak'))
        .toList();
    expect(bakFiles, hasLength(1));

    final bakFileBytes = await bakFiles.first.readAsBytes();
    final zipArchive = ZipDecoder().decodeBytes(bakFileBytes);

    final manifestEntry = zipArchive.findFile('manifest.json');
    expect(manifestEntry, isNotNull);
    final manifest =
        jsonDecode(utf8.decode(manifestEntry!.content)) as Map<String, dynamic>;
    expect(manifest['app'], BackupService.appId);
    expect(manifest['formatVersion'], archive.supportedManifestFormatVersion);
    expect(manifest['dataPath'], 'data/app.json');
    expect(manifest['books'], isA<Map>());
    expect(manifest['books']['book-1'], isNotNull);
    expect(
      manifest['books']['book-1']['source'],
      archive.bookSourceEntryPath('book-1'),
    );

    final dataEntry = zipArchive.findFile('data/app.json');
    expect(dataEntry, isNotNull);
    final data =
        jsonDecode(utf8.decode(dataEntry!.content)) as Map<String, dynamic>;
    expect(data['schemaVersion'], BackupService.schemaVersion);
    expect(data['app'], isNull);
    expect(data['createdAt'], isNull);
    expect(data['files'], isNull);
    final boxes = data['boxes'] as Map<String, dynamic>;
    expect(boxes.keys, containsAll(BackupService.backupDataBoxNames));
    expect(boxes, isNot(containsPair(HiveBoxNames.dictionaryCache, anything)));
    expect(
      boxes,
      isNot(containsPair(HiveBoxNames.dictionaryCacheFor('en'), anything)),
    );
    final analyticsEntries =
        boxes[HiveBoxNames.learningAnalyticsFor('en')]['entries']
            as List<dynamic>;
    expect(analyticsEntries, hasLength(1));
    expect(analyticsEntries.single, {
      'key': {'type': 'int', 'value': 20260515},
      'value': 7,
    });

    final settingsEntries =
        boxes[HiveBoxNames.settings]['entries'] as List<dynamic>;
    final settingKeys = settingsEntries
        .map((entry) => entry['key']['value'] as String)
        .toSet();
    expect(settingKeys, isNot(contains('apiKey')));
    expect(settingKeys, isNot(contains('aiApiKeys')));
    expect(settingKeys, isNot(contains('backupFolderPath')));
    expect(settingKeys, isNot(contains('backupFolderBookmark')));
    expect(settingKeys, contains('aiProviderId'));

    final sourceEntry = zipArchive.findFile(
      archive.bookSourceEntryPath('book-1'),
    );
    expect(sourceEntry, isNotNull);
    expect(utf8.decode(sourceEntry!.content), 'mock epub content');

    await db.bookDao.deleteAllForLanguage('en');
    await db.userVocabularyDao.clearForLanguage('en');
    await db.readingConfigDao.clearForLanguage('en');
    await db.readingTimeDao.clearForLanguage('en');
    await db.learningAnalyticsDao.clearForLanguage('en');
    await dictionaryCacheBox().clear();
    await db.wordContextDao.clearForLanguage('en');
    await db.learningItemDao.clearForLanguage('en');
    await db.rssDao.deleteAllArticles();
    await db.rssDao.deleteAllSubscriptions();

    await backup.importBackupFile(bakFiles.first.path);

    final restoredBook = await db.bookDao.getById('book-1');
    expect(restoredBook?.title, 'Test Book');
    expect(restoredBook?.chapterScrollOffset, 320);
    final restoredMetadata = DriftBookRepository.metadataFromEntry(
      restoredBook!,
    );
    expect(restoredMetadata.difficultyStudyWords, ['flow', 'reading']);
    expect(restoredMetadata.difficultyRating?.level, BookDifficultyLevel.l2);
    expect(restoredBook.difficultyVocabularySignature, 'vocab-v1');
    expect(
      (await db.userVocabularyDao.entryFor('en_flow'))?.status,
      'known',
    );
    expect(await db.readingConfigDao.valueFor('fontSize', 'en'), '18.0');
    expect(await db.readingTimeDao.secondsFor('_global_', 'en'), 120);
    expect(await db.learningAnalyticsDao.valueFor('20260515', 'en'), 7);
    expect(dictionaryCacheBox().get('flow'), isNull);
    expect(
      await db.wordContextDao.dataFor('flow', 'en'),
      '[{"word":"flow","text":"A steady flow of ideas."}]',
    );
    expect(
      (await db.learningItemDao.getById('learning-1'))?.answer,
      'movement',
    );
    expect((await db.rssDao.allSubscriptions()).single.title, 'Example');
    expect(settings.aiProviderId, 'openai');
    expect(settings.apiKeyFor('openai'), 'secret-key');
    expect(settings.backupFolderPath, '/private/backups');
    expect(settings.backupFolderBookmark, 'bookmark');
  });

  test('exports Drift data to the legacy backup payload shape', () async {
    final epubFile = File('${tempDir.path}/drift.epub');
    await epubFile.writeAsString('drift epub content');

    final book = BookMetadata(
      id: 'drift-book',
      title: 'Drift Book',
      author: 'Author',
      sourcePath: epubFile.path,
      totalChapters: 4,
      currentChapter: 2,
      chapterProgress: 0.5,
      chapterScrollOffset: 240,
      lastReadAt: DateTime.utc(2026, 6, 12, 8),
    );
    await db.bookDao.upsert(
      DriftBookRepository.companionFromMetadata(
        book,
        languageCode: 'en',
      ),
    );
    await db.userVocabularyDao.upsert(
      UserVocabulariesCompanion.insert(
        id: 'en:flow',
        canonical: 'flow',
        status: 'known',
        language: const Value('en'),
      ),
    );
    await db.bookmarkDao.insertWordBookmark(
      WordBookmarksCompanion.insert(
        id: 'word-bookmark-1',
        bookId: book.id,
        word: 'flow',
        language: const Value('en'),
        translation: const Value('流动'),
        context: const Value('A steady flow of ideas.'),
        addedAt: const Value('2026-06-12T08:00:00.000Z'),
      ),
    );
    await db.bookmarkDao.insertReadingBookmark(
      ReadingBookmarksCompanion.insert(
        id: 'reading-bookmark-1',
        bookId: book.id,
        chapterIndex: 2,
        progress: 0.5,
        language: const Value('en'),
        chapterTitle: const Value('Chapter 3'),
        excerpt: const Value('A marked paragraph.'),
        createdAt: const Value('2026-06-12T08:05:00.000Z'),
      ),
    );
    await db.readingConfigDao.putValue('fontSize', 'en', '19.0');
    await db.readingTimeDao.putSeconds('_global_', 'en', 300);
    await db.wordContextDao.putData(
      'flow',
      'en',
      '[{"word":"flow","text":"A steady flow of ideas."}]',
    );
    await db.learningItemDao.upsert(
      DriftLearningItemRepository.companionFromItem(
        LearningItem(
          id: 'drift-learning-1',
          type: LearningItemType.word,
          canonicalKey: 'flow',
          title: 'flow',
          content: 'flow',
          answer: 'movement',
          note: '',
          sourceText: 'A steady flow of ideas.',
          bookId: book.id,
          chapterIndex: 2,
          chapterTitle: 'Chapter 3',
          createdAt: DateTime.utc(2026, 6, 12, 8, 10),
          updatedAt: DateTime.utc(2026, 6, 12, 8, 10),
        ),
        languageCode: 'en',
      ),
    );
    await db.learningAnalyticsDao.putValue('20260612', 'en', 3);
    await db.rssDao.insertSubscription(
      RssSubscriptionsCompanion.insert(
        id: 'rss-1',
        url: 'https://example.com/drift.xml',
        title: const Value('Drift RSS'),
        lastFetchedAt: const Value('2026-06-12T08:20:00.000Z'),
      ),
    );
    await db.bookGlossaryDao.upsert(
      BookGlossaryCompanion.insert(
        id: 'glossary-1',
        bookId: book.id,
        word: 'flow',
        explanation: const Value('movement'),
        createdAt: const Value('2026-06-12T08:30:00.000Z'),
      ),
    );
    await db.characterRegistryDao.putValue(
      book.id,
      '[{"name":"Reader","aliases":[]}]',
    );
    await db.settingsDao.putValue('aiProviderId', 'openai');
    await db.settingsDao.putValue('apiKey', 'secret-key');
    await db.settingsDao.putValue('backupFolderPath', '/private/backups');

    await userVocabularyBox().put('hive-only', 'known');

    final backupPath = await backup.exportNow(
      folderPath: '${tempDir.path}/drift_backups',
    );

    final bakFile = File(backupPath);
    final boxes = _decodeBackupBoxes(bakFile);
    expect(boxes.keys, containsAll(BackupService.backupDataBoxNames));

    final bookEntries =
        boxes[HiveBoxNames.booksFor('en')]['entries'] as List<dynamic>;
    final bookEntry = bookEntries.single as Map<String, dynamic>;
    expect(bookEntry['key'], {'type': 'string', 'value': book.id});
    expect(bookEntry['value']['title'], 'Drift Book');
    expect(bookEntry['value']['chapterScrollOffset'], 240);

    final vocabEntries =
        boxes[HiveBoxNames.userVocabularyFor('en')]['entries'] as List<dynamic>;
    expect(vocabEntries, [
      {
        'key': {'type': 'string', 'value': 'flow'},
        'value': 'known',
      },
    ]);

    final wordBookmarkEntries =
        boxes[HiveBoxNames.wordBookmarksFor('en')]['entries'] as List<dynamic>;
    expect(wordBookmarkEntries.single['key'], {
      'type': 'string',
      'value': book.id,
    });
    expect(
      (jsonDecode(wordBookmarkEntries.single['value'] as String)
              as List<dynamic>)
          .single['word'],
      'flow',
    );

    final readingTimeEntries =
        boxes[HiveBoxNames.readingTimeFor('en')]['entries'] as List<dynamic>;
    expect(readingTimeEntries.single, {
      'key': {'type': 'string', 'value': '_global_'},
      'value': 300,
    });

    final glossaryEntries =
        boxes[HiveBoxNames.bookGlossary]['entries'] as List<dynamic>;
    expect(glossaryEntries.single['value']['explanation'], 'movement');

    final settingsEntries =
        boxes[HiveBoxNames.settings]['entries'] as List<dynamic>;
    final settingKeys = settingsEntries
        .map((entry) => entry['key']['value'] as String)
        .toSet();
    expect(settingKeys, contains('aiProviderId'));
    expect(settingKeys, isNot(contains('apiKey')));
    expect(settingKeys, isNot(contains('backupFolderPath')));

    final zipArchive = ZipDecoder().decodeBytes(await bakFile.readAsBytes());
    final sourceEntry = zipArchive.findFile(
      archive.bookSourceEntryPath(book.id),
    );
    expect(sourceEntry, isNotNull);
    expect(utf8.decode(sourceEntry!.content), 'drift epub content');
  });

  test('imports v2 backup data into Drift storage', () async {
    final preImportDir = Directory('${tempDir.path}/drift_pre_import');
    await settings.setBackupFolderPath(preImportDir.path);

    final currentSource = File('${tempDir.path}/current.epub');
    await currentSource.writeAsString('current epub content');
    await db.bookDao.upsert(
      DriftBookRepository.companionFromMetadata(
        BookMetadata(
          id: 'current-book',
          title: 'Current Book',
          author: 'Author',
          sourcePath: currentSource.path,
          totalChapters: 1,
        ),
        languageCode: 'en',
      ),
    );
    await db.userVocabularyDao.upsert(
      UserVocabulariesCompanion.insert(
        id: 'en_current',
        canonical: 'current',
        status: 'known',
        language: const Value('en'),
      ),
    );
    await userVocabularyBox().put('hive-current', 'known');

    final importedBook = BookMetadata(
      id: 'imported-book',
      title: 'Imported Book',
      author: 'Author',
      sourcePath: '/external/imported.epub',
      totalChapters: 5,
      currentChapter: 3,
      chapterProgress: 0.75,
      chapterScrollOffset: 512,
      lastReadAt: DateTime.utc(2026, 6, 13, 9),
    );
    final importedItem = LearningItem(
      id: 'imported-learning',
      type: LearningItemType.word,
      canonicalKey: 'imported',
      title: 'imported',
      content: 'imported',
      answer: 'brought in',
      note: '',
      sourceText: 'Imported data should replace current data.',
      bookId: importedBook.id,
      chapterIndex: 3,
      chapterTitle: 'Chapter 4',
      createdAt: DateTime.utc(2026, 6, 13, 9, 10),
      updatedAt: DateTime.utc(2026, 6, 13, 9, 10),
    );
    final backupFile = await _writeFlowBackup(
      path: '${tempDir.path}/drift_import.flow.bak',
      schemaVersion: BackupService.schemaVersion,
      bookIds: [importedBook.id],
      bookHasCover: const {'imported-book': false},
      sourceBytesByBookId: {
        importedBook.id: Uint8List.fromList(utf8.encode('imported epub bytes')),
      },
      boxes: {
        HiveBoxNames.settings: {
          'entries': [
            {
              'key': {'type': 'string', 'value': 'aiProviderId'},
              'value': 'openai',
            },
            {
              'key': {'type': 'string', 'value': 'backupFolderPath'},
              'value': '/should/not/replace',
            },
          ],
        },
        HiveBoxNames.rssSubscriptions: {
          'entries': [
            {
              'key': {'type': 'int', 'value': 0},
              'value': {
                'url': 'https://example.com/imported.xml',
                'title': 'Imported RSS',
                'lastFetchedAt': '2026-06-13T09:20:00.000Z',
              },
            },
          ],
        },
        HiveBoxNames.characterRegistry: {
          'entries': [
            {
              'key': {'type': 'string', 'value': importedBook.id},
              'value': '[{"name":"Imported","aliases":[]}]',
            },
          ],
        },
        HiveBoxNames.booksFor('en'): {
          'entries': [
            {
              'key': {'type': 'string', 'value': importedBook.id},
              'value': importedBook.toJson(),
            },
          ],
        },
        HiveBoxNames.userVocabularyFor('en'): {
          'entries': [
            {
              'key': {'type': 'string', 'value': 'imported'},
              'value': 'learning',
            },
          ],
        },
        HiveBoxNames.wordBookmarksFor('en'): {
          'entries': [
            {
              'key': {'type': 'string', 'value': importedBook.id},
              'value': jsonEncode([
                {
                  'word': 'imported',
                  'translation': '导入的',
                  'context': 'Imported data should replace current data.',
                  'addedAt': '2026-06-13T09:05:00.000Z',
                },
              ]),
            },
          ],
        },
        HiveBoxNames.readingBookmarksFor('en'): {
          'entries': [
            {
              'key': {'type': 'string', 'value': importedBook.id},
              'value': jsonEncode([
                {
                  'chapterIndex': 3,
                  'progress': 0.75,
                  'chapterTitle': 'Chapter 4',
                  'excerpt': 'A restored paragraph.',
                  'createdAt': '2026-06-13T09:06:00.000Z',
                },
              ]),
            },
          ],
        },
        HiveBoxNames.readingConfigFor('en'): {
          'entries': [
            {
              'key': {'type': 'string', 'value': 'fontSize'},
              'value': '21.0',
            },
          ],
        },
        HiveBoxNames.readingTimeFor('en'): {
          'entries': [
            {
              'key': {'type': 'string', 'value': '_global_'},
              'value': 600,
            },
          ],
        },
        HiveBoxNames.wordContextsFor('en'): {
          'entries': [
            {
              'key': {'type': 'string', 'value': 'imported'},
              'value':
                  '[{"word":"imported","text":"Imported data should replace current data."}]',
            },
          ],
        },
        HiveBoxNames.learningItemsFor('en'): {
          'entries': [
            {
              'key': {'type': 'string', 'value': importedItem.id},
              'value': importedItem.toJson(),
            },
          ],
        },
        HiveBoxNames.learningAnalyticsFor('en'): {
          'entries': [
            {
              'key': {'type': 'string', 'value': 'lookups'},
              'value': 5,
            },
          ],
        },
        HiveBoxNames.bookGlossary: {
          'entries': [
            {
              'key': {'type': 'string', 'value': 'glossary-imported'},
              'value': {
                'id': 'glossary-imported',
                'bookId': importedBook.id,
                'word': 'imported',
                'explanation': 'brought in',
                'createdAt': '2026-06-13T09:30:00.000Z',
              },
            },
          ],
        },
      },
    );

    await backup.importBackupFile(backupFile.path);

    expect(await db.bookDao.getById('current-book'), isNull);
    final restoredBook = await db.bookDao.getById(importedBook.id);
    expect(restoredBook?.title, 'Imported Book');
    expect(
      restoredBook?.sourcePath,
      '${documentsDir.path}/books/imported-book.epub',
    );
    expect(
      await File(restoredBook!.sourcePath).readAsString(),
      'imported epub bytes',
    );
    expect(await db.userVocabularyDao.entryFor('en_current'), isNull);
    expect(
      await db.userVocabularyDao.entryFor('en_imported'),
      isA<UserVocabulary>(),
    );
    expect(
      await db.readingConfigDao.valueFor('fontSize', 'en'),
      '21.0',
    );
    expect(await db.readingTimeDao.secondsFor('_global_', 'en'), 600);
    expect(
      await db.wordContextDao.dataFor('imported', 'en'),
      contains('Imported data'),
    );
    expect(
      (await db.learningItemDao.getById(importedItem.id))?.answer,
      'brought in',
    );
    expect(await db.learningAnalyticsDao.valueFor('lookups', 'en'), 5);
    expect((await db.rssDao.allSubscriptions()).single.title, 'Imported RSS');
    expect(
      (await db.bookGlossaryDao.entriesForBook(importedBook.id)).single.word,
      'imported',
    );
    expect(
      await db.characterRegistryDao.valueFor(importedBook.id),
      contains('Imported'),
    );
    expect(settings.aiProviderId, 'openai');
    expect(settings.backupFolderPath, preImportDir.path);
    expect(userVocabularyBox().get('hive-current'), 'known');
    expect(
      preImportDir.listSync().whereType<File>().where(
        (file) => file.path.endsWith('.flow.bak'),
      ),
      hasLength(1),
    );
  });

  test('exports and restores book source and cover files', () async {
    final sourceBytes = utf8.encode('epub bytes');
    final coverBytes = Uint8List.fromList([0, 1, 2, 3, 4]);
    final sourceFile = File('${tempDir.path}/picked.epub');
    final coverFile = File('${tempDir.path}/cover.png');
    await sourceFile.writeAsBytes(sourceBytes);
    await coverFile.writeAsBytes(coverBytes);

    final book = BookMetadata(
      id: 'book-file',
      title: 'Restorable Book',
      author: 'Author',
      sourcePath: sourceFile.path,
      coverPath: coverFile.path,
      totalChapters: 2,
      currentChapter: 1,
      chapterProgress: 0.25,
      chapterScrollOffset: 480,
    );
    await db.bookDao.upsert(
      DriftBookRepository.companionFromMetadata(book, languageCode: 'en'),
    );

    await backup.exportNow(folderPath: '${tempDir.path}/backups');

    final backupDir = Directory('${tempDir.path}/backups');
    final bakFiles = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.flow.bak'))
        .toList();
    expect(bakFiles, hasLength(1));

    final bakFileBytes = await bakFiles.first.readAsBytes();
    final zipArchive = ZipDecoder().decodeBytes(bakFileBytes);

    final sourceEntry = zipArchive.findFile(
      archive.bookSourceEntryPath('book-file'),
    );
    expect(sourceEntry, isNotNull);
    expect(sourceEntry!.content, sourceBytes);

    final coverEntry = zipArchive.findFile(
      archive.bookCoverEntryPath('book-file'),
    );
    expect(coverEntry, isNotNull);
    expect(coverEntry!.content, coverBytes);

    await db.bookDao.deleteAllForLanguage('en');
    await sourceFile.delete();
    await coverFile.delete();

    await backup.importBackupFile(bakFiles.first.path);

    final restored = (await db.bookDao.getById('book-file'))!;
    final restoredSource = File(restored.sourcePath);
    final restoredCover = File(restored.coverPath!);
    expect(restored.sourcePath, '${documentsDir.path}/books/book-file.epub');
    expect(
      restored.coverPath,
      '${documentsDir.path}/books/book-file_cover.png',
    );
    expect(await restoredSource.readAsBytes(), sourceBytes);
    expect(await restoredCover.readAsBytes(), coverBytes);
    expect(restored.currentChapter, 1);
    expect(restored.chapterScrollOffset, 480);
  });

  test('direct import creates pre-import backup before restore', () async {
    final preImportDir = Directory('${tempDir.path}/pre_import_backups');
    await settings.setBackupFolderPath(preImportDir.path);

    await db.userVocabularyDao.upsert(
      UserVocabulariesCompanion.insert(
        id: 'en_imported',
        canonical: 'imported',
        status: 'known',
        language: const Value('en'),
      ),
    );
    final importPath = await backup.exportNow(
      folderPath: '${tempDir.path}/restore_source',
    );
    final lastBackupAt = settings.lastBackupAt;
    final lastBackupPath = settings.lastBackupPath;

    await db.userVocabularyDao.clearForLanguage('en');
    await db.userVocabularyDao.upsert(
      UserVocabulariesCompanion.insert(
        id: 'en_current',
        canonical: 'current',
        status: 'learning',
        language: const Value('en'),
      ),
    );

    await backup.importBackupFile(importPath);

    expect(
      (await db.userVocabularyDao.entryFor('en_imported'))?.status,
      'known',
    );
    expect(await db.userVocabularyDao.entryFor('en_current'), isNull);
    expect(settings.lastBackupAt, lastBackupAt);
    expect(settings.lastBackupPath, lastBackupPath);

    final preImportFiles = preImportDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.flow.bak'))
        .toList();
    expect(preImportFiles, hasLength(1));
    expect(
      preImportFiles.single.path.split(Platform.pathSeparator).last,
      startsWith('flow_read_pre_import_'),
    );

    final boxes = _decodeBackupBoxes(preImportFiles.single);
    final vocabEntries =
        boxes[HiveBoxNames.userVocabularyFor('en')]['entries'] as List<dynamic>;
    expect(vocabEntries.single, {
      'key': {'type': 'string', 'value': 'current'},
      'value': 'learning',
    });
  });

  test('imports v1 backup data into Drift default language', () async {
    await db.userVocabularyDao.upsert(
      UserVocabulariesCompanion.insert(
        id: 'en_current',
        canonical: 'current',
        status: 'learning',
        language: const Value('en'),
      ),
    );

    final sourceBytes = utf8.encode('legacy epub bytes');
    final legacyBook = BookMetadata(
      id: 'legacy-book',
      title: 'Legacy Book',
      author: 'Author',
      sourcePath: '/legacy/source.epub',
      totalChapters: 2,
      currentChapter: 1,
      chapterProgress: 0.5,
    );
    final backupFile = await _writeFlowBackup(
      path: '${tempDir.path}/legacy.flow.bak',
      schemaVersion: 1,
      bookIds: [legacyBook.id],
      bookHasCover: const {'legacy-book': false},
      sourceBytesByBookId: {'legacy-book': Uint8List.fromList(sourceBytes)},
      boxes: {
        HiveBoxNames.books: {
          'entries': [
            {
              'key': {'type': 'string', 'value': legacyBook.id},
              'value': legacyBook.toJson(),
            },
          ],
        },
        HiveBoxNames.userVocabulary: {
          'entries': [
            {
              'key': {'type': 'string', 'value': 'legacy'},
              'value': 'known',
            },
          ],
        },
        HiveBoxNames.wordBookmarks: {'entries': <Map<String, dynamic>>[]},
        HiveBoxNames.readingBookmarks: {'entries': <Map<String, dynamic>>[]},
        HiveBoxNames.readingConfig: {
          'entries': [
            {
              'key': {'type': 'string', 'value': 'fontSize'},
              'value': '19',
            },
          ],
        },
        HiveBoxNames.readingTime: {
          'entries': [
            {
              'key': {'type': 'string', 'value': 'legacy-book'},
              'value': 75,
            },
          ],
        },
        HiveBoxNames.wordContexts: {'entries': <Map<String, dynamic>>[]},
        HiveBoxNames.learningItems: {'entries': <Map<String, dynamic>>[]},
        HiveBoxNames.learningAnalytics: {'entries': <Map<String, dynamic>>[]},
      },
    );

    await backup.importBackupFile(backupFile.path);

    final restoredBook = await db.bookDao.getById('legacy-book');
    expect(restoredBook?.title, 'Legacy Book');
    expect(
      restoredBook?.sourcePath,
      '${documentsDir.path}/books/legacy-book.epub',
    );
    expect(await File(restoredBook!.sourcePath).readAsBytes(), sourceBytes);
    expect(
      (await db.userVocabularyDao.entryFor('en_legacy'))?.status,
      'known',
    );
    expect(await db.userVocabularyDao.entryFor('en_current'), isNull);
    expect(await db.readingConfigDao.valueFor('fontSize', 'en'), '19');
    expect(await db.readingTimeDao.secondsFor('legacy-book', 'en'), 75);
    expect(settings.activeSourceLanguage, 'en');
  });

  test('exportNow writes a .flow.bak file into the selected folder', () async {
    await db.readingTimeDao.putSeconds('_global_', 'en', 30);

    final path = await backup.exportNow(folderPath: '${tempDir.path}/backups');
    final file = File(path);

    expect(await file.exists(), isTrue);
    expect(file.path, endsWith('.flow.bak'));
    expect(file.path, isNot(endsWith('.json')));

    final bakFileBytes = await file.readAsBytes();
    final zipArchive = ZipDecoder().decodeBytes(bakFileBytes);
    final manifest =
        jsonDecode(utf8.decode(zipArchive.findFile('manifest.json')!.content))
            as Map<String, dynamic>;
    expect(manifest['app'], BackupService.appId);
    expect(manifest['formatVersion'], archive.supportedManifestFormatVersion);
  });

  test('export fails when a book source file is missing', () async {
    final book = BookMetadata(
      id: 'missing-source',
      title: 'Missing Book',
      author: 'Author',
      sourcePath: '${tempDir.path}/nonexistent.epub',
      totalChapters: 1,
    );
    await db.bookDao.upsert(
      DriftBookRepository.companionFromMetadata(book, languageCode: 'en'),
    );

    expect(
      () => backup.exportNow(folderPath: '${tempDir.path}/backups'),
      throwsA(
        isA<BackupException>().having(
          (e) => e.message,
          'message',
          contains('缺失'),
        ),
      ),
    );
  });

  test(
    'imports Word Hunter backup as vocabulary status and examples',
    () async {
      await db.userVocabularyDao.upsert(
        UserVocabulariesCompanion.insert(
          id: 'en_agenda',
          canonical: 'agenda',
          status: 'known',
          language: const Value('en'),
        ),
      );
      await db.wordContextDao.putData(
        'agenda',
        'en',
        jsonEncode([
          {'word': 'agenda', 'text': 'Existing example.'},
        ]),
      );

      final result = await backup.importWordHunterPayload({
        'known': {'Flow': 'o', 'the': 'o'},
        'learning': ['migrate'],
        'context': {
          'Agenda': [
            {
              'word': 'Agenda',
              'text': 'Let us see what is on the agenda today.',
              'title': 'Sapiens',
              'url': 'file:///book',
              'timestamp': 1696336821349,
            },
          ],
          'Partition': [
            {'text': 'function partition(nums, l, r) {', 'title': 'LeetCode'},
          ],
        },
      });

      expect(result.knownCount, 2);
      expect(result.learningCount, 2);
      expect(result.exampleCount, 2);

      expect((await db.userVocabularyDao.entryFor('en_flow'))?.status, 'known');
      expect((await db.userVocabularyDao.entryFor('en_the'))?.status, 'known');
      expect(
        (await db.userVocabularyDao.entryFor('en_agenda'))?.status,
        'known',
      );
      expect(
        (await db.userVocabularyDao.entryFor('en_migrate'))?.status,
        'learning',
      );
      expect(
        (await db.userVocabularyDao.entryFor('en_partition'))?.status,
        'learning',
      );

      final agendaExamples =
          jsonDecode((await db.wordContextDao.dataFor('agenda', 'en'))!)
              as List<dynamic>;
      expect(agendaExamples, hasLength(2));
      expect(
        agendaExamples.last['text'],
        'Let us see what is on the agenda today.',
      );
      expect(agendaExamples.last['title'], 'Sapiens');

      final partitionExamples =
          jsonDecode((await db.wordContextDao.dataFor('partition', 'en'))!)
              as List<dynamic>;
      expect(
        partitionExamples.single['text'],
        'function partition(nums, l, r) {',
      );
    },
  );

  test('imports Word Hunter backup from file without double parsing', () async {
    final file = File('${tempDir.path}/word_hunter.json');
    await file.writeAsString(
      jsonEncode({
        'known': {'already': 'o', 'mastered': 'o'},
        'context': {
          'learning': [
            {
              'word': 'learning',
              'text': 'Learning appears in an imported sentence.',
              'title': 'Imported',
            },
          ],
        },
      }),
    );

    final result = await backup.importWordHunterBackupFile(file.path);

    expect(result.knownCount, 2);
    expect(result.learningCount, 1);
    expect(result.exampleCount, 1);

    expect(
      (await db.userVocabularyDao.entryFor('en_already'))?.status,
      'known',
    );
    expect(
      (await db.userVocabularyDao.entryFor('en_mastered'))?.status,
      'known',
    );
    expect(
      (await db.userVocabularyDao.entryFor('en_learning'))?.status,
      'learning',
    );

    final examples =
        jsonDecode((await db.wordContextDao.dataFor('learning', 'en'))!)
            as List<dynamic>;
    expect(
      examples.single['text'],
      'Learning appears in an imported sentence.',
    );
  });
}

WordHunterImportService _driftWordHunterImportService(AppDatabase db) {
  return WordHunterImportService(
    vocabularyService: UserVocabularyService(
      repository: DriftUserVocabularyRepository(
        db.userVocabularyDao,
        languageCode: 'en',
      ),
      languageCode: 'en',
    ),
    wordContextService: WordContextService(
      repository: DriftWordContextRepository(
        db.wordContextDao,
        languageCode: 'en',
      ),
    ),
  );
}

Map<String, dynamic> _decodeBackupBoxes(File file) {
  final zipArchive = ZipDecoder().decodeBytes(file.readAsBytesSync());
  final data =
      jsonDecode(utf8.decode(zipArchive.findFile('data/app.json')!.content))
          as Map<String, dynamic>;
  return data['boxes'] as Map<String, dynamic>;
}

Future<File> _writeFlowBackup({
  required String path,
  required int schemaVersion,
  required List<String> bookIds,
  required Map<String, bool> bookHasCover,
  required Map<String, Uint8List> sourceBytesByBookId,
  required Map<String, dynamic> boxes,
}) async {
  final manifest = archive.buildManifest(
    appId: BackupService.appId,
    formatVersion: archive.supportedManifestFormatVersion,
    createdAt: DateTime.utc(2026, 6, 3, 8),
    bookIds: bookIds,
    bookHasCover: bookHasCover,
  );
  final data = archive.buildDataPayload(
    schemaVersion: schemaVersion,
    boxes: boxes,
  );
  final entries = <String, Map<String, dynamic>>{
    for (final id in bookIds)
      archive.bookSourceEntryPath(id): {
        'bytes': sourceBytesByBookId[id]!,
        'compress': false,
      },
  };
  final bytes = archive.encodeZipArchive({
    'manifestJson': jsonEncode(manifest),
    'dataJson': jsonEncode(data),
    'entries': entries,
  });
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

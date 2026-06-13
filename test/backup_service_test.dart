import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flow_read/models/book_difficulty.dart';
import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/models/learning_item.dart';
import 'package:flow_rss/flow_rss.dart';
import 'package:flow_read/services/backup_archive.dart' as archive;
import 'package:flow_read/services/backup_service.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/storage/hive_box_names.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_test_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory documentsDir;
  late SettingsService settings;
  late BackupService backup;

  setUp(() async {
    tempDir = await initHiveTestStorage(
      'flow_read_backup_test_',
      hivePathSuffix: 'hive',
    );
    await openFlowReadTestBoxes();
    documentsDir = await Directory('${tempDir.path}/documents').create();

    settings = await createTestSettingsService();
    settingsBox()
      ..put('aiProviderId', settings.aiProviderId)
      ..put('aiApiKeys', '{}')
      ..put('backupFolderPath', '')
      ..put('backupFolderBookmark', '');
    backup = BackupService(
      settings,
      documentsDirectoryProvider: () async => documentsDir,
    );
  });

  tearDown(() async {
    backup.dispose();
    await disposeHiveTestStorage(tempDir);
  });

  test('exports Hive data to .flow.bak and imports it back', () async {
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

    await booksBox().put(book.id, book.copyWith(sourcePath: epubFile.path));
    await userVocabularyBox().put('flow', 'known');
    await readingConfigBox().put('fontSize', '18.0');
    await readingTimeBox().put('_global_', 120);
    await learningAnalyticsBox().put(20260515, 7);
    await dictionaryCacheBox().put('flow', '{"word":"flow"}');
    await wordContextsBox().put(
      'flow',
      '[{"word":"flow","text":"A steady flow of ideas."}]',
    );
    await learningItemsBox().put(
      'learning-1',
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
    );
    await rssSubscriptionsBox().add(
      RssFeedSubscription(
        url: 'https://example.com/rss.xml',
        title: 'Example',
        lastFetchedAt: DateTime.utc(2026, 5, 15),
      ),
    );
    await settings.setAIProvider('openai');
    await settings.setAIModel('reader-model');
    await settings.setApiKey('secret-key');
    await settings.setBackupFolderPath(
      '/private/backups',
      bookmark: 'bookmark',
    );
    await settingsBox().put('rss_read_articles', jsonEncode(['a1']));

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

    await booksBox().clear();
    await userVocabularyBox().clear();
    await readingConfigBox().clear();
    await readingTimeBox().clear();
    await learningAnalyticsBox().clear();
    await dictionaryCacheBox().clear();
    await wordContextsBox().clear();
    await learningItemsBox().clear();
    await rssSubscriptionsBox().clear();

    await backup.importBackupFile(bakFiles.first.path);

    final restoredBook = booksBox().get('book-1');
    expect(restoredBook?.title, 'Test Book');
    expect(restoredBook?.chapterScrollOffset, 320);
    expect(restoredBook?.difficultyStudyWords, ['flow', 'reading']);
    expect(restoredBook?.difficultyRating?.level, BookDifficultyLevel.l2);
    expect(restoredBook?.difficultyVocabularySignature, 'vocab-v1');
    expect(userVocabularyBox().get('flow'), 'known');
    expect(readingConfigBox().get('fontSize'), '18.0');
    expect(readingTimeBox().get('_global_'), 120);
    expect(learningAnalyticsBox().get(20260515), 7);
    expect(dictionaryCacheBox().get('flow'), isNull);
    expect(
      wordContextsBox().get('flow'),
      '[{"word":"flow","text":"A steady flow of ideas."}]',
    );
    expect(learningItemsBox().get('learning-1')?.answer, 'movement');
    expect(rssSubscriptionsBox().values.single.title, 'Example');
    expect(settings.aiProviderId, 'openai');
    expect(settings.apiKeyFor('openai'), 'secret-key');
    expect(settings.backupFolderPath, '/private/backups');
    expect(settings.backupFolderBookmark, 'bookmark');
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
    await booksBox().put(book.id, book);

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

    await booksBox().clear();
    await sourceFile.delete();
    await coverFile.delete();

    await backup.importBackupFile(bakFiles.first.path);

    final restored = booksBox().get('book-file')!;
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

    await userVocabularyBox().put('imported', 'known');
    final importPath = await backup.exportNow(
      folderPath: '${tempDir.path}/restore_source',
    );
    final lastBackupAt = settings.lastBackupAt;
    final lastBackupPath = settings.lastBackupPath;

    await userVocabularyBox().clear();
    await userVocabularyBox().put('current', 'learning');

    await backup.importBackupFile(importPath);

    expect(userVocabularyBox().get('imported'), 'known');
    expect(userVocabularyBox().get('current'), isNull);
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

  test('imports v1 backup data into English language boxes', () async {
    await userVocabularyBox().put('current', 'learning');

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

    final restoredBook = booksBox().get('legacy-book');
    expect(restoredBook?.title, 'Legacy Book');
    expect(
      restoredBook?.sourcePath,
      '${documentsDir.path}/books/legacy-book.epub',
    );
    expect(await File(restoredBook!.sourcePath).readAsBytes(), sourceBytes);
    expect(userVocabularyBox().get('legacy'), 'known');
    expect(userVocabularyBox().get('current'), isNull);
    expect(readingConfigBox().get('fontSize'), '19');
    expect(readingTimeBox().get('legacy-book'), 75);
    expect(settings.activeSourceLanguage, 'en');
    expect(v1BooksBox().get('legacy-book')?.title, 'Legacy Book');
    expect(v1UserVocabularyBox().get('legacy'), 'known');
  });

  test('exportNow writes a .flow.bak file into the selected folder', () async {
    await readingTimeBox().put('_global_', 30);

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
    await booksBox().put(book.id, book);

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
      await userVocabularyBox().put('agenda', 'known');
      await wordContextsBox().put(
        'agenda',
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

      final vocabulary = UserVocabularyService();
      await vocabulary.init();
      expect(vocabulary.isKnown('flow'), isTrue);
      expect(vocabulary.isKnown('the'), isTrue);
      expect(vocabulary.isKnown('agenda'), isTrue);
      expect(vocabulary.isLearning('migrate'), isTrue);
      expect(vocabulary.isLearning('partition'), isTrue);

      final agendaExamples =
          jsonDecode(wordContextsBox().get('agenda')!) as List<dynamic>;
      expect(agendaExamples, hasLength(2));
      expect(
        agendaExamples.last['text'],
        'Let us see what is on the agenda today.',
      );
      expect(agendaExamples.last['title'], 'Sapiens');

      final partitionExamples =
          jsonDecode(wordContextsBox().get('partition')!) as List<dynamic>;
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

    final vocabulary = UserVocabularyService();
    await vocabulary.init();
    expect(vocabulary.isKnown('already'), isTrue);
    expect(vocabulary.isKnown('mastered'), isTrue);
    expect(vocabulary.isLearning('learning'), isTrue);

    final examples =
        jsonDecode(wordContextsBox().get('learning')!) as List<dynamic>;
    expect(
      examples.single['text'],
      'Learning appears in an imported sentence.',
    );
  });
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

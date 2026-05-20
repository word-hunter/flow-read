import 'dart:convert';
import 'dart:io';

import 'package:flow_read/models/book_difficulty.dart';
import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/models/learning_item.dart';
import 'package:flow_read/models/rss_models.dart';
import 'package:flow_read/services/backup_service.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/storage/hive_box_names.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_test_storage.dart';

void main() {
  late Directory tempDir;
  late SettingsService settings;
  late BackupService backup;

  setUp(() async {
    tempDir = await initHiveTestStorage(
      'flow_read_backup_test_',
      hivePathSuffix: 'hive',
    );
    await openFlowReadTestBoxes();

    settings = SettingsService();
    await settings.init();
    backup = BackupService(settings);
  });

  tearDown(() async {
    backup.dispose();
    await disposeHiveTestStorage(tempDir);
  });

  test('exports Hive data to JSON and imports it back', () async {
    final book = BookMetadata(
      id: 'book-1',
      title: 'Test Book',
      author: 'Author',
      sourcePath: '/books/test.epub',
      totalChapters: 3,
      currentChapter: 1,
      chapterProgress: 0.4,
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
    await booksBox().put(book.id, book);
    await userVocabularyBox().put('flow', 'known');
    await readingConfigBox().put('fontSize', '18.0');
    await readingTimeBox().put('_global_', 120);
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

    final payload = backup.createBackupPayload(
      createdAt: DateTime.utc(2026, 5, 15, 9),
    );

    final settingsEntries =
        (payload['boxes']
                as Map<String, dynamic>)[HiveBoxNames.settings]['entries']
            as List<dynamic>;
    final settingKeys = settingsEntries
        .map((entry) => entry['key']['value'] as String)
        .toSet();
    expect(settingKeys, isNot(contains('apiKey')));
    expect(settingKeys, isNot(contains('aiApiKeys')));
    expect(settingKeys, isNot(contains('backupFolderPath')));
    expect(settingKeys, isNot(contains('backupFolderBookmark')));
    expect(settingKeys, contains('aiProviderId'));

    await settings.setIncludeSecretsInBackup(true);
    final payloadWithSecrets = backup.createBackupPayload(
      createdAt: DateTime.utc(2026, 5, 15, 9),
    );
    final secretSettingKeys =
        ((payloadWithSecrets['boxes']
                    as Map<String, dynamic>)[HiveBoxNames.settings]['entries']
                as List<dynamic>)
            .map((entry) => entry['key']['value'] as String);
    expect(secretSettingKeys, contains('aiApiKeys'));

    await booksBox().clear();
    await userVocabularyBox().clear();
    await readingConfigBox().clear();
    await readingTimeBox().clear();
    await dictionaryCacheBox().clear();
    await wordContextsBox().clear();
    await learningItemsBox().clear();
    await rssSubscriptionsBox().clear();

    await backup.importBackupPayload(payload);

    final restoredBook = booksBox().get('book-1');
    expect(restoredBook?.title, 'Test Book');
    expect(restoredBook?.difficultyStudyWords, ['flow', 'reading']);
    expect(restoredBook?.difficultyRating?.level, BookDifficultyLevel.l2);
    expect(restoredBook?.difficultyVocabularySignature, 'vocab-v1');
    expect(userVocabularyBox().get('flow'), 'known');
    expect(readingConfigBox().get('fontSize'), '18.0');
    expect(readingTimeBox().get('_global_'), 120);
    expect(dictionaryCacheBox().get('flow'), '{"word":"flow"}');
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

  test('exportNow writes a backup file into the selected folder', () async {
    await settings.setBackupFolderPath('${tempDir.path}/backups');
    await readingTimeBox().put('_global_', 30);

    final path = await backup.exportNow();
    final file = File(path);

    expect(await file.exists(), isTrue);
    final payload =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(payload['app'], BackupService.appId);
    expect(payload['schemaVersion'], BackupService.schemaVersion);
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
      expect(userVocabularyBox().get('flow'), 'known');
      expect(userVocabularyBox().get('the'), 'known');
      expect(userVocabularyBox().get('agenda'), 'known');
      expect(userVocabularyBox().get('migrate'), 'learning');
      expect(userVocabularyBox().get('partition'), 'learning');

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
    expect(userVocabularyBox().get('already'), 'known');
    expect(userVocabularyBox().get('mastered'), 'known');
    expect(userVocabularyBox().get('learning'), 'learning');

    final examples =
        jsonDecode(wordContextsBox().get('learning')!) as List<dynamic>;
    expect(
      examples.single['text'],
      'Learning appears in an imported sentence.',
    );
  });
}

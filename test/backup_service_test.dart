import 'dart:convert';
import 'dart:io';

import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/models/bookmarked_word.dart';
import 'package:flow_read/models/reading_bookmark.dart';
import 'package:flow_read/models/reading_config.dart';
import 'package:flow_read/models/rss_models.dart';
import 'package:flow_read/models/word_level.dart';
import 'package:flow_read/services/backup_service.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late SettingsService settings;
  late BackupService backup;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('flow_read_backup_test_');
    Hive.init('${tempDir.path}/hive');
    _registerAdapters();
    await _openBoxes();

    settings = SettingsService();
    await settings.init();
    backup = BackupService(settings);
  });

  tearDown(() async {
    backup.dispose();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
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
    );
    await Hive.box<BookMetadata>('books').put(book.id, book);
    await Hive.box<String>('user_vocabulary').put('flow', 'known');
    await Hive.box<String>('reading_config').put('fontSize', '18.0');
    await Hive.box<int>('reading_time').put('_global_', 120);
    await Hive.box<String>('dictionary_cache').put('flow', '{"word":"flow"}');
    await Hive.box<String>(
      'word_contexts',
    ).put('flow', '[{"word":"flow","text":"A steady flow of ideas."}]');
    await Hive.box<RssFeedSubscription>('rss_subscriptions').add(
      RssFeedSubscription(
        url: 'https://example.com/rss.xml',
        title: 'Example',
        lastFetchedAt: DateTime.utc(2026, 5, 15),
      ),
    );
    await settings.setAIProvider('openai');
    await settings.setAIModel('reader-model');
    await settings.setApiKey('secret-key');
    await settings.setBackupFolderPath('/private/backups');
    await Hive.box('settings').put('rss_read_articles', jsonEncode(['a1']));

    final payload = backup.createBackupPayload(
      createdAt: DateTime.utc(2026, 5, 15, 9),
    );

    final settingsEntries =
        (payload['boxes'] as Map<String, dynamic>)['settings']['entries']
            as List<dynamic>;
    final settingKeys = settingsEntries
        .map((entry) => entry['key']['value'] as String)
        .toSet();
    expect(settingKeys, isNot(contains('apiKey')));
    expect(settingKeys, isNot(contains('aiApiKeys')));
    expect(settingKeys, isNot(contains('backupFolderPath')));
    expect(settingKeys, contains('aiProviderId'));

    await settings.setIncludeSecretsInBackup(true);
    final payloadWithSecrets = backup.createBackupPayload(
      createdAt: DateTime.utc(2026, 5, 15, 9),
    );
    final secretSettingKeys =
        ((payloadWithSecrets['boxes']
                    as Map<String, dynamic>)['settings']['entries']
                as List<dynamic>)
            .map((entry) => entry['key']['value'] as String);
    expect(secretSettingKeys, contains('aiApiKeys'));

    await Hive.box<BookMetadata>('books').clear();
    await Hive.box<String>('user_vocabulary').clear();
    await Hive.box<String>('reading_config').clear();
    await Hive.box<int>('reading_time').clear();
    await Hive.box<String>('dictionary_cache').clear();
    await Hive.box<String>('word_contexts').clear();
    await Hive.box<RssFeedSubscription>('rss_subscriptions').clear();

    await backup.importBackupPayload(payload);

    final restoredBook = Hive.box<BookMetadata>('books').get('book-1');
    expect(restoredBook?.title, 'Test Book');
    expect(Hive.box<String>('user_vocabulary').get('flow'), 'known');
    expect(Hive.box<String>('reading_config').get('fontSize'), '18.0');
    expect(Hive.box<int>('reading_time').get('_global_'), 120);
    expect(Hive.box<String>('dictionary_cache').get('flow'), '{"word":"flow"}');
    expect(
      Hive.box<String>('word_contexts').get('flow'),
      '[{"word":"flow","text":"A steady flow of ideas."}]',
    );
    expect(
      Hive.box<RssFeedSubscription>('rss_subscriptions').values.single.title,
      'Example',
    );
    expect(settings.aiProviderId, 'openai');
    expect(settings.apiKeyFor('openai'), 'secret-key');
    expect(settings.backupFolderPath, '/private/backups');
  });

  test('exportNow writes a backup file into the selected folder', () async {
    await settings.setBackupFolderPath('${tempDir.path}/backups');
    await Hive.box<int>('reading_time').put('_global_', 30);

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
      await Hive.box<String>('user_vocabulary').put('agenda', 'known');
      await Hive.box<String>('word_contexts').put(
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
      expect(Hive.box<String>('user_vocabulary').get('flow'), 'known');
      expect(Hive.box<String>('user_vocabulary').get('the'), 'known');
      expect(Hive.box<String>('user_vocabulary').get('agenda'), 'known');
      expect(Hive.box<String>('user_vocabulary').get('migrate'), 'learning');
      expect(Hive.box<String>('user_vocabulary').get('partition'), 'learning');

      final agendaExamples =
          jsonDecode(Hive.box<String>('word_contexts').get('agenda')!)
              as List<dynamic>;
      expect(agendaExamples, hasLength(2));
      expect(
        agendaExamples.last['text'],
        'Let us see what is on the agenda today.',
      );
      expect(agendaExamples.last['title'], 'Sapiens');

      final partitionExamples =
          jsonDecode(Hive.box<String>('word_contexts').get('partition')!)
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
    expect(Hive.box<String>('user_vocabulary').get('already'), 'known');
    expect(Hive.box<String>('user_vocabulary').get('mastered'), 'known');
    expect(Hive.box<String>('user_vocabulary').get('learning'), 'learning');

    final examples =
        jsonDecode(Hive.box<String>('word_contexts').get('learning')!)
            as List<dynamic>;
    expect(
      examples.single['text'],
      'Learning appears in an imported sentence.',
    );
  });
}

void _registerAdapters() {
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(BookMetadataAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(BookmarkedWordAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(ReadingBookmarkAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(ReadingConfigAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(WordLevelInfoAdapter());
  }
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(RssFeedSubscriptionAdapter());
  }
}

Future<void> _openBoxes() async {
  await Hive.openBox<BookMetadata>('books');
  await Hive.openBox<String>('user_vocabulary');
  await Hive.openBox('settings');
  await Hive.openBox<String>('word_bookmarks');
  await Hive.openBox<String>('reading_bookmarks');
  await Hive.openBox<String>('reading_config');
  await Hive.openBox<int>('reading_time');
  await Hive.openBox<WordLevelInfo>('word_levels');
  await Hive.openBox<String>('dictionary_cache');
  await Hive.openBox<RssFeedSubscription>('rss_subscriptions');
  await Hive.openBox<String>('word_contexts');
}

import 'dart:io';

import 'package:flow_read/storage/hive_box_names.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/hive_test_storage.dart';
import 'support/legacy_hive_repositories.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_repository_lifecycle_');
    await openFlowReadTestBoxes();
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test(
    'repositories reuse shared bootstrap boxes and do not close them',
    () async {
      final bookRepository = HiveBookMetadataRepository();
      await _initAndClose(bookRepository.init, bookRepository.close);
      final bookmarkRepository = HiveBookmarkRepository();
      await _initAndClose(bookmarkRepository.init, bookmarkRepository.close);
      final vocabularyRepository = HiveUserVocabularyRepository();
      await _initAndClose(
        vocabularyRepository.init,
        vocabularyRepository.close,
      );
      final learningItemRepository = HiveLearningItemRepository();
      await _initAndClose(
        learningItemRepository.init,
        learningItemRepository.close,
      );
      final readingConfigRepository = HiveReadingConfigRepository();
      await _initAndClose(
        readingConfigRepository.init,
        readingConfigRepository.close,
      );
      final readingTimeRepository = HiveReadingTimeRepository();
      await _initAndClose(
        readingTimeRepository.init,
        readingTimeRepository.close,
      );
      final wordLevelRepository = HiveWordLevelRepository();
      await _initAndClose(wordLevelRepository.init, wordLevelRepository.close);
      final rssRepository = HiveRssRepository();
      await _initAndClose(rssRepository.init, rssRepository.close);
      final dictionaryCacheRepository = HiveDictionaryCacheRepository();
      await _initAndClose(
        dictionaryCacheRepository.init,
        dictionaryCacheRepository.close,
      );
      final wordContextRepository = HiveWordContextRepository();
      await _initAndClose(
        wordContextRepository.init,
        wordContextRepository.close,
      );

      for (final boxName in HiveBoxNames.bootstrapBoxes) {
        expect(Hive.isBoxOpen(boxName), isTrue, reason: boxName);
      }
    },
  );
}

Future<void> _initAndClose(
  Future<void> Function() init,
  Future<void> Function() close,
) async {
  await init();
  await close();
}

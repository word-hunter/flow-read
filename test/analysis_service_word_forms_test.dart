import 'dart:io';

import 'package:flow_read/models/word_level.dart';
import 'package:flow_read/services/analysis_service.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/services/word_level_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'flow_read_word_forms_test_',
    );
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(WordLevelInfoAdapter());
    }
    await Hive.openBox<String>('user_vocabulary');
    await Hive.openBox<WordLevelInfo>('word_levels');
    await Hive.openBox('settings');
    await Hive.box('settings').put('word_levels_imported', 'true');
    await Hive.box<WordLevelInfo>('word_levels').addAll([
      const WordLevelInfo(
        word: 'partitions',
        originForm: 'partition',
        levelIndex: 6,
      ),
      const WordLevelInfo(
        word: 'migrating',
        originForm: 'migrate',
        levelIndex: 5,
      ),
    ]);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('analysis normalizes plural and tense forms like Word Hunter', () async {
    final vocab = UserVocabularyService();
    await vocab.init();
    await vocab.setKnown('can');
    await vocab.setKnown('partition');
    await vocab.setLearning('migrate');

    final wordLevels = WordLevelService();
    await wordLevels.init();

    final result = AnalysisService.analyzeChapter(
      'Web',
      "Partitions can't stop migrating rapidly.",
      vocab,
      wordLevels,
    );

    expect(result.knownWords, contains('can'));
    expect(result.knownWords, contains('partition'));
    expect(result.learningWords, contains('migrate'));
    expect(
      result.vocabulary.map((item) => item.word),
      isNot(contains('partitions')),
    );
    expect(
      result.vocabulary.map((item) => item.word),
      isNot(contains('migrating')),
    );
  });
}

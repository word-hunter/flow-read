import 'dart:io';

import 'package:flow_read/models/word_level.dart';
import 'package:flow_read/services/analysis_service.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/services/word_level_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_word_forms_test_');
    await openUserVocabularyTestBox();
    await openWordLevelsTestBox();
    await openSettingsTestBox();
    await settingsBox().put('word_levels_imported', 'true');
    await wordLevelsBox().addAll([
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
    await disposeHiveTestStorage(tempDir);
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

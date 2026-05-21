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
    await openFlowReadTestBoxes();
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

  test('analysis does not emit fake words from common contractions', () {
    final result = AnalysisService.analyzeChapter(
      'Contractions',
      "I didn't say it isn\u2019t true. It wasn\u2019t easy, "
          "Wouldn\u2019t work, and hadn\u2019t happened.",
    );

    final words = result.vocabulary.map((item) => item.word);

    expect(words, isNot(contains('didn')));
    expect(words, isNot(contains('isn')));
    expect(words, isNot(contains('wasn')));
    expect(words, isNot(contains('wouldn')));
    expect(words, isNot(contains('hadn')));
    expect(words, isNot(contains("didn't")));
    expect(words, isNot(contains("isn't")));
    expect(words, isNot(contains("wasn't")));
    expect(words, isNot(contains("wouldn't")));
    expect(words, isNot(contains("hadn't")));
  });

  test('analysis handles stacked contractions and apostrophe variants', () {
    final result = AnalysisService.analyzeChapter(
      'Contractions',
      'They shouldn\u2019t\u2019ve left. You\u2018re here. '
          'They\u02BCve arrived. We\uFF07ll stay. It\u00B4s done. '
          'Cannot fail. \u2019Twas late. \u2019til morning.',
    );

    final words = result.vocabulary.map((item) => item.word);

    expect(words, isNot(contains('shouldn')));
    expect(words, isNot(contains("shouldn't")));
    expect(words, isNot(contains("shouldn't've")));
    expect(words, isNot(contains("you're")));
    expect(words, isNot(contains("they've")));
    expect(words, isNot(contains("we'll")));
    expect(words, isNot(contains("it's")));
    expect(words, isNot(contains('cannot')));
    expect(words, isNot(contains('twas')));
    expect(words, isNot(contains('til')));
  });
}

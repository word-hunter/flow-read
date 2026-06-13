import 'dart:io';

import 'package:flow_language/flow_language.dart';

import 'package:flow_read/models/word_level.dart';
import 'package:flow_read/services/analysis_service.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/services/word_level_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_user_vocabulary_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_word_level_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_storage.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;

  setUp(() async {
    tempDir = await initTestStorage('flow_read_word_forms_test_');
    db = await createTestAppDatabase();
    final repository = DriftWordLevelRepository(
      db.wordLevelDao,
      db.settingsDao,
    );
    await repository.init();
    await repository.addAll(const [
      WordLevelInfo(word: 'partitions', originForm: 'partition', levelIndex: 6),
      WordLevelInfo(word: 'migrating', originForm: 'migrate', levelIndex: 5),
      WordLevelInfo(word: 'looked', originForm: 'look', levelIndex: 0),
      WordLevelInfo(word: 'thinks', originForm: 'think', levelIndex: 0),
      WordLevelInfo(word: 'answers', originForm: 'answer', levelIndex: 0),
      WordLevelInfo(word: 'spoken', originForm: 'speak', levelIndex: 0),
      WordLevelInfo(word: 'years', originForm: 'year', levelIndex: 0),
    ]);
    await repository.markImported();
  });

  tearDown(() async {
    await disposeTestStorage(tempDir);
  });

  test('analysis normalizes plural and tense forms like Word Hunter', () async {
    final vocab = UserVocabularyService(
      repository: DriftUserVocabularyRepository(
        db.userVocabularyDao,
        languageCode: 'en',
      ),
    );
    await vocab.init();
    await vocab.setKnown('can');
    await vocab.setKnown('partition');
    await vocab.setLearning('migrate');

    final wordLevels = WordLevelService(repository: _wordLevelRepository(db));
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

  test(
    'analysis canonicalizes common verb inflections via WordLevelService',
    () async {
      final vocab = UserVocabularyService(
        repository: DriftUserVocabularyRepository(
          db.userVocabularyDao,
          languageCode: 'en',
        ),
      );
      await vocab.init();
      await vocab.setKnown('look');
      await vocab.setKnown('think');
      await vocab.setLearning('answer');

      final wordLevels = WordLevelService(
        repository: _wordLevelRepository(db),
      );
      await wordLevels.init();

      final result = AnalysisService.analyzeChapter(
        'Verbs',
        'She looked around, thinks deeply, and answers quickly.',
        vocab,
        wordLevels,
      );

      expect(result.knownWords, contains('look'));
      expect(result.knownWords, contains('think'));
      expect(result.learningWords, contains('answer'));

      expect(
        result.vocabulary.map((item) => item.word),
        isNot(contains('looked')),
      );
      expect(
        result.vocabulary.map((item) => item.word),
        isNot(contains('thinks')),
      );
      expect(
        result.vocabulary.map((item) => item.word),
        isNot(contains('answers')),
      );
    },
  );

  test(
    'known words are recognized in non-lemma forms (past participle, plural)',
    () async {
      final vocab = UserVocabularyService(
        repository: DriftUserVocabularyRepository(
          db.userVocabularyDao,
          languageCode: 'en',
        ),
      );
      await vocab.init();
      await vocab.setKnown('speak');
      await vocab.setKnown('year');

      final wordLevels = WordLevelService(
        repository: _wordLevelRepository(db),
      );
      await wordLevels.init();

      final result = AnalysisService.analyzeChapter(
        'Non-lemma',
        'She has spoken for three years.',
        vocab,
        wordLevels,
      );

      expect(result.knownWords, contains('speak'));
      expect(result.knownWords, contains('year'));
      expect(
        result.vocabulary.map((item) => item.word),
        isNot(contains('spoken')),
      );
      expect(
        result.vocabulary.map((item) => item.word),
        isNot(contains('years')),
      );
    },
  );

  test('analysis uses an explicit language module when supplied', () {
    final result = AnalysisService.analyzeChapter(
      'Custom',
      '#terra #skip plain',
      null,
      null,
      const _HashLanguageModule(),
    );

    expect(result.vocabulary.map((item) => item.word), ['terra']);
  });
}

DriftWordLevelRepository _wordLevelRepository(AppDatabase db) {
  return DriftWordLevelRepository(db.wordLevelDao, db.settingsDao);
}

class _HashLanguageModule implements LanguageModule {
  const _HashLanguageModule();

  @override
  String get languageCode => 'x-test';

  @override
  String get languageName => 'Test';

  @override
  RegExp get wordPattern => RegExp(r'#[A-Za-z]+');

  @override
  List<String> tokenize(String text) {
    return wordPattern
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
  }

  @override
  TokenizedText tokenizeToTokens(String text) {
    return tokenizeTextWithPattern(
      text: text,
      languageCode: languageCode,
      wordPattern: wordPattern,
      canonicalize: canonicalize,
    );
  }

  @override
  String canonicalize(String word) {
    return word.replaceFirst('#', '').toLowerCase();
  }

  @override
  bool isCommonWord(String word, {int? maxLength}) => word == 'skip';

  @override
  List<String> splitSentences(String text) => [text];

  @override
  Set<String> get subordinatingMarkers => const {};
}

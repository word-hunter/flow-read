import 'dart:io';

import 'package:flow_read/models/book.dart';
import 'package:flow_read/models/book_difficulty.dart';
import 'package:flow_read/models/chapter.dart';
import 'package:flow_read/services/analysis_service.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_book_difficulty_test_');
    await openFlowReadTestBoxes();
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test('book difficulty is based on unique study words in the whole book', () {
    final words = _studyWords(90);
    final book = _bookWithWords(words.followedBy(words.take(20)));

    final rating = AnalysisService.analyzeBookDifficulty(book);

    expect(rating.studyWordCount, 90);
    expect(rating.newWordCount, 90);
    expect(rating.learningWordCount, 0);
    expect(rating.masteredWordCount, 0);
    expect(rating.level, BookDifficultyLevel.l5);
  });

  test(
    'book difficulty compares new words with total mastered vocabulary',
    () async {
      final vocab = UserVocabularyService();
      await vocab.init();

      for (final word in _knownWords(7000)) {
        await vocab.setKnown(word);
      }

      final easier = AnalysisService.analyzeBookDifficulty(
        _bookWithWords(_studyWords(500)),
        vocab,
      );
      final harder = AnalysisService.analyzeBookDifficulty(
        _bookWithWords(_studyWords(1000)),
        vocab,
      );

      expect(easier.userKnownWordCount, 7000);
      expect(easier.newWordCount, 500);
      expect(easier.level, BookDifficultyLevel.l3);
      expect(harder.userKnownWordCount, 7000);
      expect(harder.newWordCount, 1000);
      expect(harder.level, BookDifficultyLevel.l4);
      expect(harder.score, greaterThan(easier.score));
    },
  );

  test('book difficulty changes when user vocabulary changes', () async {
    final vocab = UserVocabularyService();
    await vocab.init();

    final words = _studyWords(120);
    final book = _bookWithWords(words);

    final initial = AnalysisService.analyzeBookDifficulty(book, vocab);
    expect(initial.newWordCount, 120);

    for (final word in words.take(100)) {
      await vocab.setKnown(word);
    }

    final updated = AnalysisService.analyzeBookDifficulty(book, vocab);
    expect(updated.masteredWordCount, 100);
    expect(updated.newWordCount, 20);
    expect(updated.level.index, lessThan(initial.level.index));
  });

  test(
    'learning words count as a lighter reading load than unknown words',
    () async {
      final vocab = UserVocabularyService();
      await vocab.init();
      for (final word in _knownWords(1000)) {
        await vocab.setKnown(word);
      }

      final words = _studyWords(40);
      final book = _bookWithWords(words);
      for (final word in words.take(20)) {
        await vocab.setLearning(word);
      }

      final rating = AnalysisService.analyzeBookDifficulty(book, vocab);

      expect(rating.learningWordCount, 20);
      expect(rating.newWordCount, 20);
      expect(rating.weightedNewWordCount, 30);
      expect(rating.userKnownWordCount, 1000);
      expect(rating.level, BookDifficultyLevel.l2);
    },
  );

  test('book difficulty rating survives JSON round trip', () {
    const rating = BookDifficultyRating(
      studyWordCount: 12,
      masteredWordCount: 3,
      userKnownWordCount: 100,
      learningWordCount: 4,
      newWordCount: 5,
      weightedNewWordCount: 7,
      newWordToKnownRatio: 0.07,
      score: 28,
      level: BookDifficultyLevel.l3,
    );

    final restored = BookDifficultyRating.fromJson(rating.toJson());

    expect(restored.level, BookDifficultyLevel.l3);
    expect(restored.studyWordCount, 12);
    expect(restored.weightedNewWordCount, 7);
    expect(restored.newWordToKnownRatio, 0.07);
  });
}

Book _bookWithWords(Iterable<String> words) {
  return Book(
    title: 'Fixture',
    author: 'FlowRead',
    chapters: [
      Chapter(
        title: 'One',
        plainText: words.join(' '),
        rawHtml: '<p>${words.join(' ')}</p>',
      ),
    ],
  );
}

List<String> _studyWords(int count) {
  return List.generate(count, (index) => 'xeno${_letters(index)}');
}

List<String> _knownWords(int count) {
  return List.generate(count, (index) => 'known${_letters(index)}');
}

String _letters(int value) {
  const alphabet = 'abcdefghijklmnopqrstuvwxyz';
  var index = value;
  final buffer = StringBuffer();
  do {
    buffer.write(alphabet[index % alphabet.length]);
    index = index ~/ alphabet.length;
  } while (index > 0);
  return buffer.toString();
}

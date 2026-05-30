import 'package:flow_read/models/analysis_result.dart';
import 'package:flow_read/models/book.dart';
import 'package:flow_read/models/chapter.dart';
import 'package:flow_read/models/learning_analytics.dart';
import 'package:flow_read/models/learning_item.dart';
import 'package:flow_read/services/learning_analytics_service.dart';
import 'package:flow_read/services/reading_time_service.dart';
import 'package:flow_read/storage/repositories/learning_analytics_repository.dart';
import 'package:flow_read/storage/repositories/reading_time_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'builds a chapter report with lookup dependency and next step',
    () async {
      final analytics = LearningAnalyticsService(
        repository: _MemoryLearningAnalyticsRepository(),
        clock: () => DateTime(2026, 5, 20, 9),
      );
      await analytics.init();

      for (final word in ['one', 'two', 'three', 'four']) {
        await analytics.recordLookup(
          bookId: 'book-1',
          chapterIndex: 0,
          word: word,
        );
      }
      await analytics.recordLookup(
        bookId: 'book-1',
        chapterIndex: 1,
        word: 'flow',
      );
      await analytics.recordLookup(
        bookId: 'book-1',
        chapterIndex: 1,
        word: 'flow',
      );
      await analytics.recordPracticeAnswer(
        bookId: 'book-1',
        chapterIndex: 1,
        isCorrect: true,
      );
      await analytics.recordPracticeAnswer(
        bookId: 'book-1',
        chapterIndex: 1,
        isCorrect: false,
      );

      final report = analytics.buildChapterReport(
        bookId: 'book-1',
        book: _book,
        chapterIndex: 1,
        chapterProgress: 1,
        analysis: _analysis,
        readingTime: null,
        userVocabulary: null,
        learningItems: [_item(chapterIndex: 1)],
        dueReviewCount: 0,
      );

      expect(report.wordCount, 120);
      expect(report.lookupCount, 2);
      expect(report.repeatedLookupCount, 1);
      expect(
        report.lookupDependency.direction,
        LookupDependencyDirection.lower,
      );
      expect(report.masteredWordCount, 2);
      expect(report.learningWordCount, 1);
      expect(report.learningItemCount, 1);
      expect(report.practiceAnsweredCount, 2);
      expect(report.practiceCorrectCount, 1);
      expect(report.practiceAccuracyPercent, 50);
      expect(report.nextStep, contains('复盘本章 1 个学习卡片'));
    },
  );

  test('diagnoses chapter weak points from lookup and practice data', () async {
    final analytics = LearningAnalyticsService(
      repository: _MemoryLearningAnalyticsRepository(),
      clock: () => DateTime(2026, 5, 20, 9),
    );
    await analytics.init();

    await analytics.recordLookup(
      bookId: 'book-1',
      chapterIndex: 0,
      word: 'simple',
    );
    for (final word in ['current', 'current', 'current', 'syntax', 'clue']) {
      await analytics.recordLookup(
        bookId: 'book-1',
        chapterIndex: 1,
        word: word,
      );
    }
    for (final isCorrect in [true, false, false]) {
      await analytics.recordPracticeAnswer(
        bookId: 'book-1',
        chapterIndex: 1,
        isCorrect: isCorrect,
      );
    }

    final report = analytics.buildChapterReport(
      bookId: 'book-1',
      book: _book,
      chapterIndex: 1,
      chapterProgress: 1,
      analysis: _analysis,
      readingTime: null,
      userVocabulary: null,
      learningItems: const [],
      dueReviewCount: 0,
    );

    expect(report.weakPoints.map((point) => point.type), [
      ChapterWeakPointType.lowPracticeAccuracy,
      ChapterWeakPointType.highLookupDependency,
      ChapterWeakPointType.repeatedLookups,
    ]);
    expect(report.weakPoints[2].detail, contains('current'));
    expect(report.nextStep, contains('回看本章练习错题'));
  });

  test('builds weekly reading, lookup, and review summary', () async {
    var now = DateTime(2026, 5, 18, 8);
    final analytics = LearningAnalyticsService(
      repository: _MemoryLearningAnalyticsRepository(),
      clock: () => now,
    );
    await analytics.init();
    final readingTime = ReadingTimeService(
      repository: _MemoryReadingTimeRepository(),
      clock: () => now,
    );
    await readingTime.init();

    readingTime.start('book-1', 0);
    now = now.add(const Duration(minutes: 30));
    await readingTime.stop();

    await analytics.recordLookup(
      bookId: 'book-1',
      chapterIndex: 0,
      word: 'flow',
      at: now,
    );
    await analytics.recordLookup(
      bookId: 'book-1',
      chapterIndex: 0,
      word: 'flow',
      at: now,
    );
    await analytics.recordLookup(
      bookId: 'book-1',
      chapterIndex: 0,
      word: 'river',
      at: now,
    );

    final reviewedAt = DateTime(2026, 5, 19, 9);
    final summary = analytics.buildWeeklySummary(
      readingTime: readingTime,
      dailyGoalSeconds: 10 * 60,
      learningItems: [
        _item(
          id: 'remembered',
          updatedAt: reviewedAt,
          lastResult: LearningReviewResult.remembered,
          reviewCount: 1,
        ),
        _item(
          id: 'missed',
          updatedAt: reviewedAt,
          lastResult: LearningReviewResult.missed,
        ),
      ],
      dueReviewCount: 2,
      now: reviewedAt,
    );

    expect(summary.readingSeconds, 30 * 60);
    expect(summary.goalReachedDays, 1);
    expect(summary.goalProgressPercent, 50);
    expect(summary.lookupCount, 3);
    expect(summary.repeatedLookupCount, 1);
    expect(summary.reviewedCount, 2);
    expect(summary.rememberedCount, 1);
    expect(summary.missedCount, 1);
    expect(summary.dueReviewCount, 2);
  });
}

final _book = Book(
  title: 'Learning Book',
  author: 'Tester',
  chapters: [
    Chapter(title: 'One', plainText: _words(120), rawHtml: ''),
    Chapter(title: 'Two', plainText: _words(120), rawHtml: ''),
  ],
);

const _analysis = AnalysisResult(
  passageText: '',
  title: 'Two',
  vocabulary: [
    Vocabulary(word: 'river', meaning: '', context: '', familiarity: 0.2),
  ],
  knownWords: {'flow', 'steady'},
  learningWords: {'current'},
  syntaxPatterns: [],
  comprehension: Comprehension(
    whatHappened: '',
    whyHappened: '',
    implicitMeaning: '',
  ),
  practice: [],
  difficulty: Difficulty(vocab: 1, syntax: 1, inference: 1, explanation: ''),
);

String _words(int count) {
  return List.filled(count, 'flow').join(' ');
}

LearningItem _item({
  String id = 'item-1',
  int chapterIndex = 0,
  DateTime? updatedAt,
  LearningReviewResult lastResult = LearningReviewResult.newItem,
  int reviewCount = 0,
}) {
  final createdAt = DateTime(2026, 5, 18, 8);
  return LearningItem(
    id: id,
    type: LearningItemType.word,
    canonicalKey: id,
    title: id,
    content: id,
    answer: 'meaning',
    note: '',
    sourceText: 'source',
    bookId: 'book-1',
    chapterIndex: chapterIndex,
    chapterTitle: 'Chapter',
    createdAt: createdAt,
    updatedAt: updatedAt ?? createdAt,
    reviewCount: reviewCount,
    lastResult: lastResult,
  );
}

class _MemoryLearningAnalyticsRepository
    implements LearningAnalyticsRepository {
  final Map<String, int> _counts = {};

  @override
  Future<void> init() async {}

  @override
  int countFor(String key) => _counts[key] ?? 0;

  @override
  Iterable<String> get keys => _counts.keys;

  @override
  Future<void> putCount(String key, int count) async {
    _counts[key] = count;
  }

  @override
  Future<void> close() async {}
}

class _MemoryReadingTimeRepository implements ReadingTimeRepository {
  final Map<String, int> _seconds = {};

  @override
  Future<void> init() async {}

  @override
  int secondsFor(String key) => _seconds[key] ?? 0;

  @override
  Future<void> putSeconds(String key, int seconds) async {
    _seconds[key] = seconds;
  }

  @override
  Future<void> close() async {}
}

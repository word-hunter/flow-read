import '../models/analysis_result.dart';
import '../models/book.dart';
import '../models/learning_analytics.dart';
import '../models/learning_item.dart';
import '../storage/repositories/learning_analytics_repository.dart';
import 'english_word_utils.dart';
import 'reading_time_service.dart';
import 'user_vocabulary_service.dart';

class LearningAnalyticsService {
  LearningAnalyticsService({
    LearningAnalyticsRepository? repository,
    DateTime Function()? clock,
  }) : _repository = repository ?? HiveLearningAnalyticsRepository(),
       _clock = clock ?? DateTime.now;

  static const _lookupChapterPrefix = 'lookup.chapter';
  static const _lookupChapterWordPrefix = 'lookup.chapter_word';
  static const _lookupDayPrefix = 'lookup.day';
  static const _lookupDayWordPrefix = 'lookup.day_word';

  final LearningAnalyticsRepository _repository;
  final DateTime Function() _clock;

  Future<void> init() async {
    await _repository.init();
  }

  Future<void> recordLookup({
    required String bookId,
    required int chapterIndex,
    required String word,
    DateTime? at,
  }) async {
    final normalizedBookId = bookId.trim();
    final normalizedWord = _canonicalWord(word);
    if (normalizedBookId.isEmpty ||
        chapterIndex < 0 ||
        normalizedWord.isEmpty) {
      return;
    }

    final day = _dateKey(at ?? _clock());
    await _increment(_chapterLookupKey(normalizedBookId, chapterIndex));
    await _increment(
      _chapterWordLookupKey(normalizedBookId, chapterIndex, normalizedWord),
    );
    await _increment(_dayLookupKey(day));
    await _increment(_dayWordLookupKey(day, normalizedWord));
  }

  int lookupCountForChapter(String bookId, int chapterIndex) {
    return _repository.countFor(_chapterLookupKey(bookId, chapterIndex));
  }

  int repeatedLookupCountForChapter(String bookId, int chapterIndex) {
    final prefix = _chapterWordPrefixFor(bookId, chapterIndex);
    return _repository.keys
        .where((key) => key.startsWith(prefix))
        .map(_repository.countFor)
        .fold<int>(0, (sum, count) => sum + (count > 1 ? count - 1 : 0));
  }

  ChapterLearningReport buildChapterReport({
    required String bookId,
    required Book book,
    required int chapterIndex,
    required double chapterProgress,
    required AnalysisResult? analysis,
    required ReadingTimeService? readingTime,
    required UserVocabularyService? userVocabulary,
    required List<LearningItem> learningItems,
    required int dueReviewCount,
  }) {
    final safeChapterIndex = chapterIndex
        .clamp(0, book.chapters.length - 1)
        .toInt();
    final chapter = book.chapters[safeChapterIndex];
    final wordCount = _wordCount(chapter.plainText);
    final lookupCount = lookupCountForChapter(bookId, safeChapterIndex);
    final repeatedLookupCount = repeatedLookupCountForChapter(
      bookId,
      safeChapterIndex,
    );
    final lookupPerThousand = _perThousand(lookupCount, wordCount);
    final comparison = _buildLookupComparison(
      book: book,
      bookId: bookId,
      chapterIndex: safeChapterIndex,
      currentLookupCount: lookupCount,
      currentPerThousand: lookupPerThousand,
    );
    final chapterItems = learningItems
        .where(
          (item) =>
              item.bookId == bookId && item.chapterIndex == safeChapterIndex,
        )
        .toList(growable: false);
    final knownWords = _sortedPreview(analysis?.knownWords ?? const {});
    final learningWords = _sortedPreview(analysis?.learningWords ?? const {});
    final newWordCount = _newWordCount(analysis, userVocabulary);
    var readingSeconds =
        readingTime?.secondsForChapter(bookId, safeChapterIndex) ?? 0;
    if (readingSeconds == 0 && book.chapters.length == 1) {
      readingSeconds = readingTime?.secondsForBook(bookId) ?? 0;
    }

    final report = ChapterLearningReport(
      chapterTitle: chapter.title.trim().isEmpty
          ? '第 ${safeChapterIndex + 1} 章'
          : chapter.title.trim(),
      chapterIndex: safeChapterIndex,
      chapterCount: book.chapters.length,
      chapterProgress: chapterProgress.clamp(0.0, 1.0).toDouble(),
      wordCount: wordCount,
      readingTimeSeconds: readingSeconds,
      lookupCount: lookupCount,
      repeatedLookupCount: repeatedLookupCount,
      lookupPerThousandWords: lookupPerThousand,
      lookupDependency: comparison,
      masteredWordCount: analysis?.knownWords.length ?? 0,
      learningWordCount: analysis?.learningWords.length ?? 0,
      newWordCount: newWordCount,
      learningItemCount: chapterItems.length,
      dueReviewCount: dueReviewCount,
      masteredWords: knownWords,
      learningWords: learningWords,
      nextStep: '',
    );

    return ChapterLearningReport(
      chapterTitle: report.chapterTitle,
      chapterIndex: report.chapterIndex,
      chapterCount: report.chapterCount,
      chapterProgress: report.chapterProgress,
      wordCount: report.wordCount,
      readingTimeSeconds: report.readingTimeSeconds,
      lookupCount: report.lookupCount,
      repeatedLookupCount: report.repeatedLookupCount,
      lookupPerThousandWords: report.lookupPerThousandWords,
      lookupDependency: report.lookupDependency,
      masteredWordCount: report.masteredWordCount,
      learningWordCount: report.learningWordCount,
      newWordCount: report.newWordCount,
      learningItemCount: report.learningItemCount,
      dueReviewCount: report.dueReviewCount,
      masteredWords: report.masteredWords,
      learningWords: report.learningWords,
      nextStep: _nextStep(report),
    );
  }

  WeeklyLearningSummary buildWeeklySummary({
    required ReadingTimeService? readingTime,
    required int dailyGoalSeconds,
    required List<LearningItem> learningItems,
    required int dueReviewCount,
    DateTime? now,
  }) {
    final target = now ?? _clock();
    final weekStart = ReadingTimeService.weekStartFor(target);
    final weekEnd = weekStart.add(const Duration(days: 7));
    final reviewedItems = learningItems
        .where((item) {
          return item.updatedAt.isAtSameMomentAs(weekStart) ||
              (item.updatedAt.isAfter(weekStart) &&
                  item.updatedAt.isBefore(weekEnd));
        })
        .where((item) => item.lastResult != LearningReviewResult.newItem);
    final reviewed = reviewedItems.toList(growable: false);
    final remembered = reviewed
        .where((item) => item.lastResult == LearningReviewResult.remembered)
        .length;
    final missed = reviewed
        .where((item) => item.lastResult == LearningReviewResult.missed)
        .length;
    final weeklyGoalSeconds = dailyGoalSeconds <= 0 ? 0 : dailyGoalSeconds * 6;

    return WeeklyLearningSummary(
      weekStart: weekStart,
      weekEndExclusive: weekEnd,
      readingSeconds: readingTime?.secondsForWeek(target) ?? 0,
      dailyGoalSeconds: dailyGoalSeconds,
      weeklyGoalSeconds: weeklyGoalSeconds,
      goalReachedDays:
          readingTime?.goalReachedDaysForWeek(dailyGoalSeconds, target) ?? 0,
      lookupCount: _lookupCountForWeek(weekStart),
      repeatedLookupCount: _repeatedLookupCountForWeek(weekStart),
      reviewedCount: reviewed.length,
      rememberedCount: remembered,
      missedCount: missed,
      dueReviewCount: dueReviewCount,
      learningItemCount: learningItems.length,
    );
  }

  Future<void> _increment(String key) async {
    await _repository.putCount(key, _repository.countFor(key) + 1);
  }

  LookupDependencyComparison _buildLookupComparison({
    required Book book,
    required String bookId,
    required int chapterIndex,
    required int currentLookupCount,
    required double currentPerThousand,
  }) {
    if (chapterIndex <= 0) {
      return LookupDependencyComparison(
        currentLookupCount: currentLookupCount,
        previousLookupCount: 0,
        currentPerThousandWords: currentPerThousand,
        previousPerThousandWords: 0,
        direction: LookupDependencyDirection.noData,
      );
    }

    final previousIndex = chapterIndex - 1;
    final previousLookupCount = lookupCountForChapter(bookId, previousIndex);
    final previousPerThousand = _perThousand(
      previousLookupCount,
      _wordCount(book.chapters[previousIndex].plainText),
    );

    var direction = LookupDependencyDirection.steady;
    if (previousLookupCount == 0 && currentLookupCount == 0) {
      direction = LookupDependencyDirection.noData;
    } else if (currentPerThousand < previousPerThousand - 0.5) {
      direction = LookupDependencyDirection.lower;
    } else if (currentPerThousand > previousPerThousand + 0.5) {
      direction = LookupDependencyDirection.higher;
    }

    return LookupDependencyComparison(
      currentLookupCount: currentLookupCount,
      previousLookupCount: previousLookupCount,
      currentPerThousandWords: currentPerThousand,
      previousPerThousandWords: previousPerThousand,
      direction: direction,
    );
  }

  String _nextStep(ChapterLearningReport report) {
    if (report.chapterProgress < 0.95) {
      final remain = ((1 - report.chapterProgress) * 100).round();
      return '先读完本章剩余约 $remain%，再做复盘。';
    }
    if (report.dueReviewCount > 0) {
      return '先完成 ${report.dueReviewCount} 条到期复习，再进入下一章。';
    }
    if (report.lookupDependency.direction == LookupDependencyDirection.higher &&
        report.lookupCount >= 3) {
      return '下一章先读完整段并猜词，再查影响理解的关键词。';
    }
    if (report.newWordCount >= 12) {
      return '从本章新词里挑 3-5 个高频词加入学习卡片。';
    }
    if (report.learningItemCount > 0) {
      return '复盘本章 ${report.learningItemCount} 个学习卡片，确认能离开释义回忆原句。';
    }
    if (report.chapterIndex + 1 < report.chapterCount) {
      return '进入下一章前，快速回忆本章事件和已掌握词。';
    }
    return '本书已到最后一章，适合做一次整书复盘。';
  }

  int _lookupCountForWeek(DateTime weekStart) {
    var total = 0;
    for (var i = 0; i < 7; i += 1) {
      total += _repository.countFor(
        _dayLookupKey(_dateKey(weekStart.add(Duration(days: i)))),
      );
    }
    return total;
  }

  int _repeatedLookupCountForWeek(DateTime weekStart) {
    var total = 0;
    for (var i = 0; i < 7; i += 1) {
      final prefix = _dayWordPrefixFor(
        _dateKey(weekStart.add(Duration(days: i))),
      );
      total += _repository.keys
          .where((key) => key.startsWith(prefix))
          .map(_repository.countFor)
          .fold<int>(0, (sum, count) => sum + (count > 1 ? count - 1 : 0));
    }
    return total;
  }

  int _wordCount(String text) => englishWordPattern.allMatches(text).length;

  double _perThousand(int count, int wordCount) {
    if (count <= 0 || wordCount <= 0) return 0;
    return count / wordCount * 1000;
  }

  int _newWordCount(
    AnalysisResult? analysis,
    UserVocabularyService? userVocabulary,
  ) {
    if (analysis == null) return 0;
    return analysis.vocabulary.where((word) {
      return userVocabulary?.getStatus(word.word) == null;
    }).length;
  }

  List<String> _sortedPreview(Set<String> words) {
    final sorted = words.toList()..sort();
    return sorted.take(4).toList(growable: false);
  }

  String _canonicalWord(String word) {
    return normalizeEnglishApostrophes(word).toLowerCase().trim();
  }

  String _dateKey(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  String _escape(String value) => Uri.encodeComponent(value);

  String _chapterLookupKey(String bookId, int chapterIndex) {
    return '$_lookupChapterPrefix.${_escape(bookId)}.$chapterIndex';
  }

  String _chapterWordLookupKey(String bookId, int chapterIndex, String word) {
    return '${_chapterWordPrefixFor(bookId, chapterIndex)}${_escape(word)}';
  }

  String _chapterWordPrefixFor(String bookId, int chapterIndex) {
    return '$_lookupChapterWordPrefix.${_escape(bookId)}.$chapterIndex.';
  }

  String _dayLookupKey(String day) => '$_lookupDayPrefix.$day';

  String _dayWordLookupKey(String day, String word) {
    return '${_dayWordPrefixFor(day)}${_escape(word)}';
  }

  String _dayWordPrefixFor(String day) => '$_lookupDayWordPrefix.$day.';
}

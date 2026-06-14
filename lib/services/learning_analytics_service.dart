import 'package:flow_language/flow_language.dart';

import '../models/analysis_result.dart';
import '../models/book.dart';
import '../models/learning_analytics.dart';
import '../models/learning_item.dart';
import '../storage/repositories/learning_analytics_repository.dart';
import 'reading_time_service.dart';
import 'user_vocabulary_service.dart';

class LearningAnalyticsService {
  LearningAnalyticsService({
    required LearningAnalyticsRepository repository,
    required LanguageModule languageModule,
    DateTime Function()? clock,
  }) : _repository = repository,
       _languageModule = languageModule,
       _clock = clock ?? DateTime.now;

  static const _lookupChapterPrefix = 'lookup.chapter';
  static const _lookupChapterWordPrefix = 'lookup.chapter_word';
  static const _lookupDayPrefix = 'lookup.day';
  static const _lookupDayWordPrefix = 'lookup.day_word';
  static const _practiceChapterAnsweredPrefix = 'practice.chapter_answered';
  static const _practiceChapterCorrectPrefix = 'practice.chapter_correct';

  final LearningAnalyticsRepository _repository;
  final LanguageModule _languageModule;
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

  List<String> lookedUpWordsForChapter(String bookId, int chapterIndex) {
    final prefix = _chapterWordPrefixFor(bookId, chapterIndex);
    return _repository.keys
        .where((key) => key.startsWith(prefix))
        .map((key) => Uri.decodeComponent(key.substring(prefix.length)))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  Future<void> recordPracticeAnswer({
    required String bookId,
    required int chapterIndex,
    required bool isCorrect,
  }) async {
    final normalizedBookId = bookId.trim();
    if (normalizedBookId.isEmpty || chapterIndex < 0) return;

    await _increment(
      _chapterPracticeAnsweredKey(normalizedBookId, chapterIndex),
    );
    if (isCorrect) {
      await _increment(
        _chapterPracticeCorrectKey(normalizedBookId, chapterIndex),
      );
    }
  }

  int practiceAnsweredCountForChapter(String bookId, int chapterIndex) {
    return _repository.countFor(
      _chapterPracticeAnsweredKey(bookId, chapterIndex),
    );
  }

  int practiceCorrectCountForChapter(String bookId, int chapterIndex) {
    return _repository.countFor(
      _chapterPracticeCorrectKey(bookId, chapterIndex),
    );
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
    final practiceAnsweredCount = practiceAnsweredCountForChapter(
      bookId,
      safeChapterIndex,
    );
    final practiceCorrectCount = practiceCorrectCountForChapter(
      bookId,
      safeChapterIndex,
    );
    final repeatedLookupWords = _repeatedLookupWordPreviews(
      bookId,
      safeChapterIndex,
    );
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
      practiceAnsweredCount: practiceAnsweredCount,
      practiceCorrectCount: practiceCorrectCount,
      weakPoints: const [],
      nextActions: const [],
      masteredWords: knownWords,
      learningWords: learningWords,
      nextStep: '',
    );

    final nextActions = _nextActions(report);
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
      practiceAnsweredCount: report.practiceAnsweredCount,
      practiceCorrectCount: report.practiceCorrectCount,
      weakPoints: _weakPoints(report, repeatedLookupWords),
      nextActions: nextActions,
      masteredWords: report.masteredWords,
      learningWords: report.learningWords,
      nextStep: _nextStep(nextActions),
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
    final readingSeconds = readingTime?.secondsForWeek(target) ?? 0;
    final previousWeekStart = weekStart.subtract(const Duration(days: 7));
    final previousReadingSeconds =
        readingTime?.secondsForWeek(previousWeekStart) ?? 0;
    final lookupCount = _lookupCountForWeek(weekStart);
    final repeatedLookupCount = _repeatedLookupCountForWeek(weekStart);

    return WeeklyLearningSummary(
      weekStart: weekStart,
      weekEndExclusive: weekEnd,
      readingSeconds: readingSeconds,
      dailyGoalSeconds: dailyGoalSeconds,
      weeklyGoalSeconds: weeklyGoalSeconds,
      goalReachedDays:
          readingTime?.goalReachedDaysForWeek(dailyGoalSeconds, target) ?? 0,
      lookupCount: lookupCount,
      repeatedLookupCount: repeatedLookupCount,
      reviewedCount: reviewed.length,
      rememberedCount: remembered,
      missedCount: missed,
      dueReviewCount: dueReviewCount,
      learningItemCount: learningItems.length,
      progressSummary: _weeklyProgressSummary(
        readingSeconds: readingSeconds,
        previousReadingSeconds: previousReadingSeconds,
      ),
      weakPointSummary: _weeklyWeakPointSummary(
        lookupCount: lookupCount,
        repeatedLookupCount: repeatedLookupCount,
        rememberedCount: remembered,
        missedCount: missed,
        dueReviewCount: dueReviewCount,
      ),
      nextStep: _weeklyNextStep(
        readingSeconds: readingSeconds,
        weeklyGoalSeconds: weeklyGoalSeconds,
        dueReviewCount: dueReviewCount,
        missedCount: missed,
        repeatedLookupCount: repeatedLookupCount,
        lookupCount: lookupCount,
      ),
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

  List<ChapterNextAction> _nextActions(ChapterLearningReport report) {
    final actions = <ChapterNextAction>[];
    if (report.chapterProgress < 0.95) {
      final remain = ((1 - report.chapterProgress) * 100).round();
      actions.add(
        ChapterNextAction(
          type: ChapterNextActionType.finishChapter,
          title: '读完本章',
          detail: '先读完本章剩余约 $remain%，再做复盘。',
          priority: 10,
        ),
      );
    }
    if (report.dueReviewCount > 0) {
      actions.add(
        ChapterNextAction(
          type: ChapterNextActionType.reviewDueItems,
          title: '完成到期复习',
          detail: '先完成 ${report.dueReviewCount} 条到期复习，再进入下一章。',
          priority: 20,
        ),
      );
    }
    if (report.practiceAnsweredCount >= 3 && report.practiceAccuracy < 0.7) {
      actions.add(
        ChapterNextAction(
          type: ChapterNextActionType.reviewPracticeMistakes,
          title: '回看练习错题',
          detail: '回看本章练习错题，先用原文依据修正理解再继续读。',
          priority: 30,
        ),
      );
    }
    if (report.lookupDependency.direction == LookupDependencyDirection.higher &&
        report.lookupCount >= 3) {
      actions.add(
        ChapterNextAction(
          type: ChapterNextActionType.reduceLookupDependency,
          title: '降低查词依赖',
          detail: '下一章先读完整段并猜词，再查影响理解的关键词。',
          priority: 40,
        ),
      );
    }
    if (report.newWordCount >= 12) {
      actions.add(
        ChapterNextAction(
          type: ChapterNextActionType.createVocabularyCards,
          title: '精选新词',
          detail: '从本章新词里挑 3-5 个高频词加入学习卡片。',
          priority: 50,
        ),
      );
    }
    if (report.learningItemCount > 0) {
      actions.add(
        ChapterNextAction(
          type: ChapterNextActionType.reviewLearningCards,
          title: '复盘学习卡片',
          detail: '复盘本章 ${report.learningItemCount} 个学习卡片，确认能离开释义回忆原句。',
          priority: 60,
        ),
      );
    }

    actions.add(
      report.chapterIndex + 1 < report.chapterCount
          ? const ChapterNextAction(
              type: ChapterNextActionType.continueReading,
              title: '继续阅读',
              detail: '进入下一章前，快速回忆本章事件和已掌握词。',
              priority: 90,
            )
          : const ChapterNextAction(
              type: ChapterNextActionType.wholeBookReview,
              title: '整书复盘',
              detail: '本书已到最后一章，适合做一次整书复盘。',
              priority: 90,
            ),
    );

    actions.sort((a, b) => a.priority.compareTo(b.priority));
    return actions;
  }

  String _nextStep(List<ChapterNextAction> actions) {
    if (actions.isEmpty) return '';
    return actions.first.detail;
  }

  List<ChapterWeakPoint> _weakPoints(
    ChapterLearningReport report,
    List<String> repeatedLookupWords,
  ) {
    final points = <ChapterWeakPoint>[];
    if (report.chapterProgress < 0.95) {
      final remain = ((1 - report.chapterProgress) * 100).round();
      points.add(
        ChapterWeakPoint(
          type: ChapterWeakPointType.incompleteReading,
          title: '本章还没读完',
          detail: '剩余约 $remain%，先读完再判断本章真实卡点。',
          priority: 10,
        ),
      );
    }
    if (report.dueReviewCount > 0) {
      points.add(
        ChapterWeakPoint(
          type: ChapterWeakPointType.reviewBacklog,
          title: '复习积压',
          detail: '当前有 ${report.dueReviewCount} 条到期复习，可能影响后续章节理解。',
          priority: 20,
        ),
      );
    }
    if (report.practiceAnsweredCount >= 3 && report.practiceAccuracy < 0.7) {
      points.add(
        ChapterWeakPoint(
          type: ChapterWeakPointType.lowPracticeAccuracy,
          title: '练习正确率偏低',
          detail: '本章练习正确率 ${report.practiceAccuracyPercent}%，优先回看错题对应原文。',
          priority: 30,
        ),
      );
    }
    if (report.lookupDependency.direction == LookupDependencyDirection.higher &&
        report.lookupCount >= 3) {
      points.add(
        ChapterWeakPoint(
          type: ChapterWeakPointType.highLookupDependency,
          title: '查词依赖上升',
          detail:
              '本章 ${report.lookupPerThousandWords.toStringAsFixed(1)} 次/千词，高于上一章。',
          priority: 40,
        ),
      );
    }
    if (report.repeatedLookupCount >= 2) {
      final examples = repeatedLookupWords.take(3).join('、');
      points.add(
        ChapterWeakPoint(
          type: ChapterWeakPointType.repeatedLookups,
          title: '重复查词较多',
          detail: examples.isEmpty
              ? '本章有 ${report.repeatedLookupCount} 次重复查词，适合转成学习卡片。'
              : '反复查询 $examples，适合转成学习卡片。',
          priority: 50,
        ),
      );
    }
    if (report.newWordCount >= 12) {
      points.add(
        ChapterWeakPoint(
          type: ChapterWeakPointType.vocabularyLoad,
          title: '新词负荷偏高',
          detail: '本章有 ${report.newWordCount} 个新词，先挑 3-5 个高频词学习。',
          priority: 60,
        ),
      );
    }

    points.sort((a, b) => a.priority.compareTo(b.priority));
    return points;
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

  String _weeklyProgressSummary({
    required int readingSeconds,
    required int previousReadingSeconds,
  }) {
    if (readingSeconds <= 0) {
      return '本周还没有阅读记录，先安排一次 15 分钟阅读。';
    }
    final current = _durationPhrase(readingSeconds);
    final delta = readingSeconds - previousReadingSeconds;
    if (previousReadingSeconds <= 0) {
      return '本周已阅读 $current，开始形成本周节奏。';
    }
    if (delta >= 10 * 60) {
      return '本周已阅读 $current，比上周多 ${_durationPhrase(delta)}。';
    }
    if (delta <= -10 * 60) {
      return '本周已阅读 $current，比上周少 ${_durationPhrase(delta.abs())}。';
    }
    return '本周已阅读 $current，和上周接近。';
  }

  String _weeklyWeakPointSummary({
    required int lookupCount,
    required int repeatedLookupCount,
    required int rememberedCount,
    required int missedCount,
    required int dueReviewCount,
  }) {
    if (missedCount > rememberedCount && missedCount > 0) {
      return '本周需回看的复习多于已记住内容，优先处理错题和遗忘卡片。';
    }
    if (repeatedLookupCount >= 3) {
      return '本周重复查词 $repeatedLookupCount 次，说明部分词还没有进入可回忆状态。';
    }
    if (lookupCount >= 10) {
      return '本周查词 $lookupCount 次，阅读阻力主要来自词汇密度。';
    }
    if (dueReviewCount > 0) {
      return '当前还有 $dueReviewCount 条待复习，先清理积压可以降低后续阅读阻力。';
    }
    return '本周没有明显薄弱点，继续保持阅读和复习节奏。';
  }

  String _weeklyNextStep({
    required int readingSeconds,
    required int weeklyGoalSeconds,
    required int dueReviewCount,
    required int missedCount,
    required int repeatedLookupCount,
    required int lookupCount,
  }) {
    if (dueReviewCount > 0) {
      return '先完成 $dueReviewCount 条到期复习，再安排下一次阅读。';
    }
    if (missedCount > 0) {
      return '回看本周 $missedCount 条未记住内容，补上原文依据。';
    }
    if (weeklyGoalSeconds > 0 && readingSeconds < weeklyGoalSeconds) {
      return '补一次 15-20 分钟阅读，把本周阅读目标推进到 100%。';
    }
    if (repeatedLookupCount > 0) {
      return '把本周重复查过的词挑 3 个转成学习卡片。';
    }
    if (lookupCount > 0) {
      return '从本周查词里挑最影响理解的词，做一次轻量复盘。';
    }
    return '继续下一章，保持阅读节奏。';
  }

  String _durationPhrase(int seconds) {
    if (seconds < 60) return '$seconds 秒';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes 分钟';
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    return remain > 0 ? '$hours 小时 $remain 分钟' : '$hours 小时';
  }

  int _wordCount(String text) => _languageModule.wordCount(text);

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

  List<String> _repeatedLookupWordPreviews(String bookId, int chapterIndex) {
    final prefix = _chapterWordPrefixFor(bookId, chapterIndex);
    final repeated = _repository.keys
        .where((key) => key.startsWith(prefix))
        .map((key) {
          final count = _repository.countFor(key);
          final word = Uri.decodeComponent(key.substring(prefix.length));
          return _RepeatedLookupWord(word: word, repeatedCount: count - 1);
        })
        .where((item) => item.repeatedCount > 0)
        .toList();
    repeated.sort((a, b) {
      final countCompare = b.repeatedCount.compareTo(a.repeatedCount);
      if (countCompare != 0) return countCompare;
      return a.word.compareTo(b.word);
    });
    return repeated.map((item) => item.word).take(4).toList(growable: false);
  }

  String _canonicalWord(String word) {
    return _languageModule.canonicalize(word);
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

  String _chapterPracticeAnsweredKey(String bookId, int chapterIndex) {
    return '$_practiceChapterAnsweredPrefix.${_escape(bookId)}.$chapterIndex';
  }

  String _chapterPracticeCorrectKey(String bookId, int chapterIndex) {
    return '$_practiceChapterCorrectPrefix.${_escape(bookId)}.$chapterIndex';
  }

  String _dayLookupKey(String day) => '$_lookupDayPrefix.$day';

  String _dayWordLookupKey(String day, String word) {
    return '${_dayWordPrefixFor(day)}${_escape(word)}';
  }

  String _dayWordPrefixFor(String day) => '$_lookupDayWordPrefix.$day.';
}

class _RepeatedLookupWord {
  final String word;
  final int repeatedCount;

  const _RepeatedLookupWord({required this.word, required this.repeatedCount});
}

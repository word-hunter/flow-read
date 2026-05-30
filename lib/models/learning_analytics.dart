enum LookupDependencyDirection { noData, lower, steady, higher }

enum ChapterWeakPointType {
  incompleteReading,
  reviewBacklog,
  lowPracticeAccuracy,
  highLookupDependency,
  repeatedLookups,
  vocabularyLoad,
}

class ChapterWeakPoint {
  final ChapterWeakPointType type;
  final String title;
  final String detail;
  final int priority;

  const ChapterWeakPoint({
    required this.type,
    required this.title,
    required this.detail,
    required this.priority,
  });
}

class LookupDependencyComparison {
  final int currentLookupCount;
  final int previousLookupCount;
  final double currentPerThousandWords;
  final double previousPerThousandWords;
  final LookupDependencyDirection direction;

  const LookupDependencyComparison({
    required this.currentLookupCount,
    required this.previousLookupCount,
    required this.currentPerThousandWords,
    required this.previousPerThousandWords,
    required this.direction,
  });

  double get deltaPerThousandWords {
    return currentPerThousandWords - previousPerThousandWords;
  }

  int get changePercent {
    if (previousPerThousandWords <= 0) return 0;
    return (deltaPerThousandWords / previousPerThousandWords * 100).round();
  }
}

class ChapterLearningReport {
  final String chapterTitle;
  final int chapterIndex;
  final int chapterCount;
  final double chapterProgress;
  final int wordCount;
  final int readingTimeSeconds;
  final int lookupCount;
  final int repeatedLookupCount;
  final double lookupPerThousandWords;
  final LookupDependencyComparison lookupDependency;
  final int masteredWordCount;
  final int learningWordCount;
  final int newWordCount;
  final int learningItemCount;
  final int dueReviewCount;
  final int practiceAnsweredCount;
  final int practiceCorrectCount;
  final List<ChapterWeakPoint> weakPoints;
  final List<String> masteredWords;
  final List<String> learningWords;
  final String nextStep;

  const ChapterLearningReport({
    required this.chapterTitle,
    required this.chapterIndex,
    required this.chapterCount,
    required this.chapterProgress,
    required this.wordCount,
    required this.readingTimeSeconds,
    required this.lookupCount,
    required this.repeatedLookupCount,
    required this.lookupPerThousandWords,
    required this.lookupDependency,
    required this.masteredWordCount,
    required this.learningWordCount,
    required this.newWordCount,
    required this.learningItemCount,
    required this.dueReviewCount,
    required this.practiceAnsweredCount,
    required this.practiceCorrectCount,
    required this.weakPoints,
    required this.masteredWords,
    required this.learningWords,
    required this.nextStep,
  });

  double get practiceAccuracy {
    if (practiceAnsweredCount <= 0) return 0;
    return practiceCorrectCount / practiceAnsweredCount;
  }

  int get practiceAccuracyPercent => (practiceAccuracy * 100).round();
}

class WeeklyLearningSummary {
  final DateTime weekStart;
  final DateTime weekEndExclusive;
  final int readingSeconds;
  final int dailyGoalSeconds;
  final int weeklyGoalSeconds;
  final int goalReachedDays;
  final int lookupCount;
  final int repeatedLookupCount;
  final int reviewedCount;
  final int rememberedCount;
  final int missedCount;
  final int dueReviewCount;
  final int learningItemCount;

  const WeeklyLearningSummary({
    required this.weekStart,
    required this.weekEndExclusive,
    required this.readingSeconds,
    required this.dailyGoalSeconds,
    required this.weeklyGoalSeconds,
    required this.goalReachedDays,
    required this.lookupCount,
    required this.repeatedLookupCount,
    required this.reviewedCount,
    required this.rememberedCount,
    required this.missedCount,
    required this.dueReviewCount,
    required this.learningItemCount,
  });

  double get goalProgress {
    if (weeklyGoalSeconds <= 0) return 0;
    return (readingSeconds / weeklyGoalSeconds).clamp(0.0, 1.0);
  }

  int get goalProgressPercent => (goalProgress * 100).round();
}

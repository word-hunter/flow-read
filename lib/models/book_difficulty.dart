enum BookDifficultyLevel {
  l1,
  l2,
  l3,
  l4,
  l5;

  String get shortLabel {
    switch (this) {
      case BookDifficultyLevel.l1:
        return 'L1';
      case BookDifficultyLevel.l2:
        return 'L2';
      case BookDifficultyLevel.l3:
        return 'L3';
      case BookDifficultyLevel.l4:
        return 'L4';
      case BookDifficultyLevel.l5:
        return 'L5';
    }
  }

  String get label {
    switch (this) {
      case BookDifficultyLevel.l1:
        return '轻松读';
      case BookDifficultyLevel.l2:
        return '舒适挑战';
      case BookDifficultyLevel.l3:
        return '需要查词';
      case BookDifficultyLevel.l4:
        return '高强度阅读';
      case BookDifficultyLevel.l5:
        return '暂不建议硬读';
    }
  }

  String get description {
    switch (this) {
      case BookDifficultyLevel.l1:
        return '当前词汇储备基本覆盖这本书，可以把注意力放在理解和阅读速度上。';
      case BookDifficultyLevel.l2:
        return '有少量生词，适合正常阅读并顺手积累。';
      case BookDifficultyLevel.l3:
        return '生词负荷较明显，建议分章节阅读并配合复习。';
      case BookDifficultyLevel.l4:
        return '生词较多，阅读会频繁中断，建议先预习关键词。';
      case BookDifficultyLevel.l5:
        return '当前生词负荷过高，更适合作为精读或暂缓阅读。';
    }
  }

  static BookDifficultyLevel resolve({
    required double weightedNewWordCount,
    required double newWordToKnownRatio,
  }) {
    if (weightedNewWordCount <= 0) return BookDifficultyLevel.l1;
    if (newWordToKnownRatio <= 0.02) return BookDifficultyLevel.l1;
    if (newWordToKnownRatio <= 0.05) return BookDifficultyLevel.l2;
    if (newWordToKnownRatio <= 0.12) return BookDifficultyLevel.l3;
    if (newWordToKnownRatio <= 0.25) return BookDifficultyLevel.l4;
    return BookDifficultyLevel.l5;
  }
}

class BookDifficultyRating {
  final int studyWordCount;
  final int masteredWordCount;
  final int userKnownWordCount;
  final int learningWordCount;
  final int newWordCount;
  final double weightedNewWordCount;
  final double newWordToKnownRatio;
  final int score;
  final BookDifficultyLevel level;

  const BookDifficultyRating({
    required this.studyWordCount,
    required this.masteredWordCount,
    required this.userKnownWordCount,
    required this.learningWordCount,
    required this.newWordCount,
    required this.weightedNewWordCount,
    required this.newWordToKnownRatio,
    required this.score,
    required this.level,
  });

  int get activeNewWordCount => learningWordCount + newWordCount;

  String get levelText => '${level.shortLabel} ${level.label}';

  int get newWordToKnownRatioPercent => (newWordToKnownRatio * 100).round();

  String get weightedNewWordText => weightedNewWordCount % 1 == 0
      ? weightedNewWordCount.toStringAsFixed(0)
      : weightedNewWordCount.toStringAsFixed(1);

  String get tooltipText {
    return '${level.shortLabel} ${level.label}\n'
        '${level.description}\n'
        '当前生词: $activeNewWordCount 个\n'
        '未掌握: $newWordCount 个，学习中: $learningWordCount 个\n'
        '用户已掌握词汇: $userKnownWordCount 个\n'
        '本书可学习词: $studyWordCount 个，其中已掌握 $masteredWordCount 个\n'
        '生词负荷: $weightedNewWordText，相当于已掌握词汇的 $newWordToKnownRatioPercent%';
  }

  String get reasonText {
    return '当前生词 $activeNewWordCount 个：未掌握 $newWordCount 个，学习中 $learningWordCount 个；'
        '用户已掌握 $userKnownWordCount 个，生词负荷 $weightedNewWordText（$newWordToKnownRatioPercent%）。';
  }

  String get compactReasonText {
    return '生词 $activeNewWordCount 个，未掌握 $newWordCount 个，学习中 $learningWordCount 个；'
        '负荷占已掌握词 $newWordToKnownRatioPercent%。';
  }
}

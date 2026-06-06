import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book_difficulty.dart';
import '../models/learning_analytics.dart';
import '../providers/reading/bookmark_notifier.dart';
import '../providers/reading/current_book_provider.dart';
import '../providers/reading/vocabulary_provider.dart';
import '../widgets/reading_desk/donut_chart_painter.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabulary = ref.watch(vocabularyProvider);
    final bookmarks = ref.watch(bookmarkNotifierProvider);
    final currentBook = ref.watch(currentBookProvider);
    final theme = Theme.of(context);
    final allVocab = vocabulary.getAllVocabulary();
    final bookDifficulty = vocabulary.currentBookDifficulty;
    final chapterReport = vocabulary.currentChapterLearningReport;
    final weeklySummary = vocabulary.weeklyLearningSummary;

    final knownCount = vocabulary.knownWordCount;
    final learningCount = vocabulary.learningWordCount;
    final newCount = allVocab
        .where((v) => vocabulary.getWordStatus(v.word) == null)
        .length;
    final total = knownCount + learningCount + newCount;
    final donutSegments = _buildDonutSegments(
      knownCount: knownCount,
      learningCount: learningCount,
      newCount: newCount,
    );
    final centerPercent = total > 0 ? (knownCount * 100 / total).round() : 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (chapterReport != null) ...[
                      _buildChapterReportCard(context, chapterReport),
                      const SizedBox(height: 14),
                    ],
                    if (weeklySummary != null) ...[
                      _buildWeeklySummaryCard(context, weeklySummary),
                      const SizedBox(height: 14),
                    ],
                    if (bookDifficulty != null) ...[
                      _buildBookDifficultyCard(bookDifficulty, theme),
                      const SizedBox(height: 14),
                    ],
                    _buildVocabularyStructureCard(
                      context: context,
                      knownCount: knownCount,
                      learningCount: learningCount,
                      newCount: newCount,
                      total: total,
                      segments: donutSegments,
                      centerPercent: centerPercent,
                    ),
                    const SizedBox(height: 14),
                    _buildStatGrid(
                      context,
                      knownCount: knownCount,
                      totalVocabularyCount: vocabulary.totalVocabularyCount,
                      bookmarkCount: bookmarks.bookmarkedWords.length,
                      chapterCount: currentBook.chapterCount,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.insights, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '学习报告',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterReportCard(
    BuildContext context,
    ChapterLearningReport report,
  ) {
    final theme = Theme.of(context);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            icon: Icons.auto_stories_outlined,
            title: '本章学习报告',
            subtitle:
                '第 ${report.chapterIndex + 1}/${report.chapterCount} 章 · ${report.chapterTitle}',
          ),
          const SizedBox(height: 14),
          _MetricGrid(
            metrics: [
              _MetricData(
                icon: Icons.flag_outlined,
                label: '已读',
                value: '${(report.chapterProgress * 100).round()}%',
              ),
              _MetricData(
                icon: Icons.timer_outlined,
                label: '阅读',
                value: _durationText(report.readingTimeSeconds),
              ),
              _MetricData(
                icon: Icons.search_outlined,
                label: '查词',
                value: '${report.lookupCount} 次',
              ),
              _MetricData(
                icon: Icons.fact_check_outlined,
                label: '练习正确率',
                value: _practiceAccuracyValue(report),
              ),
              _MetricData(
                icon: Icons.notes_outlined,
                label: '词数',
                value: '${report.wordCount}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InsightRow(
            icon: _trendIcon(report.lookupDependency.direction),
            title: '查词依赖',
            body: _lookupDependencyText(report),
            color: _trendColor(theme, report.lookupDependency.direction),
          ),
          if (report.weakPoints.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InsightRow(
              icon: Icons.priority_high_outlined,
              title: '主要卡点',
              body: _weakPointText(report),
              color: _weakPointColor(theme, report),
            ),
          ],
          const SizedBox(height: 10),
          _InsightRow(
            icon: Icons.school_outlined,
            title: '掌握了什么',
            body: _masteryText(report),
            color: theme.colorScheme.primary,
          ),
          if (report.practiceAnsweredCount > 0) ...[
            const SizedBox(height: 10),
            _InsightRow(
              icon: Icons.quiz_outlined,
              title: '练习表现',
              body: _practiceAccuracyText(report),
              color: _practiceAccuracyColor(theme, report),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _nextActionText(report),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummaryCard(
    BuildContext context,
    WeeklyLearningSummary summary,
  ) {
    final theme = Theme.of(context);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            icon: Icons.calendar_month_outlined,
            title: '本周阅读 / 复习',
            subtitle:
                '${summary.goalReachedDays} 天达成每日目标 · 当前 ${summary.dueReviewCount} 条待复习',
          ),
          const SizedBox(height: 14),
          _MetricGrid(
            metrics: [
              _MetricData(
                icon: Icons.schedule_outlined,
                label: '本周阅读',
                value: _durationText(summary.readingSeconds),
              ),
              _MetricData(
                icon: Icons.track_changes_outlined,
                label: '周目标',
                value: '${summary.goalProgressPercent}%',
              ),
              _MetricData(
                icon: Icons.search_outlined,
                label: '本周查词',
                value: '${summary.lookupCount} 次',
              ),
              _MetricData(
                icon: Icons.fact_check_outlined,
                label: '本周复习',
                value: '${summary.reviewedCount} 条',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InsightRow(
            icon: Icons.timeline_outlined,
            title: '本周变化',
            body: summary.progressSummary,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 10),
          _InsightRow(
            icon: Icons.report_problem_outlined,
            title: '本周薄弱点',
            body: summary.weakPointSummary,
            color: _weeklyWeakPointColor(theme, summary),
          ),
          const SizedBox(height: 10),
          _InsightRow(
            icon: Icons.arrow_forward,
            title: '下一步',
            body: summary.nextStep,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildBookDifficultyCard(
    BookDifficultyRating rating,
    ThemeData theme,
  ) {
    final color = _difficultyColor(rating.level);
    final weightedText = rating.weightedNewWordCount % 1 == 0
        ? rating.weightedNewWordCount.toStringAsFixed(0)
        : rating.weightedNewWordCount.toStringAsFixed(1);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.speed_outlined, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '书籍难度',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rating.levelText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${rating.score}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: rating.score / 100,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            rating.level.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DifficultyChip(
                icon: Icons.auto_stories_outlined,
                label: '可学习词 ${rating.studyWordCount}',
              ),
              _DifficultyChip(
                icon: Icons.help_outline,
                label: '未掌握 ${rating.newWordCount}',
              ),
              _DifficultyChip(
                icon: Icons.school_outlined,
                label: '学习中 ${rating.learningWordCount}',
              ),
              _DifficultyChip(
                icon: Icons.done_outline,
                label: '已掌握 ${rating.userKnownWordCount}',
              ),
              _DifficultyChip(
                icon: Icons.monitor_weight_outlined,
                label:
                    '负荷 $weightedText · ${rating.newWordToKnownRatioPercent}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyStructureCard({
    required BuildContext context,
    required int knownCount,
    required int learningCount,
    required int newCount,
    required int total,
    required List<DonutSegment> segments,
    required int centerPercent,
  }) {
    final theme = Theme.of(context);
    final legendItems = [
      _LegendItem(
        label: '已掌握',
        color: const Color(0xFF2979FF),
        value: total > 0 ? '${(knownCount * 100 / total).round()}%' : '0%',
      ),
      _LegendItem(
        label: '学习中',
        color: const Color(0xFF66BB6A),
        value: total > 0 ? '${(learningCount * 100 / total).round()}%' : '0%',
      ),
      _LegendItem(
        label: '新词',
        color: const Color(0xFFFFCA28),
        value: total > 0 ? '${(newCount * 100 / total).round()}%' : '0%',
      ),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            icon: Icons.donut_large_outlined,
            title: '词汇结构',
            subtitle: '按当前书籍和已沉淀词汇状态统计',
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: CustomPaint(
                    painter: DonutChartPainter(
                      segments: segments,
                      strokeWidth: 18,
                      centerValue: '$centerPercent%',
                      centerLabel: '已掌握',
                      centerValueColor: theme.colorScheme.onSurface,
                      centerLabelColor: theme.colorScheme.onSurfaceVariant,
                    ),
                    size: const Size(160, 160),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: legendItems
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: item.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Text(
                                  item.value,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(
    BuildContext context, {
    required int knownCount,
    required int totalVocabularyCount,
    required int bookmarkCount,
    required int chapterCount,
  }) {
    return _MetricGrid(
      metrics: [
        _MetricData(icon: Icons.menu_book, label: '总掌握词', value: '$knownCount'),
        _MetricData(
          icon: Icons.school,
          label: '当前词汇',
          value: '$totalVocabularyCount',
        ),
        _MetricData(
          icon: Icons.bookmark,
          label: '书签',
          value: '$bookmarkCount',
        ),
        _MetricData(
          icon: Icons.menu_book_outlined,
          label: '目录项',
          value: '$chapterCount',
        ),
      ],
    );
  }

  List<DonutSegment> _buildDonutSegments({
    required int knownCount,
    required int learningCount,
    required int newCount,
  }) {
    final segments = <DonutSegment>[];
    if (knownCount > 0) {
      segments.add(
        DonutSegment(
          label: '已掌握',
          value: knownCount.toDouble(),
          color: const Color(0xFF2979FF),
        ),
      );
    }
    if (learningCount > 0) {
      segments.add(
        DonutSegment(
          label: '学习中',
          value: learningCount.toDouble(),
          color: const Color(0xFF66BB6A),
        ),
      );
    }
    if (newCount > 0) {
      segments.add(
        DonutSegment(
          label: '新词',
          value: newCount.toDouble(),
          color: const Color(0xFFFFCA28),
        ),
      );
    }

    if (segments.isEmpty) {
      segments.add(
        const DonutSegment(label: '新词', value: 1, color: Color(0xFFFFCA28)),
      );
    }
    return segments;
  }

  String _lookupDependencyText(ChapterLearningReport report) {
    final current = report.lookupPerThousandWords.toStringAsFixed(1);
    final comparison = report.lookupDependency;
    if (comparison.direction == LookupDependencyDirection.noData) {
      return '本章 $current 次/千词；继续读下一章后可比较趋势。';
    }
    final previous = comparison.previousPerThousandWords.toStringAsFixed(1);
    if (comparison.direction == LookupDependencyDirection.lower) {
      return '本章 $current 次/千词，上一章 $previous，下降 ${comparison.changePercent.abs()}%。';
    }
    if (comparison.direction == LookupDependencyDirection.higher) {
      return '本章 $current 次/千词，上一章 $previous，上升 ${comparison.changePercent.abs()}%。';
    }
    return '本章 $current 次/千词，和上一章 $previous 接近。';
  }

  String _masteryText(ChapterLearningReport report) {
    final parts = [
      '已掌握 ${report.masteredWordCount}',
      '学习中 ${report.learningWordCount}',
      '新词 ${report.newWordCount}',
      '卡片 ${report.learningItemCount}',
    ];
    final examples = [
      ...report.masteredWords,
      ...report.learningWords,
    ].take(4).join('、');
    if (examples.isNotEmpty) {
      parts.add('可回忆：$examples');
    }
    return parts.join(' · ');
  }

  String _weakPointText(ChapterLearningReport report) {
    return report.weakPoints
        .take(3)
        .map((point) => '${point.title}：${point.detail}')
        .join('\n');
  }

  Color _weakPointColor(ThemeData theme, ChapterLearningReport report) {
    if (report.weakPoints.isEmpty) return theme.colorScheme.onSurfaceVariant;
    final first = report.weakPoints.first;
    return switch (first.type) {
      ChapterWeakPointType.incompleteReading =>
        theme.colorScheme.onSurfaceVariant,
      ChapterWeakPointType.reviewBacklog => const Color(0xFFF9A825),
      ChapterWeakPointType.lowPracticeAccuracy => const Color(0xFFC62828),
      ChapterWeakPointType.highLookupDependency => const Color(0xFFC62828),
      ChapterWeakPointType.repeatedLookups => const Color(0xFFE67E22),
      ChapterWeakPointType.vocabularyLoad => const Color(0xFFE67E22),
    };
  }

  String _practiceAccuracyValue(ChapterLearningReport report) {
    if (report.practiceAnsweredCount == 0) return '未练习';
    return '${report.practiceAccuracyPercent}%';
  }

  String _practiceAccuracyText(ChapterLearningReport report) {
    final answered = report.practiceAnsweredCount;
    final correct = report.practiceCorrectCount;
    return '已提交 $answered 题，答对 $correct 题，正确率 ${report.practiceAccuracyPercent}%。';
  }

  String _nextActionText(ChapterLearningReport report) {
    if (report.nextActions.isEmpty) return report.nextStep;
    return report.nextActions
        .take(3)
        .map((action) => '${action.title}：${action.detail}')
        .join('\n');
  }

  Color _practiceAccuracyColor(ThemeData theme, ChapterLearningReport report) {
    if (report.practiceAnsweredCount == 0) {
      return theme.colorScheme.onSurfaceVariant;
    }
    if (report.practiceAccuracy >= 0.8) return const Color(0xFF2E7D32);
    if (report.practiceAccuracy >= 0.6) return const Color(0xFFF9A825);
    return const Color(0xFFC62828);
  }

  Color _weeklyWeakPointColor(ThemeData theme, WeeklyLearningSummary summary) {
    if (summary.missedCount > summary.rememberedCount &&
        summary.missedCount > 0) {
      return const Color(0xFFC62828);
    }
    if (summary.repeatedLookupCount >= 3 || summary.lookupCount >= 10) {
      return const Color(0xFFE67E22);
    }
    if (summary.dueReviewCount > 0) return const Color(0xFFF9A825);
    return theme.colorScheme.primary;
  }

  IconData _trendIcon(LookupDependencyDirection direction) {
    return switch (direction) {
      LookupDependencyDirection.lower => Icons.trending_down,
      LookupDependencyDirection.higher => Icons.trending_up,
      LookupDependencyDirection.steady => Icons.trending_flat,
      LookupDependencyDirection.noData => Icons.query_stats,
    };
  }

  Color _trendColor(ThemeData theme, LookupDependencyDirection direction) {
    return switch (direction) {
      LookupDependencyDirection.lower => const Color(0xFF2E7D32),
      LookupDependencyDirection.higher => const Color(0xFFC62828),
      LookupDependencyDirection.steady => theme.colorScheme.primary,
      LookupDependencyDirection.noData => theme.colorScheme.onSurfaceVariant,
    };
  }

  Color _difficultyColor(BookDifficultyLevel level) {
    switch (level) {
      case BookDifficultyLevel.l1:
        return const Color(0xFF2E7D32);
      case BookDifficultyLevel.l2:
        return const Color(0xFF00897B);
      case BookDifficultyLevel.l3:
        return const Color(0xFFF9A825);
      case BookDifficultyLevel.l4:
        return const Color(0xFFE67E22);
      case BookDifficultyLevel.l5:
        return const Color(0xFFC62828);
    }
  }

  static String _durationText(int seconds) {
    if (seconds <= 0) return '0 分钟';
    if (seconds < 60) return '$seconds 秒';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes 分钟';
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    return remain > 0 ? '$hours 小时 $remain 分' : '$hours 小时';
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PanelHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final List<_MetricData> metrics;

  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 4 : 2;
        const spacing = 10.0;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: tileWidth,
                child: _MetricTile(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _MetricData {
  final IconData icon;
  final String label;
  final String value;

  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _MetricTile extends StatelessWidget {
  final _MetricData metric;

  const _MetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _InsightRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DifficultyChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;
  final String value;

  const _LegendItem({
    required this.label,
    required this.color,
    required this.value,
  });
}

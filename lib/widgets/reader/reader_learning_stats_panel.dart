import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../../models/learning_analytics.dart';
import '../../providers/reading/bookmark_notifier.dart';
import '../../providers/reading/current_book_notifier.dart';
import '../../providers/reading/vocabulary_notifier.dart';
import '../flow/flow_components.dart';

class ReaderLearningStatsPanel extends riverpod.ConsumerWidget {
  const ReaderLearningStatsPanel({
    super.key,
    required this.onStartTraining,
  });

  final VoidCallback onStartTraining;

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    ref.watch(vocabularyNotifierProvider);
    ref.watch(currentBookNotifierProvider);
    final bookmarkState = ref.watch(bookmarkNotifierProvider);
    final vocabulary = ref.read(vocabularyNotifierProvider.notifier);
    final currentBook = ref.read(currentBookNotifierProvider.notifier);
    final report = vocabulary.currentChapterLearningReport;
    final theme = Theme.of(context);

    if (report == null) {
      return _EmptyStatsState(theme: theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: Row(
            children: [
              Icon(
                Icons.insights_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '本章统计',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                '${report.chapterIndex + 1}/${report.chapterCount}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProgressBlock(report: report),
                const SizedBox(height: 10),
                _MetricGrid(
                  metrics: [
                    _MetricData(
                      icon: Icons.timer_outlined,
                      label: '阅读',
                      value: _durationText(report.readingTimeSeconds),
                    ),
                    _MetricData(
                      icon: Icons.search_outlined,
                      label: '查词',
                      value: '${report.lookupCount}',
                    ),
                    _MetricData(
                      icon: Icons.text_fields_outlined,
                      label: '词汇',
                      value: '${vocabulary.totalVocabularyCount}',
                    ),
                    _MetricData(
                      icon: Icons.bookmark_outline,
                      label: '书签',
                      value: '${bookmarkState.bookmarkedWords.length}',
                    ),
                    _MetricData(
                      icon: Icons.fact_check_outlined,
                      label: '练习',
                      value: report.practiceAnsweredCount > 0
                          ? '${report.practiceAccuracyPercent}%'
                          : '未开始',
                    ),
                    _MetricData(
                      icon: Icons.auto_stories_outlined,
                      label: '章节',
                      value: '${currentBook.chapterCount}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _VocabularyBreakdown(report: report),
                const SizedBox(height: 12),
                _NextStepBlock(report: report),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: FlowButton.tonal(
            onPressed: onStartTraining,
            icon: const Icon(Icons.fitness_center_outlined, size: 17),
            child: const Text('练习本章词汇'),
          ),
        ),
      ],
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({required this.report});

  final ChapterLearningReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = report.chapterProgress.clamp(0.0, 1.0).toDouble();

    return _PanelSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.chapterTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: progress,
              backgroundColor: theme.colorScheme.outlineVariant.withValues(
                alpha: 0.24,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '已读 ${(progress * 100).round()}% · ${report.wordCount} 词',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _VocabularyBreakdown extends StatelessWidget {
  const _VocabularyBreakdown({required this.report});

  final ChapterLearningReport report;

  @override
  Widget build(BuildContext context) {
    return _PanelSection(
      child: Column(
        children: [
          _BreakdownRow(
            label: '已掌握',
            value: report.masteredWordCount,
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          _BreakdownRow(
            label: '学习中',
            value: report.learningWordCount,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          _BreakdownRow(
            label: '生词',
            value: report.newWordCount,
            color: Theme.of(context).colorScheme.error,
          ),
        ],
      ),
    );
  }
}

class _NextStepBlock extends StatelessWidget {
  const _NextStepBlock({required this.report});

  final ChapterLearningReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PanelSection(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              report.nextStep,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) => _MetricTile(data: metrics[index]),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PanelSection(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, size: 17, color: theme.colorScheme.primary),
          const Spacer(),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            data.label,
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

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          '$value',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PanelSection extends StatelessWidget {
  const _PanelSection({
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.42,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _EmptyStatsState extends StatelessWidget {
  const _EmptyStatsState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.34),
            ),
            const SizedBox(height: 12),
            Text(
              '暂无本章统计',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _durationText(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  final remain = seconds % 60;
  if (minutes < 60) {
    return remain == 0 ? '${minutes}m' : '${minutes}m ${remain}s';
  }
  final hours = minutes ~/ 60;
  final hourMinutes = minutes % 60;
  return hourMinutes == 0 ? '${hours}h' : '${hours}h ${hourMinutes}m';
}

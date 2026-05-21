import 'package:flutter/material.dart';

class TodayReviewCard extends StatelessWidget {
  final int dueCount;
  final int totalLearningItems;
  final VoidCallback onStart;

  const TodayReviewCard({
    super.key,
    required this.dueCount,
    required this.totalLearningItems,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDue = dueCount > 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasDue
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.28)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.36),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: hasDue
                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hasDue ? Icons.replay_circle_filled : Icons.check_circle_outline,
              color: hasDue
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasDue ? '今日复习' : '今日已完成',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasDue
                      ? '$dueCount 条待复习，每次最多 10 条'
                      : '$totalLearningItems 个学习项会按间隔再次出现',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: hasDue ? onStart : null,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('开始复习'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
        ],
      ),
    );
  }
}

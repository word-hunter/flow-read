import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/book_difficulty.dart';
import 'book_cover_view.dart';

enum FeaturedBookAction { rename, remove }

class FeaturedBookCard extends StatelessWidget {
  final String title;
  final String author;
  final Uint8List? coverBytes;
  final int progressPercent;
  final int currentChapter;
  final int totalChapters;
  final int readingTimeSeconds;
  final int dailyReadingGoalSeconds;
  final int noteCount;
  final String? latestExcerpt;
  final BookDifficultyRating? difficulty;
  final bool isDifficultyLoading;
  final DateTime? lastReadAt;
  final VoidCallback onContinueReading;
  final VoidCallback? onRename;
  final VoidCallback? onRemove;

  const FeaturedBookCard({
    super.key,
    required this.title,
    required this.author,
    this.coverBytes,
    required this.progressPercent,
    required this.currentChapter,
    required this.totalChapters,
    required this.readingTimeSeconds,
    required this.dailyReadingGoalSeconds,
    required this.noteCount,
    this.latestExcerpt,
    this.difficulty,
    this.isDifficultyLoading = false,
    this.lastReadAt,
    required this.onContinueReading,
    this.onRename,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.36),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 780;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCover(),
                    const SizedBox(width: 22),
                    Expanded(child: _buildDetails(context, theme)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInsightPanel(theme),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildCover(),
              const SizedBox(width: 28),
              Expanded(child: _buildDetails(context, theme)),
              const SizedBox(width: 28),
              SizedBox(width: 340, child: _buildInsightPanel(theme)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCover() {
    return BookCoverView(
      coverBytes: coverBytes,
      progressPercent: progressPercent,
      width: BookCoverView.featuredSize.width,
      height: BookCoverView.featuredSize.height,
    );
  }

  Widget _buildDetails(BuildContext context, ThemeData theme) {
    final lastReadText = lastReadAt != null
        ? '上次阅读: ${_dateText(lastReadAt!)}'
        : '还没有阅读记录';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          author,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (difficulty != null || isDifficultyLoading) ...[
          const SizedBox(height: 12),
          _FeaturedDifficultySummary(
            rating: difficulty,
            isLoading: isDifficultyLoading,
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              '阅读进度',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progressPercent / 100,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surface.withValues(
                    alpha: 0.58,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$progressPercent%',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '$lastReadText · ${_chapterLabel()}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: onContinueReading,
              icon: const Icon(Icons.menu_book, size: 18),
              label: const Text('继续阅读'),
            ),
            if (onRename != null || onRemove != null)
              PopupMenuButton<FeaturedBookAction>(
                tooltip: '更多操作',
                onSelected: _handleAction,
                itemBuilder: (context) => [
                  if (onRename != null)
                    const PopupMenuItem(
                      value: FeaturedBookAction.rename,
                      child: _FeaturedMenuItem(
                        icon: Icons.drive_file_rename_outline,
                        label: '重命名',
                      ),
                    ),
                  if (onRemove != null) const PopupMenuDivider(),
                  if (onRemove != null)
                    PopupMenuItem(
                      value: FeaturedBookAction.remove,
                      child: _FeaturedMenuItem(
                        icon: Icons.remove_circle_outline,
                        label: '移出书架',
                        color: theme.colorScheme.error,
                      ),
                    ),
                ],
                child: Container(
                  height: 40,
                  width: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Icon(
                    Icons.more_horiz,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightPanel(ThemeData theme) {
    final excerpt = latestExcerpt?.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoMetric(
                  icon: Icons.timer_outlined,
                  label: '本书已读',
                  value: _durationText(readingTimeSeconds),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _InfoMetric(
                  icon: Icons.event_available_outlined,
                  label: '预计剩余',
                  value: _remainingText(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoMetric(
                  icon: Icons.sticky_note_2_outlined,
                  label: '笔记与书签',
                  value: '$noteCount 条',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _InfoMetric(
                  icon: Icons.bookmark_border,
                  label: '上次章节',
                  value: _chapterLabel(),
                ),
              ),
            ],
          ),
          if (excerpt != null && excerpt.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 14),
            Text(
              '最近摘录',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              excerpt,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _GoalStrip(
            theme: theme,
            dailyGoalText: _durationText(dailyReadingGoalSeconds),
          ),
        ],
      ),
    );
  }

  void _handleAction(FeaturedBookAction action) {
    switch (action) {
      case FeaturedBookAction.rename:
        onRename?.call();
        return;
      case FeaturedBookAction.remove:
        onRemove?.call();
        return;
    }
  }

  String _chapterLabel() {
    final chapterNumber = min(currentChapter + 1, max(totalChapters, 1));
    if (totalChapters <= 0) return '第 $chapterNumber 章';
    return '第 $chapterNumber / $totalChapters 章';
  }

  String _remainingText() {
    if (progressPercent >= 100) return '已读完';
    if (progressPercent <= 0 || readingTimeSeconds <= 0) return '待估算';
    final remainingSeconds =
        (readingTimeSeconds * (100 - progressPercent) / progressPercent)
            .round();
    return _durationText(remainingSeconds);
  }

  String _durationText(int seconds) {
    if (seconds < 60) return '${max(seconds, 0)} 秒';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes 分钟';
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    return remain > 0 ? '$hours 小时 $remain 分钟' : '$hours 小时';
  }

  String _dateText(DateTime value) {
    return '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
  }
}

class _FeaturedDifficultySummary extends StatelessWidget {
  final BookDifficultyRating? rating;
  final bool isLoading;

  const _FeaturedDifficultySummary({
    required this.rating,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = rating == null
        ? theme.colorScheme.onSurfaceVariant
        : _difficultyColor(rating!.level);
    final showLoading = isLoading && rating == null;
    final title = showLoading ? '难度计算中' : rating?.levelText ?? '暂无评级';
    final tooltip = showLoading
        ? '正在异步计算难易度\n完成后会根据当前生词量和已掌握词汇给出评级。'
        : rating?.tooltipText ?? '暂无足够内容生成难度说明。';

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed_outlined, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
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
}

class _InfoMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 19, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalStrip extends StatelessWidget {
  final ThemeData theme;
  final String dailyGoalText;

  const _GoalStrip({required this.theme, required this.dailyGoalText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_outlined, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '阅读目标 · 每日 $dailyGoalText',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _FeaturedMenuItem({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = color ?? theme.colorScheme.onSurface;

    return Row(
      children: [
        Icon(icon, size: 18, color: foreground),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
          ),
        ),
      ],
    );
  }
}

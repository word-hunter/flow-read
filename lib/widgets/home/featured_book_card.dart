import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

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
  final int noteCount;
  final String? latestExcerpt;
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
    required this.noteCount,
    this.latestExcerpt,
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
          _GoalStrip(theme: theme),
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

  const _GoalStrip({required this.theme});

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
              '阅读目标 · 每日 1 小时',
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

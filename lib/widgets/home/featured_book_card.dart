import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/book_difficulty.dart';
import 'book_cover_view.dart';
import 'book_difficulty_chip.dart';
import 'home_hover_surface.dart';

enum FeaturedBookAction { rename, remove }

class FeaturedBookCard extends StatelessWidget {
  static const double _progressMaxWidth = 560;

  final String title;
  final String author;
  final Uint8List? coverBytes;
  final int progressPercent;
  final int currentChapter;
  final int totalChapters;
  final int readingTimeSeconds;
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
          if (constraints.maxWidth < 540) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCover(),
                const SizedBox(height: 20),
                _buildDetails(context, theme),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildCover(),
              const SizedBox(width: 32),
              Expanded(child: _buildDetails(context, theme)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCover() {
    final showDifficulty = difficulty != null || isDifficultyLoading;

    return SizedBox(
      width: BookCoverView.featuredSize.width,
      height: BookCoverView.featuredSize.height,
      child: Stack(
        children: [
          BookCoverView(
            coverBytes: coverBytes,
            progressPercent: progressPercent,
            width: BookCoverView.featuredSize.width,
            height: BookCoverView.featuredSize.height,
            showProgressBadge: false,
          ),
          if (showDifficulty)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Align(
                alignment: Alignment.centerLeft,
                child: BookDifficultyChip(
                  rating: difficulty,
                  isLoading: isDifficultyLoading,
                  compact: true,
                ),
              ),
            ),
        ],
      ),
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
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
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
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _FeaturedMetric(
              icon: Icons.timer_outlined,
              label: '本书已读',
              value: _durationText(readingTimeSeconds),
            ),
            _FeaturedMetric(
              icon: Icons.bookmark_border,
              label: '上次章节',
              value: _chapterLabel(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildProgress(theme),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                lastReadText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
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
                child: HomeHoverSurface(
                  height: 40,
                  width: 48,
                  borderRadius: BorderRadius.circular(12),
                  backgroundColor: Colors.transparent,
                  hoverBackgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.07,
                  ),
                  borderColor: theme.colorScheme.outlineVariant,
                  hoverBorderColor: theme.colorScheme.primary.withValues(
                    alpha: 0.46,
                  ),
                  builder: (context, isHovering) => Icon(
                    Icons.more_horiz,
                    color: isHovering
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
      ],
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

  Widget _buildProgress(ThemeData theme) {
    final progressFillColor = _progressFillColor(theme);
    final progressTextColor = _progressTextColor(theme);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _progressMaxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '阅读进度',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$progressPercent%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: progressTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressPercent.clamp(0, 100) / 100,
              minHeight: 8,
              backgroundColor: theme.colorScheme.outlineVariant.withValues(
                alpha: 0.72,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(progressFillColor),
            ),
          ),
        ],
      ),
    );
  }

  Color _progressFillColor(ThemeData theme) {
    final level = difficulty?.level;
    if (level == null) return theme.colorScheme.primary;
    return BookDifficultyChipPalette.forLevel(level).border;
  }

  Color _progressTextColor(ThemeData theme) {
    final level = difficulty?.level;
    if (level == null) return theme.colorScheme.primary;
    return BookDifficultyChipPalette.forLevel(level).foreground;
  }

  String _chapterLabel() {
    final chapterNumber = min(currentChapter + 1, max(totalChapters, 1));
    if (totalChapters <= 0) return '第 $chapterNumber 章';
    return '第 $chapterNumber / $totalChapters 章';
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

class _FeaturedMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _FeaturedMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minWidth: 144, maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.62),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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

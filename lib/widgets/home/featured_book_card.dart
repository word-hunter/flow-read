import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/book_difficulty.dart';
import '../../theme/city_theme_tokens.dart';
import '../book_difficulty_chip.dart';
import '../flow/flow_components.dart';
import '../city/city_widgets.dart';
import 'book_cover_view.dart';
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
  final bool forceDefaultCover;
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
    this.forceDefaultCover = false,
    this.lastReadAt,
    required this.onContinueReading,
    this.onRename,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final city = Theme.of(context).extension<CityThemeTokens>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: city == null
          ? BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.36),
              ),
            )
          : cityCardDecoration(context),
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
            title: title,
            author: author,
            width: BookCoverView.featuredSize.width,
            height: BookCoverView.featuredSize.height,
            showProgressBadge: false,
            forceDefaultCover: forceDefaultCover,
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
    final city = Theme.of(context).extension<CityThemeTokens>();
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
            color: city?.textPrimary ?? theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          author,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: city?.textSecondary ?? theme.colorScheme.onSurfaceVariant,
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
        _buildProgress(context, theme),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: city?.textSecondary ?? theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                lastReadText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      city?.textSecondary ?? theme.colorScheme.onSurfaceVariant,
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
            FlowButton.primary(
              onPressed: onContinueReading,
              icon: const Icon(Icons.menu_book, size: 18),
              size: FlowButtonSize.large,
              child: const Text('继续阅读'),
            ),
            if (onRename != null || onRemove != null)
              FlowMenuButton<FeaturedBookAction>(
                tooltip: '更多操作',
                entries: [
                  if (onRename != null)
                    const FlowMenuItem(
                      value: FeaturedBookAction.rename,
                      icon: Icons.drive_file_rename_outline,
                      label: '重命名',
                    ),
                  if (onRename != null && onRemove != null)
                    const FlowMenuDivider(),
                  if (onRemove != null)
                    const FlowMenuItem(
                      value: FeaturedBookAction.remove,
                      icon: Icons.remove_circle_outline,
                      label: '移出书架',
                      destructive: true,
                    ),
                ],
                onSelected: _handleAction,
                child: HomeHoverSurface(
                  height: 40,
                  width: 48,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: Colors.transparent,
                  hoverBackgroundColor: theme.colorScheme.primary.withValues(
                    alpha: city == null ? 0.10 : 0.08,
                  ),
                  borderColor:
                      city?.warmBorder ?? theme.colorScheme.outlineVariant,
                  hoverBorderColor:
                      city?.activeBlue ??
                      theme.colorScheme.primary.withValues(alpha: 0.58),
                  builder: (context, isHovering) => Icon(
                    Icons.more_horiz,
                    color: isHovering
                        ? city?.activeBlue ?? theme.colorScheme.primary
                        : city?.textPrimary ?? theme.colorScheme.onSurface,
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

  Widget _buildProgress(BuildContext context, ThemeData theme) {
    final city = Theme.of(context).extension<CityThemeTokens>();
    final progressFillColor = _progressFillColor(context, theme);
    final progressTextColor = _progressTextColor(context, theme);

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
                  color:
                      city?.textSecondary ?? theme.colorScheme.onSurfaceVariant,
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
                alpha: city == null ? 0.72 : 0.48,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(progressFillColor),
            ),
          ),
        ],
      ),
    );
  }

  Color _progressFillColor(BuildContext context, ThemeData theme) {
    final level = difficulty?.level;
    final city = Theme.of(context).extension<CityThemeTokens>();
    if (level == null) return city?.activeBlue ?? theme.colorScheme.primary;
    return BookDifficultyChipPalette.forLevel(level).border;
  }

  Color _progressTextColor(BuildContext context, ThemeData theme) {
    final level = difficulty?.level;
    final city = Theme.of(context).extension<CityThemeTokens>();
    if (level == null) return city?.activeBlue ?? theme.colorScheme.primary;
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
    final city = Theme.of(context).extension<CityThemeTokens>();

    return Container(
      constraints: const BoxConstraints(minWidth: 144, maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:
            city?.panelSurface ??
            theme.colorScheme.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              city?.warmBorder ??
              theme.colorScheme.outlineVariant.withValues(alpha: 0.62),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: city?.activeBlue ?? theme.colorScheme.primary,
          ),
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
                    color:
                        city?.textSecondary ??
                        theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: city?.textPrimary ?? theme.colorScheme.onSurface,
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

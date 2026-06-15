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
      padding: const EdgeInsets.all(22),
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
          final content = constraints.maxWidth < 560
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCover(),
                    const SizedBox(height: 20),
                    _buildDetails(context, theme),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildCover(),
                    const SizedBox(width: 28),
                    Expanded(child: _buildDetails(context, theme)),
                  ],
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContinueTag(context, theme),
              const SizedBox(height: 14),
              content,
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
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: city?.textPrimary ?? theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          author,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 13,
            color: city?.textSecondary ?? theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 15,
              color: city?.textSecondary ?? theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                _chapterLabel(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 13,
                  color:
                      city?.textSecondary ?? theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _buildProgress(context, theme, lastReadText: lastReadText),
        const SizedBox(height: 22),
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

  Widget _buildContinueTag(BuildContext context, ThemeData theme) {
    final city = Theme.of(context).extension<CityThemeTokens>();
    final accent = city?.activeBlue ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '继续阅读',
        style: theme.textTheme.labelMedium?.copyWith(
          color: accent,
          fontWeight: FontWeight.w800,
        ),
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

  Widget _buildProgress(
    BuildContext context,
    ThemeData theme, {
    required String lastReadText,
  }) {
    final city = Theme.of(context).extension<CityThemeTokens>();
    final progressFillColor = _progressFillColor(context, theme);
    final progressTextColor = _progressTextColor(context, theme);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _progressMaxWidth),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = min(
            190.0,
            max(96.0, constraints.maxWidth * 0.32),
          );
          final progressTrack = ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressPercent.clamp(0, 100) / 100,
              minHeight: 6,
              backgroundColor: theme.colorScheme.outlineVariant.withValues(
                alpha: city == null ? 0.72 : 0.48,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(progressFillColor),
            ),
          );
          final progressGroup = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '阅读进度',
                style: theme.textTheme.labelMedium?.copyWith(
                  color:
                      city?.textSecondary ?? theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(width: trackWidth, child: progressTrack),
              const SizedBox(width: 10),
              Text(
                '$progressPercent%',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: progressTextColor,
                ),
              ),
            ],
          );
          final lastReadGroup = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 1,
                height: 14,
                color: city?.warmBorder ?? theme.colorScheme.outlineVariant,
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.schedule,
                size: 14,
                color:
                    city?.textSecondary ?? theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  lastReadText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color:
                        city?.textSecondary ??
                        theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 500) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                progressGroup,
                const SizedBox(height: 10),
                lastReadGroup,
              ],
            );
          }

          return Row(
            children: [
              progressGroup,
              const SizedBox(width: 18),
              Expanded(child: lastReadGroup),
            ],
          );
        },
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

  String _dateText(DateTime value) {
    final now = DateTime.now();
    final date = DateUtils.dateOnly(value);
    final today = DateUtils.dateOnly(now);
    final time =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    if (date == today) return '今天 $time';
    if (date == today.subtract(const Duration(days: 1))) return '昨天 $time';
    return '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
  }
}

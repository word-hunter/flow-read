import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
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
  final List<String> readingExcerpts;
  final bool isLoadingReadingExcerpts;
  final BookDifficultyRating? difficulty;
  final bool isDifficultyLoading;
  final bool forceDefaultCover;
  final DateTime? lastReadAt;
  final EdgeInsetsGeometry margin;
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
    this.readingExcerpts = const [],
    this.isLoadingReadingExcerpts = false,
    this.difficulty,
    this.isDifficultyLoading = false,
    this.forceDefaultCover = false,
    this.lastReadAt,
    this.margin = const EdgeInsets.symmetric(horizontal: 24),
    required this.onContinueReading,
    this.onRename,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(context, theme),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showInfoPanel = constraints.maxWidth >= 920;
          final infoPanelWidth = min(
            420.0,
            max(300.0, constraints.maxWidth * 0.32),
          );
          final content = constraints.maxWidth < 640
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCover(),
                    const SizedBox(height: 22),
                    _buildDetails(context, theme),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildCover(),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: showInfoPanel ? 5 : 1,
                      child: _buildDetails(context, theme),
                    ),
                    if (showInfoPanel) ...[
                      const SizedBox(width: 30),
                      SizedBox(
                        width: infoPanelWidth,
                        child: _buildReadingInfoPanel(context, theme),
                      ),
                    ],
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
    return SizedBox(
      width: BookCoverView.featuredSize.width,
      height: BookCoverView.featuredSize.height,
      child: BookCoverView(
        coverBytes: coverBytes,
        progressPercent: progressPercent,
        title: title,
        author: author,
        width: BookCoverView.featuredSize.width,
        height: BookCoverView.featuredSize.height,
        showProgressBadge: false,
        forceDefaultCover: forceDefaultCover,
      ),
    );
  }

  Widget _buildDetails(BuildContext context, ThemeData theme) {
    final city = Theme.of(context).extension<CityThemeTokens>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 22,
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
            fontSize: 14,
            color: city?.textSecondary ?? theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        _buildChapterSummary(context, theme),
        const SizedBox(height: 14),
        _buildProgress(context, theme),
        const SizedBox(height: 16),
        _buildMetaChips(context, theme),
        const SizedBox(height: 24),
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

  BoxDecoration _cardDecoration(BuildContext context, ThemeData theme) {
    final city = Theme.of(context).extension<CityThemeTokens>();
    if (city == null) {
      return BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.36),
        ),
      );
    }

    return cityCardDecoration(context).copyWith(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          city.cardSurface,
          city.skyBottom.withValues(alpha: 0.62),
          city.cardSurface,
        ],
        stops: const [0, 0.58, 1],
      ),
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

  Widget _buildMetaChips(BuildContext context, ThemeData theme) {
    final city = Theme.of(context).extension<CityThemeTokens>();
    final textColor = city?.textSecondary ?? theme.colorScheme.onSurfaceVariant;
    final chipBorder = city?.warmBorder ?? theme.colorScheme.outlineVariant;
    final chips = <Widget>[
      if (difficulty != null || isDifficultyLoading)
        BookDifficultyChip(
          rating: difficulty,
          isLoading: isDifficultyLoading,
          compact: true,
          maxWidth: 156,
        ),
      _InfoChip(
        icon: Icons.auto_stories_outlined,
        label: _remainingChapterText(),
        foreground: textColor,
        background:
            city?.panelSurface ??
            theme.colorScheme.surface.withValues(alpha: 0.72),
        border: chipBorder,
      ),
    ];

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _buildChapterSummary(BuildContext context, ThemeData theme) {
    final city = Theme.of(context).extension<CityThemeTokens>();
    final color = city?.textSecondary ?? theme.colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.menu_book_outlined, size: 17, color: color),
        const SizedBox(width: 7),
        Text(
          _chapterLabel(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildReadingInfoPanel(BuildContext context, ThemeData theme) {
    final city = Theme.of(context).extension<CityThemeTokens>();
    final activeBlue = city?.activeBlue ?? theme.colorScheme.primary;
    final borderColor = city?.warmBorder ?? theme.colorScheme.outlineVariant;
    final textPrimary = city?.textPrimary ?? theme.colorScheme.onSurface;
    final textSecondary =
        city?.textSecondary ?? theme.colorScheme.onSurfaceVariant;

    return Container(
      constraints: const BoxConstraints(minHeight: 238),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color:
            city?.panelSurface.withValues(alpha: 0.72) ??
            theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ReadingInfoDecorationPainter(
                activeBlue: activeBlue,
                borderColor: borderColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote,
                  size: 22,
                  color: activeBlue.withValues(alpha: 0.36),
                ),
                const SizedBox(height: 6),
                _ReadingExcerptCarousel(
                  excerpts: readingExcerpts,
                  isLoading: isLoadingReadingExcerpts,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  accent: activeBlue,
                ),
                const SizedBox(height: 16),
                _ReadingInfoRow(
                  icon: Icons.timeline_outlined,
                  label: '章节进度',
                  value: _chapterLabel(),
                  color: textSecondary,
                ),
                const SizedBox(height: 8),
                _ReadingInfoRow(
                  icon: Icons.flag_outlined,
                  label: '剩余内容',
                  value: _remainingProgressText(),
                  color: textSecondary,
                ),
                const SizedBox(height: 8),
                _ReadingInfoRow(
                  icon: Icons.schedule,
                  label: '最近阅读',
                  value: lastReadAt != null ? _dateText(lastReadAt!) : '还没有记录',
                  color: textSecondary,
                ),
              ],
            ),
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

  Widget _buildProgress(
    BuildContext context,
    ThemeData theme,
  ) {
    final city = Theme.of(context).extension<CityThemeTokens>();
    final progressFillColor = _progressFillColor(context, theme);
    final progressTextColor = _progressTextColor(context, theme);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _progressMaxWidth),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = min(
            260.0,
            max(126.0, constraints.maxWidth * 0.38),
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
          return progressGroup;
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
    final chapterNumber = max(
      1,
      min(currentChapter + 1, max(totalChapters, 1)),
    );
    if (totalChapters <= 0) return '第 $chapterNumber 章';
    return '第 $chapterNumber / $totalChapters 章';
  }

  String _remainingChapterText() {
    if (totalChapters <= 0) return '待确认';
    final chapterNumber = max(1, min(currentChapter + 1, totalChapters));
    final remaining = max(totalChapters - chapterNumber, 0);
    if (remaining == 0) return '最后一章';
    return '剩余 $remaining 章';
  }

  String _remainingProgressText() {
    final remaining = (100 - progressPercent.clamp(0, 100)).clamp(0, 100);
    if (remaining == 0) return '即将完成';
    return '剩余 $remaining%';
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

class _InfoChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color foreground;
  final Color background;
  final Color border;

  const _InfoChip({
    this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: BoxConstraints(
        minHeight: 30,
        minWidth: icon == null ? 48 : 0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ReadingInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: color,
      fontWeight: FontWeight.w700,
    );

    return Row(
      children: [
        Icon(icon, size: 15, color: color.withValues(alpha: 0.78)),
        const SizedBox(width: 7),
        Text(label, style: textStyle),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: textStyle?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ReadingExcerptCarousel extends StatefulWidget {
  final List<String> excerpts;
  final bool isLoading;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;

  const _ReadingExcerptCarousel({
    required this.excerpts,
    required this.isLoading,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
  });

  @override
  State<_ReadingExcerptCarousel> createState() =>
      _ReadingExcerptCarouselState();
}

class _ReadingExcerptCarouselState extends State<_ReadingExcerptCarousel> {
  static const _rotationDuration = Duration(seconds: 7);
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _configureTimer();
  }

  @override
  void didUpdateWidget(_ReadingExcerptCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.excerpts, widget.excerpts)) {
      _index = 0;
      _configureTimer();
    } else if (oldWidget.isLoading != widget.isLoading) {
      _configureTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _configureTimer() {
    _timer?.cancel();
    _timer = null;
    if (widget.isLoading || widget.excerpts.length < 2) return;
    _timer = Timer.periodic(_rotationDuration, (_) {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % widget.excerpts.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final excerpt = _currentExcerpt;
    final hasExcerpts = widget.excerpts.isNotEmpty;
    final excerptStyle = theme.textTheme.bodyMedium?.copyWith(
      color: hasExcerpts ? widget.textPrimary : widget.textSecondary,
      height: 1.42,
      fontWeight: hasExcerpts ? FontWeight.w600 : FontWeight.w500,
    );
    final lineHeight =
        (excerptStyle?.fontSize ?? theme.textTheme.bodyMedium?.fontSize ?? 14) *
        (excerptStyle?.height ?? 1.42);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasExcerpts ? '书中片段' : '阅读片段',
          style: theme.textTheme.labelSmall?.copyWith(
            color: widget.accent,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: lineHeight * 3,
          child: ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    ...previousChildren,
                    ?currentChild,
                  ],
                );
              },
              child: Align(
                key: ValueKey(excerpt),
                alignment: Alignment.topLeft,
                child: Text(
                  excerpt,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: excerptStyle,
                ),
              ),
            ),
          ),
        ),
        if (widget.excerpts.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            children: List.generate(widget.excerpts.length, (index) {
              final selected = index == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(right: 5),
                width: selected ? 16 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: selected
                      ? widget.accent.withValues(alpha: 0.70)
                      : widget.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  String get _currentExcerpt {
    if (widget.excerpts.isNotEmpty) {
      return widget.excerpts[_index.clamp(0, widget.excerpts.length - 1)];
    }
    if (widget.isLoading) return '正在提取当前书籍片段...';
    return '暂未找到适合展示的书中片段。';
  }
}

class _ReadingInfoDecorationPainter extends CustomPainter {
  final Color activeBlue;
  final Color borderColor;

  const _ReadingInfoDecorationPainter({
    required this.activeBlue,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sunPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFC95C).withValues(alpha: 0.12);
    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFC95C).withValues(alpha: 0.18);
    final cloudPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = activeBlue.withValues(alpha: 0.055);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = activeBlue.withValues(alpha: 0.10);
    final warmLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = borderColor.withValues(alpha: 0.62);

    final sunCenter = Offset(size.width * 0.78, size.height * 0.72);
    canvas.drawCircle(sunCenter, 22, sunPaint);
    for (var index = 0; index < 8; index++) {
      final angle = index * pi / 4;
      final start = sunCenter + Offset(cos(angle), sin(angle)) * 30;
      final end = sunCenter + Offset(cos(angle), sin(angle)) * 38;
      canvas.drawLine(start, end, rayPaint);
    }

    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.62, size.height * 0.64, 76, 30),
      cloudPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.53, size.height * 0.70, 88, 34),
      cloudPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.72, size.height * 0.78, 94, 30),
      cloudPaint,
    );

    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.88)
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.75,
        size.width * 0.60,
        size.height * 0.98,
        size.width * 0.92,
        size.height * 0.84,
      );
    canvas.drawPath(path, linePaint);

    canvas.drawLine(
      Offset(size.width * 0.54, size.height * 0.25),
      Offset(size.width * 0.84, size.height * 0.25),
      warmLinePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.64, size.height * 0.33),
      Offset(size.width * 0.92, size.height * 0.33),
      warmLinePaint,
    );
  }

  @override
  bool shouldRepaint(_ReadingInfoDecorationPainter oldDelegate) {
    return oldDelegate.activeBlue != activeBlue ||
        oldDelegate.borderColor != borderColor;
  }
}

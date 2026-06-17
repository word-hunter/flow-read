import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/city_theme_tokens.dart';

class ReadingStatsRing extends StatelessWidget {
  final int totalSeconds;
  final int dailyGoalSeconds;
  final VoidCallback? onTap;
  final bool isExpanded;

  const ReadingStatsRing({
    super.key,
    required this.totalSeconds,
    this.dailyGoalSeconds = 3600,
    this.onTap,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final city = Theme.of(context).extension<CityThemeTokens>();
    final weeklyGoalSeconds = math.max(dailyGoalSeconds, 1) * 6;
    final progress = (totalSeconds / weeklyGoalSeconds).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();
    final borderColor = isExpanded
        ? (city?.activeBlue ?? colorScheme.primary).withValues(alpha: 0.42)
        : (city?.warmBorder ?? colorScheme.outlineVariant).withValues(
            alpha: city == null ? 0.46 : 1,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Tooltip(
        message: '查看阅读目标详情',
        child: Material(
          color:
              city?.panelSurface ??
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.52),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            mouseCursor: SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '本周阅读',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color:
                                  city?.textSecondary ??
                                  colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color:
                              (city?.textSecondary ??
                                      colorScheme.onSurfaceVariant)
                                  .withValues(alpha: 0.78),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ProgressRing(
                      size: 96,
                      strokeWidth: 8,
                      progress: progress,
                      trackColor:
                          (city?.warmBorder ?? colorScheme.outlineVariant)
                              .withValues(alpha: 0.42),
                      progressColor: city?.activeBlue ?? colorScheme.primary,
                      child: Text(
                        '$percent%',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: city?.textPrimary ?? colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_durationText(totalSeconds)} / ${_durationText(weeklyGoalSeconds)}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            city?.textSecondary ?? colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '每日目标 ${_durationText(dailyGoalSeconds)}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            (city?.textSecondary ??
                                    colorScheme.onSurfaceVariant)
                                .withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReadingGoalSummaryCard extends StatelessWidget {
  final int totalSeconds;
  final int dailyGoalSeconds;
  final VoidCallback? onTap;
  final bool isExpanded;

  const ReadingGoalSummaryCard({
    super.key,
    required this.totalSeconds,
    this.dailyGoalSeconds = 3600,
    this.onTap,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final city = Theme.of(context).extension<CityThemeTokens>();
    final weeklyGoalSeconds = math.max(dailyGoalSeconds, 1) * 6;
    final progress = (totalSeconds / weeklyGoalSeconds).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();
    final borderColor = isExpanded
        ? (city?.activeBlue ?? colorScheme.primary).withValues(alpha: 0.42)
        : (city?.warmBorder ?? colorScheme.outlineVariant).withValues(
            alpha: city == null ? 0.46 : 1,
          );

    return Tooltip(
      message: '查看阅读目标详情',
      child: Material(
        color:
            city?.cardSurface ??
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '阅读目标',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: city?.textPrimary ?? colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: city?.warmBorder ?? colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '本周阅读',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color:
                          city?.textSecondary ?? colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: _ProgressRing(
                      size: 132,
                      strokeWidth: 9,
                      progress: progress,
                      trackColor:
                          (city?.warmBorder ?? colorScheme.outlineVariant)
                              .withValues(alpha: 0.42),
                      progressColor: city?.activeBlue ?? colorScheme.primary,
                      child: Text(
                        '$percent%',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: city?.textPrimary ?? colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${_durationText(totalSeconds)} / ${_durationText(weeklyGoalSeconds)}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          city?.textSecondary ?? colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '每日目标 ${_durationText(dailyGoalSeconds)}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          (city?.textSecondary ?? colorScheme.onSurfaceVariant)
                              .withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReadingGoalDetailsPanel extends StatefulWidget {
  final int weekTotalSeconds;
  final int monthTotalSeconds;
  final List<int> weekDailySeconds;
  final List<int> monthDailySeconds;
  final int dailyGoalSeconds;
  final DateTime goalDate;
  final VoidCallback onClose;
  final bool showPointer;

  const ReadingGoalDetailsPanel({
    super.key,
    required this.weekTotalSeconds,
    required this.monthTotalSeconds,
    required this.weekDailySeconds,
    required this.monthDailySeconds,
    required this.dailyGoalSeconds,
    required this.goalDate,
    required this.onClose,
    this.showPointer = true,
  });

  @override
  State<ReadingGoalDetailsPanel> createState() =>
      _ReadingGoalDetailsPanelState();
}

enum _ReadingGoalPeriod { week, month }

enum _GoalDayState { achieved, partial, missed, noData }

class _ReadingGoalDetailsPanelState extends State<ReadingGoalDetailsPanel> {
  _ReadingGoalPeriod _period = _ReadingGoalPeriod.week;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final city = Theme.of(context).extension<CityThemeTokens>();
    final dayGoal = math.max(widget.dailyGoalSeconds, 1);
    final weekSeconds = _normalizedWeekSeconds;
    final monthSeconds = _normalizedMonthSeconds;
    final totalSeconds = _period == _ReadingGoalPeriod.week
        ? _positiveOrSum(widget.weekTotalSeconds, weekSeconds)
        : _positiveOrSum(widget.monthTotalSeconds, monthSeconds);
    final targetSeconds = _period == _ReadingGoalPeriod.week
        ? dayGoal * 6
        : dayGoal * 30;
    final progress = (totalSeconds / targetSeconds).clamp(0.0, 1.0);
    final percent = (progress * 100).round();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (widget.showPointer)
          Positioned(
            left: -9,
            top: 128,
            child: _AnchorPointer(
              fillColor: city?.cardSurface ?? colorScheme.surface,
              borderColor: (city?.warmBorder ?? colorScheme.outlineVariant)
                  .withValues(alpha: city == null ? 0.58 : 1),
            ),
          ),
        Material(
          elevation: 10,
          shadowColor:
              city?.warmShadow ?? colorScheme.shadow.withValues(alpha: 0.14),
          color: city?.cardSurface ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (city?.warmBorder ?? colorScheme.outlineVariant)
                    .withValues(alpha: city == null ? 0.58 : 1),
              ),
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: KeyedSubtree(
                  key: ValueKey(_period),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: 16),
                      _buildSummary(
                        theme: theme,
                        totalSeconds: totalSeconds,
                        targetSeconds: targetSeconds,
                        progress: progress,
                        percent: percent,
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        color: city?.warmBorder ?? colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 12),
                      if (_period == _ReadingGoalPeriod.week)
                        _buildWeekDetails(theme, weekSeconds)
                      else
                        _buildMonthDetails(theme, monthSeconds),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final city = Theme.of(context).extension<CityThemeTokens>();
    return Row(
      children: [
        Expanded(
          child: Text(
            '阅读目标',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: city?.textPrimary ?? colorScheme.onSurface,
            ),
          ),
        ),
        _PeriodToggle(
          value: _period,
          onChanged: (period) => setState(() => _period = period),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: '关闭',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          icon: const Icon(Icons.close),
          iconSize: 18,
          color: (city?.textSecondary ?? colorScheme.onSurfaceVariant)
              .withValues(alpha: 0.68),
          onPressed: widget.onClose,
        ),
      ],
    );
  }

  Widget _buildSummary({
    required ThemeData theme,
    required int totalSeconds,
    required int targetSeconds,
    required double progress,
    required int percent,
  }) {
    final colorScheme = theme.colorScheme;
    final city = Theme.of(context).extension<CityThemeTokens>();
    final remainingSeconds = math.max(targetSeconds - totalSeconds, 0);
    final title = _period == _ReadingGoalPeriod.week ? '本周总结' : '本月总结';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: city?.textSecondary ?? colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _ProgressRing(
              size: 148,
              strokeWidth: 12,
              progress: progress,
              trackColor: (city?.warmBorder ?? colorScheme.outlineVariant)
                  .withValues(alpha: 0.42),
              progressColor: city?.activeBlue ?? colorScheme.primary,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$percent%',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: city?.textPrimary ?? colorScheme.onSurface,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '已完成',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: city?.activeBlue ?? colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _GoalMetricTable(
                rows: [
                  _GoalMetricRowData('已读', _durationText(totalSeconds)),
                  _GoalMetricRowData('目标', _durationText(targetSeconds)),
                  _GoalMetricRowData('剩余', _durationText(remainingSeconds)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekDetails(ThemeData theme, List<int> weekSeconds) {
    final labels = const ['一', '二', '三', '四', '五', '六', '日'];
    final dayGoal = math.max(widget.dailyGoalSeconds, 1);
    final reachedDays = weekSeconds
        .where((seconds) => seconds >= dayGoal)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDetailsTitle(theme, trailing: '本周达标 $reachedDays / 7 天'),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: Row(
            children: [
              for (var index = 0; index < 7; index += 1)
                Expanded(
                  child: _WeekDayProgress(
                    label: labels[index],
                    progress: (weekSeconds[index] / dayGoal).clamp(0.0, 1.0),
                    state: _stateForDay(
                      weekSeconds[index],
                      _weekStart.add(Duration(days: index)),
                    ),
                    isToday: _isSameDay(
                      _weekStart.add(Duration(days: index)),
                      widget.goalDate,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthDetails(ThemeData theme, List<int> monthSeconds) {
    final dayGoal = math.max(widget.dailyGoalSeconds, 1);
    final reachedDays = monthSeconds
        .where((seconds) => seconds >= dayGoal)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDetailsTitle(
          theme,
          trailing: '本月达标 $reachedDays / ${monthSeconds.length} 天',
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: monthSeconds.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.88,
          ),
          itemBuilder: (context, index) {
            final day = index + 1;
            final date = DateTime(
              widget.goalDate.year,
              widget.goalDate.month,
              day,
            );
            return _MonthDayDot(
              day: day,
              state: _stateForDay(monthSeconds[index], date),
              isToday: _isSameDay(date, widget.goalDate),
            );
          },
        ),
        const SizedBox(height: 14),
        _GoalLegend(
          items: const [
            _GoalLegendItem(_GoalDayState.achieved, '达标'),
            _GoalLegendItem(_GoalDayState.partial, '部分达标'),
            _GoalLegendItem(_GoalDayState.missed, '未达标'),
            _GoalLegendItem(_GoalDayState.noData, '无数据'),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsTitle(ThemeData theme, {required String trailing}) {
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            '每日完成情况',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          trailing,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  List<int> get _normalizedWeekSeconds {
    return List.generate(
      7,
      (index) => index < widget.weekDailySeconds.length
          ? widget.weekDailySeconds[index]
          : 0,
      growable: false,
    );
  }

  List<int> get _normalizedMonthSeconds {
    final days = _daysInMonth(widget.goalDate);
    return List.generate(
      days,
      (index) => index < widget.monthDailySeconds.length
          ? widget.monthDailySeconds[index]
          : 0,
      growable: false,
    );
  }

  DateTime get _weekStart {
    final day = DateTime(
      widget.goalDate.year,
      widget.goalDate.month,
      widget.goalDate.day,
    );
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  _GoalDayState _stateForDay(int seconds, DateTime date) {
    if (_isFutureDate(date)) return _GoalDayState.noData;
    final dayGoal = math.max(widget.dailyGoalSeconds, 1);
    if (seconds >= dayGoal) return _GoalDayState.achieved;
    if (seconds >= dayGoal * 0.5) return _GoalDayState.partial;
    return _GoalDayState.missed;
  }

  bool _isFutureDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final today = DateTime(
      widget.goalDate.year,
      widget.goalDate.month,
      widget.goalDate.day,
    );
    return normalized.isAfter(today);
  }

  int _positiveOrSum(int seconds, List<int> daySeconds) {
    if (seconds > 0) return seconds;
    return daySeconds.fold(0, (total, value) => total + value);
  }
}

class _WeekDayProgress extends StatelessWidget {
  final String label;
  final double progress;
  final _GoalDayState state;
  final bool isToday;

  const _WeekDayProgress({
    required this.label,
    required this.progress,
    required this.state,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progressColor = _stateColor(colorScheme, state);
    final ringProgress = state == _GoalDayState.noData ? 0.0 : progress;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ProgressRing(
          size: 44,
          strokeWidth: 5.5,
          progress: ringProgress,
          trackColor: colorScheme.outlineVariant.withValues(alpha: 0.56),
          progressColor: progressColor,
          child: _WeekDayCenter(state: state),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isToday ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 18,
          height: 2,
          decoration: BoxDecoration(
            color: isToday ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class _WeekDayCenter extends StatelessWidget {
  final _GoalDayState state;

  const _WeekDayCenter({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: switch (state) {
        _GoalDayState.achieved => Icon(
          Icons.check_rounded,
          size: 18,
          color: colorScheme.primary,
        ),
        _GoalDayState.partial => Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: colorScheme.tertiary,
            shape: BoxShape.circle,
          ),
        ),
        _GoalDayState.missed => Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.amber.shade700,
            shape: BoxShape.circle,
          ),
        ),
        _GoalDayState.noData => Text(
          '-',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.58),
            fontWeight: FontWeight.w800,
          ),
        ),
      },
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  final _ReadingGoalPeriod value;
  final ValueChanged<_ReadingGoalPeriod> onChanged;

  const _PeriodToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final city = Theme.of(context).extension<CityThemeTokens>();

    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color:
            city?.panelSurface ??
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (city?.warmBorder ?? colorScheme.outlineVariant).withValues(
            alpha: city == null ? 0.72 : 1,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PeriodToggleItem(
            label: '本周',
            selected: value == _ReadingGoalPeriod.week,
            onTap: () => onChanged(_ReadingGoalPeriod.week),
          ),
          _PeriodToggleItem(
            label: '本月',
            selected: value == _ReadingGoalPeriod.month,
            onTap: () => onChanged(_ReadingGoalPeriod.month),
          ),
        ],
      ),
    );
  }
}

class _PeriodToggleItem extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodToggleItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_PeriodToggleItem> createState() => _PeriodToggleItemState();
}

class _PeriodToggleItemState extends State<_PeriodToggleItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final city = Theme.of(context).extension<CityThemeTokens>();
    final backgroundColor = widget.selected
        ? city?.activeBlue ?? colorScheme.primary
        : _hovered
        ? (city?.activeBlue ?? colorScheme.primary).withValues(alpha: 0.12)
        : Colors.transparent;
    final borderColor = widget.selected
        ? city?.activeBlue ?? colorScheme.primary
        : _hovered
        ? (city?.activeBlue ?? colorScheme.primary).withValues(alpha: 0.22)
        : Colors.transparent;
    final textColor = widget.selected
        ? colorScheme.onPrimary
        : _hovered
        ? city?.activeBlue ?? colorScheme.primary
        : city?.textSecondary ?? colorScheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
        boxShadow: _hovered
            ? [
                BoxShadow(
                  color: (city?.activeBlue ?? colorScheme.primary).withValues(
                    alpha: 0.12,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : const [],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (hovered) => setState(() => _hovered = hovered),
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(999),
          hoverColor: Colors.transparent,
          splashColor: (city?.activeBlue ?? colorScheme.primary).withValues(
            alpha: 0.08,
          ),
          highlightColor: (city?.activeBlue ?? colorScheme.primary).withValues(
            alpha: 0.06,
          ),
          child: SizedBox(
            width: 50,
            height: 28,
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                style:
                    theme.textTheme.labelMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ) ??
                    TextStyle(color: textColor, fontWeight: FontWeight.w800),
                child: Text(widget.label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthDayDot extends StatelessWidget {
  final int day;
  final _GoalDayState state;
  final bool isToday;

  const _MonthDayDot({
    required this.day,
    required this.state,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = _stateColor(colorScheme, state);
    final filled = state == _GoalDayState.achieved;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$day',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : Colors.transparent,
            border: Border.all(
              color: isToday ? colorScheme.primary : color,
              width: isToday ? 3 : (state == _GoalDayState.noData ? 2 : 2.4),
            ),
          ),
          child: state == _GoalDayState.partial
              ? Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.72),
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

class _GoalLegend extends StatelessWidget {
  final List<_GoalLegendItem> items;

  const _GoalLegend({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: items
          .map((item) {
            final color = _stateColor(colorScheme, item.state);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  item.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          })
          .toList(growable: false),
    );
  }
}

class _GoalLegendItem {
  final _GoalDayState state;
  final String label;

  const _GoalLegendItem(this.state, this.label);
}

class _GoalMetricTable extends StatelessWidget {
  final List<_GoalMetricRowData> rows;

  const _GoalMetricTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final city = Theme.of(context).extension<CityThemeTokens>();

    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            city?.panelSurface ??
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (city?.warmBorder ?? colorScheme.outlineVariant).withValues(
            alpha: city == null ? 0.58 : 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < rows.length; index += 1) ...[
              _GoalMetricTextRow(row: rows[index]),
              if (index != rows.length - 1)
                Divider(
                  height: 16,
                  color: (city?.warmBorder ?? colorScheme.outlineVariant)
                      .withValues(alpha: city == null ? 0.6 : 1),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GoalMetricTextRow extends StatelessWidget {
  final _GoalMetricRowData row;

  const _GoalMetricTextRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final city = Theme.of(context).extension<CityThemeTokens>();

    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            row.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: city?.textSecondary ?? colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            row.value,
            textAlign: TextAlign.right,
            style: theme.textTheme.titleSmall?.copyWith(
              color: city?.textPrimary ?? colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalMetricRowData {
  final String label;
  final String value;

  const _GoalMetricRowData(this.label, this.value);
}

class _AnchorPointer extends StatelessWidget {
  final Color fillColor;
  final Color borderColor;

  const _AnchorPointer({required this.fillColor, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(10, 18),
      painter: _AnchorPointerPainter(
        fillColor: fillColor,
        borderColor: borderColor,
      ),
    );
  }
}

class _AnchorPointerPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;

  const _AnchorPointerPainter({
    required this.fillColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_AnchorPointerPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.borderColor != borderColor;
}

class _ProgressRing extends StatelessWidget {
  static const _animationDuration = Duration(milliseconds: 620);

  final double size;
  final double strokeWidth;
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final Widget child;

  const _ProgressRing({
    required this.size,
    required this.strokeWidth,
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress),
        duration: _animationDuration,
        curve: Curves.easeOutCubic,
        builder: (context, animatedProgress, child) {
          return CustomPaint(
            painter: _RingPainter(
              progress: animatedProgress,
              trackColor: trackColor,
              progressColor: progressColor,
              strokeWidth: strokeWidth,
            ),
            child: Center(child: child),
          );
        },
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

Color _stateColor(ColorScheme colorScheme, _GoalDayState state) {
  return switch (state) {
    _GoalDayState.achieved => colorScheme.primary,
    _GoalDayState.partial => colorScheme.tertiary,
    _GoalDayState.missed => Colors.amber.shade700,
    _GoalDayState.noData => colorScheme.outlineVariant,
  };
}

String _durationText(int seconds) {
  if (seconds < 60) return '${math.max(seconds, 0)}秒';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '$minutes分钟';
  final hours = minutes ~/ 60;
  final remain = minutes % 60;
  return remain > 0 ? '$hours小时 $remain分' : '$hours小时';
}

int _daysInMonth(DateTime date) {
  return DateTime(date.year, date.month + 1, 0).day;
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

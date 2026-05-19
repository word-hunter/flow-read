import 'dart:math';
import 'package:flutter/material.dart';

class ReadingStatsRing extends StatelessWidget {
  final int totalSeconds;
  final int dailyGoalSeconds;

  const ReadingStatsRing({
    super.key,
    required this.totalSeconds,
    this.dailyGoalSeconds = 3600,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weeklyGoalSeconds = max(dailyGoalSeconds, 1) * 6;
    final progress = (totalSeconds / weeklyGoalSeconds).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();

    final timeText = _durationText(totalSeconds);
    final weeklyGoalText = _durationText(weeklyGoalSeconds);
    final dailyGoalText = _durationText(dailyGoalSeconds);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '本周阅读',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress,
                trackColor: theme.colorScheme.outlineVariant.withValues(
                  alpha: 0.4,
                ),
                progressColor: theme.colorScheme.primary,
              ),
              child: Center(
                child: Text(
                  '$percent%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$timeText / $weeklyGoalText',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '每日目标: $dailyGoalText',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _durationText(int seconds) {
    if (seconds < 60) return '${max(seconds, 0)}秒';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes分钟';
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    return remain > 0 ? '$hours小时 $remain分' : '$hours小时';
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 8.0;

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

      final sweepAngle = 2 * pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}

import 'package:flutter/material.dart';

class DonutSegment {
  final String label;
  final double value;
  final Color color;

  const DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

class DonutChartPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double strokeWidth;
  final String centerLabel;
  final String centerValue;
  final Color centerValueColor;
  final Color centerLabelColor;

  DonutChartPainter({
    required this.segments,
    this.strokeWidth = 20,
    this.centerLabel = '',
    this.centerValue = '',
    this.centerValueColor = const Color(0xFF1A1A2E),
    this.centerLabelColor = const Color(0xFF1A1A2E),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    double startAngle = -90 * (3.14159 / 180);

    for (final segment in segments) {
      final sweepAngle = (segment.value / total) * 2 * 3.14159;

      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }

    _drawCenterText(canvas, center);
  }

  void _drawCenterText(Canvas canvas, Offset center) {
    if (centerValue.isEmpty && centerLabel.isEmpty) return;

    final valuePainter = TextPainter(
      text: TextSpan(
        text: centerValue,
        style: TextStyle(
          color: centerValueColor,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    valuePainter.layout();

    final labelPainter = TextPainter(
      text: TextSpan(
        text: centerLabel,
        style: TextStyle(
          color: centerLabelColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();

    final totalHeight =
        valuePainter.height +
        (centerLabel.isNotEmpty ? labelPainter.height + 2 : 0);
    final startY = center.dy - totalHeight / 2;

    valuePainter.paint(
      canvas,
      Offset(center.dx - valuePainter.width / 2, startY),
    );

    if (centerLabel.isNotEmpty) {
      labelPainter.paint(
        canvas,
        Offset(
          center.dx - labelPainter.width / 2,
          startY + valuePainter.height + 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return segments != oldDelegate.segments ||
        strokeWidth != oldDelegate.strokeWidth ||
        centerLabel != oldDelegate.centerLabel ||
        centerValue != oldDelegate.centerValue ||
        centerValueColor != oldDelegate.centerValueColor ||
        centerLabelColor != oldDelegate.centerLabelColor;
  }
}

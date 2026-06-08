import 'dart:math' as math;

import 'package:flutter/material.dart';

class DefaultBookCover extends StatelessWidget {
  static const Key titleTextKey = ValueKey('default-book-cover-title');
  static const Key authorTextKey = ValueKey('default-book-cover-author');

  final String title;
  final String author;
  final int progressPercent;
  final bool showProgressBadge;

  const DefaultBookCover({
    super.key,
    required this.title,
    required this.author,
    required this.progressPercent,
    this.showProgressBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = title.trim().isEmpty ? 'Untitled Book' : title.trim();
    final displayAuthor = author.trim().isEmpty
        ? 'FLOW READ'
        : author.trim().toUpperCase();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _finite(constraints.maxWidth, 128);
        final height = _finite(constraints.maxHeight, 184);
        final scale = math.min(width / 128, height / 184).clamp(0.82, 1.72);
        final titleSize = (17.5 * scale).clamp(15.0, 30.0);
        final brandSize = (8.5 * scale).clamp(7.0, 13.0);
        final authorSize = (10.5 * scale).clamp(8.5, 16.0);
        final bottomTop = height * 0.82;
        final bottomHeight = height * 0.18;
        final progressBadgeHeight = 27 * scale;

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _DefaultBookCoverPainter()),
              Positioned(
                top: height * 0.12,
                left: width * 0.16,
                right: width * 0.16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'FLOW READ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF168BCB),
                        fontSize: brandSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5 * scale),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3B63C),
                        borderRadius: BorderRadius.circular(1),
                      ),
                      child: SizedBox(width: 28 * scale, height: 1.2 * scale),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: height * 0.245,
                left: width * 0.11,
                right: width * 0.08,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    displayTitle,
                    key: titleTextKey,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF08416D),
                      fontSize: titleSize,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: width * 0.31,
                right: width * 0.23,
                top: height * 0.59,
                child: _TitleDivider(scale: scale),
              ),
              Positioned(
                left: width * 0.31,
                right: width * 0.21,
                top: height * 0.65,
                child: _SmallOrnament(scale: scale),
              ),
              if (showProgressBadge)
                Positioned(
                  left: width * 0.12,
                  top: bottomTop + (bottomHeight - progressBadgeHeight) / 2,
                  child: _DefaultProgressBadge(
                    progressPercent: progressPercent,
                    scale: scale,
                  ),
                ),
              Positioned(
                left: showProgressBadge ? width * 0.41 : width * 0.16,
                right: width * 0.12,
                top: bottomTop + (height * 0.052),
                child: Text(
                  displayAuthor,
                  key: authorTextKey,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.94),
                    fontSize: authorSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _finite(double value, double fallback) {
    return value.isFinite && value > 0 ? value : fallback;
  }
}

class _TitleDivider extends StatelessWidget {
  final double scale;

  const _TitleDivider({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _Line(color: Color(0xFF168BCB))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10 * scale),
          child: Icon(
            Icons.auto_awesome,
            size: 18 * scale,
            color: const Color(0xFFF3B63C),
          ),
        ),
        const Expanded(child: _Line(color: Color(0xFF168BCB))),
      ],
    );
  }
}

class _SmallOrnament extends StatelessWidget {
  final double scale;

  const _SmallOrnament({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.wb_sunny_outlined,
          size: 18 * scale,
          color: const Color(0xFFF3B63C),
        ),
        SizedBox(height: 8 * scale),
        Row(
          children: [
            const Expanded(child: _Line(color: Color(0xFFF3B63C))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14 * scale),
              child: Icon(
                Icons.diamond_outlined,
                size: 12 * scale,
                color: const Color(0xFF168BCB),
              ),
            ),
            const Expanded(child: _Line(color: Color(0xFFF3B63C))),
          ],
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final Color color;

  const _Line({required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1),
      ),
      child: const SizedBox(height: 1.2),
    );
  }
}

class _DefaultProgressBadge extends StatelessWidget {
  final int progressPercent;
  final double scale;

  const _DefaultProgressBadge({
    required this.progressPercent,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFD96B),
        borderRadius: BorderRadius.circular(8 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 7 * scale,
            offset: Offset(0, 2 * scale),
          ),
        ],
      ),
      child: SizedBox(
        width: 46 * scale,
        height: 27 * scale,
        child: Center(
          child: Text(
            '$progressPercent%',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF08416D),
              fontSize: (14 * scale).clamp(11.0, 24.0),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _DefaultBookCoverPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cover = Offset.zero & size;

    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFBF0), Color(0xFFFFF3DD)],
      ).createShader(cover);
    canvas.drawRect(cover, basePaint);

    _paintTopSky(canvas, size);
    _paintClouds(canvas, size);
    _paintBottomBand(canvas, size);
    _paintSpine(canvas, size);
  }

  void _paintTopSky(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.52, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.16)
      ..cubicTo(w * 0.95, h * 0.13, w * 0.90, h * 0.13, w * 0.86, h * 0.17)
      ..cubicTo(w * 0.82, h * 0.10, w * 0.69, h * 0.09, w * 0.66, h * 0.18)
      ..cubicTo(w * 0.62, h * 0.14, w * 0.57, h * 0.15, w * 0.54, h * 0.16)
      ..cubicTo(w * 0.50, h * 0.13, w * 0.51, h * 0.05, w * 0.48, 0)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF75C9F0).withValues(alpha: 0.9),
            const Color(0xFF37A3DB).withValues(alpha: 0.92),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  void _paintClouds(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cloudPaint = Paint()
      ..color = const Color(0xFFE5F4FA).withValues(alpha: 0.84);
    final creamPaint = Paint()..color = const Color(0xFFFFF7E7);

    void cloud(Color color, List<Offset> centers, List<double> radii) {
      final paint = Paint()..color = color;
      for (var i = 0; i < centers.length; i++) {
        canvas.drawCircle(centers[i], radii[i], paint);
      }
    }

    cloud(
      cloudPaint.color,
      [
        Offset(w * 0.88, h * 0.58),
        Offset(w * 0.76, h * 0.66),
        Offset(w * 0.97, h * 0.72),
      ],
      [w * 0.14, w * 0.10, w * 0.18],
    );
    cloud(
      cloudPaint.color.withValues(alpha: 0.72),
      [
        Offset(w * 0.14, h * 0.82),
        Offset(w * 0.27, h * 0.82),
        Offset(w * 0.40, h * 0.86),
        Offset(w * 0.72, h * 0.85),
      ],
      [w * 0.09, w * 0.10, w * 0.08, w * 0.09],
    );
    cloud(
      creamPaint.color,
      [
        Offset(w * 0.72, h * 0.76),
        Offset(w * 0.82, h * 0.72),
        Offset(w * 0.94, h * 0.74),
        Offset(w * 0.64, h * 0.83),
      ],
      [w * 0.12, w * 0.13, w * 0.12, w * 0.10],
    );
  }

  void _paintBottomBand(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final band = Rect.fromLTWH(0, h * 0.82, w, h * 0.18);
    canvas.drawRect(
      band,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2199DA), Color(0xFF0876BF)],
        ).createShader(band),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.975, w, h * 0.025),
      Paint()..color = const Color(0xFF046AAD),
    );
  }

  void _paintSpine(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w * 0.09, h),
      Paint()..color = Colors.white.withValues(alpha: 0.34),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.045, 0, w * 0.018, h),
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.065, h * 0.82, w * 0.028, h * 0.18),
      Paint()..color = const Color(0xFF006DAF).withValues(alpha: 0.28),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

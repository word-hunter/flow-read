import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'city_atmosphere_settings.dart';
import 'city_theme_preset.dart';
import 'city_theme_scope.dart';

class AtmosphereBackground extends StatefulWidget {
  final AtmosphereScene scene;
  final double intensity;
  final bool reduceMotion;
  final AtmospherePerformanceMode performanceMode;
  final Widget child;

  const AtmosphereBackground({
    super.key,
    required this.scene,
    required this.child,
    this.intensity = 0.30,
    this.reduceMotion = false,
    this.performanceMode = AtmospherePerformanceMode.auto,
  });

  @override
  State<AtmosphereBackground> createState() => _AtmosphereBackgroundState();
}

class _AtmosphereBackgroundState extends State<AtmosphereBackground> {
  final ValueNotifier<double> _timeSeconds = ValueNotifier<double>(0);
  late List<_AtmosphereParticle> _stars;
  late List<_AtmosphereParticle> _rain;
  late List<_AtmosphereParticle> _wind;
  Timer? _timer;
  DateTime _startedAt = DateTime.now();

  bool get _hasMotion {
    return !widget.reduceMotion &&
        widget.scene != AtmosphereScene.none &&
        widget.intensity > 0;
  }

  @override
  void initState() {
    super.initState();
    _buildParticles();
    _configureTicker();
  }

  @override
  void didUpdateWidget(AtmosphereBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene != widget.scene ||
        oldWidget.performanceMode != widget.performanceMode) {
      _buildParticles();
    }
    if (oldWidget.scene != widget.scene ||
        oldWidget.reduceMotion != widget.reduceMotion ||
        oldWidget.performanceMode != widget.performanceMode ||
        oldWidget.intensity != widget.intensity) {
      _configureTicker();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timeSeconds.dispose();
    super.dispose();
  }

  void _buildParticles() {
    _stars = _particles(seed: 17, count: 18);
    _rain = _particles(
      seed: 41,
      count: widget.performanceMode == AtmospherePerformanceMode.low ? 36 : 84,
    );
    _wind = _particles(
      seed: 73,
      count: widget.performanceMode == AtmospherePerformanceMode.low ? 6 : 12,
    );
  }

  List<_AtmosphereParticle> _particles({
    required int seed,
    required int count,
  }) {
    final random = math.Random(seed);
    return List.generate(count, (_) {
      return _AtmosphereParticle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        speed: 0.14 + random.nextDouble() * 0.28,
        size: 0.6 + random.nextDouble() * 1.7,
        opacity: 0.10 + random.nextDouble() * 0.20,
        drift: -0.025 + random.nextDouble() * 0.05,
      );
    });
  }

  void _configureTicker() {
    _timer?.cancel();
    _timer = null;
    _timeSeconds.value = 0;
    if (!_hasMotion) return;

    _startedAt = DateTime.now();
    final interval = widget.performanceMode == AtmospherePerformanceMode.low
        ? const Duration(milliseconds: 67)
        : const Duration(milliseconds: 33);
    _timer = Timer.periodic(interval, (_) {
      final elapsed = DateTime.now().difference(_startedAt);
      _timeSeconds.value = elapsed.inMilliseconds / 1000;
    });
  }

  @override
  Widget build(BuildContext context) {
    final preset = CityThemeScope.of(context);
    final scene = _hasMotion ? widget.scene : AtmosphereScene.none;

    return ColoredBox(
      color: preset.pageBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (scene != AtmosphereScene.none)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _timeSeconds,
                    builder: (context, timeSeconds, _) {
                      return CustomPaint(
                        painter: _CityAtmospherePainter(
                          scene: scene,
                          preset: preset,
                          intensity: widget.intensity.clamp(0.0, 1.0),
                          timeSeconds: timeSeconds,
                          stars: _stars,
                          rain: _rain,
                          wind: _wind,
                          lowPower:
                              widget.performanceMode ==
                              AtmospherePerformanceMode.low,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          widget.child,
        ],
      ),
    );
  }
}

class _CityAtmospherePainter extends CustomPainter {
  final AtmosphereScene scene;
  final CityThemePreset preset;
  final double intensity;
  final double timeSeconds;
  final List<_AtmosphereParticle> stars;
  final List<_AtmosphereParticle> rain;
  final List<_AtmosphereParticle> wind;
  final bool lowPower;

  const _CityAtmospherePainter({
    required this.scene,
    required this.preset,
    required this.intensity,
    required this.timeSeconds,
    required this.stars,
    required this.rain,
    required this.wind,
    required this.lowPower,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintBase(canvas, size);
    switch (scene) {
      case AtmosphereScene.cityMorning:
        _paintMorning(canvas, size);
      case AtmosphereScene.cityDay:
        _paintDay(canvas, size);
      case AtmosphereScene.cityDusk:
        _paintDusk(canvas, size);
      case AtmosphereScene.cityMoon:
        _paintMoon(canvas, size);
      case AtmosphereScene.cityRain:
        _paintRain(canvas, size, allowFlash: false);
      case AtmosphereScene.cityWind:
        _paintWind(canvas, size);
      case AtmosphereScene.cityStormHint:
        _paintRain(canvas, size, allowFlash: !lowPower);
      case AtmosphereScene.none:
        break;
    }
  }

  void _paintBase(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          preset.surfaceSoft.withValues(alpha: 0.46 + 0.18 * intensity),
          preset.pageBackground,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _paintMorning(Canvas canvas, Size size) {
    _drawGlow(
      canvas,
      center: Offset(size.width * 0.78, size.height * 0.10),
      radius: size.shortestSide * 0.42,
      color: preset.accent,
      opacity: 0.22,
    );
    _drawCloud(
      canvas,
      size,
      base: Offset(size.width * 0.20, size.height * 0.20),
      speed: 0.018,
      scale: 1.05,
      opacity: 0.22,
    );
    _drawCloud(
      canvas,
      size,
      base: Offset(size.width * 0.62, size.height * 0.31),
      speed: 0.012,
      scale: 0.86,
      opacity: 0.16,
    );
  }

  void _paintDay(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = preset.accent.withValues(alpha: 0.12 * intensity);
    final y = size.height * 0.25;
    final path = Path()
      ..moveTo(0, y)
      ..quadraticBezierTo(size.width * 0.25, y - 24, size.width * 0.5, y)
      ..quadraticBezierTo(size.width * 0.75, y + 18, size.width, y - 8);
    canvas.drawPath(path, paint);

    _drawGlow(
      canvas,
      center: Offset(size.width * 0.18, size.height * 0.12),
      radius: size.shortestSide * 0.34,
      color: preset.accent,
      opacity: 0.10,
    );
  }

  void _paintDusk(Canvas canvas, Size size) {
    _drawGlow(
      canvas,
      center: Offset(size.width * 0.18, size.height * 0.16),
      radius: size.shortestSide * 0.52,
      color: preset.accent,
      opacity: 0.20,
    );
    _drawCloud(
      canvas,
      size,
      base: Offset(size.width * 0.66, size.height * 0.24),
      speed: -0.010,
      scale: 1.18,
      opacity: 0.15,
    );
  }

  void _paintMoon(Canvas canvas, Size size) {
    final moonCenter = Offset(size.width * 0.80, size.height * 0.14);
    _drawGlow(
      canvas,
      center: moonCenter,
      radius: size.shortestSide * 0.22,
      color: preset.accent,
      opacity: 0.11,
    );
    final moonPaint = Paint()
      ..color = preset.primaryText.withValues(alpha: 0.16 + 0.08 * intensity);
    canvas.drawCircle(moonCenter, 26, moonPaint);
    canvas.drawCircle(
      moonCenter.translate(-8, -4),
      24,
      Paint()..color = preset.pageBackground.withValues(alpha: 0.72),
    );

    final starPaint = Paint();
    for (final particle in stars) {
      final twinkle =
          0.65 + 0.35 * math.sin(timeSeconds * particle.speed + particle.x);
      starPaint.color = preset.accent.withValues(
        alpha: particle.opacity * intensity * twinkle,
      );
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height * 0.42),
        particle.size,
        starPaint,
      );
    }
    _drawCloud(
      canvas,
      size,
      base: Offset(size.width * 0.28, size.height * 0.25),
      speed: 0.008,
      scale: 1.0,
      opacity: 0.10,
    );
  }

  void _paintRain(Canvas canvas, Size size, {required bool allowFlash}) {
    _drawCloud(
      canvas,
      size,
      base: Offset(size.width * 0.58, size.height * 0.16),
      speed: 0.006,
      scale: 1.18,
      opacity: 0.15,
    );
    final paint = Paint()
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    for (final particle in rain) {
      final y =
          ((particle.y + timeSeconds * particle.speed * 0.05) % 1.0) *
          size.height;
      final x = (particle.x + particle.drift * timeSeconds * 0.12) % 1.0;
      final start = Offset(x * size.width, y);
      paint.color = preset.secondaryText.withValues(
        alpha: particle.opacity * intensity * 0.82,
      );
      canvas.drawLine(
        start,
        start.translate(-8, 14 + particle.size * 4),
        paint,
      );
    }
    if (allowFlash) {
      final cycle = (timeSeconds % 58) / 58;
      if (cycle > 0.965) {
        final flash = math.sin((cycle - 0.965) / 0.035 * math.pi);
        canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.08 * flash * intensity),
        );
      }
    }
  }

  void _paintWind(Canvas canvas, Size size) {
    _drawCloud(
      canvas,
      size,
      base: Offset(size.width * 0.18, size.height * 0.18),
      speed: 0.026,
      scale: 1.02,
      opacity: 0.14,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..color = preset.secondaryText.withValues(alpha: 0.12 * intensity);
    for (var i = 0; i < 4; i += 1) {
      final y = size.height * (0.18 + i * 0.10);
      final offset = (timeSeconds * 12 + i * 70) % (size.width + 120) - 120;
      final path = Path()
        ..moveTo(offset, y)
        ..quadraticBezierTo(offset + 58, y - 10, offset + 112, y + 2);
      canvas.drawPath(path, paint);
    }
    final leafPaint = Paint()..color = preset.accent.withValues(alpha: 0.16);
    for (final particle in wind) {
      final x =
          ((particle.x + timeSeconds * particle.speed * 0.018) % 1.0) *
          size.width;
      final y = particle.y * size.height * 0.62 + size.height * 0.08;
      final rect = Rect.fromCenter(
        center: Offset(x, y),
        width: 4 + particle.size * 2,
        height: 2 + particle.size,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        leafPaint,
      );
    }
  }

  void _drawGlow(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    required double opacity,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: opacity * intensity),
          color.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.drawCircle(center, radius, paint);
  }

  void _drawCloud(
    Canvas canvas,
    Size size, {
    required Offset base,
    required double speed,
    required double scale,
    required double opacity,
  }) {
    final x = (base.dx + timeSeconds * speed * size.width) % (size.width + 180);
    final center = Offset(x - 90, base.dy);
    final paint = Paint()
      ..color = preset.surface.withValues(alpha: opacity * intensity);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: 120 * scale,
        height: 34 * scale,
      ),
      paint,
    );
    canvas.drawCircle(
      center.translate(-26 * scale, -8 * scale),
      24 * scale,
      paint,
    );
    canvas.drawCircle(
      center.translate(18 * scale, -12 * scale),
      30 * scale,
      paint,
    );
    canvas.drawCircle(
      center.translate(54 * scale, -4 * scale),
      19 * scale,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CityAtmospherePainter oldDelegate) {
    return oldDelegate.scene != scene ||
        oldDelegate.preset.id != preset.id ||
        oldDelegate.intensity != intensity ||
        oldDelegate.timeSeconds != timeSeconds ||
        oldDelegate.lowPower != lowPower ||
        oldDelegate.stars != stars ||
        oldDelegate.rain != rain ||
        oldDelegate.wind != wind;
  }
}

class _AtmosphereParticle {
  final double x;
  final double y;
  final double speed;
  final double size;
  final double opacity;
  final double drift;

  const _AtmosphereParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.drift,
  });
}

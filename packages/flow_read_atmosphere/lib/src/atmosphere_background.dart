import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'atmosphere_palette.dart';
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

  bool get _shouldPaint {
    return widget.scene != AtmosphereScene.none && widget.intensity > 0;
  }

  bool get _hasMotion {
    return _shouldPaint && !widget.reduceMotion;
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
    _stars = _particles(
      seed: 17,
      count: widget.performanceMode == AtmospherePerformanceMode.low ? 24 : 48,
    );
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
    final scene = _shouldPaint ? widget.scene : AtmosphereScene.none;

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

  static const _landscapeGrassBright = Color(0xFF9BE45C);
  static const _landscapeGrassMid = Color(0xFF79C84A);
  static const _landscapeGrassDark = Color(0xFF3E8F4D);
  static const _landscapeTreeGreen = Color(0xFF38A65C);
  static const _landscapeTreeDark = Color(0xFF2F7F4A);

  static const _landscapeTufts = <_LandscapeAccent>[
    _LandscapeAccent(0.06, 0.89, 0.80, 0.2, 0),
    _LandscapeAccent(0.12, 0.82, 0.72, 1.4, 1),
    _LandscapeAccent(0.19, 0.93, 0.92, 2.1, 0),
    _LandscapeAccent(0.28, 0.86, 0.76, 0.7, 1),
    _LandscapeAccent(0.36, 0.95, 0.84, 2.9, 0),
    _LandscapeAccent(0.48, 0.84, 0.70, 1.8, 1),
    _LandscapeAccent(0.57, 0.91, 0.88, 0.4, 0),
    _LandscapeAccent(0.66, 0.80, 0.64, 2.5, 1),
    _LandscapeAccent(0.73, 0.94, 0.92, 1.1, 0),
    _LandscapeAccent(0.82, 0.86, 0.78, 2.8, 1),
    _LandscapeAccent(0.90, 0.92, 0.86, 0.9, 0),
    _LandscapeAccent(0.96, 0.83, 0.68, 2.0, 1),
  ];

  static const _landscapeFlowers = <_LandscapeAccent>[
    _LandscapeAccent(0.10, 0.90, 0.74, 0.5, 0),
    _LandscapeAccent(0.22, 0.84, 0.58, 2.0, 1),
    _LandscapeAccent(0.31, 0.94, 0.68, 1.1, 2),
    _LandscapeAccent(0.51, 0.87, 0.62, 2.5, 0),
    _LandscapeAccent(0.61, 0.96, 0.72, 1.6, 2),
    _LandscapeAccent(0.78, 0.89, 0.64, 0.8, 1),
    _LandscapeAccent(0.88, 0.83, 0.58, 2.9, 0),
    _LandscapeAccent(0.94, 0.95, 0.66, 1.9, 2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (scene != AtmosphereScene.cityLandscapeDay) {
      _paintBase(canvas, size);
    }
    switch (scene) {
      case AtmosphereScene.cityMorning:
        _paintMorning(canvas, size);
      case AtmosphereScene.cityDay:
        _paintDay(canvas, size);
      case AtmosphereScene.cityLandscapeDay:
        _paintCityLandscapeDay(canvas, size);
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
    final horizonY = _horizonY(size);
    final skyRect = Rect.fromLTRB(0, 0, size.width, horizonY + 28);
    final grassRect = Rect.fromLTRB(
      0,
      horizonY - 18,
      size.width,
      size.height,
    );

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _skyColors(),
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    _drawDistantHills(canvas, size, horizonY);

    final grassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _grassColors(),
      ).createShader(grassRect);
    canvas.drawRect(grassRect, grassPaint);

    _drawHorizon(canvas, size, horizonY);
  }

  void _paintMorning(Canvas canvas, Size size) {
    _drawSun(
      canvas,
      center: Offset(size.width * 0.22, size.height * 0.18),
      radius: 30,
      opacity: 0.78,
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
    _drawSun(
      canvas,
      center: Offset(size.width * 0.78, size.height * 0.15),
      radius: 34,
      opacity: 0.88,
    );
    _drawCloud(
      canvas,
      size,
      base: Offset(size.width * 0.18, size.height * 0.20),
      speed: 0.010,
      scale: 0.92,
      opacity: 0.18,
    );
  }

  void _paintCityLandscapeDay(Canvas canvas, Size size) {
    final palette = AtmospherePalette.cityLandscapeDay;
    final horizonY = _landscapeHorizonY(size);
    final grassPath = _landscapeGrassPath(size, horizonY);

    _drawLandscapeSky(canvas, size, palette);
    _drawLandscapeSun(canvas, size, palette);
    _drawLandscapeDistantLine(canvas, size, horizonY, palette);
    _drawLandscapeClouds(canvas, size, palette);
    _drawLandscapeGrass(canvas, size, horizonY, grassPath);
    _drawLandscapeDetails(canvas, size, grassPath, palette);
    _drawLandscapePaperWash(canvas, size, palette);
  }

  void _drawLandscapeSky(
    Canvas canvas,
    Size size,
    AtmospherePalette palette,
  ) {
    final rect = Offset.zero & size;
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          palette.sky,
          palette.skySoft,
          const Color(0xFFBDEBFF),
        ],
        stops: const [0, 0.58, 1],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);
  }

  void _drawLandscapeSun(
    Canvas canvas,
    Size size,
    AtmospherePalette palette,
  ) {
    final center = Offset(size.width * 0.82, size.height * 0.14);
    final radius = size.shortestSide.clamp(280, 720).toDouble() * 0.055;
    final glowRect = Rect.fromCircle(center: center, radius: radius * 3.2);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.sunlight.withValues(alpha: 0.38 + intensity * 0.24),
          palette.sunlight.withValues(alpha: 0),
        ],
      ).createShader(glowRect);
    canvas.drawCircle(center, radius * 3.2, glowPaint);
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = palette.sunlight.withValues(alpha: 0.90),
    );
    canvas.drawCircle(
      center,
      radius + 7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.42),
    );
  }

  void _drawLandscapeDistantLine(
    Canvas canvas,
    Size size,
    double horizonY,
    AtmospherePalette palette,
  ) {
    final baseY = horizonY + size.height * 0.026;
    final buildingPaint = Paint()
      ..color = palette.ink.withValues(alpha: 0.10 + intensity * 0.08);
    final buildingStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = palette.ink.withValues(alpha: 0.14 + intensity * 0.06);

    const buildings = <_LandscapeBuilding>[
      _LandscapeBuilding(0.08, 0.050, 0.040, true),
      _LandscapeBuilding(0.16, 0.060, 0.058, false),
      _LandscapeBuilding(0.25, 0.047, 0.044, true),
      _LandscapeBuilding(0.69, 0.055, 0.052, false),
      _LandscapeBuilding(0.78, 0.046, 0.038, true),
      _LandscapeBuilding(0.87, 0.064, 0.060, false),
    ];
    for (final building in buildings) {
      final left = size.width * building.x;
      final width = size.width * building.width;
      final height = size.height * building.height;
      final rect = Rect.fromLTWH(left, baseY - height, width, height);
      canvas.drawRect(rect, buildingPaint);
      canvas.drawRect(rect, buildingStroke);
      if (building.roof) {
        final roof = Path()
          ..moveTo(left - width * 0.08, baseY - height)
          ..lineTo(left + width * 0.50, baseY - height - height * 0.34)
          ..lineTo(left + width * 1.08, baseY - height)
          ..close();
        canvas.drawPath(roof, buildingPaint);
        canvas.drawPath(roof, buildingStroke);
      }
    }

    final treePaint = Paint()
      ..color = _landscapeTreeGreen.withValues(alpha: 0.28 + intensity * 0.18);
    final treeDarkPaint = Paint()
      ..color = _landscapeTreeDark.withValues(alpha: 0.18 + intensity * 0.16);
    const trees = <_LandscapeAccent>[
      _LandscapeAccent(0.02, 0, 0.75, 0, 0),
      _LandscapeAccent(0.34, 0, 0.62, 0, 1),
      _LandscapeAccent(0.40, 0, 0.82, 0, 0),
      _LandscapeAccent(0.46, 0, 0.58, 0, 1),
      _LandscapeAccent(0.56, 0, 0.72, 0, 0),
      _LandscapeAccent(0.62, 0, 0.64, 0, 1),
      _LandscapeAccent(0.95, 0, 0.78, 0, 0),
    ];
    for (final tree in trees) {
      final center = Offset(size.width * tree.x, baseY - 8 * tree.scale);
      final radius = 22 * tree.scale;
      canvas.drawCircle(
        center.translate(-8 * tree.scale, 2),
        radius,
        treePaint,
      );
      canvas.drawCircle(
        center.translate(9 * tree.scale, -2),
        radius * 0.88,
        treeDarkPaint,
      );
      canvas.drawCircle(
        center.translate(21 * tree.scale, 4),
        radius * 0.74,
        treePaint,
      );
    }

    canvas.drawLine(
      Offset(0, baseY),
      Offset(size.width, baseY),
      Paint()
        ..strokeWidth = 1.1
        ..color = palette.ink.withValues(alpha: 0.10 + intensity * 0.06),
    );
  }

  void _drawLandscapeClouds(
    Canvas canvas,
    Size size,
    AtmospherePalette palette,
  ) {
    final drift = timeSeconds * size.width / 78;
    _drawLandscapeCloud(
      canvas,
      palette,
      Offset(
        _loopX(size.width * 0.16 + drift, size.width, 170),
        size.height * 0.14,
      ),
      scale: 1.10,
      outlineOpacity: 0.58,
    );
    _drawLandscapeCloud(
      canvas,
      palette,
      Offset(
        _loopX(size.width * 0.68 + drift * 0.70, size.width, 150),
        size.height * 0.21,
      ),
      scale: 0.82,
      outlineOpacity: 0.50,
    );
    _drawLandscapeCloud(
      canvas,
      palette,
      Offset(
        _loopX(size.width * 0.43 - drift * 0.45, size.width, 130),
        size.height * 0.32,
      ),
      scale: 0.58,
      outlineOpacity: 0.42,
    );
    _drawLandscapeCloud(
      canvas,
      palette,
      Offset(
        _loopX(size.width * 0.92 + drift * 0.36, size.width, 120),
        size.height * 0.10,
      ),
      scale: 0.52,
      outlineOpacity: 0.38,
    );
    _drawLandscapeWindCloud(
      canvas,
      palette,
      Offset(
        _loopX(size.width * 0.56 + drift * 0.28, size.width, 180),
        size.height * 0.38,
      ),
      scale: 0.74,
    );
  }

  void _drawLandscapeCloud(
    Canvas canvas,
    AtmospherePalette palette,
    Offset center, {
    required double scale,
    required double outlineOpacity,
  }) {
    final s = scale;
    final path = Path()
      ..moveTo(center.dx - 76 * s, center.dy + 18 * s)
      ..cubicTo(
        center.dx - 84 * s,
        center.dy + 4 * s,
        center.dx - 66 * s,
        center.dy - 7 * s,
        center.dx - 48 * s,
        center.dy - 3 * s,
      )
      ..cubicTo(
        center.dx - 41 * s,
        center.dy - 24 * s,
        center.dx - 12 * s,
        center.dy - 32 * s,
        center.dx + 6 * s,
        center.dy - 17 * s,
      )
      ..cubicTo(
        center.dx + 21 * s,
        center.dy - 35 * s,
        center.dx + 51 * s,
        center.dy - 25 * s,
        center.dx + 53 * s,
        center.dy - 5 * s,
      )
      ..cubicTo(
        center.dx + 77 * s,
        center.dy - 4 * s,
        center.dx + 86 * s,
        center.dy + 16 * s,
        center.dx + 66 * s,
        center.dy + 25 * s,
      )
      ..lineTo(center.dx - 60 * s, center.dy + 25 * s)
      ..cubicTo(
        center.dx - 72 * s,
        center.dy + 25 * s,
        center.dx - 80 * s,
        center.dy + 22 * s,
        center.dx - 76 * s,
        center.dy + 18 * s,
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = palette.cloud.withValues(alpha: 0.78 + intensity * 0.18),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1 * s.clamp(0.70, 1.40).toDouble()
        ..strokeCap = StrokeCap.round
        ..color = palette.ink.withValues(
          alpha: outlineOpacity * (0.70 + intensity * 0.28),
        ),
    );
  }

  void _drawLandscapeWindCloud(
    Canvas canvas,
    AtmospherePalette palette,
    Offset center, {
    required double scale,
  }) {
    final rect = Rect.fromCenter(
      center: center,
      width: 160 * scale,
      height: 20 * scale,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(16 * scale));
    canvas.drawRRect(
      rrect,
      Paint()..color = palette.cloud.withValues(alpha: 0.36 + intensity * 0.16),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = palette.ink.withValues(alpha: 0.18 + intensity * 0.10),
    );
  }

  void _drawLandscapeGrass(
    Canvas canvas,
    Size size,
    double horizonY,
    Path grassPath,
  ) {
    final grassRect = Rect.fromLTRB(
      0,
      horizonY - size.height * 0.08,
      size.width,
      size.height,
    );
    canvas.drawPath(
      grassPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_landscapeGrassBright, _landscapeGrassMid],
        ).createShader(grassRect),
    );

    final lowerPath = Path()
      ..moveTo(0, horizonY + size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.34,
        horizonY + size.height * 0.08,
        size.width * 0.70,
        horizonY + size.height * 0.20,
      )
      ..quadraticBezierTo(
        size.width * 0.90,
        horizonY + size.height * 0.27,
        size.width,
        horizonY + size.height * 0.18,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      lowerPath,
      Paint()
        ..color = _landscapeGrassDark.withValues(
          alpha: 0.12 + intensity * 0.08,
        ),
    );

    final crestPath = _landscapeGrassCrestPath(size, horizonY);
    canvas.drawPath(
      crestPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = _landscapeGrassDark.withValues(
          alpha: 0.18 + intensity * 0.10,
        ),
    );
  }

  void _drawLandscapeDetails(
    Canvas canvas,
    Size size,
    Path grassPath,
    AtmospherePalette palette,
  ) {
    canvas.save();
    canvas.clipPath(grassPath);

    final bladePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..color = _landscapeGrassDark.withValues(alpha: 0.30 + intensity * 0.24);
    for (var i = 0; i < _landscapeTufts.length; i += 1) {
      final tuft = _landscapeTufts[i];
      final base = Offset(size.width * tuft.x, size.height * tuft.y);
      final sway =
          math.sin(timeSeconds * math.pi * 2 / 14 + tuft.phase) *
          2.2 *
          intensity;
      bladePaint.strokeWidth = 1.0 + tuft.scale * 0.35;
      for (var blade = -1; blade <= 1; blade += 1) {
        final bladeOffset = blade * 4.0 * tuft.scale;
        final height = (12 + blade.abs() * 3 + i % 3 * 2) * tuft.scale;
        canvas.drawLine(
          base.translate(bladeOffset, 0),
          base.translate(bladeOffset + sway + blade * 2.2, -height),
          bladePaint,
        );
      }
    }

    for (final flower in _landscapeFlowers) {
      final center = Offset(size.width * flower.x, size.height * flower.y);
      final sway =
          math.sin(timeSeconds * math.pi * 2 / 16 + flower.phase) *
          1.4 *
          intensity;
      _drawLandscapeFlower(
        canvas,
        center.translate(sway, 0),
        flower.scale,
        flower.variant,
        palette,
      );
    }

    canvas.restore();
  }

  void _drawLandscapeFlower(
    Canvas canvas,
    Offset center,
    double scale,
    int variant,
    AtmospherePalette palette,
  ) {
    final stemPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.9
      ..color = _landscapeGrassDark.withValues(alpha: 0.34 + intensity * 0.18);
    canvas.drawLine(center.translate(0, 6 * scale), center, stemPaint);

    if (variant == 2) {
      final dotPaint = Paint()
        ..color = palette.paper.withValues(alpha: 0.78 + intensity * 0.16);
      for (var i = 0; i < 6; i += 1) {
        final angle = i * math.pi / 3;
        canvas.drawCircle(
          center.translate(
            math.cos(angle) * 4.2 * scale,
            math.sin(angle) * 4.2 * scale,
          ),
          1.2 * scale,
          dotPaint,
        );
      }
      canvas.drawCircle(
        center,
        1.2 * scale,
        Paint()..color = palette.ink.withValues(alpha: 0.18),
      );
      return;
    }

    final petalPaint = Paint()
      ..color = (variant == 0 ? palette.coral : palette.mint).withValues(
        alpha: 0.74 + intensity * 0.18,
      );
    for (var i = 0; i < 5; i += 1) {
      final angle = i * math.pi * 2 / 5;
      canvas.drawCircle(
        center.translate(
          math.cos(angle) * 3.2 * scale,
          math.sin(angle) * 3.2 * scale,
        ),
        2.2 * scale,
        petalPaint,
      );
    }
    canvas.drawCircle(
      center,
      1.8 * scale,
      Paint()..color = palette.sunlight.withValues(alpha: 0.86),
    );
  }

  void _drawLandscapePaperWash(
    Canvas canvas,
    Size size,
    AtmospherePalette palette,
  ) {
    final washOpacity = (0.06 + (1 - intensity) * 0.045)
        .clamp(0.06, 0.12)
        .toDouble();
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = palette.paper.withValues(alpha: washOpacity),
    );
  }

  double _landscapeHorizonY(Size size) {
    return size.height * (size.width < 640 ? 0.72 : 0.68);
  }

  Path _landscapeGrassPath(Size size, double horizonY) {
    return _landscapeGrassCrestPath(size, horizonY)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  Path _landscapeGrassCrestPath(Size size, double horizonY) {
    return Path()
      ..moveTo(0, horizonY + size.height * 0.045)
      ..quadraticBezierTo(
        size.width * 0.35,
        horizonY - size.height * 0.055,
        size.width * 0.72,
        horizonY + size.height * 0.020,
      )
      ..quadraticBezierTo(
        size.width * 0.92,
        horizonY + size.height * 0.060,
        size.width,
        horizonY,
      );
  }

  double _loopX(double x, double width, double padding) {
    final span = width + padding * 2;
    return (x + padding) % span - padding;
  }

  void _paintDusk(Canvas canvas, Size size) {
    _drawSun(
      canvas,
      center: Offset(size.width * 0.22, _horizonY(size) - 24),
      radius: 36,
      opacity: 0.82,
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
    _drawMoon(canvas, center: moonCenter, radius: 28);

    final starPaint = Paint();
    for (final particle in stars) {
      final twinkle =
          0.65 + 0.35 * math.sin(timeSeconds * particle.speed + particle.x);
      starPaint.color = Colors.white.withValues(
        alpha: (0.12 + particle.opacity * intensity) * twinkle,
      );
      canvas.drawCircle(
        Offset(
          particle.x * size.width,
          particle.y * _horizonY(size) * 0.74 + 12,
        ),
        particle.size + 0.5,
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

  double _horizonY(Size size) {
    return size.height * (size.width < 640 ? 0.70 : 0.66);
  }

  List<Color> _skyColors() {
    return switch (preset.phase) {
      CityTimePhase.dawn => const [
        Color(0xFFBDE9FF),
        Color(0xFFEAF8FF),
        Color(0xFFFFF0BE),
      ],
      CityTimePhase.day => const [
        Color(0xFF8ED8FF),
        Color(0xFFDDF6FF),
        Color(0xFFFFF9D8),
      ],
      CityTimePhase.dusk => const [
        Color(0xFF7EA4D8),
        Color(0xFFF2B08B),
        Color(0xFFFFE0B1),
      ],
      CityTimePhase.night => const [
        Color(0xFF111C33),
        Color(0xFF1D3155),
        Color(0xFF274A64),
      ],
    };
  }

  List<Color> _grassColors() {
    return switch (preset.phase) {
      CityTimePhase.dawn => const [
        Color(0xFFC8EAA9),
        Color(0xFF86BD6E),
      ],
      CityTimePhase.day => const [
        Color(0xFFB7E88D),
        Color(0xFF5EA95A),
      ],
      CityTimePhase.dusk => const [
        Color(0xFFC8D37C),
        Color(0xFF6F9656),
      ],
      CityTimePhase.night => const [
        Color(0xFF395B3C),
        Color(0xFF203D2E),
      ],
    };
  }

  void _drawDistantHills(Canvas canvas, Size size, double horizonY) {
    final hillColor = switch (preset.phase) {
      CityTimePhase.night => const Color(0xFF233E42),
      CityTimePhase.dusk => const Color(0xFF8EA060),
      _ => const Color(0xFF8BC77B),
    };
    final paint = Paint()..color = hillColor.withValues(alpha: 0.42);
    final backPath = Path()
      ..moveTo(0, horizonY + 6)
      ..quadraticBezierTo(
        size.width * 0.20,
        horizonY - 34,
        size.width * 0.42,
        horizonY + 2,
      )
      ..quadraticBezierTo(
        size.width * 0.62,
        horizonY - 30,
        size.width,
        horizonY + 4,
      )
      ..lineTo(size.width, horizonY + 38)
      ..lineTo(0, horizonY + 38)
      ..close();
    canvas.drawPath(backPath, paint);
  }

  void _drawHorizon(Canvas canvas, Size size, double horizonY) {
    final paint = Paint()
      ..color = Colors.white.withValues(
        alpha: preset.phase == CityTimePhase.night ? 0.06 : 0.22,
      )
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, horizonY), Offset(size.width, horizonY), paint);
  }

  void _drawSun(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double opacity,
  }) {
    _drawGlow(
      canvas,
      center: center,
      radius: radius * 4.2,
      color: const Color(0xFFFFD66E),
      opacity: 0.58 * opacity,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFFFD966).withValues(
          alpha: (0.72 + 0.20 * intensity) * opacity,
        ),
    );
    canvas.drawCircle(
      center,
      radius + 8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFFFF4B8).withValues(alpha: 0.34 * opacity),
    );
  }

  void _drawMoon(
    Canvas canvas, {
    required Offset center,
    required double radius,
  }) {
    _drawGlow(
      canvas,
      center: center,
      radius: radius * 3.6,
      color: const Color(0xFFFFF2B8),
      opacity: 0.48,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFFFF1B8).withValues(
          alpha: 0.76 + 0.16 * intensity,
        ),
    );
    canvas.drawCircle(
      center.translate(-9, -4),
      radius * 0.92,
      Paint()..color = const Color(0xFF16243D).withValues(alpha: 0.86),
    );
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

class _LandscapeAccent {
  final double x;
  final double y;
  final double scale;
  final double phase;
  final int variant;

  const _LandscapeAccent(
    this.x,
    this.y,
    this.scale,
    this.phase,
    this.variant,
  );
}

class _LandscapeBuilding {
  final double x;
  final double width;
  final double height;
  final bool roof;

  const _LandscapeBuilding(this.x, this.width, this.height, this.roof);
}

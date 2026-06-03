import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/reading_provider.dart';

typedef WordMasteryAnchorBuilder =
    Widget Function(BuildContext context, Offset? Function() origin);

class WordMasteryActionAnchor extends StatefulWidget {
  const WordMasteryActionAnchor({super.key, required this.builder});

  final WordMasteryAnchorBuilder builder;

  @override
  State<WordMasteryActionAnchor> createState() =>
      _WordMasteryActionAnchorState();
}

class _WordMasteryActionAnchorState extends State<WordMasteryActionAnchor> {
  final _anchorKey = GlobalKey();

  Offset? _origin() {
    final renderObject = _anchorKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.localToGlobal(renderObject.size.center(Offset.zero));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(key: _anchorKey, child: widget.builder(context, _origin));
  }
}

class WordMasteryConfettiHost extends StatefulWidget {
  const WordMasteryConfettiHost({super.key, required this.child});

  final Widget child;

  @override
  State<WordMasteryConfettiHost> createState() =>
      _WordMasteryConfettiHostState();
}

class _WordMasteryConfettiHostState extends State<WordMasteryConfettiHost> {
  late final ConfettiController _controller;
  int _lastCelebrationTick = 0;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final celebration = context
        .select<ReadingProvider, ({int tick, Offset? origin})>(
          (provider) => (
            tick: provider.wordMasteredCelebrationTick,
            origin: provider.wordMasteredCelebrationOrigin,
          ),
        );
    if (celebration.tick != _lastCelebrationTick) {
      _lastCelebrationTick = celebration.tick;
      if (celebration.tick > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _controller.play();
        });
      }
    }

    final theme = Theme.of(context);
    final mediaSize = MediaQuery.sizeOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : mediaSize.width;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : mediaSize.height;
        final origin = _localOrigin(
          celebration.origin,
          Size(width, height),
          MediaQuery.paddingOf(context),
          context,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            Positioned(
              left: origin.dx,
              top: origin.dy,
              child: IgnorePointer(
                child: SizedBox.square(
                  dimension: 1,
                  child: ConfettiWidget(
                    confettiController: _controller,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    emissionFrequency: 0,
                    numberOfParticles: 22,
                    minBlastForce: 8,
                    maxBlastForce: 18,
                    gravity: 0.18,
                    particleDrag: 0.08,
                    createParticlePath: buildWordMasteryStarPath,
                    colors: buildWordMasteryStarColors(theme.colorScheme),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Offset _localOrigin(
    Offset? globalOrigin,
    Size size,
    EdgeInsets padding,
    BuildContext layoutContext,
  ) {
    Offset local;
    final stackRenderObject = layoutContext.findRenderObject();
    if (globalOrigin != null &&
        stackRenderObject is RenderBox &&
        stackRenderObject.hasSize) {
      local = stackRenderObject.globalToLocal(globalOrigin);
    } else {
      local = Offset(size.width / 2, padding.top + size.height * 0.18);
    }

    final maxX = (size.width - 16).clamp(16.0, double.infinity).toDouble();
    final maxY = (size.height - 16).clamp(16.0, double.infinity).toDouble();
    return Offset(
      local.dx.clamp(16.0, maxX).toDouble(),
      local.dy.clamp(16.0, maxY).toDouble(),
    );
  }
}

Path buildWordMasteryStarPath(Size size) {
  final smallestSide = math.min(size.width, size.height);
  final outerRadius = smallestSide / 2;
  final innerRadius = outerRadius * 0.46;
  final center = Offset(size.width / 2, size.height / 2);
  final path = Path();

  for (var i = 0; i < 10; i += 1) {
    final radius = i.isEven ? outerRadius : innerRadius;
    final angle = -math.pi / 2 + i * math.pi / 5;
    final point = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }

  return path..close();
}

List<Color> buildWordMasteryStarColors(ColorScheme colorScheme) {
  final stops = [
    colorScheme.primary,
    colorScheme.tertiary,
    colorScheme.secondary,
  ];
  return [for (var i = 0; i < 9; i += 1) _sampleColorGradient(stops, i / 8)];
}

Color _sampleColorGradient(List<Color> stops, double value) {
  final scaled = value.clamp(0.0, 1.0) * (stops.length - 1);
  final startIndex = scaled.floor().clamp(0, stops.length - 2);
  final endIndex = startIndex + 1;
  final localValue = scaled - startIndex;
  return Color.lerp(stops[startIndex], stops[endIndex], localValue)!;
}

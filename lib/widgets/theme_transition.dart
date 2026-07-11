import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef ThemeMutation = Future<void> Function();

const _themeRevealDuration = Duration(milliseconds: 280);
const _reducedMotionDuration = Duration(milliseconds: 100);
const _themeRevealCurve = Cubic(0.23, 1, 0.32, 1);

class ThemeTransitionController {
  _ThemeTransitionHostState? _state;

  Future<void> run(ThemeMutation mutation, {bool reduceMotion = false}) {
    final state = _state;
    if (state == null || !state.mounted) return mutation();
    return state.run(mutation, reduceMotion: reduceMotion);
  }
}

class ThemeTransitionHost extends StatefulWidget {
  final Widget child;
  final bool reduceMotion;

  const ThemeTransitionHost({
    super.key,
    required this.child,
    this.reduceMotion = false,
  });

  @override
  State<ThemeTransitionHost> createState() => _ThemeTransitionHostState();
}

class ThemeTransitionScope extends InheritedWidget {
  final ThemeTransitionController controller;

  const ThemeTransitionScope({
    required this.controller,
    required super.child,
    super.key,
  });

  static ThemeTransitionController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ThemeTransitionScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(ThemeTransitionScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

class _ThemeTransitionHostState extends State<ThemeTransitionHost>
    with SingleTickerProviderStateMixin {
  final _boundaryKey = GlobalKey();
  final _transitionController = ThemeTransitionController();
  late final AnimationController _controller;
  ui.Image? _snapshot;
  bool _activeReduceMotion = false;

  @override
  void initState() {
    super.initState();
    _transitionController._state = this;
    _controller = AnimationController(
      vsync: this,
      duration: _themeRevealDuration,
    );
  }

  @override
  void dispose() {
    _transitionController._state = null;
    _controller.dispose();
    _disposeSnapshot();
    super.dispose();
  }

  Future<void> run(
    ThemeMutation mutation, {
    bool reduceMotion = false,
  }) async {
    final image = await _captureCurrentFrame();
    if (image == null) {
      await mutation();
      return;
    }

    _controller.stop();
    _controller.value = 0;
    _activeReduceMotion = widget.reduceMotion || reduceMotion;
    _controller.duration = _activeReduceMotion
        ? _reducedMotionDuration
        : _themeRevealDuration;
    _disposeSnapshot();

    setState(() {
      _snapshot = image;
    });

    await WidgetsBinding.instance.endOfFrame;
    Object? error;
    StackTrace? stackTrace;
    try {
      await mutation();
    } catch (e, st) {
      error = e;
      stackTrace = st;
    }

    if (mounted) {
      await _controller.forward(from: 0);
      if (mounted) {
        setState(_disposeSnapshot);
      }
    }

    if (error != null) {
      Error.throwWithStackTrace(error, stackTrace!);
    }
  }

  Future<ui.Image?> _captureCurrentFrame() async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return null;
      final renderObject = _boundaryKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) return null;
      if (renderObject.size.isEmpty) return null;
      final pixelRatio = View.of(context).devicePixelRatio;
      return renderObject.toImage(pixelRatio: pixelRatio);
    } catch (_) {
      return null;
    }
  }

  void _disposeSnapshot() {
    _snapshot?.dispose();
    _snapshot = null;
  }

  @override
  Widget build(BuildContext context) {
    return ThemeTransitionScope(
      controller: _transitionController,
      child: Stack(
        alignment: Alignment.topLeft,
        fit: StackFit.expand,
        children: [
          RepaintBoundary(key: _boundaryKey, child: widget.child),
          if (_snapshot != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    if (_activeReduceMotion) {
                      return Opacity(
                        opacity: 1 - _controller.value,
                        child: child,
                      );
                    }
                    final progress = _themeRevealCurve.transform(
                      _controller.value,
                    );
                    final edgePosition = -0.18 + progress * 2.36;
                    final fade = Curves.easeOutQuad.transform(
                      _controller.value,
                    );
                    return ClipPath(
                      clipper: _DiagonalRevealClipper(edgePosition),
                      child: Opacity(opacity: 1 - fade * 0.14, child: child),
                    );
                  },
                  child: RawImage(image: _snapshot, fit: BoxFit.fill),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiagonalRevealClipper extends CustomClipper<Path> {
  final double edgePosition;

  const _DiagonalRevealClipper(this.edgePosition);

  @override
  Path getClip(Size size) {
    final width = size.width;
    final height = size.height;
    if (width <= 0 || height <= 0) return Path();

    if (edgePosition <= 0) {
      return Path()..addRect(Offset.zero & size);
    }
    if (edgePosition >= 2) return Path();

    if (edgePosition <= 1) {
      final topX = edgePosition * width;
      final leftY = edgePosition * height;
      return Path()
        ..moveTo(topX, 0)
        ..lineTo(width, 0)
        ..lineTo(width, height)
        ..lineTo(0, height)
        ..lineTo(0, leftY)
        ..close();
    }

    final rightY = (edgePosition - 1) * height;
    final bottomX = (edgePosition - 1) * width;
    return Path()
      ..moveTo(width, rightY)
      ..lineTo(width, height)
      ..lineTo(bottomX, height)
      ..close();
  }

  @override
  bool shouldReclip(_DiagonalRevealClipper oldClipper) {
    return oldClipper.edgePosition != edgePosition;
  }
}

Future<void> runThemeTransition(
  BuildContext context,
  ThemeMutation mutation,
) async {
  final transition = ThemeTransitionScope.maybeOf(context);
  if (transition == null) {
    await mutation();
    return;
  }
  final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  await transition.run(mutation, reduceMotion: reduceMotion);
}

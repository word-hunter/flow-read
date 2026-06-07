import 'dart:ui';

import 'package:flutter/material.dart';
import '../shells/shell.dart';
import '../tokens/semantic_colors.dart';
import '../theme/flow_theme_data.dart';

enum SurfaceLevel { background, elevated, floating, overlay }

class AppSurface extends StatelessWidget {
  final Widget child;
  final SurfaceLevel level;
  final EdgeInsets? padding;
  final BorderRadiusGeometry? borderRadius;

  const AppSurface({
    super.key,
    required this.child,
    this.level = SurfaceLevel.background,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlowThemeData.of(context);
    final strategy = theme?.surfaceStrategy ?? SurfaceStrategy.solid;

    switch (strategy) {
      case SurfaceStrategy.solid:
        return _SolidSurface(
          level: level,
          padding: padding,
          borderRadius: borderRadius,
          colors: theme?.colors,
          child: child,
        );
      case SurfaceStrategy.glass:
        return _GlassSurface(
          level: level,
          padding: padding,
          borderRadius: borderRadius,
          colors: theme?.colors,
          child: child,
        );
      case SurfaceStrategy.highContrast:
        return _SolidSurface(
          level: level,
          padding: padding,
          borderRadius: borderRadius,
          colors: theme?.colors,
          child: child,
        );
    }
  }
}

class _SolidSurface extends StatelessWidget {
  final Widget child;
  final SurfaceLevel level;
  final EdgeInsets? padding;
  final BorderRadiusGeometry? borderRadius;
  final SemanticColors? colors;

  const _SolidSurface({
    required this.child,
    required this.level,
    this.padding,
    this.borderRadius,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    Color? bg;
    if (colors != null) {
      switch (level) {
        case SurfaceLevel.background:
          bg = colors!.background;
          break;
        case SurfaceLevel.elevated:
          bg = colors!.surfaceElevated;
          break;
        case SurfaceLevel.floating:
          bg = colors!.surface;
          break;
        case SurfaceLevel.overlay:
          bg = colors!.surface;
          break;
      }
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}

class _GlassSurface extends StatelessWidget {
  final Widget child;
  final SurfaceLevel level;
  final EdgeInsets? padding;
  final BorderRadiusGeometry? borderRadius;
  final SemanticColors? colors;

  const _GlassSurface({
    required this.child,
    required this.level,
    this.padding,
    this.borderRadius,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (colors?.glassTint ?? Colors.white).withValues(alpha: 0.2),
            borderRadius: borderRadius,
          ),
          child: child,
        ),
      ),
    );
  }
}

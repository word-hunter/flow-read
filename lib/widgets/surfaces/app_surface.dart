import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../../theme/app_surface_tokens.dart';

enum AppSurfaceRole {
  readerCanvas,
  readerControl,
  leftWorkspace,
  rightAssistant,
  popover,
  dialog,
  bottomSheet,
}

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    required this.role,
    this.forceStrategy,
  });

  final AppSurfaceRole role;
  final Widget child;
  final SurfaceStrategy? forceStrategy;

  @override
  Widget build(BuildContext context) {
    final tokens = AppSurfaceTokens.of(context);
    final strategy = forceStrategy ?? tokens.strategy;

    final color = switch (role) {
      AppSurfaceRole.readerCanvas => tokens.readerOpaqueSurface,
      AppSurfaceRole.leftWorkspace => tokens.leftWorkspaceColor,
      AppSurfaceRole.rightAssistant => tokens.assistantSurface,
      AppSurfaceRole.readerControl => tokens.readerControlSurface,
      AppSurfaceRole.popover => tokens.assistantSurface,
      AppSurfaceRole.dialog => tokens.assistantSurface,
      AppSurfaceRole.bottomSheet => tokens.assistantSurface,
    };

    if (strategy == SurfaceStrategy.glass) {
      return _GlassSurface(
        tintColor: tokens.glassTintColor,
        strokeColor: tokens.glassStrokeColor,
        blurSigma: tokens.glassBlurSigma,
        opacity: tokens.glassOpacity,
        child: ColoredBox(color: color, child: child),
      );
    }

    return ColoredBox(color: color, child: child);
  }
}

class _GlassSurface extends StatelessWidget {
  final Color tintColor;
  final Color strokeColor;
  final double blurSigma;
  final double opacity;
  final Widget child;

  const _GlassSurface({
    required this.tintColor,
    required this.strokeColor,
    required this.blurSigma,
    required this.opacity,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (blurSigma <= 0) return child;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tintColor.withValues(alpha: opacity),
            border: Border.all(
              color: strokeColor,
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

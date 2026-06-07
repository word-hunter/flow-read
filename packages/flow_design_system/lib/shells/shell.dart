import 'package:flutter/material.dart';
import '../tokens/typography.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';
import '../tokens/durations.dart';
import '../tokens/semantic_colors.dart';
import '../tokens/component_tokens.dart';
import '../tokens/icons.dart';

enum ShellId {
  android,
  ios,
  macosStandard,
  macosLiquidGlass,
  windows,
}

extension ShellIdLabels on ShellId {
  String get label {
    switch (this) {
      case ShellId.android:
        return 'Android (Material 3)';
      case ShellId.ios:
        return 'iOS (Cupertino)';
      case ShellId.macosStandard:
        return 'macOS Standard HIG';
      case ShellId.macosLiquidGlass:
        return 'macOS Liquid Glass';
      case ShellId.windows:
        return 'Windows (Fluent)';
    }
  }
}

enum SurfaceStrategy { solid, glass, highContrast }

abstract class Shell {
  ShellId get id;
  String get label;

  bool isAvailableOnCurrentPlatform();

  ThemeData buildTheme({
    required ColorScheme colorScheme,
    required SemanticColors colors,
    required Brightness brightness,
    required TypographyPrimitives typography,
    required SpacingPrimitives spacing,
    required RadiiPrimitives radii,
    required DurationPrimitives durations,
    Color? scaffoldBackgroundColor,
  });

  SurfaceStrategy get surfaceStrategy;

  ButtonTokens get buttonTokens;
  CardTokens get cardTokens;
  NavigationTokens get navigationTokens;
  IconTokens get iconTokens;

  Curve get standardCurve;
  Curve get decelerateCurve;
  Curve get accelerateCurve;

  ScrollPhysics get scrollPhysics;
}

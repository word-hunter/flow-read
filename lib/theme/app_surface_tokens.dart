import 'package:flutter/material.dart';

enum SurfaceStrategy { solid, glass, highContrast }

class AppSurfaceTokens extends ThemeExtension<AppSurfaceTokens> {
  final SurfaceStrategy strategy;
  final Color readerOpaqueSurface;
  final Color readerControlSurface;
  final Color assistantSurface;
  final Color leftWorkspaceColor;
  final Color glassTintColor;
  final Color glassStrokeColor;
  final Color glassHighlightColor;
  final Color glassShadowColor;
  final double glassBlurSigma;
  final double glassOpacity;

  const AppSurfaceTokens({
    required this.strategy,
    required this.readerOpaqueSurface,
    required this.readerControlSurface,
    required this.assistantSurface,
    required this.leftWorkspaceColor,
    required this.glassTintColor,
    required this.glassStrokeColor,
    required this.glassHighlightColor,
    required this.glassShadowColor,
    required this.glassBlurSigma,
    required this.glassOpacity,
  });

  static AppSurfaceTokens light() => const AppSurfaceTokens(
        strategy: SurfaceStrategy.solid,
        readerOpaqueSurface: Colors.white,
        readerControlSurface: Color(0xFFF8F8F8),
        assistantSurface: Colors.white,
        leftWorkspaceColor: Color(0xFFFAFAFA),
        glassTintColor: Colors.white,
        glassStrokeColor: Color(0x1A000000),
        glassHighlightColor: Color(0x0A000000),
        glassShadowColor: Color(0x08000000),
        glassBlurSigma: 0,
        glassOpacity: 0.72,
      );

  static AppSurfaceTokens dark() => const AppSurfaceTokens(
        strategy: SurfaceStrategy.solid,
        readerOpaqueSurface: Color(0xFF1E1E1E),
        readerControlSurface: Color(0xFF252525),
        assistantSurface: Color(0xFF252525),
        leftWorkspaceColor: Color(0xFF222222),
        glassTintColor: Color(0xFF2A2A2A),
        glassStrokeColor: Color(0x1AFFFFFF),
        glassHighlightColor: Color(0x0AFFFFFF),
        glassShadowColor: Color(0x08000000),
        glassBlurSigma: 0,
        glassOpacity: 0.72,
      );

  static AppSurfaceTokens highContrastLight() => const AppSurfaceTokens(
        strategy: SurfaceStrategy.highContrast,
        readerOpaqueSurface: Colors.white,
        readerControlSurface: Colors.white,
        assistantSurface: Colors.white,
        leftWorkspaceColor: Colors.white,
        glassTintColor: Colors.white,
        glassStrokeColor: Color(0x33000000),
        glassHighlightColor: Color(0x0A000000),
        glassShadowColor: Colors.transparent,
        glassBlurSigma: 0,
        glassOpacity: 1.0,
      );

  static AppSurfaceTokens highContrastDark() => const AppSurfaceTokens(
        strategy: SurfaceStrategy.highContrast,
        readerOpaqueSurface: Color(0xFF000000),
        readerControlSurface: Color(0xFF000000),
        assistantSurface: Color(0xFF000000),
        leftWorkspaceColor: Color(0xFF000000),
        glassTintColor: Color(0xFF000000),
        glassStrokeColor: Color(0x33FFFFFF),
        glassHighlightColor: Color(0x0AFFFFFF),
        glassShadowColor: Colors.transparent,
        glassBlurSigma: 0,
        glassOpacity: 1.0,
      );

  static AppSurfaceTokens of(BuildContext context) {
    return Theme.of(context).extension<AppSurfaceTokens>() ?? light();
  }

  @override
  AppSurfaceTokens copyWith({
    SurfaceStrategy? strategy,
    Color? readerOpaqueSurface,
    Color? readerControlSurface,
    Color? assistantSurface,
    Color? leftWorkspaceColor,
    Color? glassTintColor,
    Color? glassStrokeColor,
    Color? glassHighlightColor,
    Color? glassShadowColor,
    double? glassBlurSigma,
    double? glassOpacity,
  }) {
    return AppSurfaceTokens(
      strategy: strategy ?? this.strategy,
      readerOpaqueSurface: readerOpaqueSurface ?? this.readerOpaqueSurface,
      readerControlSurface: readerControlSurface ?? this.readerControlSurface,
      assistantSurface: assistantSurface ?? this.assistantSurface,
      leftWorkspaceColor: leftWorkspaceColor ?? this.leftWorkspaceColor,
      glassTintColor: glassTintColor ?? this.glassTintColor,
      glassStrokeColor: glassStrokeColor ?? this.glassStrokeColor,
      glassHighlightColor: glassHighlightColor ?? this.glassHighlightColor,
      glassShadowColor: glassShadowColor ?? this.glassShadowColor,
      glassBlurSigma: glassBlurSigma ?? this.glassBlurSigma,
      glassOpacity: glassOpacity ?? this.glassOpacity,
    );
  }

  @override
  AppSurfaceTokens lerp(ThemeExtension<AppSurfaceTokens>? other, double t) {
    if (other is! AppSurfaceTokens) return this;
    return AppSurfaceTokens(
      strategy: t < 0.5 ? strategy : other.strategy,
      readerOpaqueSurface:
          Color.lerp(readerOpaqueSurface, other.readerOpaqueSurface, t)!,
      readerControlSurface:
          Color.lerp(readerControlSurface, other.readerControlSurface, t)!,
      assistantSurface:
          Color.lerp(assistantSurface, other.assistantSurface, t)!,
      leftWorkspaceColor:
          Color.lerp(leftWorkspaceColor, other.leftWorkspaceColor, t)!,
      glassTintColor: Color.lerp(glassTintColor, other.glassTintColor, t)!,
      glassStrokeColor:
          Color.lerp(glassStrokeColor, other.glassStrokeColor, t)!,
      glassHighlightColor:
          Color.lerp(glassHighlightColor, other.glassHighlightColor, t)!,
      glassShadowColor:
          Color.lerp(glassShadowColor, other.glassShadowColor, t)!,
      glassBlurSigma: glassBlurSigma + (other.glassBlurSigma - glassBlurSigma) * t,
      glassOpacity: glassOpacity + (other.glassOpacity - glassOpacity) * t,
    );
  }
}

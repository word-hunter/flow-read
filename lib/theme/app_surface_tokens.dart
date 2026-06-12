import 'package:flutter/material.dart';

enum SurfaceStrategy { solid, glass, highContrast }

class AppSurfaceTokens extends ThemeExtension<AppSurfaceTokens> {
  final SurfaceStrategy strategy;
  final Color readerWorkspaceBackground;
  final Color readerOpaqueSurface;
  final Color readerControlSurface;
  final Color assistantSurface;
  final Color leftWorkspaceColor;
  final Color panelBorderColor;
  final Color panelShadowColor;
  final Color readerPageBorderColor;
  final Color glassTintColor;
  final Color glassStrokeColor;
  final Color glassHighlightColor;
  final Color glassShadowColor;
  final double glassBlurSigma;
  final double glassOpacity;

  const AppSurfaceTokens({
    required this.strategy,
    required this.readerWorkspaceBackground,
    required this.readerOpaqueSurface,
    required this.readerControlSurface,
    required this.assistantSurface,
    required this.leftWorkspaceColor,
    required this.panelBorderColor,
    required this.panelShadowColor,
    required this.readerPageBorderColor,
    required this.glassTintColor,
    required this.glassStrokeColor,
    required this.glassHighlightColor,
    required this.glassShadowColor,
    required this.glassBlurSigma,
    required this.glassOpacity,
  });

  static AppSurfaceTokens light() => const AppSurfaceTokens(
    strategy: SurfaceStrategy.solid,
    readerWorkspaceBackground: Color(0xFFEAF7FF),
    readerOpaqueSurface: Color(0xFFFFFCF6),
    readerControlSurface: Color(0xFFF9FCFF),
    assistantSurface: Color(0xFFF9FCFF),
    leftWorkspaceColor: Color(0xFFF9FCFF),
    panelBorderColor: Color(0xFFCFE0F1),
    panelShadowColor: Color(0x1F4B76A8),
    readerPageBorderColor: Color(0xFFE7D9C6),
    glassTintColor: Colors.white,
    glassStrokeColor: Color(0x1A071A33),
    glassHighlightColor: Color(0x0A000000),
    glassShadowColor: Color(0x08000000),
    glassBlurSigma: 0,
    glassOpacity: 0.72,
  );

  static AppSurfaceTokens dark() => const AppSurfaceTokens(
    strategy: SurfaceStrategy.solid,
    readerWorkspaceBackground: Color(0xFF07111D),
    readerOpaqueSurface: Color(0xFF09131F),
    readerControlSurface: Color(0xFF0F1B2A),
    assistantSurface: Color(0xFF0C1724),
    leftWorkspaceColor: Color(0xFF0C1724),
    panelBorderColor: Color(0xFF263548),
    panelShadowColor: Color(0x66000000),
    readerPageBorderColor: Color(0xFF1D2A3B),
    glassTintColor: Color(0xFF121E2C),
    glassStrokeColor: Color(0x1AFFFFFF),
    glassHighlightColor: Color(0x0AFFFFFF),
    glassShadowColor: Color(0x08000000),
    glassBlurSigma: 0,
    glassOpacity: 0.72,
  );

  static AppSurfaceTokens cityLight() => const AppSurfaceTokens(
    strategy: SurfaceStrategy.solid,
    readerWorkspaceBackground: Color(0xFFE9F5FB),
    readerOpaqueSurface: Color(0xFFFEFCF8),
    readerControlSurface: Color(0xFFFEF9EF),
    assistantSurface: Color(0xFFFEF9EF),
    leftWorkspaceColor: Color(0xFFFEFAF3),
    panelBorderColor: Color(0xFFEADBC6),
    panelShadowColor: Color(0x1AE5C99A),
    readerPageBorderColor: Color(0xFFEADBC6),
    glassTintColor: Colors.white,
    glassStrokeColor: Color(0x1AE5C99A),
    glassHighlightColor: Color(0x0AFFFFFF),
    glassShadowColor: Color(0x08000000),
    glassBlurSigma: 0,
    glassOpacity: 0.78,
  );

  static AppSurfaceTokens cityDark() => const AppSurfaceTokens(
    strategy: SurfaceStrategy.solid,
    readerWorkspaceBackground: Color(0xFF121926),
    readerOpaqueSurface: Color(0xFF121926),
    readerControlSurface: Color(0xFF1A2233),
    assistantSurface: Color(0xFF1A2233),
    leftWorkspaceColor: Color(0xFF1A2233),
    panelBorderColor: Color(0xFF5A5040),
    panelShadowColor: Color(0x66000000),
    readerPageBorderColor: Color(0xFF5A5040),
    glassTintColor: Color(0xFF1A2233),
    glassStrokeColor: Color(0x1AFFFFFF),
    glassHighlightColor: Color(0x0AFFFFFF),
    glassShadowColor: Color(0x08000000),
    glassBlurSigma: 0,
    glassOpacity: 0.78,
  );

  static AppSurfaceTokens highContrastLight() => const AppSurfaceTokens(
    strategy: SurfaceStrategy.highContrast,
    readerWorkspaceBackground: Colors.white,
    readerOpaqueSurface: Colors.white,
    readerControlSurface: Colors.white,
    assistantSurface: Colors.white,
    leftWorkspaceColor: Colors.white,
    panelBorderColor: Color(0xFF000000),
    panelShadowColor: Colors.transparent,
    readerPageBorderColor: Color(0xFF000000),
    glassTintColor: Colors.white,
    glassStrokeColor: Color(0x33000000),
    glassHighlightColor: Color(0x0A000000),
    glassShadowColor: Colors.transparent,
    glassBlurSigma: 0,
    glassOpacity: 1.0,
  );

  static AppSurfaceTokens highContrastDark() => const AppSurfaceTokens(
    strategy: SurfaceStrategy.highContrast,
    readerWorkspaceBackground: Color(0xFF000000),
    readerOpaqueSurface: Color(0xFF000000),
    readerControlSurface: Color(0xFF000000),
    assistantSurface: Color(0xFF000000),
    leftWorkspaceColor: Color(0xFF000000),
    panelBorderColor: Color(0xFFFFFFFF),
    panelShadowColor: Colors.transparent,
    readerPageBorderColor: Color(0xFFFFFFFF),
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
    Color? readerWorkspaceBackground,
    Color? readerOpaqueSurface,
    Color? readerControlSurface,
    Color? assistantSurface,
    Color? leftWorkspaceColor,
    Color? panelBorderColor,
    Color? panelShadowColor,
    Color? readerPageBorderColor,
    Color? glassTintColor,
    Color? glassStrokeColor,
    Color? glassHighlightColor,
    Color? glassShadowColor,
    double? glassBlurSigma,
    double? glassOpacity,
  }) {
    return AppSurfaceTokens(
      strategy: strategy ?? this.strategy,
      readerWorkspaceBackground:
          readerWorkspaceBackground ?? this.readerWorkspaceBackground,
      readerOpaqueSurface: readerOpaqueSurface ?? this.readerOpaqueSurface,
      readerControlSurface: readerControlSurface ?? this.readerControlSurface,
      assistantSurface: assistantSurface ?? this.assistantSurface,
      leftWorkspaceColor: leftWorkspaceColor ?? this.leftWorkspaceColor,
      panelBorderColor: panelBorderColor ?? this.panelBorderColor,
      panelShadowColor: panelShadowColor ?? this.panelShadowColor,
      readerPageBorderColor:
          readerPageBorderColor ?? this.readerPageBorderColor,
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
      readerWorkspaceBackground: Color.lerp(
        readerWorkspaceBackground,
        other.readerWorkspaceBackground,
        t,
      )!,
      readerOpaqueSurface: Color.lerp(
        readerOpaqueSurface,
        other.readerOpaqueSurface,
        t,
      )!,
      readerControlSurface: Color.lerp(
        readerControlSurface,
        other.readerControlSurface,
        t,
      )!,
      assistantSurface: Color.lerp(
        assistantSurface,
        other.assistantSurface,
        t,
      )!,
      leftWorkspaceColor: Color.lerp(
        leftWorkspaceColor,
        other.leftWorkspaceColor,
        t,
      )!,
      panelBorderColor: Color.lerp(
        panelBorderColor,
        other.panelBorderColor,
        t,
      )!,
      panelShadowColor: Color.lerp(
        panelShadowColor,
        other.panelShadowColor,
        t,
      )!,
      readerPageBorderColor: Color.lerp(
        readerPageBorderColor,
        other.readerPageBorderColor,
        t,
      )!,
      glassTintColor: Color.lerp(glassTintColor, other.glassTintColor, t)!,
      glassStrokeColor: Color.lerp(
        glassStrokeColor,
        other.glassStrokeColor,
        t,
      )!,
      glassHighlightColor: Color.lerp(
        glassHighlightColor,
        other.glassHighlightColor,
        t,
      )!,
      glassShadowColor: Color.lerp(
        glassShadowColor,
        other.glassShadowColor,
        t,
      )!,
      glassBlurSigma:
          glassBlurSigma + (other.glassBlurSigma - glassBlurSigma) * t,
      glassOpacity: glassOpacity + (other.glassOpacity - glassOpacity) * t,
    );
  }
}

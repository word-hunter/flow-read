import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/semantic_colors.dart';
import 'palette.dart';
import 'utils.dart';

class ClassicPalette implements Palette {
  const ClassicPalette();

  @override
  PaletteId get id => PaletteId.classic;

  @override
  String get label => '经典';

  @override
  IconData get icon => Icons.auto_stories_outlined;

  @override
  ColorPrimitives get primitives => defaultColorPrimitives;

  static const _lightCanvas = Color(0xFFEAF7FF);
  static const _lightSurface = Color(0xFFF9FCFF);
  static const _lightSurfaceRaised = Color(0xFFFFFFFF);

  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF087CFA),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD9EBFF),
    onPrimaryContainer: Color(0xFF001D3A),
    secondary: Color(0xFFF1A40F),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFE8B6),
    onSecondaryContainer: Color(0xFF2B1B00),
    tertiary: Color(0xFF2FA66A),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFDFF5E8),
    onTertiaryContainer: Color(0xFF00210D),
    error: Color(0xFFD85662),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD8),
    onErrorContainer: Color(0xFF410007),
    surface: _lightCanvas,
    onSurface: Color(0xFF071A33),
    surfaceContainerHighest: _lightSurfaceRaised,
    onSurfaceVariant: Color(0xFF50647B),
    outline: Color(0xFF8295AB),
    outlineVariant: Color(0xFFCFE0F1),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF18283A),
    onInverseSurface: Color(0xFFEAF7FF),
    inversePrimary: Color(0xFF9BCAFF),
    surfaceTint: Color(0xFF087CFA),
  );

  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF4D9BFF),
    onPrimary: Color(0xFF001D36),
    primaryContainer: Color(0xFF0F3B67),
    onPrimaryContainer: Color(0xFFD9EBFF),
    secondary: Color(0xFFFFC04D),
    onSecondary: Color(0xFF2D1D00),
    secondaryContainer: Color(0xFF684A00),
    onSecondaryContainer: Color(0xFFFFE8B6),
    tertiary: Color(0xFF65D08E),
    onTertiary: Color(0xFF00391B),
    tertiaryContainer: Color(0xFF155B34),
    onTertiaryContainer: Color(0xFFDFF5E8),
    error: Color(0xFFFFB3B7),
    onError: Color(0xFF680011),
    errorContainer: Color(0xFF93001B),
    onErrorContainer: Color(0xFFFFDAD8),
    surface: Color(0xFF07111D),
    onSurface: Color(0xFFEAF1FA),
    surfaceContainerHighest: Color(0xFF162133),
    onSurfaceVariant: Color(0xFFB7C5D6),
    outline: Color(0xFF6C7B8F),
    outlineVariant: Color(0xFF263548),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFEAF1FA),
    onInverseSurface: Color(0xFF07111D),
    inversePrimary: Color(0xFF087CFA),
    surfaceTint: Color(0xFF4D9BFF),
  );

  @override
  ColorScheme get lightColorScheme => _lightColorScheme;

  @override
  ColorScheme get darkColorScheme => _darkColorScheme;

  @override
  SemanticColors lightSemantic() =>
      semanticFromColorScheme(
        _lightColorScheme,
        scaffoldBackground: _lightCanvas,
      ).copyWith(
        surface: _lightSurface,
        surfaceElevated: _lightSurfaceRaised,
        surfaceGlass: _lightSurfaceRaised,
        readerBackground: const Color(0xFFFFFCF6),
        readerText: const Color(0xFF0A1E3D),
        readerSidebarBackground: _lightSurface,
      );

  @override
  SemanticColors darkSemantic() =>
      semanticFromColorScheme(_darkColorScheme).copyWith(
        surface: const Color(0xFF0C1724),
        surfaceElevated: const Color(0xFF121E2C),
        surfaceGlass: const Color(0xFF121E2C),
        readerBackground: const Color(0xFF07111D),
        readerText: const Color(0xFFEAF1FA),
        readerSidebarBackground: const Color(0xFF0C1724),
      );
}

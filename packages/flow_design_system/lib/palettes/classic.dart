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

  static const _lightCanvas = Color(0xFFE9F5FB);
  static const _lightSurface = Color(0xFFFEFCF8);
  static const _lightSurfaceRaised = Color(0xFFFFFFFF);
  static const _lightShellSurface = Color(0xFFFEFAF3);

  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0277FE),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD9EBFF),
    onPrimaryContainer: Color(0xFF001D3A),
    secondary: Color(0xFF5F6F85),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE9F0F8),
    onSecondaryContainer: Color(0xFF141E2B),
    tertiary: Color(0xFF1E8BFF),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFDAEAFF),
    onTertiaryContainer: Color(0xFF001D3B),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: _lightSurface,
    onSurface: Color(0xFF10233B),
    surfaceContainerHighest: Color(0xFFF3EFE5),
    onSurfaceVariant: Color(0xFF50647B),
    outline: Color(0xFFEADBC6),
    outlineVariant: Color(0xFFF0E8D8),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2D261B),
    onInverseSurface: Color(0xFFF5F0E6),
    inversePrimary: Color(0xFF9BCAFF),
    surfaceTint: Color(0xFF0277FE),
  );

  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF5DB0FF),
    onPrimary: Color(0xFF001D36),
    primaryContainer: Color(0xFF0F3B67),
    onPrimaryContainer: Color(0xFFD9EBFF),
    secondary: Color(0xFFB8C6D9),
    onSecondary: Color(0xFF1D2B3D),
    secondaryContainer: Color(0xFF344256),
    onSecondaryContainer: Color(0xFFE9F0F8),
    tertiary: Color(0xFF9BCAFF),
    onTertiary: Color(0xFF002548),
    tertiaryContainer: Color(0xFF003A65),
    onTertiaryContainer: Color(0xFFDAEAFF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF121926),
    onSurface: Color(0xFFE8EDF2),
    surfaceContainerHighest: Color(0xFF1F2634),
    onSurfaceVariant: Color(0xFFB7C5D6),
    outline: Color(0xFF5A5040),
    outlineVariant: Color(0xFF3A3428),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE8EDF2),
    onInverseSurface: Color(0xFF2D261B),
    inversePrimary: Color(0xFF0277FE),
    surfaceTint: Color(0xFF5DB0FF),
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
        surfaceGlass: _lightShellSurface,
        readerBackground: _lightSurface,
        readerText: const Color(0xFF10233B),
        readerSidebarBackground: _lightShellSurface,
      );

  @override
  SemanticColors darkSemantic() =>
      semanticFromColorScheme(_darkColorScheme).copyWith(
        surface: const Color(0xFF1A2233),
        surfaceElevated: const Color(0xFF1F283B),
        surfaceGlass: const Color(0xFF1A2233),
        readerBackground: const Color(0xFF121926),
        readerText: const Color(0xFFE8EDF2),
        readerSidebarBackground: const Color(0xFF1A2233),
      );
}

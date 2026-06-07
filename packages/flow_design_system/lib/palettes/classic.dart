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

  static const _warmPaper = Color(0xFFFFF8EA);
  static const _softCanvas = Color(0xFFF7F0E2);

  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2F8FB8),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDDF3FA),
    onPrimaryContainer: Color(0xFF0A1E2E),
    secondary: Color(0xFFC58A1E),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFF1B8),
    onSecondaryContainer: Color(0xFF2E1F00),
    tertiary: Color(0xFF3C8C5A),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE5F5E6),
    onTertiaryContainer: Color(0xFF0A1E10),
    error: Color(0xFFD85C6D),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9D0C9),
    onErrorContainer: Color(0xFF2E0A0A),
    surface: _warmPaper,
    onSurface: Color(0xFF25211C),
    surfaceContainerHighest: _softCanvas,
    onSurfaceVariant: Color(0xFF5F574D),
    outline: Color(0xFF9B9184),
    outlineVariant: Color(0xFFE1D6C8),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2E2A25),
    onInverseSurface: Color(0xFFFFF8EA),
    inversePrimary: Color(0xFF6EC7E8),
    surfaceTint: Color(0xFF2F8FB8),
  );

  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF6EC7E8),
    onPrimary: Color(0xFF0A1E2E),
    primaryContainer: Color(0xFF1A5678),
    onPrimaryContainer: Color(0xFFDDF3FA),
    secondary: Color(0xFFFFD86B),
    onSecondary: Color(0xFF2E1F00),
    secondaryContainer: Color(0xFF8A6215),
    onSecondaryContainer: Color(0xFFFFF1B8),
    tertiary: Color(0xFF8FD19E),
    onTertiary: Color(0xFF0A1E10),
    tertiaryContainer: Color(0xFF2A6B3E),
    onTertiaryContainer: Color(0xFFE5F5E6),
    error: Color(0xFFF58A9D),
    onError: Color(0xFF2E0A0A),
    errorContainer: Color(0xFFA83E4E),
    onErrorContainer: Color(0xFFFFE2E7),
    surface: Color(0xFF1E1B16),
    onSurface: Color(0xFFF7F0E2),
    surfaceContainerHighest: Color(0xFF2C2822),
    onSurfaceVariant: Color(0xFFC4BEB4),
    outline: Color(0xFF8B857A),
    outlineVariant: Color(0xFF4A453E),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF7F0E2),
    onInverseSurface: Color(0xFF1E1B16),
    inversePrimary: Color(0xFF2F8FB8),
    surfaceTint: Color(0xFF6EC7E8),
  );

  @override
  ColorScheme get lightColorScheme => _lightColorScheme;

  @override
  ColorScheme get darkColorScheme => _darkColorScheme;

  @override
  SemanticColors lightSemantic() =>
      semanticFromColorScheme(_lightColorScheme, scaffoldBackground: _warmPaper);

  @override
  SemanticColors darkSemantic() =>
      semanticFromColorScheme(_darkColorScheme);
}

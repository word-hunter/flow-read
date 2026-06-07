import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/semantic_colors.dart';
import 'palette.dart';
import 'utils.dart';

class HighContrastPalette implements Palette {
  const HighContrastPalette();

  @override
  PaletteId get id => PaletteId.highContrast;

  @override
  String get label => '高对比';

  @override
  IconData get icon => Icons.contrast_outlined;

  @override
  ColorPrimitives get primitives => defaultColorPrimitives;

  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0057D8),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD9E4FF),
    onPrimaryContainer: Color(0xFF001A41),
    secondary: Color(0xFF4F5F7D),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDCE5FF),
    onSecondaryContainer: Color(0xFF0A1A35),
    tertiary: Color(0xFF006B5B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF83F8DE),
    onTertiaryContainer: Color(0xFF00201A),
    error: Color(0xFFB00020),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF111111),
    surfaceContainerHighest: Color(0xFFECEFF5),
    onSurfaceVariant: Color(0xFF30343A),
    outline: Color(0xFF565B62),
    outlineVariant: Color(0xFFC6CAD2),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF202124),
    onInverseSurface: Color(0xFFF8F9FA),
    inversePrimary: Color(0xFFAFC6FF),
    surfaceTint: Color(0xFF0057D8),
  );

  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFD84D),
    onPrimary: Color(0xFF171100),
    primaryContainer: Color(0xFF4F3D00),
    onPrimaryContainer: Color(0xFFFFEFAF),
    secondary: Color(0xFFBFD3FF),
    onSecondary: Color(0xFF1D2E50),
    secondaryContainer: Color(0xFF344566),
    onSecondaryContainer: Color(0xFFDCE5FF),
    tertiary: Color(0xFF7CE6CF),
    onTertiary: Color(0xFF00382E),
    tertiaryContainer: Color(0xFF005144),
    onTertiaryContainer: Color(0xFF9DFBE5),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF0B0B0B),
    onSurface: Color(0xFFF6F6F6),
    surfaceContainerHighest: Color(0xFF252525),
    onSurfaceVariant: Color(0xFFD7D7D7),
    outline: Color(0xFFA9A9A9),
    outlineVariant: Color(0xFF595959),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF6F6F6),
    onInverseSurface: Color(0xFF1B1B1B),
    inversePrimary: Color(0xFF0057D8),
    surfaceTint: Color(0xFFFFD84D),
  );

  @override
  ColorScheme get lightColorScheme => _lightColorScheme;

  @override
  ColorScheme get darkColorScheme => _darkColorScheme;

  @override
  SemanticColors lightSemantic() => semanticFromColorScheme(_lightColorScheme);

  @override
  SemanticColors darkSemantic() => semanticFromColorScheme(_darkColorScheme);
}

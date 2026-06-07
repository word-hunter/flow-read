import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/semantic_colors.dart';
import 'palette.dart';
import 'utils.dart';

class OceanPalette implements Palette {
  const OceanPalette();

  @override
  PaletteId get id => PaletteId.ocean;

  @override
  String get label => '海雾';

  @override
  IconData get icon => Icons.water_drop_outlined;

  @override
  ColorPrimitives get primitives => defaultColorPrimitives;

  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF197A8A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD0EFF4),
    onPrimaryContainer: Color(0xFF002A32),
    secondary: Color(0xFF52676C),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD6E7EC),
    onSecondaryContainer: Color(0xFF0E2024),
    tertiary: Color(0xFF7A5A97),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFEADCF8),
    onTertiaryContainer: Color(0xFF2B1242),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF7FBFC),
    onSurface: Color(0xFF172124),
    surfaceContainerHighest: Color(0xFFE6EEF1),
    onSurfaceVariant: Color(0xFF4D5C61),
    outline: Color(0xFF7A8A8F),
    outlineVariant: Color(0xFFC9D4D8),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2B3133),
    onInverseSurface: Color(0xFFEFF5F6),
    inversePrimary: Color(0xFF8ED6E2),
    surfaceTint: Color(0xFF197A8A),
  );

  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF8ED6E2),
    onPrimary: Color(0xFF00363F),
    primaryContainer: Color(0xFF004E5B),
    onPrimaryContainer: Color(0xFFD0EFF4),
    secondary: Color(0xFFB9CBD0),
    onSecondary: Color(0xFF233438),
    secondaryContainer: Color(0xFF394B50),
    onSecondaryContainer: Color(0xFFD6E7EC),
    tertiary: Color(0xFFD8B9EE),
    onTertiary: Color(0xFF41265B),
    tertiaryContainer: Color(0xFF593D73),
    onTertiaryContainer: Color(0xFFEADCF8),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF11191B),
    onSurface: Color(0xFFE1E8EA),
    surfaceContainerHighest: Color(0xFF263033),
    onSurfaceVariant: Color(0xFFC1CACE),
    outline: Color(0xFF8B9599),
    outlineVariant: Color(0xFF414B4E),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE1E8EA),
    onInverseSurface: Color(0xFF2B3133),
    inversePrimary: Color(0xFF197A8A),
    surfaceTint: Color(0xFF8ED6E2),
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

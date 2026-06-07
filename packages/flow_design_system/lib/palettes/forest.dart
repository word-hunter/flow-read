import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/semantic_colors.dart';
import 'palette.dart';
import 'utils.dart';

class ForestPalette implements Palette {
  const ForestPalette();

  @override
  PaletteId get id => PaletteId.forest;

  @override
  String get label => '松林';

  @override
  IconData get icon => Icons.park_outlined;

  @override
  ColorPrimitives get primitives => defaultColorPrimitives;

  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF3F6F4A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD8E9D2),
    onPrimaryContainer: Color(0xFF05210D),
    secondary: Color(0xFF6C6043),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF4E4BE),
    onSecondaryContainer: Color(0xFF251A06),
    tertiary: Color(0xFF7A4F5D),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFD9E2),
    onTertiaryContainer: Color(0xFF30101B),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFBFCF7),
    onSurface: Color(0xFF191D18),
    surfaceContainerHighest: Color(0xFFE6E9DE),
    onSurfaceVariant: Color(0xFF52584E),
    outline: Color(0xFF82887D),
    outlineVariant: Color(0xFFD0D4C8),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2E322D),
    onInverseSurface: Color(0xFFF0F1EC),
    inversePrimary: Color(0xFFBBD0B5),
    surfaceTint: Color(0xFF3F6F4A),
  );

  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFA9D0A7),
    onPrimary: Color(0xFF123719),
    primaryContainer: Color(0xFF28502F),
    onPrimaryContainer: Color(0xFFD8E9D2),
    secondary: Color(0xFFD7C7A1),
    onSecondary: Color(0xFF3B2F13),
    secondaryContainer: Color(0xFF53462A),
    onSecondaryContainer: Color(0xFFF4E4BE),
    tertiary: Color(0xFFEAB8C6),
    onTertiary: Color(0xFF482633),
    tertiaryContainer: Color(0xFF613C49),
    onTertiaryContainer: Color(0xFFFFD9E2),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF151B14),
    onSurface: Color(0xFFE1E4DD),
    surfaceContainerHighest: Color(0xFF293027),
    onSurfaceVariant: Color(0xFFC4C8BD),
    outline: Color(0xFF8E9389),
    outlineVariant: Color(0xFF44483F),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE1E4DD),
    onInverseSurface: Color(0xFF2E322D),
    inversePrimary: Color(0xFF3F6F4A),
    surfaceTint: Color(0xFFA9D0A7),
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

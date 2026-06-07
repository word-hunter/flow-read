import 'package:flutter/material.dart';
import '../tokens/semantic_colors.dart';
import '../tokens/component_tokens.dart';
import '../tokens/typography.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';
import '../tokens/durations.dart';
import '../palettes/palette.dart';
import '../shells/shell.dart';

class FlowThemeData extends ThemeExtension<FlowThemeData> {
  final ShellId shellId;
  final PaletteId paletteId;
  final SemanticColors colors;
  final ButtonTokens buttonTokens;
  final CardTokens cardTokens;
  final NavigationTokens navigationTokens;
  final SurfaceStrategy surfaceStrategy;
  final TypographyPrimitives typography;
  final SpacingPrimitives spacing;
  final RadiiPrimitives radii;
  final DurationPrimitives durations;

  const FlowThemeData({
    required this.shellId,
    required this.paletteId,
    required this.colors,
    required this.buttonTokens,
    required this.cardTokens,
    required this.navigationTokens,
    required this.surfaceStrategy,
    required this.typography,
    required this.spacing,
    required this.radii,
    required this.durations,
  });

  @override
  FlowThemeData copyWith({
    ShellId? shellId,
    PaletteId? paletteId,
    SemanticColors? colors,
    ButtonTokens? buttonTokens,
    CardTokens? cardTokens,
    NavigationTokens? navigationTokens,
    SurfaceStrategy? surfaceStrategy,
    TypographyPrimitives? typography,
    SpacingPrimitives? spacing,
    RadiiPrimitives? radii,
    DurationPrimitives? durations,
  }) {
    return FlowThemeData(
      shellId: shellId ?? this.shellId,
      paletteId: paletteId ?? this.paletteId,
      colors: colors ?? this.colors,
      buttonTokens: buttonTokens ?? this.buttonTokens,
      cardTokens: cardTokens ?? this.cardTokens,
      navigationTokens: navigationTokens ?? this.navigationTokens,
      surfaceStrategy: surfaceStrategy ?? this.surfaceStrategy,
      typography: typography ?? this.typography,
      spacing: spacing ?? this.spacing,
      radii: radii ?? this.radii,
      durations: durations ?? this.durations,
    );
  }

  @override
  FlowThemeData lerp(ThemeExtension<FlowThemeData>? other, double t) {
    if (other is! FlowThemeData) return this;
    return FlowThemeData(
      shellId: shellId,
      paletteId: t < 0.5 ? paletteId : other.paletteId,
      colors: t < 0.5 ? colors : other.colors,
      buttonTokens: t < 0.5 ? buttonTokens : other.buttonTokens,
      cardTokens: t < 0.5 ? cardTokens : other.cardTokens,
      navigationTokens: t < 0.5 ? navigationTokens : other.navigationTokens,
      surfaceStrategy: t < 0.5 ? surfaceStrategy : other.surfaceStrategy,
      typography: t < 0.5 ? typography : other.typography,
      spacing: t < 0.5 ? spacing : other.spacing,
      radii: t < 0.5 ? radii : other.radii,
      durations: t < 0.5 ? durations : other.durations,
    );
  }

  static FlowThemeData? of(BuildContext context) {
    return Theme.of(context).extension<FlowThemeData>();
  }
}

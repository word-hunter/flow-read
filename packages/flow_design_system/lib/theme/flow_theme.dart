import 'package:flutter/material.dart';
import '../palettes/palette.dart';
import '../palettes/registry.dart';
import '../shells/shell.dart';
import '../shells/android_shell.dart';
import '../shells/ios_shell.dart';
import '../shells/macos_standard_shell.dart';
import '../shells/windows_shell.dart';
import '../tokens/typography.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';
import '../tokens/durations.dart';
import 'flow_theme_data.dart';

class FlowTheme {
  FlowTheme._();

  static final Map<ShellId, Shell> _shells = {
    ShellId.android: const AndroidShell(),
    ShellId.ios: const IosShell(),
    ShellId.macosStandard: const MacOsStandardShell(),
    ShellId.windows: const WindowsShell(),
  };

  static Shell getShell(ShellId id) {
    final shell = _shells[id];
    if (shell == null) {
      throw ArgumentError('Shell not registered: $id');
    }
    return shell;
  }

  static ThemeData build({
    required ShellId shellId,
    required PaletteId paletteId,
    required Brightness brightness,
    Color? scaffoldBackgroundColor,
  }) {
    final shell = getShell(shellId);
    final palette = PaletteRegistry.get(paletteId);
    final colorScheme = brightness == Brightness.light
        ? palette.lightColorScheme
        : palette.darkColorScheme;
    final semantic = brightness == Brightness.light
        ? palette.lightSemantic()
        : palette.darkSemantic();

    final typography = defaultTypographyPrimitives;
    final spacing = defaultSpacingPrimitives;
    final radii = defaultRadiiPrimitives;
    final durations = defaultDurationPrimitives;

    final flowThemeData = FlowThemeData(
      shellId: shellId,
      paletteId: paletteId,
      colors: semantic,
      buttonTokens: shell.buttonTokens,
      cardTokens: shell.cardTokens,
      navigationTokens: shell.navigationTokens,
      surfaceStrategy: shell.surfaceStrategy,
      typography: typography,
      spacing: spacing,
      radii: radii,
      durations: durations,
    );

    final theme = shell.buildTheme(
      colorScheme: colorScheme,
      colors: semantic,
      brightness: brightness,
      typography: typography,
      spacing: spacing,
      radii: radii,
      durations: durations,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
    );

    return theme.copyWith(
      extensions: [
        ...theme.extensions.values,
        flowThemeData,
      ],
    );
  }

  static FlowThemeData themeDataFor({
    required ShellId shellId,
    required PaletteId paletteId,
    required Brightness brightness,
  }) {
    final shell = getShell(shellId);
    final palette = PaletteRegistry.get(paletteId);
    final semantic = brightness == Brightness.light
        ? palette.lightSemantic()
        : palette.darkSemantic();

    return FlowThemeData(
      shellId: shellId,
      paletteId: paletteId,
      colors: semantic,
      buttonTokens: shell.buttonTokens,
      cardTokens: shell.cardTokens,
      navigationTokens: shell.navigationTokens,
      surfaceStrategy: shell.surfaceStrategy,
      typography: defaultTypographyPrimitives,
      spacing: defaultSpacingPrimitives,
      radii: defaultRadiiPrimitives,
      durations: defaultDurationPrimitives,
    );
  }
}

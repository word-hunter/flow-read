import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_design_system/flow_design_system.dart';

void main() {
  group('MacOsLiquidGlassShell', () {
    const shell = MacOsLiquidGlassShell();

    test('has correct shell id', () {
      expect(shell.id, ShellId.macosLiquidGlass);
    });

    test('produces correct ThemeData for classic light', () {
      const palette = ClassicPalette();
      final theme = shell.buildTheme(
        colorScheme: palette.lightColorScheme,
        colors: palette.lightSemantic(),
        brightness: Brightness.light,
        typography: defaultTypographyPrimitives,
        spacing: defaultSpacingPrimitives,
        radii: defaultRadiiPrimitives,
        durations: defaultDurationPrimitives,
      );

      expect(theme.useMaterial3, isTrue);
      expect(theme.visualDensity, VisualDensity.compact);
      expect(theme.appBarTheme.toolbarHeight, 40);
      expect(theme.scaffoldBackgroundColor, palette.lightColorScheme.surface);
    });

    test('surface strategy is glass', () {
      expect(shell.surfaceStrategy, SurfaceStrategy.glass);
    });

    test('reuses macos component tokens', () {
      expect(shell.buttonTokens.borderRadius, BorderRadius.circular(6));
      expect(shell.buttonTokens.minHeight, 28);
      expect(shell.cardTokens.borderRadius, BorderRadius.circular(8));
      expect(shell.navigationTokens.sidebarWidth, 240);
    });

    test('scroll physics is BouncingScrollPhysics', () {
      expect(shell.scrollPhysics, isA<BouncingScrollPhysics>());
    });

    test('navigation bar and rail use glassTint background', () {
      const palette = ClassicPalette();
      final theme = shell.buildTheme(
        colorScheme: palette.lightColorScheme,
        colors: palette.lightSemantic(),
        brightness: Brightness.light,
        typography: defaultTypographyPrimitives,
        spacing: defaultSpacingPrimitives,
        radii: defaultRadiiPrimitives,
        durations: defaultDurationPrimitives,
      );

      final semantic = palette.lightSemantic();
      expect(theme.navigationBarTheme.backgroundColor, semantic.glassTint);
      expect(theme.navigationRailTheme.backgroundColor, semantic.glassTint);
    });

    test('app bar uses glassTint background', () {
      const palette = ClassicPalette();
      final theme = shell.buildTheme(
        colorScheme: palette.lightColorScheme,
        colors: palette.lightSemantic(),
        brightness: Brightness.light,
        typography: defaultTypographyPrimitives,
        spacing: defaultSpacingPrimitives,
        radii: defaultRadiiPrimitives,
        durations: defaultDurationPrimitives,
      );

      final semantic = palette.lightSemantic();
      expect(theme.appBarTheme.backgroundColor, semantic.glassTint);
    });

    test('dialog stays opaque (not glass)', () {
      const palette = ClassicPalette();
      final theme = shell.buildTheme(
        colorScheme: palette.lightColorScheme,
        colors: palette.lightSemantic(),
        brightness: Brightness.light,
        typography: defaultTypographyPrimitives,
        spacing: defaultSpacingPrimitives,
        radii: defaultRadiiPrimitives,
        durations: defaultDurationPrimitives,
      );

      // Dialog uses solid surface, not glassTint
      expect(
        theme.dialogTheme.backgroundColor,
        palette.lightColorScheme.surface,
      );
    });

    test('includes ReaderThemeTokens extension', () {
      const palette = ClassicPalette();
      final theme = shell.buildTheme(
        colorScheme: palette.lightColorScheme,
        colors: palette.lightSemantic(),
        brightness: Brightness.light,
        typography: defaultTypographyPrimitives,
        spacing: defaultSpacingPrimitives,
        radii: defaultRadiiPrimitives,
        durations: defaultDurationPrimitives,
      );

      final tokens = theme.extension<ReaderThemeTokens>();
      expect(tokens, isNotNull);
      expect(tokens!.readingMaxWidth, 820);
    });
  });

  group('MacOsLiquidGlassShell — all palettes', () {
    const palettes = <Palette>[
      ClassicPalette(),
      OceanPalette(),
      ForestPalette(),
      HighContrastPalette(),
    ];

    for (final palette in palettes) {
      test('${palette.label} light/dark builds without error', () {
        expect(
          () => const MacOsLiquidGlassShell().buildTheme(
            colorScheme: palette.lightColorScheme,
            colors: palette.lightSemantic(),
            brightness: Brightness.light,
            typography: defaultTypographyPrimitives,
            spacing: defaultSpacingPrimitives,
            radii: defaultRadiiPrimitives,
            durations: defaultDurationPrimitives,
          ),
          returnsNormally,
        );
        expect(
          () => const MacOsLiquidGlassShell().buildTheme(
            colorScheme: palette.darkColorScheme,
            colors: palette.darkSemantic(),
            brightness: Brightness.dark,
            typography: defaultTypographyPrimitives,
            spacing: defaultSpacingPrimitives,
            radii: defaultRadiiPrimitives,
            durations: defaultDurationPrimitives,
          ),
          returnsNormally,
        );
      });
    }
  });
}

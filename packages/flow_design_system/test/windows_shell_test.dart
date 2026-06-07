import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_design_system/flow_design_system.dart';

void main() {
  group('WindowsShell', () {
    const shell = WindowsShell();

    test('has correct shell id', () {
      expect(shell.id, ShellId.windows);
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
      expect(theme.visualDensity, VisualDensity.standard);
      expect(theme.appBarTheme?.toolbarHeight, 40);
      expect(theme.scaffoldBackgroundColor, palette.lightColorScheme.surface);
    });

    test('produces correct ThemeData for classic dark', () {
      const palette = ClassicPalette();
      final theme = shell.buildTheme(
        colorScheme: palette.darkColorScheme,
        colors: palette.darkSemantic(),
        brightness: Brightness.dark,
        typography: defaultTypographyPrimitives,
        spacing: defaultSpacingPrimitives,
        radii: defaultRadiiPrimitives,
        durations: defaultDurationPrimitives,
      );

      expect(theme.brightness, Brightness.dark);
      expect(theme.cardTheme?.elevation, 1);
    });

    test('windows-specific curves', () {
      expect(shell.standardCurve, Curves.easeOut);
      expect(shell.decelerateCurve, Curves.easeOut);
    });

    test('scroll physics is Clamping', () {
      expect(shell.scrollPhysics, isA<ClampingScrollPhysics>());
    });

    test('surface strategy is solid', () {
      expect(shell.surfaceStrategy, SurfaceStrategy.solid);
    });

    test('button tokens have correct values', () {
      expect(shell.buttonTokens.borderRadius, BorderRadius.circular(4));
      expect(shell.buttonTokens.minHeight, 32);
      expect(windowsButtonTokens.minHeight, 32);
    });

    test('card tokens have correct values', () {
      expect(shell.cardTokens.borderRadius, BorderRadius.circular(8));
      expect(shell.cardTokens.elevation, 1);
    });

    test('navigation tokens have compact values', () {
      expect(shell.navigationTokens.sidebarWidth, 256);
      expect(shell.navigationTokens.collapsedSidebarWidth, 48);
      expect(shell.navigationTokens.iconSize, 20);
    });

    test('dialog has 8px radius and elevation', () {
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

      expect(theme.dialogTheme?.elevation, 2);
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
      expect(tokens!.readingMaxWidth, 860);
    });
  });

  group('WindowsShell — all palettes', () {
    const palettes = <Palette>[
      ClassicPalette(),
      OceanPalette(),
      ForestPalette(),
      HighContrastPalette(),
    ];

    for (final palette in palettes) {
      test('${palette.label} light/dark builds without error', () {
        expect(
          () => const WindowsShell().buildTheme(
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
          () => const WindowsShell().buildTheme(
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

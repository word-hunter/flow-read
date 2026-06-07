import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_design_system/flow_design_system.dart';

void main() {
  group('MacOsStandardShell', () {
    const shell = MacOsStandardShell();

    test('has correct shell id', () {
      expect(shell.id, ShellId.macosStandard);
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
      expect(theme.appBarTheme?.toolbarHeight, 38);
      expect(theme.dividerTheme?.thickness, 0.5);
      expect(theme.inputDecorationTheme?.isDense, isTrue);
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
      expect(theme.dialogTheme?.elevation, 0);
    });

    test('macos-specific curves are set', () {
      expect(shell.standardCurve, Curves.easeOut);
      expect(shell.decelerateCurve, Curves.easeOut);
      expect(shell.accelerateCurve, Curves.easeIn);
    });

    test('scroll physics is BouncingScrollPhysics', () {
      expect(shell.scrollPhysics, isA<BouncingScrollPhysics>());
    });

    test('surface strategy is solid', () {
      expect(shell.surfaceStrategy, SurfaceStrategy.solid);
    });

    test('compact button styling', () {
      expect(shell.buttonTokens.borderRadius, BorderRadius.circular(6));
      expect(shell.buttonTokens.minHeight, 28);
      expect(macosButtonTokens.minHeight, 28);
    });

    test('card tokens have correct values', () {
      expect(shell.cardTokens.borderRadius, BorderRadius.circular(8));
      expect(shell.cardTokens.elevation, 0);
      expect(shell.cardTokens.padding, const EdgeInsets.all(12));
    });

    test('navigation tokens have compact values', () {
      expect(shell.navigationTokens.sidebarWidth, 240);
      expect(shell.navigationTokens.collapsedSidebarWidth, 68);
      expect(shell.navigationTokens.iconSize, 20);
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

    test('app bar has compact height and title style', () {
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

      expect(theme.appBarTheme?.toolbarHeight, 38);
      expect(theme.appBarTheme?.titleTextStyle?.fontSize, 13);
    });

    test('bottom sheet has small radius', () {
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

      expect(theme.bottomSheetTheme?.shape, isNotNull);
    });
  });

  group('MacOsStandardShell — all palettes', () {
    const palettes = <Palette>[
      ClassicPalette(),
      OceanPalette(),
      ForestPalette(),
      HighContrastPalette(),
    ];

    for (final palette in palettes) {
      test('${palette.label} light/dark builds without error', () {
        expect(
          () => const MacOsStandardShell().buildTheme(
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
          () => const MacOsStandardShell().buildTheme(
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

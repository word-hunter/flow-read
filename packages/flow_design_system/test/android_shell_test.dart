import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_design_system/flow_design_system.dart';

void main() {
  group('AndroidShell ThemeData', () {
    const shell = AndroidShell();

    test('has correct shell id', () {
      expect(shell.id, ShellId.android);
    });

    test('is always available', () {
      expect(shell.isAvailableOnCurrentPlatform(), isTrue);
    });

    test('surface strategy is solid', () {
      expect(shell.surfaceStrategy, SurfaceStrategy.solid);
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
      expect(theme.scaffoldBackgroundColor, palette.lightColorScheme.surface);
      expect(theme.appBarTheme.elevation, 0);
      expect(
        theme.appBarTheme.backgroundColor,
        palette.lightColorScheme.surface,
      );
      expect(theme.cardTheme.elevation, 0);
      expect(theme.cardTheme.shape, isNotNull);
      expect(theme.bottomSheetTheme.shape, isNotNull);
      expect(theme.dialogTheme.shape, isNotNull);
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

      expect(theme.scaffoldBackgroundColor, palette.darkColorScheme.surface);
      expect(
        theme.cardTheme.color,
        palette.darkColorScheme.surfaceContainerHighest,
      );
    });

    test('respects scaffoldBackgroundColor override', () {
      const palette = ClassicPalette();
      const overrideColor = Color(0xFFFF0000);
      final theme = shell.buildTheme(
        colorScheme: palette.lightColorScheme,
        colors: palette.lightSemantic(),
        brightness: Brightness.light,
        typography: defaultTypographyPrimitives,
        spacing: defaultSpacingPrimitives,
        radii: defaultRadiiPrimitives,
        durations: defaultDurationPrimitives,
        scaffoldBackgroundColor: overrideColor,
      );

      expect(theme.scaffoldBackgroundColor, overrideColor);
      expect(theme.appBarTheme.backgroundColor, overrideColor);
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
      expect(tokens!.pageBackground, palette.lightColorScheme.surface);
      expect(tokens.readingMaxWidth, 920);
    });

    test('ReaderThemeTokens in dark mode use correct container colors', () {
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

      final tokens = theme.extension<ReaderThemeTokens>();
      expect(tokens, isNotNull);
      expect(
        tokens!.searchHighlightBackground,
        palette.darkColorScheme.tertiaryContainer,
      );
      expect(
        tokens.searchHighlightForeground,
        palette.darkColorScheme.onTertiaryContainer,
      );
    });

    test('light mode search highlight uses primaryContainer', () {
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
      expect(
        tokens!.searchHighlightBackground,
        palette.lightColorScheme.primaryContainer,
      );
    });

    test('component tokens are available', () {
      expect(shell.buttonTokens, isNotNull);
      expect(shell.cardTokens, isNotNull);
      expect(shell.navigationTokens, isNotNull);
      expect(shell.iconTokens, isNotNull);
    });

    test('animation curves are valid', () {
      expect(shell.standardCurve, Curves.easeOut);
      expect(shell.decelerateCurve, Curves.easeOut);
      expect(shell.accelerateCurve, Curves.easeIn);
    });

    test('scroll physics is ClampingScrollPhysics', () {
      expect(shell.scrollPhysics, isA<ClampingScrollPhysics>());
    });
  });

  group('AndroidShell ThemeData — all palettes', () {
    const palettes = <Palette>[
      ClassicPalette(),
      OceanPalette(),
      ForestPalette(),
      HighContrastPalette(),
    ];

    for (final palette in palettes) {
      group(palette.label, () {
        test('light theme builds without error', () {
          expect(
            () => const AndroidShell().buildTheme(
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
        });

        test('dark theme builds without error', () {
          expect(
            () => const AndroidShell().buildTheme(
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

        test('colorScheme matches palette', () {
          final theme = const AndroidShell().buildTheme(
            colorScheme: palette.lightColorScheme,
            colors: palette.lightSemantic(),
            brightness: Brightness.light,
            typography: defaultTypographyPrimitives,
            spacing: defaultSpacingPrimitives,
            radii: defaultRadiiPrimitives,
            durations: defaultDurationPrimitives,
          );
          expect(theme.colorScheme.primary, palette.lightColorScheme.primary);
        });
      });
    }
  });
}

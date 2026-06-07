import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_design_system/flow_design_system.dart';

void main() {
  group('IosShell', () {
    const shell = IosShell();

    test('has correct shell id', () {
      expect(shell.id, ShellId.ios);
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
      expect(theme.cardTheme.shape, isNotNull);
      expect(theme.dividerTheme.thickness, 0.5);
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
      expect(
        (theme.appBarTheme.backgroundColor!.a * 255.0).round().clamp(0, 255),
        greaterThan(0),
      );
    });

    test('ios-specific curves are set', () {
      expect(shell.standardCurve, Curves.easeInOut);
      expect(shell.decelerateCurve, Curves.easeOut);
      expect(shell.accelerateCurve, Curves.easeIn);
    });

    test('scroll physics is BouncingScrollPhysics', () {
      expect(shell.scrollPhysics, isA<BouncingScrollPhysics>());
    });

    test('component tokens are available', () {
      expect(shell.buttonTokens.borderRadius, BorderRadius.circular(10));
      expect(shell.cardTokens.borderRadius, BorderRadius.circular(12));
      expect(shell.navigationTokens.sidebarWidth, 280);
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
      expect(tokens!.readingMaxWidth, 720);
    });

    test('app bar centerTitle is true', () {
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

      expect(theme.appBarTheme.centerTitle, isTrue);
    });

    test('ios button tokens have correct min height', () {
      expect(iosButtonTokens.minHeight, 36);
      expect(iosButtonTokens.animationDuration.inMilliseconds, 300);
    });

    test('ios card tokens have correct values', () {
      expect(iosCardTokens.elevation, 0);
      expect(iosCardTokens.padding, const EdgeInsets.all(16));
    });
  });

  group('IosShell — all palettes', () {
    const palettes = <Palette>[
      ClassicPalette(),
      OceanPalette(),
      ForestPalette(),
      HighContrastPalette(),
    ];

    for (final palette in palettes) {
      test('${palette.label} light/dark builds without error', () {
        expect(
          () => const IosShell().buildTheme(
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
          () => const IosShell().buildTheme(
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

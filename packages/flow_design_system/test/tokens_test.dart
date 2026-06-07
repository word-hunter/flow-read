import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_design_system/flow_design_system.dart';

void main() {
  group('FunctionalColors', () {
    test('familiarity colors are defined', () {
      expect(FunctionalColors.familiarityLow, isA<Color>());
      expect(FunctionalColors.familiarityMediumLow, isA<Color>());
      expect(FunctionalColors.familiarityMedium, isA<Color>());
      expect(FunctionalColors.familiarityHigh, isA<Color>());
      expect(FunctionalColors.vocabLearning, isA<Color>());
      expect(FunctionalColors.vocabKnown, isA<Color>());
    });

    test('familiarityColor returns correct color by score', () {
      expect(FunctionalColors.familiarityColor(0.0),
          FunctionalColors.familiarityLow);
      expect(FunctionalColors.familiarityColor(0.3),
          FunctionalColors.familiarityLow);
      expect(FunctionalColors.familiarityColor(0.31),
          FunctionalColors.vocabLearning);
      expect(FunctionalColors.familiarityColor(0.5),
          FunctionalColors.vocabLearning);
      expect(FunctionalColors.familiarityColor(0.51),
          FunctionalColors.familiarityMedium);
      expect(FunctionalColors.familiarityColor(0.7),
          FunctionalColors.familiarityMedium);
      expect(FunctionalColors.familiarityColor(0.71),
          FunctionalColors.familiarityHigh);
      expect(FunctionalColors.familiarityColor(0.9),
          FunctionalColors.familiarityHigh);
      expect(FunctionalColors.familiarityColor(1.0),
          FunctionalColors.familiarityHigh);
    });

    test('practice colors are defined', () {
      expect(FunctionalColors.practiceInference, isA<Color>());
      expect(FunctionalColors.practiceVocab, isA<Color>());
      expect(FunctionalColors.practiceSentence, isA<Color>());
      expect(FunctionalColors.practiceParaphrasing, isA<Color>());
      expect(FunctionalColors.practiceDefault, isA<Color>());
    });

    test('correct/incorrect colors are defined', () {
      expect(FunctionalColors.correct, const Color(0xFF27AE60));
      expect(FunctionalColors.incorrect, const Color(0xFFE74C3C));
    });
  });

  group('Token defaults', () {
    test('spacingPrimitives have correct values', () {
      expect(defaultSpacingPrimitives.xs, 4);
      expect(defaultSpacingPrimitives.sm, 8);
      expect(defaultSpacingPrimitives.md, 16);
      expect(defaultSpacingPrimitives.lg, 24);
      expect(defaultSpacingPrimitives.spacingScale.length, greaterThan(5));
    });

    test('radiiPrimitives have correct values', () {
      expect(defaultRadiiPrimitives.none, 0);
      expect(defaultRadiiPrimitives.sm, 4);
      expect(defaultRadiiPrimitives.md, 8);
      expect(defaultRadiiPrimitives.lg, 12);
      expect(defaultRadiiPrimitives.xl, 16);
      expect(defaultRadiiPrimitives.pill, 999);
    });

    test('durationPrimitives have correct values', () {
      expect(defaultDurationPrimitives.instant, Duration.zero);
      expect(defaultDurationPrimitives.fast, const Duration(milliseconds: 100));
      expect(
        defaultDurationPrimitives.normal,
        const Duration(milliseconds: 200),
      );
      expect(
        defaultDurationPrimitives.themeTransition,
        const Duration(milliseconds: 220),
      );
    });

    test('typographyPrimitives have correct values', () {
      expect(defaultTypographyPrimitives.fontSizeScale, contains(16));
      expect(defaultTypographyPrimitives.fontWeightScale, contains(FontWeight.w400));
      expect(defaultTypographyPrimitives.lineHeightNormal, 1.5);
    });

    test('iconTokens have correct values', () {
      expect(defaultIconTokens.sizeSmall, 16);
      expect(defaultIconTokens.sizeNormal, 20);
      expect(defaultIconTokens.sizeMedium, 24);
      expect(defaultIconTokens.sizeLarge, 32);
      expect(defaultIconTokens.home, Icons.home_outlined);
    });

    test('component tokens are not null', () {
      expect(androidButtonTokens.borderRadius, isNotNull);
      expect(androidCardTokens.borderRadius, isNotNull);
      expect(androidNavigationTokens.sidebarWidth, 260);
    });
  });

  group('SemanticColors', () {
    test('all fields are accessible', () {
      const sc = SemanticColors(
        background: Color(0xFFFFF8EA),
        surface: Color(0xFFFFF8EA),
        surfaceElevated: Color(0xFFF7F0E2),
        surfaceGlass: Color(0xFFFFF8EA),
        textPrimary: Color(0xFF25211C),
        textSecondary: Color(0xFF5F574D),
        textTertiary: Color(0xFF9B9184),
        textDisabled: Color(0xFFB0A89D),
        interactivePrimary: Color(0xFF2F8FB8),
        interactiveSecondary: Color(0xFFC58A1E),
        interactiveTertiary: Color(0xFF3C8C5A),
        interactiveDisabled: Color(0xFFB0A89D),
        borderDefault: Color(0xFFE1D6C8),
        borderFocused: Color(0xFF2F8FB8),
        borderError: Color(0xFFD85C6D),
        statusSuccess: Color(0xFF27AE60),
        statusWarning: Color(0xFFE67E22),
        statusError: Color(0xFFD85C6D),
        statusInfo: Color(0xFF2F8FB8),
        glassTint: Color(0xFFFFFFFA),
        glassStroke: Color(0xFFE1D6C8),
        glassHighlight: Color(0xFFFFFFFA),
        readerBackground: Color(0xFFFFF8EA),
        readerText: Color(0xFF25211C),
        readerSelection: Color(0xFF2F8FB8),
        readerSearchHighlight: Color(0xFFDDF3FA),
        readerSearchHighlightForeground: Color(0xFF0A1E2E),
        readerSidebarBackground: Color(0xFFFFF8EA),
      );

      expect(sc.background, const Color(0xFFFFF8EA));
      expect(sc.textPrimary, const Color(0xFF25211C));
      expect(sc.interactivePrimary, const Color(0xFF2F8FB8));
      expect(sc.readerBackground, const Color(0xFFFFF8EA));
    });
  });

  group('ShellIdLabels', () {
    test('all shell ids have labels', () {
      for (final id in ShellId.values) {
        expect(id.label, isNotEmpty);
      }
    });
  });

  group('ReaderThemeTokens', () {
    test('copyWith preserves unchanged fields', () {
      const tokens = ReaderThemeTokens(
        pageBackground: Color(0xFFFFF8EA),
        pageText: Color(0xFF25211C),
        selectionColor: Color(0xFF2F8FB8),
        searchHighlightBackground: Color(0xFFDDF3FA),
        searchHighlightForeground: Color(0xFF0A1E2E),
        sidebarBackground: Color(0xFFFFF8EA),
        readingMaxWidth: 920,
      );

      final copy = tokens.copyWith(pageBackground: const Color(0xFFFF0000));
      expect(copy.pageBackground, const Color(0xFFFF0000));
      expect(copy.pageText, tokens.pageText);
      expect(copy.readingMaxWidth, tokens.readingMaxWidth);
    });

    test('lerp interpolates colors', () {
      const a = ReaderThemeTokens(
        pageBackground: Color(0xFFFFFFFF),
        pageText: Color(0xFF000000),
        selectionColor: Color(0xFFFF0000),
        searchHighlightBackground: Color(0xFFFFFF00),
        searchHighlightForeground: Color(0xFF000000),
        sidebarBackground: Color(0xFFFFFFFF),
        readingMaxWidth: 600,
      );
      const b = ReaderThemeTokens(
        pageBackground: Color(0xFF000000),
        pageText: Color(0xFFFFFFFF),
        selectionColor: Color(0xFF0000FF),
        searchHighlightBackground: Color(0xFF00FFFF),
        searchHighlightForeground: Color(0xFFFFFFFF),
        sidebarBackground: Color(0xFF000000),
        readingMaxWidth: 900,
      );

      final result = a.lerp(b, 0.5);
      expect(result.pageBackground, isA<Color>());
      expect(result.pageText, isA<Color>());
      expect(result.readingMaxWidth, closeTo(750, 1));
    });

    test('lerp with null returns this', () {
      const tokens = ReaderThemeTokens(
        pageBackground: Color(0xFFFFF8EA),
        pageText: Color(0xFF25211C),
        selectionColor: Color(0xFF2F8FB8),
        searchHighlightBackground: Color(0xFFDDF3FA),
        searchHighlightForeground: Color(0xFF0A1E2E),
        sidebarBackground: Color(0xFFFFF8EA),
        readingMaxWidth: 920,
      );

      final result = tokens.lerp(null, 0.5);
      expect(result.pageBackground, tokens.pageBackground);
      expect(result.readingMaxWidth, tokens.readingMaxWidth);
    });
  });
}

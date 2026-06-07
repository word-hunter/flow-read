import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_design_system/flow_design_system.dart';

void main() {
  group('FlowTheme', () {
    test('builds light theme for classic palette', () {
      final theme = FlowTheme.build(
        shellId: ShellId.android,
        paletteId: PaletteId.classic,
        brightness: Brightness.light,
      );

      expect(theme, isNotNull);
      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);
    });

    test('builds dark theme for classic palette', () {
      final theme = FlowTheme.build(
        shellId: ShellId.android,
        paletteId: PaletteId.classic,
        brightness: Brightness.dark,
      );

      expect(theme, isNotNull);
      expect(theme.brightness, Brightness.dark);
    });

    test('builds theme for all palette combinations', () {
      for (final paletteId in PaletteId.values) {
        for (final brightness in Brightness.values) {
          expect(
            () => FlowTheme.build(
              shellId: ShellId.android,
              paletteId: paletteId,
              brightness: brightness,
            ),
            returnsNormally,
          );
        }
      }
    });

    test('respects scaffoldBackgroundColor override', () {
      final theme = FlowTheme.build(
        shellId: ShellId.android,
        paletteId: PaletteId.classic,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFF0000),
      );

      expect(theme.scaffoldBackgroundColor, const Color(0xFFFF0000));
    });

    test('themeDataFor returns correct FlowThemeData', () {
      final data = FlowTheme.themeDataFor(
        shellId: ShellId.android,
        paletteId: PaletteId.classic,
        brightness: Brightness.light,
      );

      expect(data.shellId, ShellId.android);
      expect(data.paletteId, PaletteId.classic);
      expect(data.surfaceStrategy, SurfaceStrategy.solid);
      expect(data.colors.background, isA<Color>());
    });

    test('unknown shell throws', () {
      // ShellId.ios is not yet registered
      expect(
        () => FlowTheme.build(
          shellId: ShellId.ios,
          paletteId: PaletteId.classic,
          brightness: Brightness.light,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('FlowThemeData', () {
    test('copyWith returns new instance with updated fields', () {
      const original = FlowThemeData(
        shellId: ShellId.android,
        paletteId: PaletteId.classic,
        colors: SemanticColors(
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
        ),
        buttonTokens: androidButtonTokens,
        cardTokens: androidCardTokens,
        navigationTokens: androidNavigationTokens,
        surfaceStrategy: SurfaceStrategy.solid,
        typography: defaultTypographyPrimitives,
        spacing: defaultSpacingPrimitives,
        radii: defaultRadiiPrimitives,
        durations: defaultDurationPrimitives,
      );

      final copy = original.copyWith(
        shellId: ShellId.windows,
        paletteId: PaletteId.ocean,
      );

      expect(copy.shellId, ShellId.windows);
      expect(copy.paletteId, PaletteId.ocean);
      expect(copy.colors, original.colors);
    });

    test('lerp t=0 returns this', () {
      const data = FlowThemeData(
        shellId: ShellId.android,
        paletteId: PaletteId.classic,
        colors: SemanticColors(
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
        ),
        buttonTokens: androidButtonTokens,
        cardTokens: androidCardTokens,
        navigationTokens: androidNavigationTokens,
        surfaceStrategy: SurfaceStrategy.solid,
        typography: defaultTypographyPrimitives,
        spacing: defaultSpacingPrimitives,
        radii: defaultRadiiPrimitives,
        durations: defaultDurationPrimitives,
      );

      final result = data.lerp(data, 0.0);
      expect(result.shellId, data.shellId);
      expect(result.paletteId, data.paletteId);
    });

    test('lerp with null returns this', () {
      const data = FlowThemeData(
        shellId: ShellId.android,
        paletteId: PaletteId.classic,
        colors: SemanticColors(
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
        ),
        buttonTokens: androidButtonTokens,
        cardTokens: androidCardTokens,
        navigationTokens: androidNavigationTokens,
        surfaceStrategy: SurfaceStrategy.solid,
        typography: defaultTypographyPrimitives,
        spacing: defaultSpacingPrimitives,
        radii: defaultRadiiPrimitives,
        durations: defaultDurationPrimitives,
      );

      final result = data.lerp(null, 0.5);
      expect(result.shellId, data.shellId);
    });
  });
}

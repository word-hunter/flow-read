import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../tokens/typography.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';
import '../tokens/durations.dart';
import '../tokens/semantic_colors.dart';
import '../tokens/component_tokens.dart';
import '../tokens/icons.dart';
import '../theme/reader_theme_tokens.dart';
import 'shell.dart';
import 'macos_standard_shell.dart';

class MacOsLiquidGlassShell implements Shell {
  const MacOsLiquidGlassShell();

  @override
  ShellId get id => ShellId.macosLiquidGlass;

  @override
  String get label => 'macOS Liquid Glass';

  @override
  bool isAvailableOnCurrentPlatform() {
    if (defaultTargetPlatform != TargetPlatform.macOS) return false;
    if (!_supportsBackdropFilter) return false;
    return true;
  }

  static bool get _supportsBackdropFilter {
    try {
      final version = Platform.operatingSystemVersion;
      final major = int.tryParse(version.split('.').first) ?? 0;
      return major >= 15;
    } catch (_) {
      return false;
    }
  }

  static const _cardRadius = 8.0;
  static const _buttonRadius = 6.0;
  static const _dialogRadius = 10.0;

  @override
  ThemeData buildTheme({
    required ColorScheme colorScheme,
    required SemanticColors colors,
    required Brightness brightness,
    required TypographyPrimitives typography,
    required SpacingPrimitives spacing,
    required RadiiPrimitives radii,
    required DurationPrimitives durations,
    Color? scaffoldBackgroundColor,
  }) {
    final surface = scaffoldBackgroundColor ?? colorScheme.surface;
    final isDark = brightness == Brightness.dark;
    // Glass sidebars use glassTint, content stays opaque
    final glassBg = colors.glassTint;
    final glassStroke = colors.glassStroke;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      visualDensity: VisualDensity.compact,
      extensions: [_readerTokens(colors, surface, isDark)],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: glassBg,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        toolbarHeight: 40,
        titleSpacing: 16,
        shadowColor: glassStroke,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        surfaceTintColor: Colors.transparent,
        color: isDark ? colorScheme.surfaceContainerHighest : surface,
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: glassBg,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        surfaceTintColor: Colors.transparent,
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: glassBg,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
        labelType: NavigationRailLabelType.all,
      ),
      dividerTheme: DividerThemeData(
        color: glassStroke,
        thickness: 0.5,
        space: 0.5,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          side: BorderSide(color: glassStroke),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: glassBg,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_dialogRadius),
        ),
        elevation: 0,
      ),
    );
  }

  @override
  SurfaceStrategy get surfaceStrategy => SurfaceStrategy.glass;

  @override
  ButtonTokens get buttonTokens => macosButtonTokens;

  @override
  CardTokens get cardTokens => macosCardTokens;

  @override
  NavigationTokens get navigationTokens => macosNavigationTokens;

  @override
  IconTokens get iconTokens => defaultIconTokens;

  @override
  Curve get standardCurve => Curves.easeOut;

  @override
  Curve get decelerateCurve => Curves.easeOut;

  @override
  Curve get accelerateCurve => Curves.easeIn;

  @override
  ScrollPhysics get scrollPhysics => const BouncingScrollPhysics();

  static ReaderThemeTokens _readerTokens(
    SemanticColors colors,
    Color surface,
    bool isDark,
  ) {
    return ReaderThemeTokens(
      pageBackground: surface,
      pageText: colors.readerText,
      selectionColor: colors.readerSelection,
      searchHighlightBackground: colors.readerSearchHighlight,
      searchHighlightForeground: colors.readerSearchHighlightForeground,
      sidebarBackground: colors.readerSidebarBackground,
      readingMaxWidth: 820,
    );
  }
}

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

class AndroidShell implements Shell {
  const AndroidShell();

  @override
  ShellId get id => ShellId.android;

  @override
  String get label => 'Android (Material 3)';

  @override
  bool isAvailableOnCurrentPlatform() => true;

  static const _cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );

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

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      extensions: [_readerTokens(colors, surface, isDark)],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: _cardShape,
        surfaceTintColor: Colors.transparent,
        color: isDark ? colorScheme.surfaceContainerHighest : null,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: surface,
        indicatorShape: _cardShape,
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: surface,
        indicatorShape: _cardShape,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  @override
  SurfaceStrategy get surfaceStrategy => SurfaceStrategy.solid;

  @override
  ButtonTokens get buttonTokens => androidButtonTokens;

  @override
  CardTokens get cardTokens => androidCardTokens;

  @override
  NavigationTokens get navigationTokens => androidNavigationTokens;

  @override
  IconTokens get iconTokens => defaultIconTokens;

  @override
  Curve get standardCurve => Curves.easeOut;

  @override
  Curve get decelerateCurve => Curves.easeOut;

  @override
  Curve get accelerateCurve => Curves.easeIn;

  @override
  ScrollPhysics get scrollPhysics => const ClampingScrollPhysics();

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
      readingMaxWidth: 920,
    );
  }
}

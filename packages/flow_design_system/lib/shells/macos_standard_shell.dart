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

class _MacosButtonTokens implements ButtonTokens {
  const _MacosButtonTokens();

  @override
  BorderRadius get borderRadius => BorderRadius.circular(6);
  @override
  EdgeInsets get paddingSmall =>
      const EdgeInsets.symmetric(horizontal: 10, vertical: 4);
  @override
  EdgeInsets get paddingMedium =>
      const EdgeInsets.symmetric(horizontal: 14, vertical: 6);
  @override
  EdgeInsets get paddingLarge =>
      const EdgeInsets.symmetric(horizontal: 18, vertical: 8);
  @override
  double get minHeight => 28;
  @override
  Duration get animationDuration => const Duration(milliseconds: 200);
}

class _MacosCardTokens implements CardTokens {
  const _MacosCardTokens();

  @override
  BorderRadius get borderRadius => BorderRadius.circular(8);
  @override
  double get elevation => 0;
  @override
  EdgeInsets get padding => const EdgeInsets.all(12);
  @override
  Color? get backgroundColor => null;
}

class _MacosNavigationTokens implements NavigationTokens {
  const _MacosNavigationTokens();

  @override
  double get sidebarWidth => 240;
  @override
  double get collapsedSidebarWidth => 68;
  @override
  BorderRadius get itemRadius => BorderRadius.circular(6);
  @override
  double get iconSize => 20;
}

const macosButtonTokens = _MacosButtonTokens();
const macosCardTokens = _MacosCardTokens();
const macosNavigationTokens = _MacosNavigationTokens();

class MacOsStandardShell implements Shell {
  const MacOsStandardShell();

  @override
  ShellId get id => ShellId.macosStandard;

  @override
  String get label => 'macOS Standard HIG';

  @override
  bool isAvailableOnCurrentPlatform() =>
      defaultTargetPlatform == TargetPlatform.macOS;

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
    final sidebarBg = isDark
        ? colorScheme.surface.withValues(alpha: 0.8)
        : surface.withValues(alpha: 0.85);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      visualDensity: VisualDensity.compact,
      extensions: [_readerTokens(colors, surface, isDark)],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        toolbarHeight: 38,
        titleSpacing: 16,
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
        backgroundColor: surface,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: sidebarBg,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
        labelType: NavigationRailLabelType.all,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        thickness: 0.5,
        space: 0.5,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
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
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
    );
  }

  @override
  SurfaceStrategy get surfaceStrategy => SurfaceStrategy.solid;

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

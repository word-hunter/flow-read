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

class _WindowsButtonTokens implements ButtonTokens {
  const _WindowsButtonTokens();

  @override
  BorderRadius get borderRadius => BorderRadius.circular(4);
  @override
  EdgeInsets get paddingSmall =>
      const EdgeInsets.symmetric(horizontal: 10, vertical: 4);
  @override
  EdgeInsets get paddingMedium =>
      const EdgeInsets.symmetric(horizontal: 16, vertical: 6);
  @override
  EdgeInsets get paddingLarge =>
      const EdgeInsets.symmetric(horizontal: 20, vertical: 10);
  @override
  double get minHeight => 32;
  @override
  Duration get animationDuration => const Duration(milliseconds: 250);
}

class _WindowsCardTokens implements CardTokens {
  const _WindowsCardTokens();

  @override
  BorderRadius get borderRadius => BorderRadius.circular(8);
  @override
  double get elevation => 1;
  @override
  EdgeInsets get padding => const EdgeInsets.all(12);
  @override
  Color? get backgroundColor => null;
}

class _WindowsNavigationTokens implements NavigationTokens {
  const _WindowsNavigationTokens();

  @override
  double get sidebarWidth => 256;
  @override
  double get collapsedSidebarWidth => 48;
  @override
  BorderRadius get itemRadius => BorderRadius.circular(4);
  @override
  double get iconSize => 20;
}

const windowsButtonTokens = _WindowsButtonTokens();
const windowsCardTokens = _WindowsCardTokens();
const windowsNavigationTokens = _WindowsNavigationTokens();

class WindowsShell implements Shell {
  const WindowsShell();

  @override
  ShellId get id => ShellId.windows;

  @override
  String get label => 'Windows (Fluent)';

  @override
  bool isAvailableOnCurrentPlatform() =>
      defaultTargetPlatform == TargetPlatform.windows;

  static const _cardRadius = 8.0;
  static const _buttonRadius = 4.0;
  static const _dialogRadius = 8.0;

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
    final acrylicBg = isDark
        ? surface.withValues(alpha: 0.75)
        : surface.withValues(alpha: 0.85);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      visualDensity: VisualDensity.standard,
      extensions: [_readerTokens(colors, surface, isDark)],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        toolbarHeight: 40,
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 1 : 0.5,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        surfaceTintColor: Colors.transparent,
        color: isDark ? colorScheme.surfaceContainerHighest : surface,
        shadowColor: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.04),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: acrylicBg,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: acrylicBg,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
        labelType: NavigationRailLabelType.all,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.6)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_dialogRadius),
        ),
        elevation: isDark ? 4 : 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }

  @override
  SurfaceStrategy get surfaceStrategy => SurfaceStrategy.solid;

  @override
  ButtonTokens get buttonTokens => windowsButtonTokens;

  @override
  CardTokens get cardTokens => windowsCardTokens;

  @override
  NavigationTokens get navigationTokens => windowsNavigationTokens;

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
      readingMaxWidth: 860,
    );
  }
}

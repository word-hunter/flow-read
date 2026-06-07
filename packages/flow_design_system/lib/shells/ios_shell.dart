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

class _IosButtonTokens implements ButtonTokens {
  const _IosButtonTokens();

  @override
  BorderRadius get borderRadius => BorderRadius.circular(10);
  @override
  EdgeInsets get paddingSmall =>
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
  @override
  EdgeInsets get paddingMedium =>
      const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
  @override
  EdgeInsets get paddingLarge =>
      const EdgeInsets.symmetric(horizontal: 22, vertical: 14);
  @override
  double get minHeight => 36;
  @override
  Duration get animationDuration => const Duration(milliseconds: 300);
}

class _IosCardTokens implements CardTokens {
  const _IosCardTokens();

  @override
  BorderRadius get borderRadius => BorderRadius.circular(12);
  @override
  double get elevation => 0;
  @override
  EdgeInsets get padding => const EdgeInsets.all(16);
  @override
  Color? get backgroundColor => null;
}

class _IosNavigationTokens implements NavigationTokens {
  const _IosNavigationTokens();

  @override
  double get sidebarWidth => 280;
  @override
  double get collapsedSidebarWidth => 72;
  @override
  BorderRadius get itemRadius => BorderRadius.circular(10);
  @override
  double get iconSize => 24;
}

const iosButtonTokens = _IosButtonTokens();
const iosCardTokens = _IosCardTokens();
const iosNavigationTokens = _IosNavigationTokens();

class IosShell implements Shell {
  const IosShell();

  @override
  ShellId get id => ShellId.ios;

  @override
  String get label => 'iOS (Cupertino)';

  @override
  bool isAvailableOnCurrentPlatform() =>
      defaultTargetPlatform == TargetPlatform.iOS;

  static const _cardRadius = 12.0;
  static const _buttonRadius = 10.0;
  static const _dialogRadius = 14.0;

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
    final barBg = isDark
        ? surface.withValues(alpha: 0.85)
        : surface.withValues(alpha: 0.85);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      extensions: [_readerTokens(colors, surface, isDark)],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: barBg,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 0.5,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        surfaceTintColor: Colors.transparent,
        color: isDark ? colorScheme.surfaceContainerHighest : surface,
        shadowColor: isDark
            ? Colors.transparent
            : Colors.black.withValues(alpha: 0.06),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: barBg,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: surface,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? colorScheme.outlineVariant.withValues(alpha: 0.3)
            : colorScheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 0.5,
        space: 0.5,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? surface.withValues(alpha: 0.95) : surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_dialogRadius),
        ),
        elevation: isDark ? 0 : 2,
      ),
    );
  }

  @override
  SurfaceStrategy get surfaceStrategy => SurfaceStrategy.solid;

  @override
  ButtonTokens get buttonTokens => iosButtonTokens;

  @override
  CardTokens get cardTokens => iosCardTokens;

  @override
  NavigationTokens get navigationTokens => iosNavigationTokens;

  @override
  IconTokens get iconTokens => defaultIconTokens;

  @override
  Curve get standardCurve => Curves.easeInOut;

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
      readingMaxWidth: 720,
    );
  }
}

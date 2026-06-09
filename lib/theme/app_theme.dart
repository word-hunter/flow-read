import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_surface_tokens.dart';

@Deprecated('Use PaletteId from package:flow_design_system instead')
enum AppThemeId { classic, ocean, forest, highContrast }

@Deprecated('Use PaletteIdLabels from package:flow_design_system instead')
extension AppThemeIdLabels on AppThemeId {
  String get label {
    switch (this) {
      case AppThemeId.classic:
        return '经典';
      case AppThemeId.ocean:
        return '海雾';
      case AppThemeId.forest:
        return '松林';
      case AppThemeId.highContrast:
        return '高对比';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeId.classic:
        return Icons.auto_stories_outlined;
      case AppThemeId.ocean:
        return Icons.water_drop_outlined;
      case AppThemeId.forest:
        return Icons.park_outlined;
      case AppThemeId.highContrast:
        return Icons.contrast_outlined;
    }
  }
}

class ReaderThemeTokens extends ThemeExtension<ReaderThemeTokens> {
  final Color pageBackground;
  final Color pageText;
  final Color selectionColor;
  final Color searchHighlightBackground;
  final Color searchHighlightForeground;
  final Color sidebarBackground;
  final double readingMaxWidth;

  const ReaderThemeTokens({
    required this.pageBackground,
    required this.pageText,
    required this.selectionColor,
    required this.searchHighlightBackground,
    required this.searchHighlightForeground,
    required this.sidebarBackground,
    required this.readingMaxWidth,
  });

  @override
  ReaderThemeTokens copyWith({
    Color? pageBackground,
    Color? pageText,
    Color? selectionColor,
    Color? searchHighlightBackground,
    Color? searchHighlightForeground,
    Color? sidebarBackground,
    double? readingMaxWidth,
  }) {
    return ReaderThemeTokens(
      pageBackground: pageBackground ?? this.pageBackground,
      pageText: pageText ?? this.pageText,
      selectionColor: selectionColor ?? this.selectionColor,
      searchHighlightBackground:
          searchHighlightBackground ?? this.searchHighlightBackground,
      searchHighlightForeground:
          searchHighlightForeground ?? this.searchHighlightForeground,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      readingMaxWidth: readingMaxWidth ?? this.readingMaxWidth,
    );
  }

  @override
  ReaderThemeTokens lerp(ThemeExtension<ReaderThemeTokens>? other, double t) {
    if (other is! ReaderThemeTokens) return this;
    return ReaderThemeTokens(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      pageText: Color.lerp(pageText, other.pageText, t)!,
      selectionColor: Color.lerp(selectionColor, other.selectionColor, t)!,
      searchHighlightBackground: Color.lerp(
        searchHighlightBackground,
        other.searchHighlightBackground,
        t,
      )!,
      searchHighlightForeground: Color.lerp(
        searchHighlightForeground,
        other.searchHighlightForeground,
        t,
      )!,
      sidebarBackground: Color.lerp(
        sidebarBackground,
        other.sidebarBackground,
        t,
      )!,
      readingMaxWidth:
          lerpDouble(readingMaxWidth, other.readingMaxWidth, t) ??
          readingMaxWidth,
    );
  }
}

@Deprecated('Use FlowTheme.build() from package:flow_design_system instead')
class AppTheme {
  static const _warmBeige = Color(0xFFFFFDF9);

  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFC8914A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF5E3CC),
    onPrimaryContainer: Color(0xFF2E200E),
    secondary: Color(0xFF6B5E4B),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF1E4CD),
    onSecondaryContainer: Color(0xFF2A1F0F),
    tertiary: Color(0xFF5B7A67),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFDEE8E0),
    onTertiaryContainer: Color(0xFF15261C),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFFFDF9),
    onSurface: Color(0xFF3A3226),
    surfaceContainerHighest: Color(0xFFF3EFE5),
    onSurfaceVariant: Color(0xFF5C5547),
    outline: Color(0xFF8B8475),
    outlineVariant: Color(0xFFDDD6C6),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2D261B),
    onInverseSurface: Color(0xFFF5F0E6),
    inversePrimary: Color(0xFFDDB87D),
    surfaceTint: Color(0xFFC8914A),
  );

  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFDDB87D),
    onPrimary: Color(0xFF402A0C),
    primaryContainer: Color(0xFF5A3D1A),
    onPrimaryContainer: Color(0xFFF5E3CC),
    secondary: Color(0xFFD4C7B2),
    onSecondary: Color(0xFF362A1A),
    secondaryContainer: Color(0xFF4E3F2D),
    onSecondaryContainer: Color(0xFFF1E4CD),
    tertiary: Color(0xFFC2D2C6),
    onTertiary: Color(0xFF2D3D31),
    tertiaryContainer: Color(0xFF435548),
    onTertiaryContainer: Color(0xFFDEE8E0),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF1C1A15),
    onSurface: Color(0xFFE8E2D6),
    surfaceContainerHighest: Color(0xFF2C2A24),
    onSurfaceVariant: Color(0xFFCCC6B8),
    outline: Color(0xFF969084),
    outlineVariant: Color(0xFF4A463C),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE8E2D6),
    onInverseSurface: Color(0xFF2D261B),
    inversePrimary: Color(0xFFC8914A),
    surfaceTint: Color(0xFFDDB87D),
  );

  static const _oceanLightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF197A8A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD0EFF4),
    onPrimaryContainer: Color(0xFF002A32),
    secondary: Color(0xFF52676C),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD6E7EC),
    onSecondaryContainer: Color(0xFF0E2024),
    tertiary: Color(0xFF7A5A97),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFEADCF8),
    onTertiaryContainer: Color(0xFF2B1242),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF7FBFC),
    onSurface: Color(0xFF172124),
    surfaceContainerHighest: Color(0xFFE6EEF1),
    onSurfaceVariant: Color(0xFF4D5C61),
    outline: Color(0xFF7A8A8F),
    outlineVariant: Color(0xFFC9D4D8),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2B3133),
    onInverseSurface: Color(0xFFEFF5F6),
    inversePrimary: Color(0xFF8ED6E2),
    surfaceTint: Color(0xFF197A8A),
  );

  static const _oceanDarkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF8ED6E2),
    onPrimary: Color(0xFF00363F),
    primaryContainer: Color(0xFF004E5B),
    onPrimaryContainer: Color(0xFFD0EFF4),
    secondary: Color(0xFFB9CBD0),
    onSecondary: Color(0xFF233438),
    secondaryContainer: Color(0xFF394B50),
    onSecondaryContainer: Color(0xFFD6E7EC),
    tertiary: Color(0xFFD8B9EE),
    onTertiary: Color(0xFF41265B),
    tertiaryContainer: Color(0xFF593D73),
    onTertiaryContainer: Color(0xFFEADCF8),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF11191B),
    onSurface: Color(0xFFE1E8EA),
    surfaceContainerHighest: Color(0xFF263033),
    onSurfaceVariant: Color(0xFFC1CACE),
    outline: Color(0xFF8B9599),
    outlineVariant: Color(0xFF414B4E),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE1E8EA),
    onInverseSurface: Color(0xFF2B3133),
    inversePrimary: Color(0xFF197A8A),
    surfaceTint: Color(0xFF8ED6E2),
  );

  static const _forestLightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF3F6F4A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD8E9D2),
    onPrimaryContainer: Color(0xFF05210D),
    secondary: Color(0xFF6C6043),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF4E4BE),
    onSecondaryContainer: Color(0xFF251A06),
    tertiary: Color(0xFF7A4F5D),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFD9E2),
    onTertiaryContainer: Color(0xFF30101B),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFBFCF7),
    onSurface: Color(0xFF191D18),
    surfaceContainerHighest: Color(0xFFE6E9DE),
    onSurfaceVariant: Color(0xFF52584E),
    outline: Color(0xFF82887D),
    outlineVariant: Color(0xFFD0D4C8),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2E322D),
    onInverseSurface: Color(0xFFF0F1EC),
    inversePrimary: Color(0xFFBBD0B5),
    surfaceTint: Color(0xFF3F6F4A),
  );

  static const _forestDarkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFA9D0A7),
    onPrimary: Color(0xFF123719),
    primaryContainer: Color(0xFF28502F),
    onPrimaryContainer: Color(0xFFD8E9D2),
    secondary: Color(0xFFD7C7A1),
    onSecondary: Color(0xFF3B2F13),
    secondaryContainer: Color(0xFF53462A),
    onSecondaryContainer: Color(0xFFF4E4BE),
    tertiary: Color(0xFFEAB8C6),
    onTertiary: Color(0xFF482633),
    tertiaryContainer: Color(0xFF613C49),
    onTertiaryContainer: Color(0xFFFFD9E2),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF151B14),
    onSurface: Color(0xFFE1E4DD),
    surfaceContainerHighest: Color(0xFF293027),
    onSurfaceVariant: Color(0xFFC4C8BD),
    outline: Color(0xFF8E9389),
    outlineVariant: Color(0xFF44483F),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE1E4DD),
    onInverseSurface: Color(0xFF2E322D),
    inversePrimary: Color(0xFF3F6F4A),
    surfaceTint: Color(0xFFA9D0A7),
  );

  static const _contrastLightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0057D8),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD9E4FF),
    onPrimaryContainer: Color(0xFF001A41),
    secondary: Color(0xFF4F5F7D),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDCE5FF),
    onSecondaryContainer: Color(0xFF0A1A35),
    tertiary: Color(0xFF006B5B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF83F8DE),
    onTertiaryContainer: Color(0xFF00201A),
    error: Color(0xFFB00020),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF111111),
    surfaceContainerHighest: Color(0xFFECEFF5),
    onSurfaceVariant: Color(0xFF30343A),
    outline: Color(0xFF565B62),
    outlineVariant: Color(0xFFC6CAD2),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF202124),
    onInverseSurface: Color(0xFFF8F9FA),
    inversePrimary: Color(0xFFAFC6FF),
    surfaceTint: Color(0xFF0057D8),
  );

  static const _contrastDarkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFD84D),
    onPrimary: Color(0xFF171100),
    primaryContainer: Color(0xFF4F3D00),
    onPrimaryContainer: Color(0xFFFFEFAF),
    secondary: Color(0xFFBFD3FF),
    onSecondary: Color(0xFF1D2E50),
    secondaryContainer: Color(0xFF344566),
    onSecondaryContainer: Color(0xFFDCE5FF),
    tertiary: Color(0xFF7CE6CF),
    onTertiary: Color(0xFF00382E),
    tertiaryContainer: Color(0xFF005144),
    onTertiaryContainer: Color(0xFF9DFBE5),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF0B0B0B),
    onSurface: Color(0xFFF6F6F6),
    surfaceContainerHighest: Color(0xFF252525),
    onSurfaceVariant: Color(0xFFD7D7D7),
    outline: Color(0xFFA9A9A9),
    outlineVariant: Color(0xFF595959),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF6F6F6),
    onInverseSurface: Color(0xFF1B1B1B),
    inversePrimary: Color(0xFF0057D8),
    surfaceTint: Color(0xFFFFD84D),
  );

  static const _cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );

  static AppThemeId themeIdFromName(String name) {
    for (final themeId in AppThemeId.values) {
      if (themeId.name == name) return themeId;
    }
    return AppThemeId.classic;
  }

  static ThemeData get lightTheme => lightThemeFor(AppThemeId.classic);

  static ThemeData get darkTheme => darkThemeFor(AppThemeId.classic);

  static ThemeData lightThemeFor(AppThemeId id) {
    switch (id) {
      case AppThemeId.classic:
        return _buildTheme(
          _lightColorScheme,
          scaffoldBackgroundColor: _warmBeige,
        );
      case AppThemeId.ocean:
        return _buildTheme(_oceanLightColorScheme);
      case AppThemeId.forest:
        return _buildTheme(_forestLightColorScheme);
      case AppThemeId.highContrast:
        return _buildTheme(_contrastLightColorScheme);
    }
  }

  static ThemeData darkThemeFor(AppThemeId id) {
    switch (id) {
      case AppThemeId.classic:
        return _buildTheme(_darkColorScheme);
      case AppThemeId.ocean:
        return _buildTheme(_oceanDarkColorScheme);
      case AppThemeId.forest:
        return _buildTheme(_forestDarkColorScheme);
      case AppThemeId.highContrast:
        return _buildTheme(_contrastDarkColorScheme);
    }
  }

  static ThemeData _buildTheme(
    ColorScheme colorScheme, {
    Color? scaffoldBackgroundColor,
  }) {
    final surface = scaffoldBackgroundColor ?? colorScheme.surface;
    final isDark = colorScheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      extensions: [
        _readerTokens(colorScheme, surface),
        _surfaceTokens(colorScheme, surface),
      ],
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static ReaderThemeTokens _readerTokens(
    ColorScheme colorScheme,
    Color surface,
  ) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return ReaderThemeTokens(
      pageBackground: surface,
      pageText: colorScheme.onSurface,
      selectionColor: colorScheme.primary.withValues(
        alpha: isDark ? 0.36 : 0.22,
      ),
      searchHighlightBackground: isDark
          ? colorScheme.tertiaryContainer
          : colorScheme.primaryContainer,
      searchHighlightForeground: isDark
          ? colorScheme.onTertiaryContainer
          : colorScheme.onPrimaryContainer,
      sidebarBackground: colorScheme.surface,
      readingMaxWidth: 920,
    );
  }

  static AppSurfaceTokens _surfaceTokens(
    ColorScheme colorScheme,
    Color surface,
  ) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return isDark ? AppSurfaceTokens.dark() : AppSurfaceTokens.light();
  }
}

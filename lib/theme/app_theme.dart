import 'package:flutter/material.dart';

class AppTheme {
  static const _amber = Color(0xFFC8914A);
  static const _darkBrown = Color(0xFF3A3226);
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

  static const _cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      scaffoldBackgroundColor: _warmBeige,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _warmBeige,
        foregroundColor: _darkBrown,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: _cardShape,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: _warmBeige,
        indicatorShape: _cardShape,
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: _warmBeige,
        indicatorShape: _cardShape,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFDDD6C6),
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
          foregroundColor: _amber,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _warmBeige,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _warmBeige,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,
      scaffoldBackgroundColor: _darkColorScheme.surface,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _darkColorScheme.surface,
        foregroundColor: _darkColorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: _cardShape,
        surfaceTintColor: Colors.transparent,
        color: _darkColorScheme.surfaceContainerHighest,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: _darkColorScheme.surface,
        indicatorShape: _cardShape,
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: _darkColorScheme.surface,
        indicatorShape: _cardShape,
      ),
      dividerTheme: DividerThemeData(
        color: _darkColorScheme.outlineVariant,
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
          foregroundColor: _darkColorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: _darkColorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _darkColorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

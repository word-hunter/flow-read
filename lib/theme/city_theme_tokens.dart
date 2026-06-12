import 'package:flutter/material.dart';

@immutable
class CityThemeTokens extends ThemeExtension<CityThemeTokens> {
  const CityThemeTokens({
    required this.skyTop,
    required this.skyMid,
    required this.skyBottom,
    required this.shellSurface,
    required this.cardSurface,
    required this.panelSurface,
    required this.warmBorder,
    required this.activeBlue,
    required this.activeBlueHover,
    required this.onActiveBlue,
    required this.textPrimary,
    required this.textSecondary,
    required this.warmShadow,
  });

  final Color skyTop;
  final Color skyMid;
  final Color skyBottom;
  final Color shellSurface;
  final Color cardSurface;
  final Color panelSurface;
  final Color warmBorder;
  final Color activeBlue;
  final Color activeBlueHover;
  final Color onActiveBlue;
  final Color textPrimary;
  final Color textSecondary;
  final Color warmShadow;

  static const sunny = CityThemeTokens(
    skyTop: Color(0xFF69BEFE),
    skyMid: Color(0xFFA6D9FD),
    skyBottom: Color(0xFFE9F5FB),
    shellSurface: Color(0xFFFEFAF3),
    cardSurface: Color(0xFFFEFCF8),
    panelSurface: Color(0xFFFEF9EF),
    warmBorder: Color(0xFFEADBC6),
    activeBlue: Color(0xFF0277FE),
    activeBlueHover: Color(0xFF1E8BFF),
    onActiveBlue: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF10233B),
    textSecondary: Color(0xFF5F6F85),
    warmShadow: Color(0x1AE5C99A),
  );

  static const night = CityThemeTokens(
    skyTop: Color(0xFF0B1830),
    skyMid: Color(0xFF101E34),
    skyBottom: Color(0xFF121926),
    shellSurface: Color(0xFF1A2233),
    cardSurface: Color(0xFF1F283B),
    panelSurface: Color(0xFF1A2233),
    warmBorder: Color(0xFF5A5040),
    activeBlue: Color(0xFF5DB0FF),
    activeBlueHover: Color(0xFF9BCAFF),
    onActiveBlue: Color(0xFF001D36),
    textPrimary: Color(0xFFE8EDF2),
    textSecondary: Color(0xFFB7C5D6),
    warmShadow: Color(0x66000000),
  );

  static CityThemeTokens forBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? night : sunny;
  }

  @override
  CityThemeTokens copyWith({
    Color? skyTop,
    Color? skyMid,
    Color? skyBottom,
    Color? shellSurface,
    Color? cardSurface,
    Color? panelSurface,
    Color? warmBorder,
    Color? activeBlue,
    Color? activeBlueHover,
    Color? onActiveBlue,
    Color? textPrimary,
    Color? textSecondary,
    Color? warmShadow,
  }) {
    return CityThemeTokens(
      skyTop: skyTop ?? this.skyTop,
      skyMid: skyMid ?? this.skyMid,
      skyBottom: skyBottom ?? this.skyBottom,
      shellSurface: shellSurface ?? this.shellSurface,
      cardSurface: cardSurface ?? this.cardSurface,
      panelSurface: panelSurface ?? this.panelSurface,
      warmBorder: warmBorder ?? this.warmBorder,
      activeBlue: activeBlue ?? this.activeBlue,
      activeBlueHover: activeBlueHover ?? this.activeBlueHover,
      onActiveBlue: onActiveBlue ?? this.onActiveBlue,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      warmShadow: warmShadow ?? this.warmShadow,
    );
  }

  @override
  CityThemeTokens lerp(ThemeExtension<CityThemeTokens>? other, double t) {
    if (other is! CityThemeTokens) return this;
    return CityThemeTokens(
      skyTop: Color.lerp(skyTop, other.skyTop, t)!,
      skyMid: Color.lerp(skyMid, other.skyMid, t)!,
      skyBottom: Color.lerp(skyBottom, other.skyBottom, t)!,
      shellSurface: Color.lerp(shellSurface, other.shellSurface, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      panelSurface: Color.lerp(panelSurface, other.panelSurface, t)!,
      warmBorder: Color.lerp(warmBorder, other.warmBorder, t)!,
      activeBlue: Color.lerp(activeBlue, other.activeBlue, t)!,
      activeBlueHover: Color.lerp(activeBlueHover, other.activeBlueHover, t)!,
      onActiveBlue: Color.lerp(onActiveBlue, other.onActiveBlue, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      warmShadow: Color.lerp(warmShadow, other.warmShadow, t)!,
    );
  }
}

extension CityThemeX on BuildContext {
  CityThemeTokens get city =>
      Theme.of(this).extension<CityThemeTokens>() ?? CityThemeTokens.sunny;
}

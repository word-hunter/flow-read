import 'package:flutter/material.dart';

import '../../theme/city_theme_tokens.dart';

ButtonStyle rssIconButtonStyle(
  ThemeData theme, {
  bool selected = false,
  bool destructive = false,
}) {
  final colorScheme = theme.colorScheme;
  final activeColor = destructive ? colorScheme.error : rssAccentColor(theme);
  final inactiveColor = destructive
      ? colorScheme.error
      : colorScheme.onSurfaceVariant;

  return ButtonStyle(
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    mouseCursor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return SystemMouseCursors.basic;
      }
      return SystemMouseCursors.click;
    }),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return Colors.transparent;
      }
      if (states.contains(WidgetState.pressed)) {
        return activeColor.withValues(alpha: 0.14);
      }
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return activeColor.withValues(alpha: selected ? 0.16 : 0.08);
      }
      return selected
          ? activeColor.withValues(alpha: 0.12)
          : Colors.transparent;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return colorScheme.onSurface.withValues(alpha: 0.38);
      }
      if (selected ||
          destructive ||
          states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return activeColor;
      }
      return inactiveColor;
    }),
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
  );
}

Color rssHoverColor(ThemeData theme, {bool selected = false}) {
  return rssAccentHoverColor(theme).withValues(alpha: selected ? 0.16 : 0.08);
}

Color rssPressedColor(ThemeData theme) {
  return rssAccentColor(theme).withValues(alpha: 0.18);
}

Color rssAccentColor(ThemeData theme) {
  return theme.extension<CityThemeTokens>()?.activeBlue ??
      theme.colorScheme.primary;
}

Color rssAccentHoverColor(ThemeData theme) {
  return theme.extension<CityThemeTokens>()?.activeBlueHover ??
      theme.colorScheme.primary;
}

Color rssOnAccentColor(ThemeData theme) {
  final brightness = ThemeData.estimateBrightnessForColor(
    rssAccentColor(theme),
  );
  return brightness == Brightness.dark ? Colors.white : Colors.black;
}

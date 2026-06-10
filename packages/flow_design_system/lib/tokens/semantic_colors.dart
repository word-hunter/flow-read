import 'package:flutter/painting.dart';

class SemanticColors {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceGlass;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color interactivePrimary;
  final Color interactiveSecondary;
  final Color interactiveTertiary;
  final Color interactiveDisabled;
  final Color borderDefault;
  final Color borderFocused;
  final Color borderError;
  final Color statusSuccess;
  final Color statusWarning;
  final Color statusError;
  final Color statusInfo;
  final Color glassTint;
  final Color glassStroke;
  final Color glassHighlight;
  final Color readerBackground;
  final Color readerText;
  final Color readerSelection;
  final Color readerSearchHighlight;
  final Color readerSearchHighlightForeground;
  final Color readerSidebarBackground;

  const SemanticColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceGlass,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.interactivePrimary,
    required this.interactiveSecondary,
    required this.interactiveTertiary,
    required this.interactiveDisabled,
    required this.borderDefault,
    required this.borderFocused,
    required this.borderError,
    required this.statusSuccess,
    required this.statusWarning,
    required this.statusError,
    required this.statusInfo,
    required this.glassTint,
    required this.glassStroke,
    required this.glassHighlight,
    required this.readerBackground,
    required this.readerText,
    required this.readerSelection,
    required this.readerSearchHighlight,
    required this.readerSearchHighlightForeground,
    required this.readerSidebarBackground,
  });

  SemanticColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceGlass,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? interactivePrimary,
    Color? interactiveSecondary,
    Color? interactiveTertiary,
    Color? interactiveDisabled,
    Color? borderDefault,
    Color? borderFocused,
    Color? borderError,
    Color? statusSuccess,
    Color? statusWarning,
    Color? statusError,
    Color? statusInfo,
    Color? glassTint,
    Color? glassStroke,
    Color? glassHighlight,
    Color? readerBackground,
    Color? readerText,
    Color? readerSelection,
    Color? readerSearchHighlight,
    Color? readerSearchHighlightForeground,
    Color? readerSidebarBackground,
  }) {
    return SemanticColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceGlass: surfaceGlass ?? this.surfaceGlass,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      interactivePrimary: interactivePrimary ?? this.interactivePrimary,
      interactiveSecondary: interactiveSecondary ?? this.interactiveSecondary,
      interactiveTertiary: interactiveTertiary ?? this.interactiveTertiary,
      interactiveDisabled: interactiveDisabled ?? this.interactiveDisabled,
      borderDefault: borderDefault ?? this.borderDefault,
      borderFocused: borderFocused ?? this.borderFocused,
      borderError: borderError ?? this.borderError,
      statusSuccess: statusSuccess ?? this.statusSuccess,
      statusWarning: statusWarning ?? this.statusWarning,
      statusError: statusError ?? this.statusError,
      statusInfo: statusInfo ?? this.statusInfo,
      glassTint: glassTint ?? this.glassTint,
      glassStroke: glassStroke ?? this.glassStroke,
      glassHighlight: glassHighlight ?? this.glassHighlight,
      readerBackground: readerBackground ?? this.readerBackground,
      readerText: readerText ?? this.readerText,
      readerSelection: readerSelection ?? this.readerSelection,
      readerSearchHighlight:
          readerSearchHighlight ?? this.readerSearchHighlight,
      readerSearchHighlightForeground:
          readerSearchHighlightForeground ??
          this.readerSearchHighlightForeground,
      readerSidebarBackground:
          readerSidebarBackground ?? this.readerSidebarBackground,
    );
  }
}

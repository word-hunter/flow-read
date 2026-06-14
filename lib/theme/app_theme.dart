import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

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

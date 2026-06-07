import 'package:flutter/material.dart';
import '../tokens/semantic_colors.dart';

SemanticColors semanticFromColorScheme(
  ColorScheme cs, {
  Color? scaffoldBackground,
}) {
  final isDark = cs.brightness == Brightness.dark;
  final surface = scaffoldBackground ?? cs.surface;
  return SemanticColors(
    background: surface,
    surface: cs.surface,
    surfaceElevated: cs.surfaceContainerHighest,
    surfaceGlass: cs.surface,
    textPrimary: cs.onSurface,
    textSecondary: cs.onSurfaceVariant,
    textTertiary: cs.outline,
    textDisabled: cs.onSurface.withValues(alpha: 0.38),
    interactivePrimary: cs.primary,
    interactiveSecondary: cs.secondary,
    interactiveTertiary: cs.tertiary,
    interactiveDisabled: cs.onSurface.withValues(alpha: 0.38),
    borderDefault: cs.outlineVariant,
    borderFocused: cs.primary,
    borderError: cs.error,
    statusSuccess: const Color(0xFF27AE60),
    statusWarning: const Color(0xFFE67E22),
    statusError: cs.error,
    statusInfo: cs.primary,
    glassTint: cs.surface.withValues(alpha: 0.85),
    glassStroke: cs.outlineVariant.withValues(alpha: 0.2),
    glassHighlight: Colors.white.withValues(alpha: 0.08),
    readerBackground: surface,
    readerText: cs.onSurface,
    readerSelection: cs.primary.withValues(alpha: isDark ? 0.36 : 0.22),
    readerSearchHighlight:
        isDark ? cs.tertiaryContainer : cs.primaryContainer,
    readerSearchHighlightForeground:
        isDark ? cs.onTertiaryContainer : cs.onPrimaryContainer,
    readerSidebarBackground: cs.surface,
  );
}

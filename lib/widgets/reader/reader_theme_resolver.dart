import 'package:flow_read_atmosphere/flow_read_atmosphere.dart';
import 'package:flutter/material.dart';

import '../../providers/reading/reading_config_notifier.dart';
import '../../theme/app_surface_tokens.dart';

const _darkReaderText = Color(0xFFEAF1FA);
const _darkReaderMutedText = Color(0xFFB7C5D6);

AppSurfaceTokens _darkSurfaceTokensFor(AppSurfaceTokens surfaceTokens) {
  if (surfaceTokens.readerOpaqueSurface ==
          AppSurfaceTokens.cityLight().readerOpaqueSurface &&
      surfaceTokens.readerWorkspaceBackground ==
          AppSurfaceTokens.cityLight().readerWorkspaceBackground) {
    return AppSurfaceTokens.cityDark();
  }

  return switch (surfaceTokens.strategy) {
    SurfaceStrategy.highContrast => AppSurfaceTokens.highContrastDark(),
    _ => AppSurfaceTokens.dark(),
  };
}

bool _isDarkReaderTheme(ReadingConfigState config) {
  return config.readingTheme == 'dark';
}

bool usesDarkReaderPalette(
  ReadingConfigState config,
  CityThemePreset? cityPreset, {
  Brightness? appBrightness,
}) {
  if (cityPreset != null) return cityPreset.phase == CityTimePhase.night;
  if (_isDarkReaderTheme(config)) return true;
  return config.readingTheme == 'light' && appBrightness == Brightness.dark;
}

Color resolveReaderTextColor(
  ReadingConfigState config,
  CityThemePreset? cityPreset, {
  Brightness? appBrightness,
}) {
  if (cityPreset != null) return cityPreset.primaryText;
  if (usesDarkReaderPalette(
    config,
    cityPreset,
    appBrightness: appBrightness,
  )) {
    return _darkReaderText;
  }

  switch (config.readingTheme) {
    case 'sepia':
      return const Color(0xFF30281F);
    default:
      return const Color(0xFF20231F);
  }
}

Color resolveReaderMutedTextColor(
  ReadingConfigState config,
  CityThemePreset? cityPreset, {
  Brightness? appBrightness,
}) {
  if (cityPreset != null) return cityPreset.secondaryText;
  if (usesDarkReaderPalette(
    config,
    cityPreset,
    appBrightness: appBrightness,
  )) {
    return _darkReaderMutedText;
  }

  switch (config.readingTheme) {
    case 'sepia':
      return const Color(0xFF6F6251);
    default:
      return const Color(0xFF626960);
  }
}

Color resolveReaderPageBackgroundColor(
  ReadingConfigState config,
  CityThemePreset? cityPreset,
  AppSurfaceTokens surfaceTokens,
) {
  if (cityPreset != null) {
    return cityPreset.pageBackground.withValues(
      alpha: cityPreset.phase == CityTimePhase.night ? 0.96 : 0.92,
    );
  }

  if (_isDarkReaderTheme(config)) {
    return _darkSurfaceTokensFor(surfaceTokens).readerOpaqueSurface;
  }

  switch (config.readingTheme) {
    case 'sepia':
      return const Color(0xFFF5ECD7);
    default:
      return surfaceTokens.readerOpaqueSurface;
  }
}

Color resolveReaderWorkspaceBackgroundColor(
  ReadingConfigState config,
  AppSurfaceTokens surfaceTokens,
  CityThemePreset? cityPreset,
) {
  if (cityPreset != null) {
    return cityPreset.phase == CityTimePhase.night
        ? _darkSurfaceTokensFor(surfaceTokens).readerWorkspaceBackground
        : surfaceTokens.readerWorkspaceBackground;
  }

  if (_isDarkReaderTheme(config)) {
    return _darkSurfaceTokensFor(surfaceTokens).readerWorkspaceBackground;
  }
  return surfaceTokens.readerWorkspaceBackground;
}

Color resolveReaderToolbarBackgroundColor(
  ReadingConfigState config,
  CityThemePreset? cityPreset,
  AppSurfaceTokens surfaceTokens,
) {
  if (cityPreset != null) {
    return cityPreset.surface.withValues(
      alpha: cityPreset.phase == CityTimePhase.night ? 0.82 : 0.78,
    );
  }

  if (_isDarkReaderTheme(config)) {
    return _darkSurfaceTokensFor(surfaceTokens).readerControlSurface;
  }

  return surfaceTokens.readerControlSurface;
}

Color resolveReaderToolbarBorderColor(
  ReadingConfigState config,
  CityThemePreset? cityPreset,
  AppSurfaceTokens surfaceTokens,
) {
  if (cityPreset != null) {
    return cityPreset.outline.withValues(alpha: 0.72);
  }

  if (_isDarkReaderTheme(config)) {
    return _darkSurfaceTokensFor(surfaceTokens).readerPageBorderColor;
  }

  return surfaceTokens.readerPageBorderColor;
}

Color resolveReaderToolbarForegroundColor(
  ReadingConfigState config,
  CityThemePreset? cityPreset,
  ThemeData theme,
) {
  if (cityPreset != null) return cityPreset.secondaryText;
  if (_isDarkReaderTheme(config)) return _darkReaderMutedText;
  return theme.colorScheme.onSurfaceVariant;
}

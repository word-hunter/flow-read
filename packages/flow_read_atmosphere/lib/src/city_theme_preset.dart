import 'package:flutter/material.dart';

import 'city_atmosphere_settings.dart';

class CityThemePreset {
  final String id;
  final String label;
  final CityTimePhase phase;
  final Color pageBackground;
  final Color surface;
  final Color surfaceSoft;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color outline;
  final AtmosphereScene atmosphereScene;
  final double atmosphereIntensity;
  final bool allowParticles;
  final bool allowFlash;

  const CityThemePreset({
    required this.id,
    required this.label,
    required this.phase,
    required this.pageBackground,
    required this.surface,
    required this.surfaceSoft,
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.outline,
    required this.atmosphereScene,
    required this.atmosphereIntensity,
    this.allowParticles = true,
    this.allowFlash = false,
  });
}

class CityThemePresets {
  static const cityDawn = CityThemePreset(
    id: 'cityDawn',
    label: '清晨',
    phase: CityTimePhase.dawn,
    pageBackground: Color(0xFFFFF8EA),
    surface: Color(0xFFFFFFFF),
    surfaceSoft: Color(0xFFFFF3D8),
    primaryText: Color(0xFF344052),
    secondaryText: Color(0xFF6C7482),
    accent: Color(0xFFF7D77A),
    outline: Color(0xFFEBDDBF),
    atmosphereScene: AtmosphereScene.cityMorning,
    atmosphereIntensity: 0.30,
  );

  static const cityDay = CityThemePreset(
    id: 'cityDay',
    label: '白天',
    phase: CityTimePhase.day,
    pageBackground: Color(0xFFFFFDF4),
    surface: Color(0xFFFFFFFF),
    surfaceSoft: Color(0xFFF2FAF7),
    primaryText: Color(0xFF2F3A4A),
    secondaryText: Color(0xFF687385),
    accent: Color(0xFFAEDCC0),
    outline: Color(0xFFD9E9E0),
    atmosphereScene: AtmosphereScene.cityLandscapeDay,
    atmosphereIntensity: 0.32,
    allowParticles: false,
  );

  static const cityDusk = CityThemePreset(
    id: 'cityDusk',
    label: '黄昏',
    phase: CityTimePhase.dusk,
    pageBackground: Color(0xFFFFF3E2),
    surface: Color(0xFFFFF8EA),
    surfaceSoft: Color(0xFFFFE6D0),
    primaryText: Color(0xFF3D3A42),
    secondaryText: Color(0xFF786E72),
    accent: Color(0xFFE9907D),
    outline: Color(0xFFEAC9B9),
    atmosphereScene: AtmosphereScene.cityDusk,
    atmosphereIntensity: 0.30,
  );

  static const cityNight = CityThemePreset(
    id: 'cityNight',
    label: '夜晚',
    phase: CityTimePhase.night,
    pageBackground: Color(0xFF232B46),
    surface: Color(0xFF2F3856),
    surfaceSoft: Color(0xFF354060),
    primaryText: Color(0xFFF4F1E8),
    secondaryText: Color(0xFFBFC8F2),
    accent: Color(0xFFBFC8F2),
    outline: Color(0xFF4E5A79),
    atmosphereScene: AtmosphereScene.cityMoon,
    atmosphereIntensity: 0.26,
  );

  static const all = <CityThemePreset>[
    cityDawn,
    cityDay,
    cityDusk,
    cityNight,
  ];

  const CityThemePresets._();

  static CityThemePreset byId(String id) {
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return cityDawn;
  }

  static bool containsId(String id) {
    return all.any((preset) => preset.id == id);
  }

  static CityThemePreset byPhase(CityTimePhase phase) {
    return switch (phase) {
      CityTimePhase.dawn => cityDawn,
      CityTimePhase.day => cityDay,
      CityTimePhase.dusk => cityDusk,
      CityTimePhase.night => cityNight,
    };
  }
}

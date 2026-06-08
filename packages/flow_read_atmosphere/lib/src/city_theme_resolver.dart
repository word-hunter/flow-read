import 'city_atmosphere_settings.dart';
import 'city_theme_preset.dart';

class CityThemeResolver {
  const CityThemeResolver._();

  static CityTimePhase phaseFor(DateTime now) {
    final local = now.toLocal();
    final minutes = local.hour * 60 + local.minute;

    if (minutes >= 5 * 60 && minutes < 9 * 60) {
      return CityTimePhase.dawn;
    }
    if (minutes >= 9 * 60 && minutes < 17 * 60) {
      return CityTimePhase.day;
    }
    if (minutes >= 17 * 60 && minutes < 19 * 60 + 30) {
      return CityTimePhase.dusk;
    }
    return CityTimePhase.night;
  }

  static CityThemePreset resolve({
    required DateTime now,
    required CityAtmosphereSettings settings,
  }) {
    if (settings.themeMode == CityThemeMode.manual) {
      return CityThemePresets.byId(settings.manualThemeId);
    }
    return CityThemePresets.byPhase(phaseFor(now));
  }
}

class AtmosphereSceneResolver {
  const AtmosphereSceneResolver._();

  static AtmosphereScene resolve({
    required CityThemePreset preset,
    required CityAtmosphereSettings settings,
  }) {
    if (!settings.enabled || settings.reduceMotion) {
      return AtmosphereScene.none;
    }

    return switch (settings.blendMode) {
      AtmosphereBlendMode.off => AtmosphereScene.none,
      AtmosphereBlendMode.followTheme => preset.atmosphereScene,
      AtmosphereBlendMode.manualOverride => _safeManualScene(
        settings.manualScene,
        settings,
      ),
    };
  }

  static AtmosphereScene _safeManualScene(
    AtmosphereScene scene,
    CityAtmosphereSettings settings,
  ) {
    if (scene == AtmosphereScene.cityStormHint &&
        (settings.reduceMotion ||
            settings.performanceMode == AtmospherePerformanceMode.low ||
            settings.normalizedIntensity < 0.2)) {
      return AtmosphereScene.cityRain;
    }
    return scene;
  }
}

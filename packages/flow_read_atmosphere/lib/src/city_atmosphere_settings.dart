enum CityThemeMode {
  systemTime,
  manual,
}

extension CityThemeModeLabels on CityThemeMode {
  String get label {
    return switch (this) {
      CityThemeMode.systemTime => '跟随时间',
      CityThemeMode.manual => '手动固定',
    };
  }
}

enum CityTimePhase {
  dawn,
  day,
  dusk,
  night,
}

extension CityTimePhaseLabels on CityTimePhase {
  String get label {
    return switch (this) {
      CityTimePhase.dawn => '清晨',
      CityTimePhase.day => '白天',
      CityTimePhase.dusk => '黄昏',
      CityTimePhase.night => '夜晚',
    };
  }
}

enum AtmosphereBlendMode {
  followTheme,
  off,
  manualOverride,
}

extension AtmosphereBlendModeLabels on AtmosphereBlendMode {
  String get label {
    return switch (this) {
      AtmosphereBlendMode.followTheme => '跟随主题',
      AtmosphereBlendMode.off => '关闭',
      AtmosphereBlendMode.manualOverride => '手动选择',
    };
  }
}

enum AtmosphereScene {
  none,
  cityMorning,
  cityDay,
  cityLandscapeDay,
  cityDusk,
  cityMoon,
  cityRain,
  cityWind,
  cityStormHint,
}

extension AtmosphereSceneLabels on AtmosphereScene {
  String get label {
    return switch (this) {
      AtmosphereScene.none => '无',
      AtmosphereScene.cityMorning => '晨光',
      AtmosphereScene.cityDay => '白日',
      AtmosphereScene.cityLandscapeDay => '蓝天草坡',
      AtmosphereScene.cityDusk => '黄昏',
      AtmosphereScene.cityMoon => '月夜',
      AtmosphereScene.cityRain => '小雨',
      AtmosphereScene.cityWind => '微风',
      AtmosphereScene.cityStormHint => '远雨',
    };
  }
}

enum AtmospherePerformanceMode {
  auto,
  low,
  balanced,
}

extension AtmospherePerformanceModeLabels on AtmospherePerformanceMode {
  String get label {
    return switch (this) {
      AtmospherePerformanceMode.auto => '自动',
      AtmospherePerformanceMode.low => '省电',
      AtmospherePerformanceMode.balanced => '平衡',
    };
  }
}

class CityAtmosphereSettings {
  final bool enabled;
  final CityThemeMode themeMode;
  final String manualThemeId;
  final AtmosphereBlendMode blendMode;
  final AtmosphereScene manualScene;
  final double atmosphereIntensity;
  final bool reduceMotion;
  final AtmospherePerformanceMode performanceMode;

  const CityAtmosphereSettings({
    this.enabled = false,
    this.themeMode = CityThemeMode.systemTime,
    this.manualThemeId = 'cityDawn',
    this.blendMode = AtmosphereBlendMode.followTheme,
    this.manualScene = AtmosphereScene.none,
    this.atmosphereIntensity = 0.30,
    this.reduceMotion = false,
    this.performanceMode = AtmospherePerformanceMode.auto,
  });

  double get normalizedIntensity {
    return atmosphereIntensity.clamp(0.0, 1.0).toDouble();
  }

  CityAtmosphereSettings copyWith({
    bool? enabled,
    CityThemeMode? themeMode,
    String? manualThemeId,
    AtmosphereBlendMode? blendMode,
    AtmosphereScene? manualScene,
    double? atmosphereIntensity,
    bool? reduceMotion,
    AtmospherePerformanceMode? performanceMode,
  }) {
    return CityAtmosphereSettings(
      enabled: enabled ?? this.enabled,
      themeMode: themeMode ?? this.themeMode,
      manualThemeId: manualThemeId ?? this.manualThemeId,
      blendMode: blendMode ?? this.blendMode,
      manualScene: manualScene ?? this.manualScene,
      atmosphereIntensity: atmosphereIntensity ?? this.atmosphereIntensity,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      performanceMode: performanceMode ?? this.performanceMode,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CityAtmosphereSettings &&
        other.enabled == enabled &&
        other.themeMode == themeMode &&
        other.manualThemeId == manualThemeId &&
        other.blendMode == blendMode &&
        other.manualScene == manualScene &&
        other.atmosphereIntensity == atmosphereIntensity &&
        other.reduceMotion == reduceMotion &&
        other.performanceMode == performanceMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      enabled,
      themeMode,
      manualThemeId,
      blendMode,
      manualScene,
      atmosphereIntensity,
      reduceMotion,
      performanceMode,
    );
  }
}

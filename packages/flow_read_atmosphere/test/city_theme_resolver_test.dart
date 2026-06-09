import 'package:flow_read_atmosphere/flow_read_atmosphere.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CityThemeResolver.phaseFor', () {
    test('resolves all time boundaries', () {
      expect(_phaseAt(4, 59), CityTimePhase.night);
      expect(_phaseAt(5, 0), CityTimePhase.dawn);
      expect(_phaseAt(8, 59), CityTimePhase.dawn);
      expect(_phaseAt(9, 0), CityTimePhase.day);
      expect(_phaseAt(16, 59), CityTimePhase.day);
      expect(_phaseAt(17, 0), CityTimePhase.dusk);
      expect(_phaseAt(19, 29), CityTimePhase.dusk);
      expect(_phaseAt(19, 30), CityTimePhase.night);
    });
  });

  group('CityThemeResolver.resolve', () {
    test('manual theme ignores current time', () {
      const settings = CityAtmosphereSettings(
        enabled: true,
        themeMode: CityThemeMode.manual,
        manualThemeId: 'cityNight',
      );

      final preset = CityThemeResolver.resolve(
        now: DateTime(2026, 6, 9, 12),
        settings: settings,
      );

      expect(preset.id, 'cityNight');
    });

    test('unknown manual theme falls back to dawn', () {
      const settings = CityAtmosphereSettings(
        enabled: true,
        themeMode: CityThemeMode.manual,
        manualThemeId: 'unknown',
      );

      final preset = CityThemeResolver.resolve(
        now: DateTime(2026, 6, 9, 12),
        settings: settings,
      );

      expect(preset.id, 'cityDawn');
    });
  });

  group('CityThemePresets', () {
    test('city day uses the landscape scene', () {
      expect(
        CityThemePresets.cityDay.atmosphereScene,
        AtmosphereScene.cityLandscapeDay,
      );
    });
  });

  group('AtmosphereSceneResolver', () {
    test('turns scene off when blend mode is off', () {
      const settings = CityAtmosphereSettings(
        enabled: true,
        blendMode: AtmosphereBlendMode.off,
      );

      expect(
        AtmosphereSceneResolver.resolve(
          preset: CityThemePresets.cityDawn,
          settings: settings,
        ),
        AtmosphereScene.none,
      );
    });

    test('manual override uses the selected scene', () {
      const settings = CityAtmosphereSettings(
        enabled: true,
        blendMode: AtmosphereBlendMode.manualOverride,
        manualScene: AtmosphereScene.cityWind,
      );

      expect(
        AtmosphereSceneResolver.resolve(
          preset: CityThemePresets.cityDawn,
          settings: settings,
        ),
        AtmosphereScene.cityWind,
      );
    });

    test(
      'reduce motion keeps follow-theme scene available for static paint',
      () {
        const settings = CityAtmosphereSettings(
          enabled: true,
          reduceMotion: true,
        );

        expect(
          AtmosphereSceneResolver.resolve(
            preset: CityThemePresets.cityDay,
            settings: settings,
          ),
          AtmosphereScene.cityLandscapeDay,
        );
      },
    );

    test('storm hint is downgraded in low performance mode', () {
      const settings = CityAtmosphereSettings(
        enabled: true,
        blendMode: AtmosphereBlendMode.manualOverride,
        manualScene: AtmosphereScene.cityStormHint,
        performanceMode: AtmospherePerformanceMode.low,
      );

      expect(
        AtmosphereSceneResolver.resolve(
          preset: CityThemePresets.cityDawn,
          settings: settings,
        ),
        AtmosphereScene.cityRain,
      );
    });
  });
}

CityTimePhase _phaseAt(int hour, int minute) {
  return CityThemeResolver.phaseFor(DateTime(2026, 6, 9, hour, minute));
}

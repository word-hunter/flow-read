import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/dao/settings_dao.dart';
import 'package:flow_read_atmosphere/flow_read_atmosphere.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<AppDatabase> databases;

  setUp(() {
    databases = [];
  });

  tearDown(() async {
    for (final db in databases) {
      await db.close();
    }
  });

  test(
    'city atmosphere settings are disabled by default and persist',
    () async {
      final db = await AppDatabase.createInMemory();
      databases.add(db);
      final dao = SettingsDao(db);
      final settings = SettingsService(dao);
      await settings.init();

      expect(settings.cityAtmosphereSettings, const CityAtmosphereSettings());

      await settings.setCityAtmosphereEnabled(true);
      await settings.setCityThemeMode(CityThemeMode.manual);
      await settings.setManualCityTheme('cityNight');
      await settings.setAtmosphereBlendMode(AtmosphereBlendMode.manualOverride);
      await settings.setManualAtmosphereScene(AtmosphereScene.cityRain);
      await settings.setAtmosphereIntensity(0.72);
      await settings.setReduceAtmosphereMotion(true);
      await settings.setAtmospherePerformanceMode(
        AtmospherePerformanceMode.low,
      );

      final reloaded = SettingsService(dao);
      await reloaded.init();
      final city = reloaded.cityAtmosphereSettings;

      expect(city.enabled, isTrue);
      expect(city.themeMode, CityThemeMode.manual);
      expect(city.manualThemeId, 'cityNight');
      expect(city.blendMode, AtmosphereBlendMode.manualOverride);
      expect(city.manualScene, AtmosphereScene.cityRain);
      expect(city.atmosphereIntensity, 0.72);
      expect(city.reduceMotion, isTrue);
      expect(city.performanceMode, AtmospherePerformanceMode.low);
    },
  );

  test('invalid city atmosphere values fall back safely', () async {
    final db = await AppDatabase.createInMemory();
    databases.add(db);
    final dao = SettingsDao(db);
    await dao.putValue('city_atmosphere.theme_mode', 'legacy');
    await dao.putValue('city_atmosphere.manual_theme_id', 'missing');
    await dao.putValue('city_atmosphere.blend_mode', 'legacy');
    await dao.putValue('city_atmosphere.manual_scene', 'legacy');
    await dao.putValue('city_atmosphere.intensity', '2.5');
    await dao.putValue('city_atmosphere.performance_mode', 'legacy');

    final settings = SettingsService(dao);
    await settings.init();
    final city = settings.cityAtmosphereSettings;

    expect(city.themeMode, CityThemeMode.systemTime);
    expect(city.manualThemeId, 'cityDawn');
    expect(city.blendMode, AtmosphereBlendMode.followTheme);
    expect(city.manualScene, AtmosphereScene.none);
    expect(city.atmosphereIntensity, 1.0);
    expect(city.performanceMode, AtmospherePerformanceMode.auto);
  });
}

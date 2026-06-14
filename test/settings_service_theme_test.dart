import 'dart:io';

import 'package:flow_design_system/flow_design_system.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/storage/database/dao/settings_dao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initTestStorage('flow_read_theme_settings_test_');
    await openFlowReadTestStorage();
  });

  tearDown(() async {
    await disposeTestStorage(tempDir);
  });

  test('app theme family and brightness mode persist', () async {
    final db = await createTestAppDatabase();
    final settings = SettingsService(SettingsDao(db));
    await settings.init();

    expect(settings.appThemeId, PaletteId.classic);
    expect(settings.themeMode, ThemeMode.system);

    await settings.setAppThemeId(PaletteId.ocean);
    await settings.setThemeMode(ThemeMode.dark);

    final reloaded = SettingsService(SettingsDao(db));
    await reloaded.init();

    expect(reloaded.appThemeId, PaletteId.ocean);
    expect(reloaded.themeMode, ThemeMode.dark);
  });

  test('theme mode toggle cycles through system, light, and dark', () async {
    final settings = await createTestSettingsService();

    expect(settings.themeMode, ThemeMode.system);
    expect(settings.nextThemeMode, ThemeMode.light);

    await settings.toggleThemeMode();
    expect(settings.themeMode, ThemeMode.light);
    expect(settings.nextThemeMode, ThemeMode.dark);

    await settings.toggleThemeMode();
    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.nextThemeMode, ThemeMode.system);

    await settings.toggleThemeMode();
    expect(settings.themeMode, ThemeMode.system);
  });

  test('unknown stored theme family falls back to classic', () async {
    final db = await createTestAppDatabase();
    await db.settingsDao.putValue('appThemeId', 'legacy_theme');

    final settings = SettingsService(SettingsDao(db));
    await settings.init();

    expect(settings.appThemeId, PaletteId.classic);
  });
}

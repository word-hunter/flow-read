import 'dart:io';

import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/dao/settings_dao.dart';
import 'package:flow_read/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_theme_settings_test_');
    await openFlowReadTestBoxes();
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test('app theme family and brightness mode persist', () async {
    final db = await AppDatabase.createInMemory();
    final settings = SettingsService(SettingsDao(db));
    await settings.init();

    expect(settings.appThemeId, AppThemeId.classic);
    expect(settings.themeMode, ThemeMode.system);

    await settings.setAppThemeId(AppThemeId.ocean);
    await settings.setThemeMode(ThemeMode.dark);

    final reloaded = SettingsService(SettingsDao(db));
    await reloaded.init();

    expect(reloaded.appThemeId, AppThemeId.ocean);
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
    await settingsBox().put('appThemeId', 'legacy_theme');

    final settings = await createTestSettingsService();

    expect(settings.appThemeId, AppThemeId.classic);
  });
}

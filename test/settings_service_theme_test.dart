import 'dart:io';

import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_theme_settings_test_');
    await openSettingsTestBox();
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test('app theme family and brightness mode persist', () async {
    final settings = SettingsService();
    await settings.init();

    expect(settings.appThemeId, AppThemeId.classic);
    expect(settings.themeMode, ThemeMode.system);

    await settings.setAppThemeId(AppThemeId.ocean);
    await settings.setThemeMode(ThemeMode.dark);

    final reloaded = SettingsService();
    await reloaded.init();

    expect(reloaded.appThemeId, AppThemeId.ocean);
    expect(reloaded.themeMode, ThemeMode.dark);
  });

  test('theme mode toggle cycles through system, light, and dark', () async {
    final settings = SettingsService();
    await settings.init();

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

    final settings = SettingsService();
    await settings.init();

    expect(settings.appThemeId, AppThemeId.classic);
  });
}

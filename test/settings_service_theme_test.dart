import 'dart:io';

import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'flow_read_theme_settings_test_',
    );
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
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

  test('unknown stored theme family falls back to classic', () async {
    await Hive.box('settings').put('appThemeId', 'legacy_theme');

    final settings = SettingsService();
    await settings.init();

    expect(settings.appThemeId, AppThemeId.classic);
  });
}

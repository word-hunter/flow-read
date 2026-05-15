import 'dart:io';

import 'package:flow_read/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'flow_read_feature_flags_test_',
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

  test(
    'RSS experimental feature is disabled by default and persists',
    () async {
      final settings = SettingsService();
      await settings.init();

      expect(settings.rssFeatureEnabled, isFalse);

      await settings.setRssFeatureEnabled(true);
      expect(settings.rssFeatureEnabled, isTrue);

      final reloaded = SettingsService();
      await reloaded.init();
      expect(reloaded.rssFeatureEnabled, isTrue);

      await reloaded.setRssFeatureEnabled(false);
      expect(reloaded.rssFeatureEnabled, isFalse);
    },
  );
}

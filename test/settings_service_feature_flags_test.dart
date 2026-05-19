import 'dart:io';

import 'package:flow_read/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_feature_flags_test_');
    await openSettingsTestBox();
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test(
    'RSS and browser experimental features are disabled by default and persist',
    () async {
      final settings = SettingsService();
      await settings.init();

      expect(settings.rssFeatureEnabled, isFalse);
      expect(settings.browserFeatureEnabled, isFalse);

      await settings.setRssFeatureEnabled(true);
      await settings.setBrowserFeatureEnabled(true);
      expect(settings.rssFeatureEnabled, isTrue);
      expect(settings.browserFeatureEnabled, isTrue);

      final reloaded = SettingsService();
      await reloaded.init();
      expect(reloaded.rssFeatureEnabled, isTrue);
      expect(reloaded.browserFeatureEnabled, isTrue);

      await reloaded.setRssFeatureEnabled(false);
      await reloaded.setBrowserFeatureEnabled(false);
      expect(reloaded.rssFeatureEnabled, isFalse);
      expect(reloaded.browserFeatureEnabled, isFalse);
    },
  );

  test(
    'AI features are enabled only for the selected provider with a key',
    () async {
      final settings = SettingsService();
      await settings.init();

      expect(settings.aiFeaturesEnabled, isFalse);

      await settings.setApiKey('   ');
      expect(settings.aiFeaturesEnabled, isFalse);

      await settings.setApiKey('deepseek-key');
      expect(settings.aiFeaturesEnabled, isTrue);

      await settings.setAIProvider('openai');
      expect(settings.aiFeaturesEnabled, isFalse);
      expect(settings.aiFeatureDisabledReason, contains('OpenAI API Key'));

      await settings.setApiKey('openai-key');
      expect(settings.aiFeaturesEnabled, isTrue);

      await settings.setAIProvider('deepseek');
      expect(settings.aiFeaturesEnabled, isTrue);
    },
  );
}

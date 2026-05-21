import 'dart:io';

import 'package:flow_read/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_feature_flags_test_');
    await openFlowReadTestBoxes();
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test('experimental features are disabled by default and persist', () async {
    final settings = SettingsService();
    await settings.init();

    expect(settings.rssFeatureEnabled, isFalse);
    expect(settings.browserFeatureEnabled, isFalse);
    expect(settings.reviewFeatureEnabled, isFalse);

    await settings.setRssFeatureEnabled(true);
    await settings.setBrowserFeatureEnabled(true);
    await settings.setReviewFeatureEnabled(true);
    expect(settings.rssFeatureEnabled, isTrue);
    expect(settings.browserFeatureEnabled, isTrue);
    expect(settings.reviewFeatureEnabled, isTrue);

    final reloaded = SettingsService();
    await reloaded.init();
    expect(reloaded.rssFeatureEnabled, isTrue);
    expect(reloaded.browserFeatureEnabled, isTrue);
    expect(reloaded.reviewFeatureEnabled, isTrue);

    await reloaded.setRssFeatureEnabled(false);
    expect(reloaded.rssFeatureEnabled, isFalse);
    expect(reloaded.browserFeatureEnabled, isTrue);
    expect(reloaded.reviewFeatureEnabled, isTrue);

    await reloaded.setBrowserFeatureEnabled(false);
    await reloaded.setReviewFeatureEnabled(false);
    expect(reloaded.browserFeatureEnabled, isFalse);
    expect(reloaded.reviewFeatureEnabled, isFalse);
    expect(reloaded.enabledExperimentalFeatures, isEmpty);
  });

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

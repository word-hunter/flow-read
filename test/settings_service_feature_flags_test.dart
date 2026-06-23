import 'dart:io';

import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/storage/database/dao/settings_dao.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initTestStorage('flow_read_feature_flags_test_');
    await openFlowReadTestStorage();
  });

  tearDown(() async {
    await disposeTestStorage(tempDir);
  });

  test('experimental features are disabled by default and persist', () async {
    final db = await createTestAppDatabase();
    final settings = SettingsService(SettingsDao(db));
    await settings.init();

    expect(settings.rssFeatureEnabled, isFalse);
    expect(settings.reviewFeatureEnabled, isFalse);

    await settings.setRssFeatureEnabled(true);
    await settings.setReviewFeatureEnabled(true);
    expect(settings.rssFeatureEnabled, isTrue);
    expect(settings.reviewFeatureEnabled, isTrue);

    final reloaded = SettingsService(SettingsDao(db));
    await reloaded.init();
    expect(reloaded.rssFeatureEnabled, isTrue);
    expect(reloaded.reviewFeatureEnabled, isTrue);

    await reloaded.setRssFeatureEnabled(false);
    expect(reloaded.rssFeatureEnabled, isFalse);
    expect(reloaded.reviewFeatureEnabled, isTrue);

    await reloaded.setReviewFeatureEnabled(false);
    expect(reloaded.reviewFeatureEnabled, isFalse);
    expect(reloaded.enabledExperimentalFeatures, isEmpty);
  });

  test('legacy browser and v2 feature flags are ignored', () async {
    final db = await createTestAppDatabase();
    final dao = SettingsDao(db);
    await dao.putValue('enabledExperimentalFeatures', '["browser","v2","rss"]');

    final settings = SettingsService(dao);
    await settings.init();

    expect(settings.rssFeatureEnabled, isTrue);
    expect(settings.enabledExperimentalFeatures, {'rss'});
  });

  test(
    'force default book cover is disabled by default and persists',
    () async {
      final db = await createTestAppDatabase();
      final settings = SettingsService(SettingsDao(db));
      await settings.init();

      expect(settings.forceDefaultBookCover, isFalse);

      await settings.setForceDefaultBookCover(true);
      expect(settings.forceDefaultBookCover, isTrue);

      final reloaded = SettingsService(SettingsDao(db));
      await reloaded.init();
      expect(reloaded.forceDefaultBookCover, isTrue);

      await reloaded.setForceDefaultBookCover(false);
      expect(reloaded.forceDefaultBookCover, isFalse);
    },
  );

  test('strict privacy mode is disabled by default and persists', () async {
    final db = await createTestAppDatabase();
    final settings = SettingsService(SettingsDao(db));
    await settings.init();

    expect(settings.strictPrivacyMode, isFalse);

    await settings.setStrictPrivacyMode(true);
    expect(settings.strictPrivacyMode, isTrue);

    final reloaded = SettingsService(SettingsDao(db));
    await reloaded.init();
    expect(reloaded.strictPrivacyMode, isTrue);

    await reloaded.setStrictPrivacyMode(false);
    expect(reloaded.strictPrivacyMode, isFalse);
  });

  test(
    'AI features are enabled only for the selected provider with a key',
    () async {
      final settings = await createTestSettingsService();

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

  test(
    'active source language and target explanation language persist',
    () async {
      final db = await createTestAppDatabase();
      final settings = SettingsService(SettingsDao(db));
      await settings.init();

      expect(settings.activeSourceLanguage, 'en');
      expect(settings.targetExplanationLanguage, 'zh');

      await settings.setActiveSourceLanguage('ja');
      await settings.setTargetExplanationLanguage('en');

      final reloaded = SettingsService(SettingsDao(db));
      await reloaded.init();

      expect(reloaded.activeSourceLanguage, 'ja');
      expect(reloaded.targetExplanationLanguage, 'en');
    },
  );
}

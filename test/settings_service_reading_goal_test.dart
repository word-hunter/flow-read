import 'dart:io';

import 'package:flow_read/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_reading_goal_test_');
    await openSettingsTestBox();
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test(
    'daily reading goal persists and normalizes to supported steps',
    () async {
      final settings = SettingsService();
      await settings.init();

      expect(
        settings.dailyReadingGoalMinutes,
        SettingsService.defaultDailyReadingGoalMinutes,
      );
      expect(settings.dailyReadingGoalSeconds, 3600);

      await settings.setDailyReadingGoalMinutes(95);
      expect(settings.dailyReadingGoalMinutes, 90);

      final reloaded = SettingsService();
      await reloaded.init();
      expect(reloaded.dailyReadingGoalMinutes, 90);

      await reloaded.setDailyReadingGoalMinutes(4);
      expect(
        reloaded.dailyReadingGoalMinutes,
        SettingsService.minDailyReadingGoalMinutes,
      );

      await reloaded.setDailyReadingGoalMinutes(999);
      expect(
        reloaded.dailyReadingGoalMinutes,
        SettingsService.maxDailyReadingGoalMinutes,
      );
    },
  );
}

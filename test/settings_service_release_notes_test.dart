import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late SettingsService settings;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'flow_read_release_notes_test_',
    );
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
    settings = SettingsService();
    await settings.init();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('tracks release notes visibility by app version', () async {
    expect(settings.shouldShowReleaseNotes('0.0.1-alpha'), isTrue);

    await settings.markReleaseNotesSeen('0.0.1-alpha');

    expect(settings.shouldShowReleaseNotes('0.0.1-alpha'), isFalse);
    expect(settings.shouldShowReleaseNotes('0.0.2-alpha'), isTrue);
  });
}

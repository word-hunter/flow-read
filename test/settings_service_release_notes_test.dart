import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flow_read/services/settings_service.dart';

import 'support/hive_test_storage.dart';

void main() {
  late Directory tempDir;
  late SettingsService settings;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_release_notes_test_');
    await openFlowReadTestBoxes();
    settings = await createTestSettingsService();
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test('tracks release notes visibility by app version', () async {
    expect(settings.shouldShowReleaseNotes('0.0.1-alpha'), isTrue);

    await settings.markReleaseNotesSeen('0.0.1-alpha');

    expect(settings.shouldShowReleaseNotes('0.0.1-alpha'), isFalse);
    expect(settings.shouldShowReleaseNotes('0.0.2-alpha'), isTrue);
  });
}

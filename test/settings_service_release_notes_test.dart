import 'dart:async';
import 'dart:io';

import 'package:flow_read/storage/database/dao/settings_dao.dart';
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

  test('waits for release notes seen marker to be persisted', () async {
    final dao = _DeferredReleaseNotesSettingsDao();
    final service = SettingsService(dao);
    await service.init();

    var completed = false;
    final markFuture = service.markReleaseNotesSeen('0.0.1-alpha');
    unawaited(markFuture.then((_) => completed = true));

    await Future<void>.delayed(Duration.zero);

    expect(completed, isFalse);
    expect(dao.valueForKey('lastSeenReleaseNotesVersion'), isNull);

    dao.completePendingWrites();
    await markFuture;

    expect(completed, isTrue);
    expect(
      dao.valueForKey('lastSeenReleaseNotesVersion'),
      '0.0.1-alpha',
    );

    final reloaded = SettingsService(dao);
    await reloaded.init();
    expect(reloaded.shouldShowReleaseNotes('0.0.1-alpha'), isFalse);
  });
}

class _DeferredReleaseNotesSettingsDao implements SettingsDao {
  final Map<String, String> _values = {};
  final List<Completer<void>> _pendingReleaseNoteWrites = [];

  String? valueForKey(String key) => _values[key];

  void completePendingWrites() {
    for (final completer in _pendingReleaseNoteWrites) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  @override
  Future<Map<String, String>> allEntries() async => Map.of(_values);

  @override
  Future<void> putValue(String key, String value) {
    if (key != 'lastSeenReleaseNotesVersion') {
      _values[key] = value;
      return Future.value();
    }

    final completer = Completer<void>();
    _pendingReleaseNoteWrites.add(completer);
    return completer.future.then((_) {
      _values[key] = value;
    });
  }

  @override
  Future<void> removeValue(String key) async {
    _values.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

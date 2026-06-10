import 'dart:async';

import 'package:flow_read/providers/settings_provider.dart';
import 'package:flow_read/services/app_version.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/storage/database/dao/settings_dao.dart';
import 'package:flow_read/widgets/release_notes_dialog.dart';
import 'package:flow_read/widgets/release_notes_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('waits for settings init before checking release notes', (
    tester,
  ) async {
    final dao = _DelayedAllEntriesSettingsDao({
      'lastSeenReleaseNotesVersion': FlowReadVersion.releaseName,
    });
    final settings = SettingsService(dao);

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => settings),
        ],
        child: const MaterialApp(
          home: ReleaseNotesGate(child: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ReleaseNotesDialog), findsNothing);

    dao.completeAllEntries();
    await tester.pumpAndSettle();

    expect(find.byType(ReleaseNotesDialog), findsNothing);
  });
}

class _DelayedAllEntriesSettingsDao implements SettingsDao {
  _DelayedAllEntriesSettingsDao(Map<String, String> values)
    : _values = Map.of(values);

  final Map<String, String> _values;
  final Completer<Map<String, String>> _entriesCompleter =
      Completer<Map<String, String>>();

  void completeAllEntries() {
    if (!_entriesCompleter.isCompleted) {
      _entriesCompleter.complete(Map.of(_values));
    }
  }

  @override
  Future<Map<String, String>> allEntries() => _entriesCompleter.future;

  @override
  Future<void> putValue(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> removeValue(String key) async {
    _values.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

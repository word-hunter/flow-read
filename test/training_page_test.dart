import 'package:flow_read/pages/training_page.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('spaced review training entry is hidden by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsService>.value(
        value: _FakeSettingsService(reviewEnabled: false),
        child: const MaterialApp(home: Scaffold(body: TrainingPage())),
      ),
    );

    expect(find.text('Vocabulary'), findsOneWidget);
    expect(find.text('Spaced Review'), findsNothing);
  });

  testWidgets(
    'spaced review training entry appears when review flag is enabled',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsService>.value(
          value: _FakeSettingsService(reviewEnabled: true),
          child: const MaterialApp(home: Scaffold(body: TrainingPage())),
        ),
      );

      expect(find.text('Spaced Review'), findsOneWidget);
    },
  );
}

class _FakeSettingsService extends SettingsService {
  _FakeSettingsService({required this.reviewEnabled});

  final bool reviewEnabled;

  @override
  bool get reviewFeatureEnabled => reviewEnabled;
}

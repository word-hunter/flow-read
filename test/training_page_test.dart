import 'package:flow_read/pages/training_page.dart';
import 'package:flow_read/providers/reading/reading_provider_riverpod.dart'
    as riverpod_reading;
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
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

  testWidgets('training entry reads book availability through Riverpod', (
    tester,
  ) async {
    final provider = _FakeReadingProvider(hasBook: false, hasBeenOpened: false);

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          riverpod_reading.readingProvider.overrideWith((ref) => provider),
        ],
        child: ChangeNotifierProvider<SettingsService>.value(
          value: _FakeSettingsService(reviewEnabled: false),
          child: const MaterialApp(home: Scaffold(body: TrainingPage())),
        ),
      ),
    );

    await tester.tap(find.text('Vocabulary'));
    await tester.pump();

    expect(find.text('Please load a book first'), findsOneWidget);
  });
}

class _FakeSettingsService extends SettingsService {
  _FakeSettingsService({required this.reviewEnabled});

  final bool reviewEnabled;

  @override
  bool get reviewFeatureEnabled => reviewEnabled;
}

class _FakeReadingProvider extends ReadingProvider {
  _FakeReadingProvider({required this.hasBook, required this.hasBeenOpened});

  @override
  final bool hasBook;

  @override
  final bool hasBeenOpened;
}

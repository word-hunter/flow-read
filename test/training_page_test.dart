import 'package:flow_read/pages/training_page.dart';
import 'package:flow_read/providers/reading/current_book_notifier.dart';
import 'package:flow_read/providers/settings_provider.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('spaced review training entry is hidden by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            (ref) => _FakeSettingsService(reviewEnabled: false),
          ),
        ],
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
        riverpod.ProviderScope(
          overrides: [
            settingsProvider.overrideWith(
              (ref) => _FakeSettingsService(reviewEnabled: true),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: TrainingPage())),
        ),
      );

      expect(find.text('Spaced Review'), findsOneWidget);
    },
  );

  testWidgets('training entry reads book availability through Riverpod', (
    tester,
  ) async {
    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          currentBookNotifierProvider.overrideWith(
            () => _FakeCurrentBookNotifier(hasBook: false, hasBeenOpened: false),
          ),
          settingsProvider.overrideWith(
            (ref) => _FakeSettingsService(reviewEnabled: false),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: TrainingPage())),
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

class _FakeCurrentBookNotifier extends CurrentBookNotifier {
  _FakeCurrentBookNotifier({required bool hasBook, required bool hasBeenOpened})
    : _hasBook = hasBook,
      _hasBeenOpened = hasBeenOpened;

  final bool _hasBook;
  final bool _hasBeenOpened;

  @override
  CurrentBookState build() => CurrentBookState(
    hasBeenOpened: _hasBeenOpened,
  );

  @override
  bool get hasBook => _hasBook;
}

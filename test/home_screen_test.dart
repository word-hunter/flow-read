import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/providers/reading/reading_provider_riverpod.dart'
    as riverpod_reading;
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/screens/home_screen.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('wide home sidebar reads reading time through Riverpod', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 760);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final provider = _HomeReadingProvider();
    final settings = _HomeSettingsService();

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          riverpod_reading.readingProvider.overrideWith((ref) => provider),
        ],
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<ReadingProvider>.value(value: provider),
            ChangeNotifierProvider<SettingsService>.value(value: settings),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      ),
    );

    expect(find.text('2小时 / 3小时'), findsOneWidget);
    expect(find.text('每日目标 30分钟'), findsOneWidget);
  });
}

class _HomeReadingProvider extends ReadingProvider {
  int _currentTab = 0;

  @override
  int get currentTab => _currentTab;

  @override
  bool get isReading => false;

  @override
  bool get hasBook => false;

  @override
  List<BookMetadata> get allBooks => const [];

  @override
  bool get isLoading => false;

  @override
  String get importStage => '';

  @override
  int get weekReadingTimeSeconds => 2 * 3600;

  @override
  int get monthReadingTimeSeconds => 8 * 3600;

  @override
  List<int> get weekDailyReadingSeconds => const [1800, 1800, 3600, 0, 0, 0, 0];

  @override
  List<int> get monthDailyReadingSeconds => List<int>.filled(31, 30 * 60);

  @override
  DateTime get readingGoalDate => DateTime(2026, 5, 20);

  @override
  int get dailyReadingGoalSeconds => 30 * 60;

  @override
  void switchTab(int index) {
    _currentTab = index;
    notifyListeners();
  }
}

class _HomeSettingsService extends SettingsService {
  @override
  bool get rssFeatureEnabled => false;

  @override
  bool get reviewFeatureEnabled => false;
}

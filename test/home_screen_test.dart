import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/providers/reading/reading_provider_riverpod.dart'
    as riverpod_reading;
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/providers/settings_provider.dart';
import 'package:flow_read/screens/home_screen.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';

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
          settingsProvider.overrideWith((ref) => settings),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('2小时 / 3小时'), findsOneWidget);
    expect(find.text('每日目标 30分钟'), findsOneWidget);
  });

  testWidgets('import overlay shows progress and calls cancel', (
    tester,
  ) async {
    final provider = _ImportingHomeReadingProvider();
    final settings = _HomeSettingsService();

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          riverpod_reading.readingProvider.overrideWith((ref) => provider),
          settingsProvider.overrideWith((ref) => settings),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('正在导入 EPUB'), findsOneWidget);
    expect(find.text('slow.epub'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.text('正在解析 EPUB...'), findsOneWidget);
    expect(find.text('取消导入'), findsNothing);

    provider.revealCancel();
    await tester.pump();
    expect(find.text('取消导入'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, '取消导入'));
    await tester.pump();

    expect(provider.cancelCalled, isTrue);
    expect(provider.isCancellingImport, isTrue);
    expect(find.text('正在取消...'), findsOneWidget);
  });

  testWidgets('import overlay holds completion long enough to reach 100%', (
    tester,
  ) async {
    final provider = _ImportingHomeReadingProvider();
    final settings = _HomeSettingsService();

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          riverpod_reading.readingProvider.overrideWith((ref) => provider),
          settingsProvider.overrideWith((ref) => settings),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    provider.completeAndClear();
    await tester.pump();

    expect(find.text('导入完成'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 360));
    final progress = tester.widget<LinearProgressIndicator>(
      find.descendant(
        of: find.byType(Card),
        matching: find.byType(LinearProgressIndicator),
      ),
    );
    expect(progress.value, moreOrLessEquals(1));

    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('正在导入 EPUB'), findsNothing);
  });

  testWidgets('import overlay keeps card height stable while status changes', (
    tester,
  ) async {
    final provider = _ImportingHomeReadingProvider();
    final settings = _HomeSettingsService();

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          riverpod_reading.readingProvider.overrideWith((ref) => provider),
          settingsProvider.overrideWith((ref) => settings),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    final cardFinder = find.byType(Card);
    final initialHeight = tester.getSize(cardFinder).height;

    provider.showLongStage();
    await tester.pump();
    expect(tester.getSize(cardFinder).height, initialHeight);

    provider.revealCancel();
    await tester.pump();
    expect(tester.getSize(cardFinder).height, initialHeight);
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

class _ImportingHomeReadingProvider extends _HomeReadingProvider {
  _ImportingHomeReadingProvider() {
    _emitImportProgress();
  }

  bool _canCancel = false;
  bool _isCancelling = false;
  String _stage = '正在解析 EPUB...';
  bool cancelCalled = false;

  @override
  bool get isImportingBook => true;

  @override
  bool get canCancelImport => _canCancel && !_isCancelling;

  @override
  bool get isCancellingImport => _isCancelling;

  @override
  String get importStage => _isCancelling ? '正在取消导入...' : _stage;

  @override
  double? get importProgress => 0.42;

  @override
  String? get importFileName => 'slow.epub';

  @override
  void cancelImport() {
    cancelCalled = true;
    _isCancelling = true;
    _emitImportProgress();
  }

  void revealCancel() {
    _canCancel = true;
    _emitImportProgress();
  }

  void showLongStage() {
    _stage =
        '正在排版 1/1 · Chapter One by Fixture Author with a very long document title';
    _emitImportProgress();
  }

  void completeAndClear() {
    importProgressNotifier.value = const ImportProgressState(
      isImportingBook: true,
      progress: 1,
      fileName: 'slow.epub',
      stage: '导入完成',
    );
    importProgressNotifier.value = ImportProgressState.idle;
  }

  void _emitImportProgress() {
    importProgressNotifier.value = ImportProgressState(
      isImportingBook: true,
      isCancellingImport: _isCancelling,
      canCancelImport: _canCancel && !_isCancelling,
      progress: importProgress,
      fileName: importFileName,
      stage: importStage,
    );
  }
}

class _HomeSettingsService extends SettingsService {
  @override
  bool get rssFeatureEnabled => false;

  @override
  bool get reviewFeatureEnabled => false;
}

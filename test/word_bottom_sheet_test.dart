import 'package:flow_read/providers/reading/reading_provider_riverpod.dart'
    as riverpod_reading;
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/services/dictionary/word_repository.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/widgets/word_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('word bottom sheet toggles bookmark through Riverpod', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 1200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final provider = _WordBookmarkReadingProvider();
    final settings = _WordBottomSheetSettingsService();

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
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 420,
                height: 900,
                child: WordBottomSheet(word: 'flow'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('加入生词本'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '加入生词本'));
    await tester.pumpAndSettle();

    expect(provider.addedBookmark, isTrue);
    expect(find.text('已加入生词本'), findsOneWidget);
  });
}

class _WordBookmarkReadingProvider extends ReadingProvider {
  bool addedBookmark = false;

  @override
  String? get selectedWord => 'flow';

  @override
  String? get selectedWordTranslation => 'movement';

  @override
  DictionaryEntry? get selectedWordEntry => const DictionaryEntry(
    word: 'flow',
    meanings: [
      Meaning(partOfSpeech: 'noun', definitions: ['movement']),
    ],
  );

  @override
  bool isBookmarked(String word) => addedBookmark;

  @override
  void addBookmark(String word, String translation) {
    addedBookmark = true;
    notifyListeners();
  }

  @override
  void removeBookmark(String word) {
    addedBookmark = false;
    notifyListeners();
  }
}

class _WordBottomSheetSettingsService extends SettingsService {
  @override
  bool get aiFeaturesEnabled => false;
}

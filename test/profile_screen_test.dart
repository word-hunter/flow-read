import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/models/bookmarked_word.dart';
import 'package:flow_read/providers/reading/reading_provider_riverpod.dart'
    as riverpod_reading;
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/screens/profile_screen.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('profile screen reads reading time through Riverpod', (
    tester,
  ) async {
    final provider = _ProfileReadingProvider(readingTimeDisplay: '2 小时 5 分钟');
    final settings = SettingsService();

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
          child: const MaterialApp(home: ProfileScreen()),
        ),
      ),
    );

    expect(find.text('阅读时长'), findsOneWidget);
    expect(find.text('2 小时 5 分钟'), findsOneWidget);
  });
}

class _ProfileReadingProvider extends ReadingProvider {
  _ProfileReadingProvider({required String readingTimeDisplay})
    : _readingTimeDisplay = readingTimeDisplay;

  final String _readingTimeDisplay;

  @override
  List<BookMetadata> get allBooks => const [];

  @override
  List<BookmarkedWord> get bookmarkedWords => const [];

  @override
  String get readingTimeDisplay => _readingTimeDisplay;
}

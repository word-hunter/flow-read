import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/models/bookmarked_word.dart';
import 'package:flow_read/providers/reading/reading_provider_riverpod.dart'
    as riverpod_reading;
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/providers/settings_provider.dart';
import 'package:flow_read/screens/profile_screen.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';

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
          settingsProvider.overrideWith((ref) => settings),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );

    expect(find.text('阅读时长'), findsOneWidget);
    expect(find.text('2 小时 5 分钟'), findsOneWidget);
    expect(find.text('阅读书籍'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('生词本'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}

class _ProfileReadingProvider extends ReadingProvider {
  _ProfileReadingProvider({required String readingTimeDisplay})
    : _readingTimeDisplay = readingTimeDisplay;

  final String _readingTimeDisplay;

  @override
  List<BookMetadata> get allBooks => const [
    BookMetadata(
      id: 'book-1',
      title: 'Test Book',
      author: 'Tester',
      sourcePath: '/tmp/test.epub',
    ),
  ];

  @override
  List<BookmarkedWord> get bookmarkedWords => [
    BookmarkedWord(
      word: 'flow',
      translation: 'movement',
      context: '',
      addedAt: DateTime(2026),
      bookId: 'book-1',
    ),
    BookmarkedWord(
      word: 'read',
      translation: 'look at words',
      context: '',
      addedAt: DateTime(2026),
      bookId: 'book-1',
    ),
  ];

  @override
  String get readingTimeDisplay => _readingTimeDisplay;
}

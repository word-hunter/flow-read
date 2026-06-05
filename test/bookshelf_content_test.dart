import 'dart:typed_data';

import 'package:flow_read/models/book_difficulty.dart';
import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/providers/reading/reading_provider_riverpod.dart'
    as riverpod_reading;
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/providers/settings_provider.dart';
import 'package:flow_read/screens/bookshelf_screen.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/widgets/home/bookshelf_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows an error when continuing a book fails', (tester) async {
    final provider = _FailingOpenReadingProvider();
    final settings = _BookshelfSettingsService();

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          riverpod_reading.readingProvider.overrideWith((ref) => provider),
          settingsProvider.overrideWith((ref) => settings),
        ],
        child: const MaterialApp(home: Scaffold(body: BookshelfContent())),
      ),
    );

    expect(find.text('我的书架'), findsNothing);
    expect(find.text('全部书籍'), findsNothing);
    expect(find.text('书架'), findsOneWidget);
    expect(find.text('最近阅读'), findsOneWidget);
    expect(find.text('本书已读'), findsOneWidget);
    expect(find.text('1 小时 30 分钟'), findsOneWidget);
    expect(find.text('上次章节'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '继续阅读'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(provider.openedBookId, 'missing-book');
    expect(provider.isReading, isFalse);
    expect(find.text('打开书籍失败：测试错误'), findsOneWidget);
  });

  testWidgets('bookshelf screen reads books through Riverpod', (tester) async {
    final provider = _FailingOpenReadingProvider();
    final settings = _BookshelfSettingsService();

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          riverpod_reading.readingProvider.overrideWith((ref) => provider),
          settingsProvider.overrideWith((ref) => settings),
        ],
        child: const MaterialApp(home: BookshelfScreen()),
      ),
    );

    expect(find.text('我的书架'), findsOneWidget);
    expect(find.text('Missing Book'), findsOneWidget);
    expect(find.text('Author'), findsOneWidget);
  });

  testWidgets('remove dialog keeps long titles constrained', (tester) async {
    final longTitle =
        'A Very Long EPUB Title That Keeps Going Across The Dialog Width '
        'And Would Previously Make The Remove Confirmation Much Too Wide';
    final provider = _FailingOpenReadingProvider(title: longTitle);
    final settings = _BookshelfSettingsService();

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          riverpod_reading.readingProvider.overrideWith((ref) => provider),
          settingsProvider.overrideWith((ref) => settings),
        ],
        child: const MaterialApp(home: Scaffold(body: BookshelfContent())),
      ),
    );

    await tester.tap(find.byTooltip('更多操作').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('移出书架').first);
    await tester.pumpAndSettle();

    final titleText = tester.widget<Text>(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(longTitle),
      ),
    );
    expect(titleText.maxLines, 3);
    expect(titleText.overflow, TextOverflow.ellipsis);
  });
}

class _FailingOpenReadingProvider extends ReadingProvider {
  _FailingOpenReadingProvider({String title = 'Missing Book'})
    : _book = BookMetadata(
        id: 'missing-book',
        title: title,
        author: 'Author',
        sourcePath: '/missing/book.epub',
        totalChapters: 3,
        lastReadAt: DateTime.utc(2026, 5, 27),
      );

  String? openedBookId;

  final BookMetadata _book;

  @override
  List<BookMetadata> get allBooks => [_book];

  @override
  bool get isLoading => false;

  @override
  bool get isReading => false;

  @override
  String? get errorMessage => '打开书籍失败：测试错误';

  @override
  bool get isLoadingBookDifficulties => false;

  @override
  int get loadingBookDifficultyCount => 0;

  @override
  Uint8List? getCoverBytes(String bookId) => null;

  @override
  int readingTimeSecondsForBook(String bookId) => 90 * 60;

  @override
  int noteCountForBook(String bookId) => 0;

  @override
  String? latestReadingExcerptForBook(String bookId) => null;

  @override
  BookDifficultyRating? difficultyForBook(String bookId) => null;

  @override
  bool isBookDifficultyLoading(String bookId) => false;

  @override
  Future<void> ensureBookDifficulties(Iterable<BookMetadata> books) async {}

  @override
  Future<bool> switchToBook(String bookId) async {
    openedBookId = bookId;
    notifyListeners();
    return false;
  }
}

class _BookshelfSettingsService extends SettingsService {
  @override
  bool get reviewFeatureEnabled => false;

  @override
  int get dailyReadingGoalSeconds => 3600;
}

import 'dart:typed_data';

import 'package:flow_read/models/book_difficulty.dart';
import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/widgets/home/bookshelf_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows an error when continuing a book fails', (tester) async {
    final provider = _FailingOpenReadingProvider();
    final settings = _BookshelfSettingsService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReadingProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
        ],
        child: const MaterialApp(home: Scaffold(body: BookshelfContent())),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, '继续阅读'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(provider.openedBookId, 'missing-book');
    expect(provider.isReading, isFalse);
    expect(find.text('打开书籍失败：测试错误'), findsOneWidget);
  });
}

class _FailingOpenReadingProvider extends ReadingProvider {
  String? openedBookId;

  final BookMetadata _book = BookMetadata(
    id: 'missing-book',
    title: 'Missing Book',
    author: 'Author',
    sourcePath: '/missing/book.epub',
    totalChapters: 3,
    lastReadAt: DateTime.utc(2026, 5, 27),
  );

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
  int readingTimeSecondsForBook(String bookId) => 0;

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

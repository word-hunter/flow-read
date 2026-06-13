import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/models/bookmarked_word.dart';
import 'package:flow_read/providers/reading/bookmark_notifier.dart';
import 'package:flow_read/providers/reading/bookshelf_notifier.dart';
import 'package:flow_read/providers/reading/services_provider.dart';
import 'package:flow_read/providers/settings_provider.dart';
import 'package:flow_read/screens/profile_screen.dart';
import 'package:flow_read/services/bookmark_service.dart';
import 'package:flow_read/services/reading_time_service.dart';
import 'package:flow_read/storage/repositories/bookmark_repository.dart';
import 'package:flow_read/storage/repositories/reading_time_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';

import 'support/test_storage.dart';

void main() {
  testWidgets('profile screen reads reading time through Riverpod', (
    tester,
  ) async {
    final bookmarks = [
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
    final settings = await createTestSettingsService();
    final timeService = _ProfileReadingTimeService();
    final bookmarkService = _ProfileBookmarkService();

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          bookshelfNotifierProvider.overrideWith(
            () => _TestProfileBookshelfNotifier(),
          ),
          bookmarkNotifierProvider.overrideWith(
            () => _TestProfileBookmarkNotifier(bookmarks),
          ),
          settingsProvider.overrideWith((ref) => settings),
          readingTimeServiceProvider.overrideWith((ref) => timeService),
          bookmarkServiceProvider.overrideWith((ref) => bookmarkService),
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

class _TestProfileBookshelfNotifier extends BookshelfNotifier {
  @override
  BookshelfState build() => const BookshelfState(
    books: [
      BookMetadata(
        id: 'book-1',
        title: 'Test Book',
        author: 'Tester',
        sourcePath: '/tmp/test.epub',
      ),
    ],
  );
}

class _TestProfileBookmarkNotifier extends BookmarkNotifier {
  _TestProfileBookmarkNotifier(this._bookmarks);
  final List<BookmarkedWord> _bookmarks;
  @override
  BookmarkState build() => BookmarkState(bookmarkedWords: _bookmarks);
}

class _ProfileBookmarkService extends BookmarkService {
  _ProfileBookmarkService()
    : super(repository: _FakeProfileBookmarkRepository());

  @override
  List<BookmarkedWord> loadWordBookmarks(String bookId) => [
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
}

class _FakeProfileBookmarkRepository implements BookmarkRepository {
  @override
  Future<void> init() async {}

  @override
  String? getWordBookmarks(String bookId) => null;

  @override
  Future<void> putWordBookmarks(String bookId, String json) async {}

  @override
  Future<void> deleteWordBookmarks(String bookId) async {}

  @override
  String? getReadingBookmarks(String bookId) => null;

  @override
  Future<void> putReadingBookmarks(String bookId, String json) async {}

  @override
  Future<void> deleteReadingBookmarks(String bookId) async {}

  @override
  Future<void> close() async {}
}

class _ProfileReadingTimeService extends ReadingTimeService {
  _ProfileReadingTimeService()
    : super(repository: _FakeProfileTimeRepository());

  @override
  String get displayText => '2 小时 5 分钟';
}

class _FakeProfileTimeRepository implements ReadingTimeRepository {
  @override
  Future<void> init() async {}

  @override
  int secondsFor(String key) => 0;

  @override
  Future<void> putSeconds(String key, int seconds) async {}

  @override
  Future<void> close() async {}
}

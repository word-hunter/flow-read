import 'package:flow_read/models/reading_bookmark.dart';
import 'package:flow_read/providers/reading/reading_provider_riverpod.dart'
    as riverpod_reading;
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/widgets/bookmark_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bookmark sheet reads and removes bookmarks through Riverpod', (
    tester,
  ) async {
    final provider = _BookmarkReadingProvider([
      _bookmark(
        chapterIndex: 1,
        chapterTitle: 'Chapter Two',
        excerpt: 'A remembered passage.',
      ),
      _bookmark(
        chapterIndex: 0,
        chapterTitle: 'Chapter One',
        excerpt: 'The opening page.',
      ),
    ]);

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          riverpod_reading.readingProvider.overrideWith((ref) => provider),
        ],
        child: const MaterialApp(home: Scaffold(body: BookmarkSheet())),
      ),
    );

    expect(find.text('2 个'), findsOneWidget);
    expect(find.text('Chapter Two'), findsOneWidget);
    expect(find.text('Chapter One'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    expect(find.text('1 个'), findsOneWidget);
    expect(find.text('Chapter Two'), findsOneWidget);
    expect(find.text('Chapter One'), findsNothing);
  });
}

ReadingBookmark _bookmark({
  required int chapterIndex,
  required String chapterTitle,
  required String excerpt,
}) {
  return ReadingBookmark(
    chapterIndex: chapterIndex,
    progress: 0.25,
    chapterTitle: chapterTitle,
    excerpt: excerpt,
    createdAt: DateTime(2026),
    bookId: 'book-1',
  );
}

class _BookmarkReadingProvider extends ReadingProvider {
  _BookmarkReadingProvider(this._bookmarks);

  final List<ReadingBookmark> _bookmarks;

  @override
  List<ReadingBookmark> get readingBookmarks => List.unmodifiable(_bookmarks);

  @override
  int get currentChapter => 1;

  @override
  void removeReadingBookmark(int index) {
    _bookmarks.removeAt(index);
    notifyListeners();
  }
}

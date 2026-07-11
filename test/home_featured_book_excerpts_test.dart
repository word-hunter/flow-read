import 'dart:math';

import 'package:flow_read/models/book.dart';
import 'package:flow_read/models/chapter.dart';
import 'package:flow_read/providers/reading/bookshelf_notifier.dart';
import 'package:flow_read/widgets/home/featured_book_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'buildBookPreviewExcerpts creates trimmed excerpts from current book',
    () {
      final book = Book(
        title: 'Preview Book',
        author: 'Flow Read',
        chapters: [
          _chapter('Short note.'),
          _chapter(
            'Amy found a curious sentence tucked inside the old chapter. '
            'It was long enough to become a useful preview card, and it gave '
            'the reader a real sense of the current scene without revealing too '
            'much of the surrounding story. '
            'Another sentence adds enough texture for rotation.',
          ),
        ],
      );

      final excerpts = buildBookPreviewExcerpts(
        book,
        currentChapter: 1,
        random: Random(1),
      );

      expect(excerpts, isNotEmpty);
      expect(excerpts.any((item) => item.contains('Amy found')), isTrue);
      expect(excerpts.every((item) => item.length <= 221), isTrue);
    },
  );

  testWidgets('featured card keeps a stable book excerpt on wide layouts', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FeaturedBookCard(
              title: 'Preview Book',
              author: 'Flow Read',
              progressPercent: 38,
              currentChapter: 1,
              totalChapters: 4,
              readingExcerpts: const [
                'First rotating excerpt from the current book.',
                'Second rotating excerpt from the current book.',
              ],
              onContinueReading: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('EN'), findsNothing);
    expect(find.text('4 章'), findsNothing);
    expect(find.textContaining('书中片段'), findsOneWidget);
    expect(find.textContaining('First rotating excerpt'), findsOneWidget);
    expect(find.textContaining('Second rotating excerpt'), findsNothing);

    final surface = tester.widget<Container>(
      find.byKey(const ValueKey('featured-book-card-surface')),
    );
    final decoration = surface.decoration! as BoxDecoration;
    expect(decoration.gradient, isNull);
    expect(decoration.borderRadius, BorderRadius.circular(12));

    await tester.pump(const Duration(seconds: 7));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('First rotating excerpt'), findsOneWidget);
    expect(find.textContaining('Second rotating excerpt'), findsNothing);
  });
}

Chapter _chapter(String plainText) {
  return Chapter(
    title: 'Chapter',
    plainText: plainText,
    rawHtml: '<p>$plainText</p>',
  );
}

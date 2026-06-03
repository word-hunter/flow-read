import 'package:flow_read/models/book_difficulty.dart';
import 'package:flow_read/widgets/book_difficulty_chip.dart';
import 'package:flow_read/widgets/home/featured_book_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders difficulty chip with design tokens and no icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookDifficultyChip(
            rating: _rating(BookDifficultyLevel.l3),
            isLoading: false,
          ),
        ),
      ),
    );

    expect(find.text('L3 · 需要查词'), findsOneWidget);
    expect(find.byIcon(Icons.speed_outlined), findsNothing);

    final decoration = _chipDecoration(tester);
    final border = decoration.border as Border;
    final text = tester.widget<Text>(find.text('L3 · 需要查词'));

    expect(decoration.color, BookDifficultyChipPalette.l3.background);
    expect(border.top.color, BookDifficultyChipPalette.l3.border);
    expect(text.style?.color, BookDifficultyChipPalette.l3.foreground);
  });

  testWidgets('renders label-only difficulty chip for inline reading marks', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookDifficultyChip(
            rating: _rating(BookDifficultyLevel.l1),
            isLoading: false,
            labelOnly: true,
          ),
        ),
      ),
    );

    expect(find.text('L1'), findsOneWidget);
    expect(find.textContaining('轻松读'), findsNothing);
    expect(find.textContaining('·'), findsNothing);

    final container = _chipContainer(tester);
    final decoration = container.decoration! as BoxDecoration;
    final border = decoration.border as Border;

    expect(container.constraints?.minWidth, 30);
    expect(container.constraints?.maxWidth, 44);
    expect(decoration.color, BookDifficultyChipPalette.l1.background);
    expect(border.top.color, BookDifficultyChipPalette.l1.border);
  });

  testWidgets('featured progress uses visible track and difficulty color', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeaturedBookCard(
            title: 'Unknown',
            author: 'Unknown Author',
            progressPercent: 8,
            currentChapter: 0,
            totalChapters: 12,
            readingTimeSeconds: 600,
            difficulty: _rating(BookDifficultyLevel.l5),
            onContinueReading: () {},
          ),
        ),
      ),
    );

    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );

    expect(progress.valueColor?.value, BookDifficultyChipPalette.l5.border);
    expect(progress.backgroundColor, isNot(progress.valueColor?.value));
  });
}

BoxDecoration _chipDecoration(WidgetTester tester) {
  final container = _chipContainer(tester);
  return container.decoration! as BoxDecoration;
}

Container _chipContainer(WidgetTester tester) {
  return tester.widget<Container>(
    find.descendant(
      of: find.byType(BookDifficultyChip),
      matching: find.byType(Container),
    ),
  );
}

BookDifficultyRating _rating(BookDifficultyLevel level) {
  return BookDifficultyRating(
    studyWordCount: 120,
    masteredWordCount: 40,
    userKnownWordCount: 1000,
    learningWordCount: 8,
    newWordCount: 22,
    weightedNewWordCount: 26,
    newWordToKnownRatio: 0.08,
    score: 60,
    level: level,
  );
}

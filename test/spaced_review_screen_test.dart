import 'package:flow_read/models/learning_item.dart';
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/screens/spaced_review_screen.dart';
import 'package:flow_read/services/review_schedule_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('fill blank review requires input before showing source answer', (
    tester,
  ) async {
    const sourceText =
        'On the back of her eyelids she could see her twin sister,';
    final item = LearningItem(
      id: 'item-1',
      type: LearningItemType.grammar,
      canonicalKey: 'on the back of her eyelids',
      title: 'On the back of her eyelids',
      content: 'On the back of her eyelids',
      answer: '介词短语作地点状语。',
      note: 'medium',
      sourceText: sourceText,
      bookId: 'book-1',
      chapterIndex: 0,
      chapterTitle: 'Chapter 1',
      createdAt: DateTime.utc(2026, 5, 21),
      updatedAt: DateTime.utc(2026, 5, 21),
    );
    final provider = _FakeReadingProvider([
      LearningReviewCard(
        item: item,
        type: LearningReviewCardType.fillBlank,
        studyGoal: '练习已沉淀的语法片段，确认能在原句中主动复现。',
        prompt: '______ she could see her twin sister,',
        answer: 'On the back of her eyelids',
        explanation: '介词短语作地点状语。',
        sourceText: sourceText,
      ),
    ]);

    await tester.pumpWidget(
      ChangeNotifierProvider<ReadingProvider>.value(
        value: provider,
        child: const MaterialApp(home: SpacedReviewScreen()),
      ),
    );

    expect(find.text('学习点'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(sourceText), findsNothing);

    await tester.enterText(
      find.byType(TextField),
      'On the back of her eyelids',
    );
    await tester.pump();
    final submitButton = find.widgetWithText(FilledButton, '提交');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('答案'), findsOneWidget);
    expect(find.text('On the back of her eyelids'), findsWidgets);
    expect(find.text('介词短语作地点状语。'), findsOneWidget);
    expect(find.text(sourceText), findsOneWidget);
  });

  testWidgets('close button avoids macOS traffic light title area', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final provider = _FakeReadingProvider([_reviewCard()]);

      await tester.pumpWidget(
        ChangeNotifierProvider<ReadingProvider>.value(
          value: provider,
          child: const MaterialApp(home: SpacedReviewScreen()),
        ),
      );

      final closeIconTop = tester.getTopLeft(find.byIcon(Icons.close)).dy;
      expect(closeIconTop, greaterThanOrEqualTo(40));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

LearningReviewCard _reviewCard() {
  const sourceText =
      'On the back of her eyelids she could see her twin sister,';
  final item = LearningItem(
    id: 'item-1',
    type: LearningItemType.grammar,
    canonicalKey: 'on the back of her eyelids',
    title: 'On the back of her eyelids',
    content: 'On the back of her eyelids',
    answer: '介词短语作地点状语。',
    note: 'medium',
    sourceText: sourceText,
    bookId: 'book-1',
    chapterIndex: 0,
    chapterTitle: 'Chapter 1',
    createdAt: DateTime.utc(2026, 5, 21),
    updatedAt: DateTime.utc(2026, 5, 21),
  );
  return LearningReviewCard(
    item: item,
    type: LearningReviewCardType.fillBlank,
    studyGoal: '练习已沉淀的语法片段，确认能在原句中主动复现。',
    prompt: '______ she could see her twin sister,',
    answer: 'On the back of her eyelids',
    explanation: '介词短语作地点状语。',
    sourceText: sourceText,
  );
}

class _FakeReadingProvider extends ReadingProvider {
  _FakeReadingProvider(this._cards);

  final List<LearningReviewCard> _cards;

  @override
  List<LearningReviewCard> get todayReviewCards => _cards;

  @override
  Future<void> recordLearningReview(
    String itemId,
    LearningReviewResult result,
  ) async {}
}

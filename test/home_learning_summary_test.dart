import 'package:flow_read/widgets/home/today_review_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('today review card shows due count and starts review', (
    tester,
  ) async {
    var started = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodayReviewCard(
            dueCount: 3,
            totalLearningItems: 8,
            onStart: () => started = true,
          ),
        ),
      ),
    );

    expect(find.text('今日复习'), findsOneWidget);
    expect(find.text('3 条待复习，每次最多 10 条'), findsOneWidget);

    await tester.tap(find.text('开始复习'));
    await tester.pump();

    expect(started, isTrue);
  });

  testWidgets('today review card disables start when no item is due', (
    tester,
  ) async {
    var started = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodayReviewCard(
            dueCount: 0,
            totalLearningItems: 5,
            onStart: () => started = true,
          ),
        ),
      ),
    );

    expect(find.text('今日已完成'), findsOneWidget);
    expect(find.text('5 个学习项会按间隔再次出现'), findsOneWidget);

    await tester.tap(find.text('开始复习'));
    await tester.pump();

    expect(started, isFalse);
  });
}

import 'package:flow_read/widgets/home/home_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sidebar shows browser entry when enabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeSidebar(
            currentTab: 0,
            onTabChanged: (_) {},
            readingTimeSeconds: 0,
            dailyReadingGoalSeconds: 3600,
            onSettingsTap: () {},
            onThemeToggle: () {},
            nextThemeMode: ThemeMode.dark,
            showRss: true,
            showBrowser: true,
          ),
        ),
      ),
    );

    expect(find.text('RSS'), findsOneWidget);
    expect(find.text('浏览器'), findsOneWidget);
  });

  testWidgets('sidebar hides browser entry when disabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeSidebar(
            currentTab: 0,
            onTabChanged: (_) {},
            readingTimeSeconds: 0,
            dailyReadingGoalSeconds: 3600,
            onSettingsTap: () {},
            onThemeToggle: () {},
            nextThemeMode: ThemeMode.dark,
            showRss: true,
            showBrowser: false,
          ),
        ),
      ),
    );

    expect(find.text('RSS'), findsOneWidget);
    expect(find.text('浏览器'), findsNothing);
  });

  testWidgets('sidebar theme button can target system mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeSidebar(
            currentTab: 0,
            onTabChanged: (_) {},
            readingTimeSeconds: 0,
            dailyReadingGoalSeconds: 3600,
            onSettingsTap: () {},
            onThemeToggle: () {},
            nextThemeMode: ThemeMode.system,
            showRss: true,
            showBrowser: false,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.devices_outlined), findsOneWidget);
    expect(find.byTooltip('切换到系统模式'), findsOneWidget);
  });

  testWidgets('sidebar reading goal uses configured daily target', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeSidebar(
            currentTab: 0,
            onTabChanged: (_) {},
            readingTimeSeconds: 3 * 3600,
            dailyReadingGoalSeconds: 30 * 60,
            onSettingsTap: () {},
            onThemeToggle: () {},
            nextThemeMode: ThemeMode.dark,
            showRss: true,
            showBrowser: false,
          ),
        ),
      ),
    );

    expect(find.text('3小时 / 3小时'), findsOneWidget);
    expect(find.text('每日目标 30分钟'), findsOneWidget);
  });

  testWidgets('sidebar reading goal opens a detail panel with month view', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeSidebar(
            currentTab: 0,
            onTabChanged: (_) {},
            readingTimeSeconds: 6300,
            monthReadingTimeSeconds: 2 * 3600,
            weekDailyReadingSeconds: const [3600, 2700, 0, 0, 0, 0, 0],
            monthDailyReadingSeconds: List<int>.generate(
              31,
              (index) => index < 2 ? 3600 : 0,
            ),
            goalDate: DateTime(2026, 5, 20),
            dailyReadingGoalSeconds: 3600,
            onSettingsTap: () {},
            onThemeToggle: () {},
            nextThemeMode: ThemeMode.dark,
            showRss: true,
            showBrowser: false,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('查看阅读目标详情'));
    await tester.pumpAndSettle();

    expect(find.text('阅读目标'), findsNWidgets(2));
    expect(find.text('本周达标 1 / 7 天'), findsOneWidget);
    expect(find.text('每日完成情况'), findsOneWidget);

    await tester.tap(find.text('本月'));
    await tester.pumpAndSettle();

    expect(find.text('本月达标 2 / 31 天'), findsOneWidget);
    expect(find.text('达标'), findsOneWidget);
    expect(find.text('无数据'), findsOneWidget);
  });
}

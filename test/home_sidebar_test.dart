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
            onSettingsTap: () {},
            onThemeToggle: () {},
            isDarkMode: false,
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
            onSettingsTap: () {},
            onThemeToggle: () {},
            isDarkMode: false,
            showRss: true,
            showBrowser: false,
          ),
        ),
      ),
    );

    expect(find.text('RSS'), findsOneWidget);
    expect(find.text('浏览器'), findsNothing);
  });
}

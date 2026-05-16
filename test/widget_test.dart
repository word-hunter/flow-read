import 'package:flutter_test/flutter_test.dart';
import 'package:flow_read/screens/settings_screen.dart';
import 'package:flow_read/services/app_version.dart';
import 'package:flow_read/services/backup_service.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  late Directory tempDir;
  late SettingsService settings;
  late BackupService backup;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('flow_read_widget_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
    settings = SettingsService();
    await settings.init();
    backup = BackupService(settings);
  });

  tearDown(() async {
    backup.dispose();
  });

  testWidgets('Settings screen renders appearance AI and backup sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: backup),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    expect(find.text('外观'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('测试功能'), findsOneWidget);
    await tester.tap(find.text('开启测试中的功能'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('RSS 入口'), findsOneWidget);
    expect(find.text('浏览器入口'), findsOneWidget);
    await tester.tap(find.widgetWithText(SwitchListTile, 'RSS 入口'));
    await tester.tap(find.widgetWithText(SwitchListTile, '浏览器入口'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump(const Duration(milliseconds: 300));
    expect(settings.rssFeatureEnabled, isTrue);
    expect(settings.browserFeatureEnabled, isTrue);
    Navigator.of(tester.element(find.text('RSS 入口'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('备份'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('关于'), findsOneWidget);
    expect(find.text('版本 ${FlowReadVersion.display}'), findsOneWidget);
  });
}

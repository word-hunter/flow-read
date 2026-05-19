import 'package:flutter_test/flutter_test.dart';
import 'package:flow_read/screens/settings_screen.dart';
import 'package:flow_read/services/app_version.dart';
import 'package:flow_read/services/backup_service.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'support/hive_test_storage.dart';

void main() {
  late SettingsService settings;
  late BackupService backup;

  setUp(() async {
    await initHiveTestStorage('flow_read_widget_test_');
    await openSettingsTestBox();
    settings = SettingsService();
    await settings.init();
    backup = BackupService(settings);
  });

  tearDown(() async {
    backup.dispose();
  });

  testWidgets('Settings screen renders redesigned settings sections', (
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

    expect(find.text('外观'), findsWidgets);
    expect(find.text('阅读'), findsOneWidget);
    expect(find.text('AI 设置'), findsOneWidget);
    expect(find.text('备份与同步'), findsOneWidget);
    expect(find.text('测试功能'), findsOneWidget);
    expect(find.text('关于'), findsOneWidget);
    expect(find.text('主题'), findsWidgets);
    expect(find.text('经典'), findsOneWidget);
    expect(find.text('颜色模式'), findsOneWidget);
    expect(find.text('生词颜色'), findsOneWidget);
    expect(find.text('学习中颜色'), findsOneWidget);

    await tester.tap(find.text('阅读'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('每日目标'), findsOneWidget);
    expect(find.text('每日 1 小时'), findsOneWidget);
    expect(find.text('周目标 6 小时'), findsOneWidget);

    await tester.tap(find.text('AI 设置'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('服务商'), findsWidgets);
    expect(find.text('Base URL'), findsWidgets);
    expect(find.text('模型'), findsWidgets);
    expect(find.text('API Key'), findsWidgets);
    expect(find.text('测试连接'), findsOneWidget);
    expect(find.text('清除配置'), findsOneWidget);
    expect(find.text('清除 AI 缓存'), findsOneWidget);

    await tester.tap(find.text('备份与同步').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('自动同步'), findsWidgets);
    expect(find.text('同步间隔'), findsOneWidget);
    expect(find.text('备份路径'), findsOneWidget);
    expect(find.text('API Key'), findsWidgets);
    await tester.drag(
      find.byKey(const ValueKey('settings-section-backup')),
      const Offset(0, -600),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('立即备份'), findsOneWidget);
    expect(find.text('导入备份'), findsOneWidget);
    expect(find.text('导入 Word Hunter 备份'), findsOneWidget);

    await tester.tap(find.text('测试功能').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('开启测试功能'), findsWidgets);
    expect(find.text('测试项列表'), findsOneWidget);
    expect(find.text('RSS 入口'), findsOneWidget);
    expect(find.text('浏览器入口'), findsOneWidget);
    await tester.tap(find.widgetWithText(SwitchListTile, '开启测试功能'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump(const Duration(milliseconds: 300));
    expect(settings.rssFeatureEnabled, isTrue);
    expect(settings.browserFeatureEnabled, isTrue);

    await tester.tap(find.text('关于').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('版本 ${FlowReadVersion.display}'), findsOneWidget);
    expect(find.text('检查更新'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

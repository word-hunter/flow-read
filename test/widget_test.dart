import 'package:flutter_test/flutter_test.dart';
import 'package:flow_read/screens/settings_screen.dart';
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
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
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
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('备份'), findsOneWidget);
  });
}

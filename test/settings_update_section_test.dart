import 'package:flow_read/services/app_update_service.dart';
import 'package:flow_read/services/dictionary/dictionary_source_config.dart';
import 'package:flow_read/services/dictionary/dictionary_source_test_service.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/widgets/settings/settings_sections.dart';
import 'package:flow_read/widgets/settings/update_check_result_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dictionary section shows all source controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SettingsDictionarySection(
              settings: SettingsService(),
              testWordController: TextEditingController(text: 'flow'),
              testingSources: false,
              testResults: const {
                DictionarySourceType.wordNet: DictionarySourceTestResult(
                  type: DictionarySourceType.wordNet,
                  word: 'flow',
                  status: DictionarySourceTestStatus.hit,
                  elapsed: Duration(milliseconds: 12),
                ),
              },
              onTestSources: () {},
              onClearCache: () {},
              cacheEntryCount: 12,
              cacheStatsLoading: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Collins'), findsOneWidget);
    expect(find.text('WordNet'), findsOneWidget);
    expect(find.text('Dictionary API'), findsOneWidget);
    expect(find.text('Longman'), findsOneWidget);
    expect(find.text('本地兜底 · 始终启用 · 第 2 位'), findsOneWidget);
    expect(find.text('测试单词'), findsOneWidget);
    expect(find.text('测试来源'), findsOneWidget);
    expect(find.text('命中 flow · 12 ms'), findsOneWidget);
    expect(find.text('最近测试：1 / 1 个来源命中'), findsOneWidget);
    expect(find.text('在线词典缓存：12 条'), findsOneWidget);
    expect(
      find.text('当前顺序：Collins → WordNet → Dictionary API → Longman'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.keyboard_arrow_up), findsNWidgets(4));
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNWidgets(4));
  });

  testWidgets('about section keeps actions at the bottom', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SettingsAboutSection(
              onShowReleaseNotes: () {},
              onCheckForUpdates: () {},
              checkingForUpdate: false,
              updateStatusMessage: null,
              updateStatusIsError: false,
              updateFallbackActionLabel: null,
              onOpenUpdateFallback: null,
              availableUpdate: _updateInfo,
              onDownloadUpdate: () {},
              onOpenUpdateReleasePage: () {},
              onOpenLogsFolder: () {},
              onOpenRepository: () {},
              onOpenIssueFeedback: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.text('诊断日志')).dy,
      lessThan(tester.getTopLeft(find.text('操作')).dy),
    );
    expect(
      tester.getTopLeft(find.text('可用更新')).dy,
      lessThan(tester.getTopLeft(find.text('操作')).dy),
    );
  });

  testWidgets('update result dialog shows immediate update actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: UpdateCheckResultDialog(update: _updateInfo)),
    );

    expect(find.text('发现新版本'), findsOneWidget);
    expect(find.text('Flow Read 9.9.9'), findsOneWidget);
    expect(find.text('立即更新'), findsOneWidget);
    expect(find.text('查看更新说明'), findsOneWidget);
  });

  testWidgets('update result dialog shows latest state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: UpdateCheckResultDialog(update: null)),
    );

    expect(find.text('已是最新版本'), findsOneWidget);
    expect(find.text('当前版本已经是最新版本。'), findsOneWidget);
    expect(find.text('知道了'), findsOneWidget);
  });
}

final _updateInfo = AppUpdateInfo(
  version: '9.9.9',
  tagName: 'v9.9.9',
  releasePageUrl: Uri.parse('https://github.com/test/releases/v9.9.9'),
  isPrerelease: false,
  publishedAt: DateTime(2026, 1, 1),
  releaseNotes: '### Added\n\n- Test update.',
  assetName: 'FlowRead-macos-9.9.9.zip',
  downloadUrl: Uri.parse('https://example.com/FlowRead-macos-9.9.9.zip'),
);

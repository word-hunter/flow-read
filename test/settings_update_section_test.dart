import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_dictionary/flow_dictionary.dart';
import 'package:flow_read/services/app_update_service.dart';
import 'package:flow_read/services/mac_permission_diagnostics.dart';
import 'package:flow_read/widgets/settings/settings_sections.dart';
import 'package:flow_read/widgets/settings/update_check_result_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_test_storage.dart';

void main() {
  testWidgets('reading section shows current book language override', (
    tester,
  ) async {
    String? clearedBookId;
    final settings = await createTestSettingsService();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SettingsReadingSection(
              settings: settings,
              activeBookMetadata: const BookMetadata(
                id: 'book-1',
                title: 'Fixture',
                author: 'Author',
                sourcePath: '/tmp/book.epub',
                sourceLanguage: 'en',
                sourceLanguageOverride: 'ja',
                languageConfidence: 1.0,
              ),
              onBookSourceLanguageChanged: (_, _) async {},
              onClearBookSourceLanguageOverride: (bookId) async {
                clearedBookId = bookId;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('当前书籍语言'), findsOneWidget);
    expect(find.textContaining('自动检测：English'), findsOneWidget);
    expect(find.text('当前覆盖：JA'), findsOneWidget);
    expect(find.text('恢复自动检测'), findsOneWidget);

    await tester.tap(find.text('恢复自动检测'));
    await tester.pump();

    expect(clearedBookId, 'book-1');
  });

  testWidgets('dictionary section shows all source controls', (tester) async {
    final settings = await createTestSettingsService();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SettingsDictionarySection(
              settings: settings,
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

    final sourceLabels = DictionarySourceRegistry.sourceTypes
        .map((type) => type.label)
        .toList();
    for (final label in sourceLabels) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('本地兜底 · 始终启用 · 第 2 位'), findsOneWidget);
    expect(find.text('测试单词'), findsOneWidget);
    expect(find.text('测试来源'), findsOneWidget);
    expect(find.text('命中 flow · 12 ms'), findsOneWidget);
    expect(find.text('最近测试：1 / 1 个来源命中'), findsOneWidget);
    expect(find.text('在线词典缓存：12 条'), findsOneWidget);
    expect(find.text('当前顺序：${sourceLabels.join(' → ')}'), findsOneWidget);
    expect(
      find.byIcon(Icons.keyboard_arrow_up),
      findsNWidgets(DictionarySourceRegistry.sourceTypes.length),
    );
    expect(
      find.byIcon(Icons.keyboard_arrow_down),
      findsNWidgets(DictionarySourceRegistry.sourceTypes.length),
    );
  });

  testWidgets('about section groups product info before support cards', (
    tester,
  ) async {
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
              onExportDiagnostics: () {},
              backupFolderPath: '',
              backupFolderBookmark: '',
              onReauthorizeBackupFolder: () {},
              macPermissionDiagnostics: MacPermissionDiagnostics(
                isMacOSProvider: () => false,
              ),
              onOpenRepository: () {},
              onOpenIssueFeedback: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Flow Read'), findsOneWidget);
    expect(find.text('辅助英语阅读与生词高亮工具'), findsOneWidget);
    expect(find.text('发现新版本 9.9.9'), findsOneWidget);
    expect(find.text('查看更新内容'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('可用更新')).dy,
      greaterThan(tester.getTopLeft(find.text('Flow Read')).dy),
    );
    expect(
      tester.getTopLeft(find.text('可用更新')).dy,
      lessThan(tester.getTopLeft(find.text('项目与反馈')).dy),
    );
    expect(find.text('操作'), findsNothing);
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

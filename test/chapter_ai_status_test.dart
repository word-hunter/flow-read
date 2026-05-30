import 'package:flow_read/models/ai_chapter_preview.dart';
import 'package:flow_read/models/ai_practice_questions.dart';
import 'package:flow_read/models/ai_summary.dart';
import 'package:flow_read/models/chapter_ai_status.dart';
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/widgets/ai_summary_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('ChapterAIStatus', () {
    test('classifies fallback and generated summary results', () {
      expect(
        ChapterAIStatus.fromSummary(
          AISummary.fallback('AI 返回了非结构化内容，以下为原始文本。'),
        ).kind,
        ChapterAIStatusKind.fallback,
      );

      expect(
        ChapterAIStatus.fromSummary(
          const AISummary(
            events: [
              SummaryEvent(
                description: 'Alice enters the room.',
                source: 'opening',
                significance: 'Sets the scene.',
                confidence: 'high',
              ),
            ],
            characterDevelopments: [],
            keyVocabulary: [],
            readingGuidance: '',
          ),
        ).kind,
        ChapterAIStatusKind.generated,
      );
    });

    test('classifies fallback preview and practice results', () {
      expect(
        ChapterAIStatus.fromPreview(
          AIChapterPreview.fallback('Raw preview text.'),
        ).kind,
        ChapterAIStatusKind.fallback,
      );

      expect(
        ChapterAIStatus.fromPractice(
          AIPracticeSet.fallback('Raw practice text.'),
        ).kind,
        ChapterAIStatusKind.fallback,
      );
    });
  });

  testWidgets('AISummaryView shows the unified chapter AI status', (
    tester,
  ) async {
    final provider = _StatusReadingProvider(
      const ChapterAIStatus.cacheHit(ChapterAIFeature.summary, '已读取缓存的章节总结。'),
    );
    final settings = _StatusSettingsService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReadingProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 480, height: 640, child: AISummaryView()),
          ),
        ),
      ),
    );

    expect(find.text('已读取缓存的章节总结。'), findsOneWidget);
    expect(find.byIcon(Icons.cached), findsOneWidget);
  });
}

class _StatusReadingProvider extends ReadingProvider {
  _StatusReadingProvider(this._status);

  final ChapterAIStatus? _status;

  @override
  ChapterAIStatus? get chapterAIStatus => _status;

  @override
  String get summaryLanguage => 'zh';

  @override
  bool get aiFeaturesEnabled => true;

  @override
  bool get isGeneratingSummary => false;

  @override
  bool get isGeneratingChapterPreview => false;

  @override
  AISummary? get aiSummary => null;

  @override
  AIChapterPreview? get aiChapterPreview => null;

  @override
  Future<void> generateChapterPreview() async {}

  @override
  Future<void> generateSummary() async {}

  @override
  void toggleSummaryLanguage() {}
}

class _StatusSettingsService extends SettingsService {
  @override
  bool get aiFeaturesEnabled => true;

  @override
  String get aiFeatureDisabledReason => '';
}

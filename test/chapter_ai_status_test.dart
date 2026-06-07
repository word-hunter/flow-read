import 'package:flow_read/models/ai_chapter_preview.dart';
import 'package:flow_read/models/ai_practice_questions.dart';
import 'package:flow_read/models/ai_summary.dart';
import 'package:flow_read/models/chapter_ai_coverage.dart';
import 'package:flow_read/models/chapter_ai_status.dart';
import 'package:flow_read/providers/reading/ai_notifier.dart';
import 'package:flow_read/providers/reading/current_book_notifier.dart';
import 'package:flow_read/providers/settings_provider.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/widgets/ai_summary_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';

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
    final provider = _StatusAINotifier(
      const ChapterAIStatus.cacheHit(ChapterAIFeature.summary, '已读取缓存的章节总结。'),
      coverage: ChapterAISummaryCoverage(
        totalChapters: 4,
        generatedChapterIndexes: const [0, 2],
      ),
    );
    final settings = _StatusSettingsService();

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          aiNotifierProvider.overrideWith(() => provider),
          currentBookNotifierProvider.overrideWith(
            () => _StatusCurrentBookNotifier(1),
          ),
          settingsProvider.overrideWith((ref) => settings),
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
    expect(find.text('已生成 2/4 章总结 · 当前章未生成'), findsOneWidget);
  });
}

class _StatusAINotifier extends AINotifier {
  _StatusAINotifier(
    this._status, {
    ChapterAISummaryCoverage? coverage,
  }) : _coverage = coverage;

  final ChapterAIStatus? _status;
  final ChapterAISummaryCoverage? _coverage;

  @override
  AIState build() => AIState(
    chapterAIStatus: _status,
    chapterAISummaryCoverage: _coverage,
    isLoadingChapterAISummaryCoverage: false,
    summaryLanguage: 'zh',
    isGeneratingSummary: false,
    isGeneratingChapterPreview: false,
    aiSummary: null,
    aiChapterPreview: null,
  );

  @override
  bool get aiFeaturesEnabled => true;
}

class _StatusCurrentBookNotifier extends CurrentBookNotifier {
  _StatusCurrentBookNotifier(this._currentChapter);
  final int _currentChapter;
  @override
  CurrentBookState build() => CurrentBookState(currentChapter: _currentChapter);
}

class _StatusSettingsService extends SettingsService {
  @override
  bool get aiFeaturesEnabled => true;

  @override
  String get aiFeatureDisabledReason => '';
}

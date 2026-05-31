import 'dart:convert';

import 'package:flow_read/models/ai_practice_questions.dart';
import 'package:flow_read/models/ai_summary.dart';
import 'package:flow_read/models/chapter_ai_status.dart';
import 'package:flow_read/services/ai_cache_service.dart';
import 'package:flow_read/services/chapter_ai_job.dart';
import 'package:flow_read/services/prompt_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('summary returns cache hit without AI call or usage count', () async {
    final model = _FakeChapterAIModel();
    final cache = _FakeChapterAICache(
      summaryJson: jsonEncode(_summary.toJson()),
    );
    final usage = _FakeChapterAIUsage();
    final job = ChapterAIJob(model: model, cache: cache, usage: usage);

    final result = await job.generateSummary(
      const ChapterSummaryJobRequest(
        bookId: 'book-one',
        chapterIndex: 2,
        chapterText: _chapterText,
        vocabulary: ['threshold'],
        outputLanguage: OutputLanguage.english,
      ),
    );

    expect(result.fromCache, isTrue);
    expect(result.status.kind, ChapterAIStatusKind.cacheHit);
    expect(result.summary.readingGuidance, _summary.readingGuidance);
    expect(model.summaryCalls, 0);
    expect(usage.summaryCount, 0);
    expect(cache.summarySaves, isEmpty);
    expect(cache.summaryLoads.single.contentHash, _chapterTextHash);
    expect(cache.summaryLoads.single.promptVersion, model.promptVersion);
    expect(
      cache.summaryLoads.single.sourceLanguage,
      SourceLanguage.english.code,
    );
    expect(
      cache.summaryLoads.single.outputLanguage,
      OutputLanguage.english.code,
    );
  });

  test('summary generation reuses prompt metadata for cache write', () async {
    final model = _FakeChapterAIModel(summary: _summary);
    final cache = _FakeChapterAICache();
    final usage = _FakeChapterAIUsage();
    final job = ChapterAIJob(model: model, cache: cache, usage: usage);

    final result = await job.generateSummary(
      const ChapterSummaryJobRequest(
        bookId: 'book-one',
        chapterIndex: 3,
        chapterText: _chapterText,
        vocabulary: ['threshold'],
        outputLanguage: OutputLanguage.zhHans,
      ),
    );

    expect(result.fromCache, isFalse);
    expect(result.status.kind, ChapterAIStatusKind.generated);
    expect(usage.summaryCount, 1);
    expect(model.summaryCalls, 1);
    expect(model.lastSummary!.sourceLanguage, SourceLanguage.english);
    expect(model.lastSummary!.outputLanguage, OutputLanguage.zhHans);
    expect(model.lastSummary!.spoilerBoundary.bookId, 'book-one');
    expect(model.lastSummary!.spoilerBoundary.currentUnitId, 'chapter:3');
    expect(
      model.lastSummary!.spoilerBoundary.scope,
      AIContextScope.currentChapter,
    );
    expect(cache.summarySaves.single.contentHash, _chapterTextHash);
    expect(cache.summarySaves.single.promptVersion, model.promptVersion);
    expect(
      cache.summarySaves.single.sourceLanguage,
      SourceLanguage.english.code,
    );
    expect(
      cache.summarySaves.single.outputLanguage,
      OutputLanguage.zhHans.code,
    );
    expect(
      AISummary.fromJson(
        jsonDecode(cache.summarySaves.single.jsonString)
            as Map<String, dynamic>,
      ).readingGuidance,
      _summary.readingGuidance,
    );
  });

  test(
    'practice generation uses read-so-far boundary and event cache key',
    () async {
      final model = _FakeChapterAIModel(practice: _practice);
      final cache = _FakeChapterAICache();
      final usage = _FakeChapterAIUsage();
      final job = ChapterAIJob(model: model, cache: cache, usage: usage);
      const events = [_event];

      final result = await job.generatePractice(
        const ChapterPracticeJobRequest(
          bookId: 'book-one',
          chapterIndex: 4,
          chapterText: _chapterText,
          vocabulary: ['threshold'],
          events: events,
        ),
      );

      expect(result.fromCache, isFalse);
      expect(result.status.kind, ChapterAIStatusKind.generated);
      expect(usage.practiceCount, 1);
      expect(model.practiceCalls, 1);
      expect(model.lastPractice!.events.single.source, _event.source);
      expect(model.lastPractice!.outputLanguage, OutputLanguage.zhHans);
      expect(
        model.lastPractice!.spoilerBoundary.scope,
        AIContextScope.readSoFar,
      );
      expect(model.lastPractice!.spoilerBoundary.currentUnitId, 'chapter:4');

      final expectedHash = AICacheService.contentHashFor(
        jsonEncode({
          'chapterText': _chapterText,
          'events': events.map((event) => event.toJson()).toList(),
        }),
      );
      expect(cache.practiceLoads.single.contentHash, expectedHash);
      expect(cache.practiceSaves.single.contentHash, expectedHash);
      expect(cache.practiceSaves.single.promptVersion, model.promptVersion);
      expect(
        cache.practiceSaves.single.sourceLanguage,
        SourceLanguage.english.code,
      );
      expect(
        cache.practiceSaves.single.outputLanguage,
        OutputLanguage.zhHans.code,
      );
      expect(
        AIPracticeSet.fromJson(
          jsonDecode(cache.practiceSaves.single.jsonString)
              as Map<String, dynamic>,
        ).questions.single.answer,
        _practice.questions.single.answer,
      );
    },
  );
}

const _chapterText = 'Alice stood on the threshold and opened the door.';
final _chapterTextHash = AICacheService.contentHashFor(_chapterText);

const _event = SummaryEvent(
  description: 'Alice opens the door.',
  source: 'opened the door',
  significance: 'The scene begins.',
  confidence: 'high',
);

const _summary = AISummary(
  events: [_event],
  characterDevelopments: [],
  keyVocabulary: [],
  readingGuidance: 'Watch how Alice crosses the threshold.',
);

const _practice = AIPracticeSet(
  questions: [
    PracticeQuestion(
      type: 'detail',
      question: 'What does Alice do?',
      source: 'opened the door',
      answer: 'She opens the door.',
      answerExplanation: 'The source says she opened the door.',
      distractors: [],
      difficulty: 'easy',
    ),
  ],
);

class _FakeChapterAIModel implements ChapterAIModelAdapter {
  _FakeChapterAIModel({this.summary, this.practice});

  final AISummary? summary;
  final AIPracticeSet? practice;
  int summaryCalls = 0;
  int practiceCalls = 0;
  _SummaryCall? lastSummary;
  _PracticeCall? lastPractice;

  @override
  int get promptVersion => 42;

  @override
  Stream<AISummary> generateSummary({
    required String chapterText,
    required List<String> vocabulary,
    required OutputLanguage outputLanguage,
    required SourceLanguage sourceLanguage,
    required SpoilerBoundary spoilerBoundary,
  }) async* {
    summaryCalls += 1;
    lastSummary = _SummaryCall(
      chapterText: chapterText,
      vocabulary: vocabulary,
      outputLanguage: outputLanguage,
      sourceLanguage: sourceLanguage,
      spoilerBoundary: spoilerBoundary,
    );
    final result = summary;
    if (result != null) yield result;
  }

  @override
  Stream<AIPracticeSet> generatePractice({
    required String chapterText,
    required List<String> vocabulary,
    required List<SummaryEvent> events,
    required SourceLanguage sourceLanguage,
    required OutputLanguage outputLanguage,
    required SpoilerBoundary spoilerBoundary,
  }) async* {
    practiceCalls += 1;
    lastPractice = _PracticeCall(
      chapterText: chapterText,
      vocabulary: vocabulary,
      events: events,
      sourceLanguage: sourceLanguage,
      outputLanguage: outputLanguage,
      spoilerBoundary: spoilerBoundary,
    );
    final result = practice;
    if (result != null) yield result;
  }
}

class _FakeChapterAICache implements ChapterAICacheAdapter {
  _FakeChapterAICache({this.summaryJson});

  final String? summaryJson;
  final summaryLoads = <_CacheCall>[];
  final summarySaves = <_CacheCall>[];
  final practiceLoads = <_CacheCall>[];
  final practiceSaves = <_CacheCall>[];

  @override
  Future<String?> loadSummary({
    required String bookId,
    required int chapterIndex,
    required String outputLanguage,
    required String contentHash,
    required int promptVersion,
    required String sourceLanguage,
  }) async {
    summaryLoads.add(
      _CacheCall(
        bookId: bookId,
        chapterIndex: chapterIndex,
        outputLanguage: outputLanguage,
        contentHash: contentHash,
        promptVersion: promptVersion,
        sourceLanguage: sourceLanguage,
      ),
    );
    return summaryJson;
  }

  @override
  Future<void> saveSummary({
    required String bookId,
    required int chapterIndex,
    required String outputLanguage,
    required String jsonString,
    required String contentHash,
    required int promptVersion,
    required String sourceLanguage,
  }) async {
    summarySaves.add(
      _CacheCall(
        bookId: bookId,
        chapterIndex: chapterIndex,
        outputLanguage: outputLanguage,
        jsonString: jsonString,
        contentHash: contentHash,
        promptVersion: promptVersion,
        sourceLanguage: sourceLanguage,
      ),
    );
  }

  @override
  Future<String?> loadPractice({
    required String bookId,
    required int chapterIndex,
    required String contentHash,
    required int promptVersion,
    required String sourceLanguage,
    required String outputLanguage,
  }) async {
    practiceLoads.add(
      _CacheCall(
        bookId: bookId,
        chapterIndex: chapterIndex,
        outputLanguage: outputLanguage,
        contentHash: contentHash,
        promptVersion: promptVersion,
        sourceLanguage: sourceLanguage,
      ),
    );
    return null;
  }

  @override
  Future<void> savePractice({
    required String bookId,
    required int chapterIndex,
    required String jsonString,
    required String contentHash,
    required int promptVersion,
    required String sourceLanguage,
    required String outputLanguage,
  }) async {
    practiceSaves.add(
      _CacheCall(
        bookId: bookId,
        chapterIndex: chapterIndex,
        outputLanguage: outputLanguage,
        jsonString: jsonString,
        contentHash: contentHash,
        promptVersion: promptVersion,
        sourceLanguage: sourceLanguage,
      ),
    );
  }
}

class _FakeChapterAIUsage implements ChapterAIUsageAdapter {
  int summaryCount = 0;
  int practiceCount = 0;

  @override
  Future<void> recordChapterSummaryGenerated() async {
    summaryCount += 1;
  }

  @override
  Future<void> recordPracticeGenerated() async {
    practiceCount += 1;
  }
}

class _SummaryCall {
  const _SummaryCall({
    required this.chapterText,
    required this.vocabulary,
    required this.outputLanguage,
    required this.sourceLanguage,
    required this.spoilerBoundary,
  });

  final String chapterText;
  final List<String> vocabulary;
  final OutputLanguage outputLanguage;
  final SourceLanguage sourceLanguage;
  final SpoilerBoundary spoilerBoundary;
}

class _PracticeCall {
  const _PracticeCall({
    required this.chapterText,
    required this.vocabulary,
    required this.events,
    required this.sourceLanguage,
    required this.outputLanguage,
    required this.spoilerBoundary,
  });

  final String chapterText;
  final List<String> vocabulary;
  final List<SummaryEvent> events;
  final SourceLanguage sourceLanguage;
  final OutputLanguage outputLanguage;
  final SpoilerBoundary spoilerBoundary;
}

class _CacheCall {
  const _CacheCall({
    required this.bookId,
    required this.chapterIndex,
    required this.outputLanguage,
    required this.contentHash,
    required this.promptVersion,
    required this.sourceLanguage,
    this.jsonString = '',
  });

  final String bookId;
  final int chapterIndex;
  final String outputLanguage;
  final String contentHash;
  final int promptVersion;
  final String sourceLanguage;
  final String jsonString;
}

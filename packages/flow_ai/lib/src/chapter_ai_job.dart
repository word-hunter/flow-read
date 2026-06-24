import 'dart:convert';

import 'models/ai_practice_questions.dart';
import 'models/ai_summary.dart';
import 'models/chapter_ai_status.dart';
import 'ai_cache_service.dart';
import 'ai_service.dart';
import 'prompt_builder.dart';

class ChapterAIJob {
  const ChapterAIJob({
    required ChapterAIModelAdapter model,
    required ChapterAICacheAdapter cache,
    required ChapterAIUsageAdapter usage,
  }) : _model = model,
       _cache = cache,
       _usage = usage;

  factory ChapterAIJob.fromServices({
    required AIService aiService,
    AICacheService? cache,
    ChapterAIUsageAdapter? usageAdapter,
  }) {
    return ChapterAIJob(
      model: AIServiceChapterAIModelAdapter(aiService),
      cache: cache == null
          ? const NoopChapterAICacheAdapter()
          : AICacheServiceChapterAICacheAdapter(cache),
      usage: usageAdapter ?? const NoopChapterAIUsageAdapter(),
    );
  }

  final ChapterAIModelAdapter _model;
  final ChapterAICacheAdapter _cache;
  final ChapterAIUsageAdapter _usage;

  Future<ChapterSummaryJobResult> generateSummary(
    ChapterSummaryJobRequest request,
  ) async {
    if (request.chapterText.trim().isEmpty) {
      throw StateError('章节正文为空，无法生成总结');
    }

    final metadata = ChapterAIJobMetadata.forChapter(
      bookId: request.bookId,
      chapterIndex: request.chapterIndex,
      sourceText: request.chapterText,
      contentHash: AICacheService.contentHashFor(request.chapterText),
      promptVersion: _model.promptVersion,
      outputLanguage: request.outputLanguage,
    );

    final cached = await _cache.loadSummary(
      bookId: request.bookId,
      chapterIndex: request.chapterIndex,
      outputLanguage: metadata.outputLanguage.code,
      contentHash: metadata.contentHash,
      promptVersion: metadata.promptVersion,
      sourceLanguage: metadata.sourceLanguage.code,
    );
    if (cached != null) {
      final summary = AISummary.fromJson(
        jsonDecode(cached) as Map<String, dynamic>,
      );
      if (summary.isEmpty || ChapterAIStatus.isSummaryFallback(summary)) {
        // Old builds could persist fallback summaries as successful cache hits.
        // Treat those as misses so a real summary can be regenerated.
      } else {
        return ChapterSummaryJobResult(
          summary: summary,
          status: const ChapterAIStatus.cacheHit(
            ChapterAIFeature.summary,
            '已读取缓存的章节总结。',
          ),
          fromCache: true,
        );
      }
    }

    await for (final summary in _model.generateSummary(
      chapterText: request.chapterText,
      vocabulary: request.vocabulary,
      outputLanguage: metadata.outputLanguage,
      sourceLanguage: metadata.sourceLanguage,
      spoilerBoundary: metadata.spoilerBoundary,
    )) {
      final status = ChapterAIStatus.fromSummary(summary);
      await _usage.recordChapterSummaryGenerated();
      if (status.kind != ChapterAIStatusKind.fallback && !summary.isEmpty) {
        await _cache.saveSummary(
          bookId: request.bookId,
          chapterIndex: request.chapterIndex,
          outputLanguage: metadata.outputLanguage.code,
          jsonString: jsonEncode(summary.toJson()),
          contentHash: metadata.contentHash,
          promptVersion: metadata.promptVersion,
          sourceLanguage: metadata.sourceLanguage.code,
        );
      }
      return ChapterSummaryJobResult(
        summary: summary,
        status: status,
        fromCache: false,
      );
    }

    throw StateError('AI 未返回章节总结');
  }

  Future<ChapterPracticeJobResult> generatePractice(
    ChapterPracticeJobRequest request,
  ) async {
    final contentHash = AICacheService.contentHashFor(
      jsonEncode({
        'chapterText': request.chapterText,
        'events': request.events.map((event) => event.toJson()).toList(),
      }),
    );
    final metadata = ChapterAIJobMetadata.forChapter(
      bookId: request.bookId,
      chapterIndex: request.chapterIndex,
      sourceText: request.chapterText,
      contentHash: contentHash,
      promptVersion: _model.promptVersion,
      outputLanguage: request.outputLanguage,
      scope: AIContextScope.readSoFar,
    );

    final cached = await _cache.loadPractice(
      bookId: request.bookId,
      chapterIndex: request.chapterIndex,
      contentHash: metadata.contentHash,
      promptVersion: metadata.promptVersion,
      sourceLanguage: metadata.sourceLanguage.code,
      outputLanguage: metadata.outputLanguage.code,
    );
    if (cached != null) {
      return ChapterPracticeJobResult(
        practice: AIPracticeSet.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        ),
        status: const ChapterAIStatus.cacheHit(
          ChapterAIFeature.practice,
          '已读取缓存的练习题。',
        ),
        fromCache: true,
      );
    }

    ChapterPracticeJobResult? result;
    await for (final practice in _model.generatePractice(
      chapterText: request.chapterText,
      vocabulary: request.vocabulary,
      events: request.events,
      sourceLanguage: metadata.sourceLanguage,
      outputLanguage: metadata.outputLanguage,
      spoilerBoundary: metadata.spoilerBoundary,
    )) {
      await _usage.recordPracticeGenerated();
      await _cache.savePractice(
        bookId: request.bookId,
        chapterIndex: request.chapterIndex,
        jsonString: jsonEncode(practice.toJson()),
        contentHash: metadata.contentHash,
        promptVersion: metadata.promptVersion,
        sourceLanguage: metadata.sourceLanguage.code,
        outputLanguage: metadata.outputLanguage.code,
      );
      result = ChapterPracticeJobResult(
        practice: practice,
        status: ChapterAIStatus.fromPractice(practice),
        fromCache: false,
      );
    }

    if (result == null) {
      throw StateError('AI 未返回练习题');
    }
    return result;
  }
}

class ChapterSummaryJobRequest {
  const ChapterSummaryJobRequest({
    required this.bookId,
    required this.chapterIndex,
    required this.chapterText,
    required this.vocabulary,
    required this.outputLanguage,
  });

  final String bookId;
  final int chapterIndex;
  final String chapterText;
  final List<String> vocabulary;
  final OutputLanguage outputLanguage;
}

class ChapterPracticeJobRequest {
  const ChapterPracticeJobRequest({
    required this.bookId,
    required this.chapterIndex,
    required this.chapterText,
    required this.vocabulary,
    required this.events,
    this.outputLanguage = OutputLanguage.zhHans,
  });

  final String bookId;
  final int chapterIndex;
  final String chapterText;
  final List<String> vocabulary;
  final List<SummaryEvent> events;
  final OutputLanguage outputLanguage;
}

class ChapterAIJobMetadata {
  const ChapterAIJobMetadata({
    required this.contentHash,
    required this.promptVersion,
    required this.sourceLanguage,
    required this.outputLanguage,
    required this.spoilerBoundary,
  });

  factory ChapterAIJobMetadata.forChapter({
    required String bookId,
    required int chapterIndex,
    required String sourceText,
    required String contentHash,
    required int promptVersion,
    required OutputLanguage outputLanguage,
    AIContextScope scope = AIContextScope.currentChapter,
  }) {
    return ChapterAIJobMetadata(
      contentHash: contentHash,
      promptVersion: promptVersion,
      sourceLanguage: SourceLanguage.inferFromText(sourceText),
      outputLanguage: outputLanguage,
      spoilerBoundary: SpoilerBoundary.chapter(
        bookId: bookId,
        chapterIndex: chapterIndex,
        scope: scope,
      ),
    );
  }

  final String contentHash;
  final int promptVersion;
  final SourceLanguage sourceLanguage;
  final OutputLanguage outputLanguage;
  final SpoilerBoundary spoilerBoundary;
}

class ChapterSummaryJobResult {
  const ChapterSummaryJobResult({
    required this.summary,
    required this.status,
    required this.fromCache,
  });

  final AISummary summary;
  final ChapterAIStatus status;
  final bool fromCache;
}

class ChapterPracticeJobResult {
  const ChapterPracticeJobResult({
    required this.practice,
    required this.status,
    required this.fromCache,
  });

  final AIPracticeSet practice;
  final ChapterAIStatus status;
  final bool fromCache;
}

abstract class ChapterAIModelAdapter {
  int get promptVersion;

  Stream<AISummary> generateSummary({
    required String chapterText,
    required List<String> vocabulary,
    required OutputLanguage outputLanguage,
    required SourceLanguage sourceLanguage,
    required SpoilerBoundary spoilerBoundary,
  });

  Stream<AIPracticeSet> generatePractice({
    required String chapterText,
    required List<String> vocabulary,
    required List<SummaryEvent> events,
    required SourceLanguage sourceLanguage,
    required OutputLanguage outputLanguage,
    required SpoilerBoundary spoilerBoundary,
  });
}

class AIServiceChapterAIModelAdapter implements ChapterAIModelAdapter {
  const AIServiceChapterAIModelAdapter(this._service);

  final AIService _service;

  @override
  int get promptVersion => _service.promptVersion;

  @override
  Stream<AISummary> generateSummary({
    required String chapterText,
    required List<String> vocabulary,
    required OutputLanguage outputLanguage,
    required SourceLanguage sourceLanguage,
    required SpoilerBoundary spoilerBoundary,
  }) {
    return _service.generateSummary(
      chapterText: chapterText,
      vocabulary: vocabulary,
      language: outputLanguage.code,
      sourceLanguage: sourceLanguage,
      spoilerBoundary: spoilerBoundary,
    );
  }

  @override
  Stream<AIPracticeSet> generatePractice({
    required String chapterText,
    required List<String> vocabulary,
    required List<SummaryEvent> events,
    required SourceLanguage sourceLanguage,
    required OutputLanguage outputLanguage,
    required SpoilerBoundary spoilerBoundary,
  }) {
    return _service.generatePractice(
      chapterText: chapterText,
      vocabulary: vocabulary,
      events: events,
      sourceLanguage: sourceLanguage,
      outputLanguage: outputLanguage,
      spoilerBoundary: spoilerBoundary,
    );
  }
}

abstract class ChapterAICacheAdapter {
  Future<String?> loadSummary({
    required String bookId,
    required int chapterIndex,
    required String outputLanguage,
    required String contentHash,
    required int promptVersion,
    required String sourceLanguage,
  });

  Future<void> saveSummary({
    required String bookId,
    required int chapterIndex,
    required String outputLanguage,
    required String jsonString,
    required String contentHash,
    required int promptVersion,
    required String sourceLanguage,
  });

  Future<String?> loadPractice({
    required String bookId,
    required int chapterIndex,
    required String contentHash,
    required int promptVersion,
    required String sourceLanguage,
    required String outputLanguage,
  });

  Future<void> savePractice({
    required String bookId,
    required int chapterIndex,
    required String jsonString,
    required String contentHash,
    required int promptVersion,
    required String sourceLanguage,
    required String outputLanguage,
  });
}

class AICacheServiceChapterAICacheAdapter implements ChapterAICacheAdapter {
  const AICacheServiceChapterAICacheAdapter(this._cache);

  final AICacheService _cache;

  @override
  Future<String?> loadSummary({
    required String bookId,
    required int chapterIndex,
    required String outputLanguage,
    required String contentHash,
    required int promptVersion,
    required String sourceLanguage,
  }) {
    return _cache.loadSummary(
      bookId,
      chapterIndex,
      outputLanguage,
      contentHash: contentHash,
      promptVersion: promptVersion,
      sourceLanguage: sourceLanguage,
      outputLanguage: outputLanguage,
    );
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
  }) {
    return _cache.saveSummary(
      bookId,
      chapterIndex,
      outputLanguage,
      jsonString,
      contentHash: contentHash,
      promptVersion: promptVersion,
      sourceLanguage: sourceLanguage,
      outputLanguage: outputLanguage,
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
  }) {
    return _cache.loadPractice(
      bookId,
      chapterIndex,
      contentHash: contentHash,
      promptVersion: promptVersion,
      sourceLanguage: sourceLanguage,
      outputLanguage: outputLanguage,
    );
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
  }) {
    return _cache.savePractice(
      bookId,
      chapterIndex,
      jsonString,
      contentHash: contentHash,
      promptVersion: promptVersion,
      sourceLanguage: sourceLanguage,
      outputLanguage: outputLanguage,
    );
  }
}

class NoopChapterAICacheAdapter implements ChapterAICacheAdapter {
  const NoopChapterAICacheAdapter();

  @override
  Future<String?> loadSummary({
    required String bookId,
    required int chapterIndex,
    required String outputLanguage,
    required String contentHash,
    required int promptVersion,
    required String sourceLanguage,
  }) async {
    return null;
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
  }) async {}

  @override
  Future<String?> loadPractice({
    required String bookId,
    required int chapterIndex,
    required String contentHash,
    required int promptVersion,
    required String sourceLanguage,
    required String outputLanguage,
  }) async {
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
  }) async {}
}

abstract class ChapterAIUsageAdapter {
  Future<void> recordChapterSummaryGenerated();

  Future<void> recordPracticeGenerated();
}

class CallbackChapterAIUsageAdapter implements ChapterAIUsageAdapter {
  CallbackChapterAIUsageAdapter({
    required this.onSummaryGenerated,
    required this.onPracticeGenerated,
  });

  final Future<void> Function() onSummaryGenerated;
  final Future<void> Function() onPracticeGenerated;

  @override
  Future<void> recordChapterSummaryGenerated() => onSummaryGenerated();

  @override
  Future<void> recordPracticeGenerated() => onPracticeGenerated();
}

class NoopChapterAIUsageAdapter implements ChapterAIUsageAdapter {
  const NoopChapterAIUsageAdapter();

  @override
  Future<void> recordChapterSummaryGenerated() async {}

  @override
  Future<void> recordPracticeGenerated() async {}
}

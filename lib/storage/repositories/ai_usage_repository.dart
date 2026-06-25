import 'package:drift/drift.dart';
import 'package:flow_ai/flow_ai.dart';

import '../database/app_database.dart';
import '../database/dao/ai_usage_dao.dart';

export '../database/dao/ai_usage_dao.dart'
    show AIUsageBreakdown, AIUsageSummary;

enum AIUsageSourceType {
  book('book'),
  rss('rss'),
  browser('browser'),
  global('global');

  const AIUsageSourceType(this.value);

  final String value;
}

enum AIUsageOperation {
  chapterSummary('summary'),
  chapterPractice('practice'),
  chapterPreview('chapter_preview'),
  textAnalysis('text_analysis'),
  wordAnalysis('word_analysis'),
  translation('translation'),
  bookSynthesis('book_synthesis'),
  rssSummary('rss_summary'),
  browserExplain('browser_explain'),
  globalAssistant('global_assistant');

  const AIUsageOperation(this.value);

  final String value;
}

class AIUsageRepository {
  AIUsageRepository(this._dao, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AiUsageDao _dao;
  final DateTime Function() _clock;

  Future<void> recordCall({
    required AIUsageSourceType sourceType,
    String? sourceId,
    String? bookId,
    int? chapterIndex,
    required String providerId,
    required String model,
    required AIUsageOperation operation,
    TokenUsageInfo? usage,
    int? durationMs,
    int? promptVersion,
    String? requestId,
  }) {
    return _dao.record(
      AiUsageEventsCompanion.insert(
        sourceType: sourceType.value,
        sourceId: Value(sourceId),
        bookId: Value(bookId),
        chapterIndex: Value(chapterIndex),
        providerId: providerId,
        model: model,
        operation: operation.value,
        promptTokens: Value(usage?.promptTokens),
        completionTokens: Value(usage?.completionTokens),
        totalTokens: Value(usage?.totalTokens),
        durationMs: Value(durationMs),
        promptVersion: Value(promptVersion),
        requestId: Value(requestId),
        createdAt: _clock(),
      ),
    );
  }

  Future<AIUsageSummary> globalSummary() => _dao.globalSummary();

  Future<AIUsageSummary> summaryForBook(String bookId) {
    return _dao.summaryForBook(bookId);
  }

  Future<List<AIUsageEvent>> recentEvents({
    String? bookId,
    int limit = 50,
  }) {
    return _dao.recentEvents(bookId: bookId, limit: limit);
  }

  Future<void> clearForBook(String bookId) => _dao.clearForBook(bookId);

  Future<void> clearAll() => _dao.clearAll();
}

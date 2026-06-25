import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'ai_usage_dao.g.dart';

@DriftAccessor(tables: [AiUsageEvents, BookEntries])
class AiUsageDao extends DatabaseAccessor<AppDatabase> with _$AiUsageDaoMixin {
  AiUsageDao(super.db);

  Future<int> record(AiUsageEventsCompanion event) {
    return into(aiUsageEvents).insert(event);
  }

  Future<AIUsageSummary> globalSummary() async {
    final totals = await _totals();
    final byOperation = await _breakdown(
      keyColumn: 'operation',
      labelColumn: 'operation',
      groupBy: 'operation',
      orderLimit: 8,
    );
    final byModel = await _breakdown(
      keyColumn: "provider_id || ':' || model",
      labelColumn: "provider_id || ' / ' || model",
      groupBy: 'provider_id, model',
      orderLimit: 8,
    );
    final byBook = await _bookBreakdown(orderLimit: 8);
    return AIUsageSummary(
      totalCalls: totals.calls,
      totalPromptTokens: totals.promptTokens,
      totalCompletionTokens: totals.completionTokens,
      totalTokens: totals.totalTokens,
      byOperation: byOperation,
      byModel: byModel,
      byBook: byBook,
    );
  }

  Future<AIUsageSummary> summaryForBook(String bookId) async {
    final totals = await _totals(
      whereSql: 'WHERE book_id = ?',
      variables: [
        Variable.withString(bookId),
      ],
    );
    final byOperation = await _breakdown(
      keyColumn: 'operation',
      labelColumn: 'operation',
      groupBy: 'operation',
      whereSql: 'WHERE book_id = ?',
      variables: [Variable.withString(bookId)],
      orderLimit: 8,
    );
    final byModel = await _breakdown(
      keyColumn: "provider_id || ':' || model",
      labelColumn: "provider_id || ' / ' || model",
      groupBy: 'provider_id, model',
      whereSql: 'WHERE book_id = ?',
      variables: [Variable.withString(bookId)],
      orderLimit: 8,
    );
    return AIUsageSummary(
      totalCalls: totals.calls,
      totalPromptTokens: totals.promptTokens,
      totalCompletionTokens: totals.completionTokens,
      totalTokens: totals.totalTokens,
      byOperation: byOperation,
      byModel: byModel,
      byBook: const [],
    );
  }

  Future<List<AIUsageEvent>> recentEvents({
    String? bookId,
    int limit = 50,
  }) {
    final query = select(aiUsageEvents)
      ..orderBy([(event) => OrderingTerm.desc(event.createdAt)])
      ..limit(limit);
    if (bookId != null) {
      query.where((event) => event.bookId.equals(bookId));
    }
    return query.get();
  }

  Future<void> clearForBook(String bookId) {
    return (delete(
      aiUsageEvents,
    )..where((event) => event.bookId.equals(bookId))).go();
  }

  Future<void> clearAll() {
    return delete(aiUsageEvents).go();
  }

  Future<_UsageTotals> _totals({
    String whereSql = '',
    List<Variable<Object>> variables = const [],
  }) async {
    final row = await customSelect(
      '''
      SELECT
        COUNT(*) AS calls,
        COALESCE(SUM(prompt_tokens), 0) AS prompt_tokens,
        COALESCE(SUM(completion_tokens), 0) AS completion_tokens,
        COALESCE(SUM(total_tokens), 0) AS total_tokens
      FROM ai_usage_events
      $whereSql
      ''',
      variables: variables,
      readsFrom: {aiUsageEvents},
    ).getSingle();
    return _UsageTotals(
      calls: _readInt(row, 'calls'),
      promptTokens: _readInt(row, 'prompt_tokens'),
      completionTokens: _readInt(row, 'completion_tokens'),
      totalTokens: _readInt(row, 'total_tokens'),
    );
  }

  Future<List<AIUsageBreakdown>> _breakdown({
    required String keyColumn,
    required String labelColumn,
    required String groupBy,
    String whereSql = '',
    List<Variable<Object>> variables = const [],
    int orderLimit = 8,
  }) async {
    final rows = await customSelect(
      '''
      SELECT
        $keyColumn AS breakdown_key,
        $labelColumn AS label,
        COUNT(*) AS calls,
        COALESCE(SUM(prompt_tokens), 0) AS prompt_tokens,
        COALESCE(SUM(completion_tokens), 0) AS completion_tokens,
        COALESCE(SUM(total_tokens), 0) AS total_tokens
      FROM ai_usage_events
      $whereSql
      GROUP BY $groupBy
      ORDER BY total_tokens DESC, calls DESC, label ASC
      LIMIT $orderLimit
      ''',
      variables: variables,
      readsFrom: {aiUsageEvents},
    ).get();
    return rows.map(_breakdownFromRow).toList(growable: false);
  }

  Future<List<AIUsageBreakdown>> _bookBreakdown({int orderLimit = 8}) async {
    final rows = await customSelect(
      '''
      SELECT
        e.book_id AS breakdown_key,
        COALESCE(NULLIF(b.title, ''), e.book_id, e.source_id, '未归属') AS label,
        COUNT(*) AS calls,
        COALESCE(SUM(e.prompt_tokens), 0) AS prompt_tokens,
        COALESCE(SUM(e.completion_tokens), 0) AS completion_tokens,
        COALESCE(SUM(e.total_tokens), 0) AS total_tokens
      FROM ai_usage_events e
      LEFT JOIN books b ON b.id = e.book_id
      WHERE e.book_id IS NOT NULL
      GROUP BY e.book_id, b.title, e.source_id
      ORDER BY total_tokens DESC, calls DESC, label ASC
      LIMIT $orderLimit
      ''',
      readsFrom: {aiUsageEvents, bookEntries},
    ).get();
    return rows.map(_breakdownFromRow).toList(growable: false);
  }

  AIUsageBreakdown _breakdownFromRow(QueryRow row) {
    return AIUsageBreakdown(
      key: row.data['breakdown_key']?.toString() ?? '',
      label: row.data['label']?.toString() ?? '',
      calls: _readInt(row, 'calls'),
      promptTokens: _readInt(row, 'prompt_tokens'),
      completionTokens: _readInt(row, 'completion_tokens'),
      totalTokens: _readInt(row, 'total_tokens'),
    );
  }

  int _readInt(QueryRow row, String key) {
    final value = row.data[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}

class AIUsageSummary {
  const AIUsageSummary({
    required this.totalCalls,
    required this.totalPromptTokens,
    required this.totalCompletionTokens,
    required this.totalTokens,
    required this.byOperation,
    required this.byModel,
    required this.byBook,
  });

  static const empty = AIUsageSummary(
    totalCalls: 0,
    totalPromptTokens: 0,
    totalCompletionTokens: 0,
    totalTokens: 0,
    byOperation: [],
    byModel: [],
    byBook: [],
  );

  final int totalCalls;
  final int totalPromptTokens;
  final int totalCompletionTokens;
  final int totalTokens;
  final List<AIUsageBreakdown> byOperation;
  final List<AIUsageBreakdown> byModel;
  final List<AIUsageBreakdown> byBook;

  bool get isEmpty => totalCalls == 0;
}

class AIUsageBreakdown {
  const AIUsageBreakdown({
    required this.key,
    required this.label,
    required this.calls,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  final String key;
  final String label;
  final int calls;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
}

class _UsageTotals {
  const _UsageTotals({
    required this.calls,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  final int calls;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
}

import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/repositories/ai_usage_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AIUsageRepository repository;
  late DateTime now;

  setUp(() async {
    db = await AppDatabase.createInMemory();
    now = DateTime.utc(2026, 6, 25, 8);
    repository = AIUsageRepository(db.aiUsageDao, clock: () => now);
  });

  tearDown(() async {
    await db.close();
  });

  test('records calls and returns global aggregations', () async {
    await db
        .into(db.bookEntries)
        .insert(
          BookEntriesCompanion.insert(
            id: 'book-1',
            title: 'Pride and Prejudice',
            sourcePath: '/tmp/pride.epub',
          ),
        );

    await repository.recordCall(
      sourceType: AIUsageSourceType.book,
      sourceId: 'book-1',
      bookId: 'book-1',
      chapterIndex: 2,
      providerId: 'deepseek',
      model: 'deepseek-chat',
      operation: AIUsageOperation.chapterSummary,
      usage: const TokenUsageInfo(
        promptTokens: 100,
        completionTokens: 40,
        totalTokens: 140,
      ),
      durationMs: 1200,
      promptVersion: 7,
    );
    await repository.recordCall(
      sourceType: AIUsageSourceType.book,
      sourceId: 'book-1',
      bookId: 'book-1',
      chapterIndex: 2,
      providerId: 'deepseek',
      model: 'deepseek-chat',
      operation: AIUsageOperation.wordAnalysis,
      usage: const TokenUsageInfo(
        promptTokens: 30,
        completionTokens: 10,
        totalTokens: 40,
      ),
    );

    final summary = await repository.globalSummary();

    expect(summary.totalCalls, 2);
    expect(summary.totalPromptTokens, 130);
    expect(summary.totalCompletionTokens, 50);
    expect(summary.totalTokens, 180);
    expect(summary.byOperation.map((item) => item.key), contains('summary'));
    expect(
      summary.byBook.single.label,
      'Pride and Prejudice',
    );
    expect(summary.byBook.single.totalTokens, 180);

    final recent = await repository.recentEvents(bookId: 'book-1');
    expect(recent, hasLength(2));
    expect(recent.first.providerId, 'deepseek');
  });

  test('clears usage history', () async {
    await repository.recordCall(
      sourceType: AIUsageSourceType.global,
      providerId: 'openai',
      model: 'gpt-test',
      operation: AIUsageOperation.globalAssistant,
      usage: const TokenUsageInfo(
        promptTokens: 10,
        completionTokens: 5,
        totalTokens: 15,
      ),
    );

    expect((await repository.globalSummary()).totalCalls, 1);

    await repository.clearAll();

    expect((await repository.globalSummary()).isEmpty, isTrue);
  });
}

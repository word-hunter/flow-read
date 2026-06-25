import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/providers/ai_usage_provider.dart';
import 'package:flow_read/providers/reading/services_provider.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/repositories/ai_usage_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = await AppDatabase.createInMemory();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) async => db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('loads global usage summary from repository provider', () async {
    final repository = AIUsageRepository(db.aiUsageDao);
    await repository.recordCall(
      sourceType: AIUsageSourceType.book,
      sourceId: 'book-1',
      bookId: 'book-1',
      chapterIndex: 1,
      providerId: 'deepseek',
      model: 'deepseek-chat',
      operation: AIUsageOperation.chapterSummary,
      usage: const TokenUsageInfo(
        promptTokens: 100,
        completionTokens: 20,
        totalTokens: 120,
      ),
    );

    final summary = await container.read(globalAIUsageProvider.future);

    expect(summary.totalCalls, 1);
    expect(summary.totalTokens, 120);
    expect(summary.byOperation.single.key, 'summary');
  });
}

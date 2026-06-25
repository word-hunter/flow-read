import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/repositories/ai_usage_repository.dart';
import '../storage/storage_bootstrap.dart';
import '../storage/database/app_database.dart';
import 'reading/services_provider.dart';

final aiUsageRepositoryProvider = FutureProvider<AIUsageRepository>((
  ref,
) async {
  final existing = appDatabase;
  final AppDatabase db;
  if (existing != null) {
    db = existing;
  } else {
    db = await ref.watch(appDatabaseProvider.future);
  }
  return AIUsageRepository(db.aiUsageDao);
});

final globalAIUsageProvider = FutureProvider<AIUsageSummary>((ref) async {
  final repository = await ref.watch(aiUsageRepositoryProvider.future);
  return repository.globalSummary();
});

final bookAIUsageProvider = FutureProvider.family<AIUsageSummary, String>((
  ref,
  bookId,
) async {
  final repository = await ref.watch(aiUsageRepositoryProvider.future);
  return repository.summaryForBook(bookId);
});

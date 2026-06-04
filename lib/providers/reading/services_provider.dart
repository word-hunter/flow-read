import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/ai_cache_service.dart';
import '../../services/ai_service.dart';
import '../../services/book_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/dictionary/dictionary_manager_service.dart';
import '../../services/dictionary/dictionary_source_registry.dart';
import '../../services/dictionary/word_repository.dart';
import '../../services/learning_analytics_service.dart';
import '../../services/learning_item_service.dart';
import '../../services/llm_client.dart';
import '../../services/pronunciation_service.dart';
import '../../services/reading_config_service.dart';
import '../../services/reading_time_service.dart';
import '../../services/review_schedule_service.dart';
import '../../services/sentence_analyzer.dart';
import '../../services/user_vocabulary_service.dart';
import '../../services/word_context_service.dart';
import '../../services/word_level_service.dart';
import '../settings_provider.dart';

final bookServiceProvider = Provider<BookService>((ref) => BookService());

final bookmarkServiceProvider = Provider<BookmarkService>((ref) {
  return BookmarkService();
});

final readingConfigServiceProvider = Provider<ReadingConfigService>((ref) {
  return ReadingConfigService();
});

final readingTimeServiceProvider = Provider<ReadingTimeService>((ref) {
  return ReadingTimeService();
});

final userVocabularyServiceProvider = Provider<UserVocabularyService>((ref) {
  return UserVocabularyService();
});

final dictionarySourceRegistryProvider = Provider<DictionarySourceRegistry>((
  ref,
) {
  final registry = DictionarySourceRegistry();
  unawaited(registry.init());
  return registry;
});

final wordRepositoryProvider = Provider<WordRepository>((ref) {
  final settings = ref.read(settingsProvider);
  final registry = ref.read(dictionarySourceRegistryProvider);
  return DictionaryManagerService(
    settings: settings,
    sources: registry.adapters(),
  );
});

final wordLevelServiceProvider = Provider<WordLevelService>((ref) {
  return WordLevelService();
});

final wordContextServiceProvider = Provider<WordContextService>((ref) {
  return WordContextService();
});

final learningItemServiceProvider = Provider<LearningItemService>((ref) {
  return LearningItemService();
});

final learningAnalyticsServiceProvider = Provider<LearningAnalyticsService>((
  ref,
) {
  return LearningAnalyticsService();
});

final reviewScheduleServiceProvider = Provider<ReviewScheduleService>((ref) {
  return ReviewScheduleService(ref.read(learningItemServiceProvider));
});

final pronunciationServiceProvider = Provider<PronunciationService>((ref) {
  return FlutterTtsPronunciationService();
});

final aiServiceProvider = Provider<AIService>((ref) {
  final settings = ref.read(settingsProvider);
  return AIService(LLMClient(settings));
});

final aiCacheServiceProvider = Provider<AICacheService>((ref) {
  return AICacheService();
});

final sentenceAnalyzerProvider = Provider<SentenceAnalyzer>((ref) {
  return RuleBasedSentenceAnalyzer();
});

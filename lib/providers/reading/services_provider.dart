import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flow_ai/flow_ai.dart';
import '../../services/book_cache.dart';
import '../../services/book_glossary_service.dart';
import '../../services/book_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/character_registry.dart';
import 'package:flow_dictionary/flow_dictionary.dart';
import '../../services/learning_analytics_service.dart';
import '../../services/learning_item_service.dart';
import '../../services/pronunciation_service.dart';
import '../../services/reading_config_service.dart';
import '../../services/reading_insight_service.dart';
import '../../services/reading_time_service.dart';
import '../../services/review_schedule_service.dart';
import '../../services/sentence_analyzer.dart';
import '../../services/reader_layout_engine.dart';
import '../../services/user_vocabulary_service.dart';
import '../../services/word_context_service.dart';
import '../../services/word_level_service.dart';
import '../../storage/database/app_database.dart';
import '../../storage/database/dao/book_glossary_dao.dart';
import '../../storage/database/repositories/drift_reading_config_repository.dart';
import '../../storage/hive_storage.dart';
import '../settings_provider.dart';

final bookCacheProvider = Provider<BookCache>((ref) => BookCache());

final bookServiceProvider = Provider<BookService>((ref) => BookService());

final bookmarkServiceProvider = Provider<BookmarkService>((ref) {
  return BookmarkService();
});

final readingConfigServiceProvider = Provider<ReadingConfigService>((ref) {
  final db = appDatabase;
  final service = db == null
      ? ReadingConfigService()
      : ReadingConfigService(
          repository: DriftReadingConfigRepository(
            db.readingConfigDao,
            languageCode: bootstrappedReadingConfigLanguage,
            initialValues: bootstrappedReadingConfigValues,
          ),
          loadImmediately: true,
        );
  unawaited(service.init());
  return service;
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
    configs: settings.dictionarySources,
    sources: registry.adapters(),
  );
});

final wordLevelServiceProvider = Provider<WordLevelService>((ref) {
  final service = WordLevelService();
  unawaited(service.init());
  return service;
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
  return AIService(LLMClient(() => settings.aiProviderConfig));
});

final aiCacheServiceProvider = Provider<AICacheService>((ref) {
  return AICacheService();
});

final sentenceAnalyzerProvider = Provider<SentenceAnalyzer>((ref) {
  return RuleBasedSentenceAnalyzer();
});

final bookGlossaryServiceProvider = Provider<BookGlossaryService>((ref) {
  return BookGlossaryService(ref.watch(bookGlossaryDaoProvider));
});

final characterRegistryProvider = Provider<CharacterRegistry>((ref) {
  return CharacterRegistry();
});

final readingInsightServiceProvider = Provider<ReadingInsightService>((ref) {
  return ReadingInsightService(
    analytics: ref.read(learningAnalyticsServiceProvider),
  );
});

final readerLayoutEngineProvider = Provider<ReaderLayoutEngine>((ref) {
  return const ReaderLayoutEngine();
});

final aiAssistantControllerProvider = Provider<AIAssistantController>((ref) {
  final assistant = AIAssistantController(
    registry: ref.watch(aiActionRegistryProvider),
    automationSettings: ref.watch(aiAutomationSettingsProvider),
    insightProfile: const ReadingInsightProfile(),
    actionController: ref.watch(aiActionControllerProvider),
  );
  ref.onDispose(() => assistant.dispose());
  return assistant;
});

final aiAutomationSettingsProvider = Provider<AIAutomationSettings>((ref) {
  final settings = ref.watch(settingsProvider);
  return AIAutomationSettings(mode: settings.aiAutomationMode);
});

final aiActionRegistryProvider = Provider<AIAssistantActionRegistry>((ref) {
  return const AIAssistantActionRegistry(promptBuilder: PromptBuilder());
});

final aiActionControllerProvider = Provider<AIActionController>((ref) {
  final controller = AIActionController(
    aiService: ref.watch(aiServiceProvider),
    cacheService: ref.watch(aiCacheServiceProvider),
  );
  ref.onDispose(() => controller.dispose());
  return controller;
});

final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final existing = appDatabase;
  return existing ?? AppDatabase.create();
});

final bookGlossaryDaoProvider = Provider<BookGlossaryDao>((ref) {
  final db = ref.watch(appDatabaseProvider).requireValue;
  return BookGlossaryDao(db);
});

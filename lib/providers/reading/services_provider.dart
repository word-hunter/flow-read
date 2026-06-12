import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:flow_ai/flow_ai.dart';
import '../../models/book.dart';
import '../../services/app_logger.dart';
import '../../services/book_cache.dart';
import '../../services/book_glossary_service.dart';
import '../../services/book_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/character_registry.dart';
import 'package:flow_dictionary/flow_dictionary.dart';
import '../../services/epub_parse_worker.dart';
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
import '../../storage/database/repositories/drift_book_repository.dart';
import '../../storage/database/repositories/drift_bookmark_repository.dart';
import '../../storage/database/repositories/drift_dictionary_cache_repository.dart';
import '../../storage/database/repositories/drift_learning_analytics_repository.dart';
import '../../storage/database/repositories/drift_learning_item_repository.dart';
import '../../storage/database/repositories/drift_reading_config_repository.dart';
import '../../storage/database/repositories/drift_reading_time_repository.dart';
import '../../storage/database/repositories/drift_user_vocabulary_repository.dart';
import '../../storage/database/repositories/drift_word_context_repository.dart';
import '../../storage/hive_storage.dart';
import '../book_insight_provider.dart';
import '../settings_provider.dart';
import 'bookshelf_notifier.dart';

final bookCacheProvider = Provider<BookCache>((ref) => BookCache());

final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger.instance);

typedef EpubBookParser = Future<Book> Function(String filePath);

final epubBookParserProvider = Provider<EpubBookParser>((ref) {
  return EpubParseWorker.parseInIsolate;
});

final bookServiceProvider = Provider<BookService>((ref) {
  final db = appDatabase;
  if (db == null) return BookService();

  final languageCode = ref.watch(settingsProvider).activeSourceLanguage;
  final service = BookService(
    repository: DriftBookRepository(
      db.bookDao,
      languageCode: languageCode,
      initialValues: languageCode == bootstrappedBookMetadataLanguage
          ? bootstrappedBookMetadataValues
          : const [],
    ),
  );
  unawaited(service.init());
  return service;
});

final bookmarkServiceProvider = Provider<BookmarkService>((ref) {
  final db = appDatabase;
  if (db == null) return BookmarkService();

  final languageCode = ref.watch(settingsProvider).activeSourceLanguage;
  final service = BookmarkService(
    repository: DriftBookmarkRepository(
      db.bookmarkDao,
      languageCode: languageCode,
      initialWordBookmarks: languageCode == bootstrappedBookmarkLanguage
          ? bootstrappedWordBookmarkValues
          : const {},
      initialReadingBookmarks: languageCode == bootstrappedBookmarkLanguage
          ? bootstrappedReadingBookmarkValues
          : const {},
    ),
  );
  unawaited(service.init());
  return service;
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
  final db = appDatabase;
  if (db == null) return ReadingTimeService();

  final languageCode = ref.watch(settingsProvider).activeSourceLanguage;
  final initialValues = languageCode == bootstrappedReadingTimeLanguage
      ? bootstrappedReadingTimeValues
      : const <String, int>{};
  final service = ReadingTimeService(
    repository: DriftReadingTimeRepository(
      db.readingTimeDao,
      languageCode: languageCode,
      initialValues: initialValues,
    ),
    initialTotalSeconds:
        initialValues[ReadingTimeService.globalStorageKey] ?? 0,
  );
  unawaited(service.init());
  return service;
});

final userVocabularyServiceProvider = Provider<UserVocabularyService>((ref) {
  final db = appDatabase;
  if (db == null) return UserVocabularyService();

  final languageCode = ref.watch(settingsProvider).activeSourceLanguage;
  final service = UserVocabularyService(
    repository: DriftUserVocabularyRepository(
      db.userVocabularyDao,
      languageCode: languageCode,
      initialValues: languageCode == bootstrappedUserVocabularyLanguage
          ? bootstrappedUserVocabularyValues
          : const {},
    ),
    languageCode: languageCode,
  );
  unawaited(service.init());
  return service;
});

final dictionarySourceRegistryProvider = Provider<DictionarySourceRegistry>((
  ref,
) {
  final registry = DictionarySourceRegistry(
    cache: ref.watch(dictionaryCacheServiceProvider),
  );
  unawaited(registry.init());
  return registry;
});

final dictionaryCacheServiceProvider = Provider<DictionaryCacheService>((ref) {
  final db = appDatabase;
  final languageCode = ref.watch(settingsProvider).activeSourceLanguage;
  final service = db == null
      ? DictionaryCacheService(languageCode: languageCode)
      : DictionaryCacheService(
          repository: DriftDictionaryCacheRepository(
            db.dictionaryCacheDao,
            languageCode: languageCode,
            initialValues: languageCode == bootstrappedDictionaryCacheLanguage
                ? bootstrappedDictionaryCacheValues
                : const {},
          ),
          languageCode: languageCode,
        );
  unawaited(service.init());
  return service;
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
  final db = appDatabase;
  if (db == null) return WordContextService();

  final languageCode = ref.watch(settingsProvider).activeSourceLanguage;
  final service = WordContextService(
    repository: DriftWordContextRepository(
      db.wordContextDao,
      languageCode: languageCode,
      initialValues: languageCode == bootstrappedWordContextLanguage
          ? bootstrappedWordContextValues
          : const {},
    ),
  );
  unawaited(service.init());
  return service;
});

final learningItemServiceProvider = Provider<LearningItemService>((ref) {
  final db = appDatabase;
  if (db == null) return LearningItemService();

  final languageCode = ref.watch(settingsProvider).activeSourceLanguage;
  final service = LearningItemService(
    repository: DriftLearningItemRepository(
      db.learningItemDao,
      languageCode: languageCode,
      initialValues: languageCode == bootstrappedLearningItemLanguage
          ? bootstrappedLearningItemValues
          : const [],
    ),
  );
  unawaited(service.init());
  return service;
});

final learningAnalyticsServiceProvider = Provider<LearningAnalyticsService>((
  ref,
) {
  final db = appDatabase;
  if (db == null) return LearningAnalyticsService();

  final languageCode = ref.watch(settingsProvider).activeSourceLanguage;
  final service = LearningAnalyticsService(
    repository: DriftLearningAnalyticsRepository(
      db.learningAnalyticsDao,
      languageCode: languageCode,
      initialValues: languageCode == bootstrappedLearningAnalyticsLanguage
          ? bootstrappedLearningAnalyticsValues
          : const {},
    ),
  );
  unawaited(service.init());
  return service;
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
  final bookshelf = ref.watch(bookshelfNotifierProvider);
  String? userProfile;
  if (bookshelf.activeBookId != null && bookshelf.book != null) {
    final service = ref.read(readingInsightServiceProvider);
    final profile = service.compute(
      bookId: bookshelf.activeBookId!,
      book: bookshelf.book!,
    );
    if (!profile.isEmpty) {
      userProfile = profile.learningFocusSummary;
    }
  }
  return AIAssistantActionRegistry(
    promptBuilder: PromptBuilder(userProfile: userProfile),
    contextSelector: const ExplanationContextSelector(),
  );
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

final bookInsightProvider = ChangeNotifierProvider<BookInsightProvider>((ref) {
  final provider = BookInsightProvider(
    cacheService: ref.watch(aiCacheServiceProvider),
  );
  ref.onDispose(() => provider.dispose());
  return provider;
});

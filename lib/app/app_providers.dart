import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';

import '../providers/reading_provider.dart';
import '../providers/rss_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_cache_service.dart';
import '../services/ai_service.dart';
import '../services/backup_service.dart';
import '../services/book_service.dart';
import '../services/bookmark_service.dart';
import '../services/dictionary/dictionary_manager_service.dart';
import '../services/dictionary/dictionary_source_registry.dart';
import '../services/learning_item_service.dart';
import '../services/learning_analytics_service.dart';
import '../services/review_schedule_service.dart';
import '../services/llm_client.dart';
import '../services/pronunciation_service.dart';
import '../services/reading_config_service.dart';
import '../services/reading_time_service.dart';
import '../services/settings_service.dart';
import '../services/user_vocabulary_service.dart';
import '../services/word_context_service.dart';
import '../services/word_level_service.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final settings = riverpod.ProviderScope.containerOf(
      context,
      listen: false,
    ).read(settingsProvider);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: settings),
        ChangeNotifierProvider(
          create: (_) => _createBackupService(settings),
        ),
        ChangeNotifierProvider(
          create: (_) => _createReadingProvider(settings),
        ),
        ChangeNotifierProvider(create: (_) => _createRssProvider()),
      ],
      child: child,
    );
  }
}

BackupService _createBackupService(SettingsService settings) {
  final service = BackupService(settings);
  service.init();
  return service;
}

ReadingProvider _createReadingProvider(SettingsService settings) {
  final provider = ReadingProvider();

  final bookService = BookService();
  provider.setBookService(bookService);

  final bookmarkService = BookmarkService();
  bookmarkService.init();
  provider.setBookmarkService(bookmarkService);

  final readingConfig = ReadingConfigService();
  readingConfig.init();
  provider.setReadingConfig(readingConfig);

  final readingTime = ReadingTimeService();
  readingTime.init();
  provider.setReadingTime(readingTime);

  final userVocab = UserVocabularyService();
  userVocab.init();
  provider.setUserVocabulary(userVocab);

  final dictionarySources = DictionarySourceRegistry();
  unawaited(dictionarySources.init());

  provider.setWordRepository(
    DictionaryManagerService(
      settings: settings,
      sources: dictionarySources.adapters(),
    ),
  );

  final wordLevelService = WordLevelService();
  wordLevelService.init();
  provider.setWordLevelService(wordLevelService);

  final wordContextService = WordContextService();
  wordContextService.init();
  provider.setWordContextService(wordContextService);

  final learningItemService = LearningItemService();
  learningItemService.init();
  provider.setLearningItemService(learningItemService);

  final learningAnalyticsService = LearningAnalyticsService();
  learningAnalyticsService.init();
  provider.setLearningAnalyticsService(learningAnalyticsService);

  provider.setReviewScheduleService(ReviewScheduleService(learningItemService));

  provider.setPronunciationService(FlutterTtsPronunciationService());

  provider.setSettings(settings);
  provider.setAIService(AIService(LLMClient(settings)));

  final aiCache = AICacheService();
  aiCache.init();
  provider.setAICache(aiCache);

  provider.init();
  return provider;
}

RssProvider _createRssProvider() {
  final provider = RssProvider();
  provider.init();
  return provider;
}

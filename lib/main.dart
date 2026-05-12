import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/book_metadata.dart';
import 'models/bookmarked_word.dart';
import 'models/reading_bookmark.dart';
import 'models/reading_config.dart';
import 'models/rss_models.dart';
import 'models/word_level.dart';
import 'providers/reading_provider.dart';
import 'providers/rss_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/review_screen.dart';
import 'screens/spaced_review_screen.dart';
import 'screens/syntax_screen.dart';
import 'services/ai_cache_service.dart';
import 'services/ai_service.dart';
import 'services/book_service.dart';
import 'services/bookmark_service.dart';
import 'services/collins_repository.dart';
import 'services/composite_word_repository.dart';
import 'services/dictionary_cache_service.dart';
import 'services/dictionary_repository.dart';
import 'services/llm_client.dart';
import 'services/longman_repository.dart';
import 'services/reading_config_service.dart';
import 'services/reading_time_service.dart';
import 'services/settings_service.dart';
import 'services/user_vocabulary_service.dart';
import 'services/word_level_service.dart';
import 'services/wordnet_repository.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(BookMetadataAdapter());
  Hive.registerAdapter(BookmarkedWordAdapter());
  Hive.registerAdapter(ReadingBookmarkAdapter());
  Hive.registerAdapter(ReadingConfigAdapter());
  Hive.registerAdapter(WordLevelInfoAdapter());
  Hive.registerAdapter(RssFeedSubscriptionAdapter());

  await Hive.openBox<BookMetadata>('books');
  await Hive.openBox<String>('user_vocabulary');
  await Hive.openBox('settings');
  await Hive.openBox<String>('word_bookmarks');
  await Hive.openBox<String>('reading_bookmarks');
  await Hive.openBox<String>('reading_config');
  await Hive.openBox<int>('reading_time');
  await Hive.openBox<WordLevelInfo>('word_levels');
  await Hive.openBox<String>('dictionary_cache');
  await Hive.openBox<RssFeedSubscription>('rss_subscriptions');

  runApp(const FlowReadApp());
}

class FlowReadApp extends StatelessWidget {
  const FlowReadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final svc = SettingsService();
            svc.init();
            return svc;
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
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

            final dictCache = DictionaryCacheService();
            dictCache.init();

            final collinsRepo = CollinsRepository(dictCache);
            final longmanRepo = LongmanRepository(dictCache);

            provider.setWordRepository(
              CompositeWordRepository([
                WordNetRepository(),
                DictionaryRepository(),
                collinsRepo,
                longmanRepo,
              ]),
            );

            final wordLevelService = WordLevelService();
            wordLevelService.init();
            provider.setWordLevelService(wordLevelService);

            final settings = context.read<SettingsService>();
            provider.setSettings(settings);

            final llmClient = LLMClient(settings);
            provider.setAIService(AIService(llmClient));

            final aiCache = AICacheService();
            aiCache.init();
            provider.setAICache(aiCache);

            provider.init();
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final rssProvider = RssProvider();
            rssProvider.init();
            return rssProvider;
          },
        ),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settings, _) => MaterialApp(
          title: 'Flow Read',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          home: const HomeScreen(),
          routes: {
            '/dashboard': (_) => const DashboardScreen(),
            '/syntax': (_) => const SyntaxScreen(),
            '/practice': (_) => const PracticeScreen(),
            '/review': (_) => const ReviewScreen(),
            '/spaced_review': (_) => const SpacedReviewScreen(),
          },
        ),
      ),
    );
  }
}

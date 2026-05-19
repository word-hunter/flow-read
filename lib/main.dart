import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/book_metadata.dart';
import 'models/bookmarked_word.dart';
import 'models/learning_item.dart';
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
import 'screens/settings_screen.dart';
import 'screens/spaced_review_screen.dart';
import 'screens/syntax_screen.dart';
import 'services/ai_cache_service.dart';
import 'services/ai_service.dart';
import 'services/backup_service.dart';
import 'services/book_service.dart';
import 'services/bookmark_service.dart';
import 'services/dictionary/collins_repository.dart';
import 'services/dictionary/dictionary_cache_service.dart';
import 'services/dictionary/dictionary_manager_service.dart';
import 'services/dictionary/dictionary_repository.dart';
import 'services/dictionary/dictionary_source_config.dart';
import 'services/learning_item_service.dart';
import 'services/llm_client.dart';
import 'services/dictionary/longman_repository.dart';
import 'services/reading_config_service.dart';
import 'services/reading_time_service.dart';
import 'services/settings_service.dart';
import 'services/user_vocabulary_service.dart';
import 'services/word_context_service.dart';
import 'services/word_level_service.dart';
import 'services/dictionary/wordnet_repository.dart';
import 'theme/app_theme.dart';
import 'widgets/epub_drop_importer.dart';
import 'widgets/release_notes_gate.dart';
import 'widgets/theme_transition.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlowReadBootstrapApp());
}

Future<void> _bootstrapStorage() async {
  await Hive.initFlutter();

  _registerHiveAdapter(0, BookMetadataAdapter());
  _registerHiveAdapter(1, BookmarkedWordAdapter());
  _registerHiveAdapter(2, ReadingBookmarkAdapter());
  _registerHiveAdapter(3, ReadingConfigAdapter());
  _registerHiveAdapter(4, WordLevelInfoAdapter());
  _registerHiveAdapter(10, RssFeedSubscriptionAdapter());
  _registerHiveAdapter(11, LearningItemAdapter());

  await Future.wait([
    Hive.openBox<BookMetadata>('books'),
    Hive.openBox<String>('user_vocabulary'),
    Hive.openBox('settings'),
    Hive.openBox<String>('word_bookmarks'),
    Hive.openBox<String>('reading_bookmarks'),
    Hive.openBox<String>('reading_config'),
    Hive.openBox<int>('reading_time'),
    Hive.openBox<WordLevelInfo>('word_levels'),
    Hive.openBox<String>('dictionary_cache'),
    Hive.openBox<RssFeedSubscription>('rss_subscriptions'),
    Hive.openBox<String>('word_contexts'),
    Hive.openBox<LearningItem>('learning_items'),
  ]);
}

void _registerHiveAdapter<T>(int typeId, TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(typeId)) {
    Hive.registerAdapter(adapter);
  }
}

class FlowReadBootstrapApp extends StatefulWidget {
  const FlowReadBootstrapApp({super.key});

  @override
  State<FlowReadBootstrapApp> createState() => _FlowReadBootstrapAppState();
}

class _FlowReadBootstrapAppState extends State<FlowReadBootstrapApp> {
  late Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrapStorage();
  }

  void _retry() {
    setState(() {
      _bootstrapFuture = _bootstrapStorage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return const FlowReadApp();
        }

        return MaterialApp(
          title: 'Flow Read',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: StartupScreen(error: snapshot.error, onRetry: _retry),
        );
      },
    );
  }
}

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key, this.error, required this.onRetry});

  static const _logoAsset = 'assets/brand/flow_read_logo.png';

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasError = error != null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: hasError
                        ? Icon(
                            Icons.error_outline_rounded,
                            size: 36,
                            color: colorScheme.error,
                          )
                        : Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                _logoAsset,
                                filterQuality: FilterQuality.high,
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Flow Read',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasError ? '启动失败，请重试' : '正在准备书架...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (hasError) ...[
                    const SizedBox(height: 16),
                    Text(
                      '$error',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('重试'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenSettingsIntent extends Intent {
  const _OpenSettingsIntent();
}

class _CurrentRouteObserver extends NavigatorObserver {
  String? currentRouteName;

  void _setCurrent(Route<dynamic>? route) {
    currentRouteName = route?.settings.name;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _setCurrent(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _setCurrent(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _setCurrent(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _setCurrent(newRoute);
  }
}

class FlowReadApp extends StatefulWidget {
  const FlowReadApp({super.key});

  @override
  State<FlowReadApp> createState() => _FlowReadAppState();
}

class _FlowReadAppState extends State<FlowReadApp> {
  static const _appMenuChannel = MethodChannel('flow_read/app_menu');

  final _navigatorKey = GlobalKey<NavigatorState>();
  final _routeObserver = _CurrentRouteObserver();

  bool get _usesNativeSettingsMenu {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  void initState() {
    super.initState();
    _appMenuChannel.setMethodCallHandler(_handleAppMenuCall);
  }

  @override
  void dispose() {
    _appMenuChannel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _handleAppMenuCall(MethodCall call) async {
    if (call.method == 'openSettings') {
      // AppKit key equivalents can consume Cmd+, before Flutter records the
      // modifier down, so align state before the synthesized modifier up.
      await HardwareKeyboard.instance.syncKeyboardState();
      _openSettings();
      return;
    }
    throw MissingPluginException('Unknown app menu method: ${call.method}');
  }

  void _openSettings() {
    final navigator = _navigatorKey.currentState;
    if (navigator == null ||
        _routeObserver.currentRouteName == SettingsScreen.routeName) {
      return;
    }
    navigator.pushNamed(SettingsScreen.routeName);
  }

  Widget _buildShortcutScope(BuildContext context, Widget? child) {
    const openSettingsIntent = _OpenSettingsIntent();

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        if (!_usesNativeSettingsMenu)
          const SingleActivator(LogicalKeyboardKey.comma, meta: true):
              openSettingsIntent,
        const SingleActivator(LogicalKeyboardKey.comma, control: true):
            openSettingsIntent,
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _OpenSettingsIntent: CallbackAction<_OpenSettingsIntent>(
            onInvoke: (_) {
              _openSettings();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child ?? const SizedBox.shrink()),
      ),
    );
  }

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
            final svc = BackupService(context.read<SettingsService>());
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

            final settings = context.read<SettingsService>();

            provider.setWordRepository(
              DictionaryManagerService(
                settings: settings,
                sources: [
                  DictionarySourceAdapter(
                    type: DictionarySourceType.wordNet,
                    repository: WordNetRepository(),
                  ),
                  DictionarySourceAdapter(
                    type: DictionarySourceType.dictionaryApi,
                    repository: DictionaryRepository(),
                  ),
                  DictionarySourceAdapter(
                    type: DictionarySourceType.collins,
                    repository: CollinsRepository(dictCache),
                  ),
                  DictionarySourceAdapter(
                    type: DictionarySourceType.longman,
                    repository: LongmanRepository(dictCache),
                  ),
                ],
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
        builder: (context, settings, _) {
          final themeId = settings.appThemeId;
          return ThemeTransitionHost(
            child: MaterialApp(
              navigatorKey: _navigatorKey,
              navigatorObservers: [_routeObserver],
              title: 'Flow Read',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightThemeFor(themeId),
              darkTheme: AppTheme.darkThemeFor(themeId),
              themeMode: settings.themeMode,
              themeAnimationDuration: const Duration(milliseconds: 220),
              themeAnimationCurve: Curves.easeOutCubic,
              builder: _buildShortcutScope,
              home: const ReleaseNotesGate(
                child: EpubDropImporter(child: HomeScreen()),
              ),
              routes: {
                SettingsScreen.routeName: (_) => const SettingsScreen(),
                '/dashboard': (_) => const DashboardScreen(),
                '/syntax': (_) => const SyntaxScreen(),
                '/practice': (_) => const PracticeScreen(),
                '/review': (_) => const ReviewScreen(),
                '/spaced_review': (_) => const SpacedReviewScreen(),
              },
            ),
          );
        },
      ),
    );
  }
}

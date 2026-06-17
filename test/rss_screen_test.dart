import 'package:flow_language/english/english.dart';
import 'package:flow_language/flow_language.dart';
import 'package:flow_read/models/reader_font.dart';
import 'package:flow_read/models/reading_memory.dart';
import 'package:flow_read/models/user_vocabulary.dart';
import 'package:flow_read/models/word_context_example.dart';
import 'package:flow_read/providers/reading/services_provider.dart';
import 'package:flow_read/providers/reading/vocabulary_notifier.dart';
import 'package:flow_read/providers/reading/word_lookup_notifier.dart';
import 'package:flow_read/providers/rss_riverpod_provider.dart';
import 'package:flow_read/providers/settings_provider.dart';
import 'package:flow_read/providers/web_content_provider.dart';
import 'package:flow_read/screens/browser_screen.dart';
import 'package:flow_read/screens/rss_article_detail_screen.dart';
import 'package:flow_read/screens/rss_screen.dart';
import 'package:flow_read/services/reading_config_service.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/services/web_content_service.dart';
import 'package:flow_read/storage/repositories/reading_config_repository.dart';
import 'package:flow_read/widgets/reader/reader_word_sidebar.dart';
import 'package:flow_read/widgets/word_bottom_sheet.dart';
import 'package:flow_rss/flow_rss.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_word_level_service.dart';
import 'support/test_storage.dart';

void main() {
  testWidgets('wide RSS screen opens article details inline', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final articles = [
      RssArticle(
        id: 'first',
        feedUrl: 'https://example.com/rss.xml',
        feedTitle: 'Example',
        title: 'First RSS article',
      ),
      RssArticle(
        id: 'second',
        feedUrl: 'https://example.com/rss.xml',
        feedTitle: 'Example',
        title: 'Second RSS article',
      ),
    ];
    final service = _FakeRssFeedService(
      subscriptions: [
        RssFeedSubscription(
          url: 'https://example.com/rss.xml',
          title: 'Example',
        ),
      ],
      articles: articles,
    );

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          rssFeedServiceProvider.overrideWithValue(service),
          rssReadingConfigServiceProvider.overrideWithValue(
            _FakeReadingConfigService(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: RssScreen())),
      ),
    );
    await tester.pumpAndSettle();

    final detailPane = find.byType(RssArticleDetailPane);
    expect(detailPane, findsOneWidget);
    expect(find.text('最新内容'), findsOneWidget);
    expect(find.text('进入精读'), findsNothing);
    expect(find.text('阅读模式'), findsNothing);
    expect(find.text('学习模式'), findsNothing);
    expect(find.byTooltip('查看原文'), findsNothing);
    expect(
      find.descendant(
        of: detailPane,
        matching: find.text('First RSS article'),
      ),
      findsOneWidget,
    );
    expect(find.byType(BrowserScreen), findsNothing);
    expect(service.readArticleIds, isEmpty);

    await tester.tap(find.text('Second RSS article').first);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: detailPane,
        matching: find.text('Second RSS article'),
      ),
      findsOneWidget,
    );
    expect(service.readArticleIds, contains('second'));
    expect(find.byType(BrowserScreen), findsNothing);
  });

  testWidgets('wide RSS word lookup uses the right dictionary panel', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = _FakeRssFeedService(
      subscriptions: [
        RssFeedSubscription(
          url: 'https://example.com/rss.xml',
          title: 'Example',
        ),
      ],
      articles: [
        RssArticle(
          id: 'rss-river',
          feedUrl: 'https://example.com/rss.xml',
          feedTitle: 'Example',
          title: 'River article',
          content: 'The river runs through the quiet valley.',
          bodyBlocks: const [
            RssArticleTextBlock(
              type: RssArticleTextBlockType.paragraph,
              text: 'The river runs through the quiet valley.',
            ),
          ],
        ),
      ],
    );
    final settings = await createTestSettingsService();

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          rssFeedServiceProvider.overrideWithValue(service),
          rssReadingConfigServiceProvider.overrideWithValue(
            _FakeReadingConfigService(),
          ),
          settingsProvider.overrideWith((ref) => settings),
          wordLevelServiceProvider.overrideWithValue(fakeWordLevelService()),
          wordLookupNotifierProvider.overrideWith(_RssLookupNotifier.new),
          vocabularyNotifierProvider.overrideWith(_RssVocabularyNotifier.new),
        ],
        child: const MaterialApp(home: Scaffold(body: RssScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ReaderWordSidebar), findsNothing);
    expect(find.byType(WordBottomSheet), findsNothing);

    _tapRichTextSpan(tester, 'river');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byType(ReaderWordSidebar), findsOneWidget);
    expect(find.byType(WordBottomSheet), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ReaderWordSidebar),
        matching: find.text('river'),
      ),
      findsWidgets,
    );
  });

  testWidgets('wide RSS article list can collapse and expand', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = _FakeRssFeedService(
      subscriptions: [
        RssFeedSubscription(
          url: 'https://example.com/rss.xml',
          title: 'Example',
        ),
      ],
      articles: [
        RssArticle(
          id: 'first',
          feedUrl: 'https://example.com/rss.xml',
          feedTitle: 'Example',
          title: 'First RSS article',
        ),
        RssArticle(
          id: 'second',
          feedUrl: 'https://example.com/rss.xml',
          feedTitle: 'Example',
          title: 'Second RSS article',
        ),
      ],
    );

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          rssFeedServiceProvider.overrideWithValue(service),
          rssReadingConfigServiceProvider.overrideWithValue(
            _FakeReadingConfigService(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: RssScreen())),
      ),
    );
    await tester.pumpAndSettle();

    final detailPane = find.byType(RssArticleDetailPane);
    expect(find.byTooltip('折叠列表'), findsOneWidget);
    expect(find.text('Second RSS article'), findsOneWidget);

    await tester.tap(find.byTooltip('折叠列表'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('展开列表'), findsOneWidget);
    expect(find.text('Second RSS article'), findsNothing);
    expect(
      find.descendant(
        of: detailPane,
        matching: find.text('First RSS article'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('展开列表'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('折叠列表'), findsOneWidget);
    expect(find.text('Second RSS article'), findsOneWidget);
  });

  testWidgets('RSS reading settings do not change book reading settings', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bookConfigService = _FakeReadingConfigService();
    final rssConfigService = _FakeReadingConfigService();
    final service = _FakeRssFeedService(
      subscriptions: [
        RssFeedSubscription(
          url: 'https://example.com/rss.xml',
          title: 'Example',
        ),
      ],
      articles: [
        RssArticle(
          id: 'settings',
          feedUrl: 'https://example.com/rss.xml',
          feedTitle: 'Example',
          title: 'Settings article',
        ),
      ],
    );

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          rssFeedServiceProvider.overrideWithValue(service),
          readingConfigServiceProvider.overrideWithValue(bookConfigService),
          rssReadingConfigServiceProvider.overrideWithValue(rssConfigService),
        ],
        child: const MaterialApp(home: Scaffold(body: RssScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('阅读设置'));
    await tester.pumpAndSettle();

    final settingsPanel = find.byKey(
      const ValueKey('font-settings-dropdown-panel'),
    );
    expect(settingsPanel, findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsNothing);

    const literataTile = ValueKey('font-family-option-Literata');
    await tester.scrollUntilVisible(
      find.byKey(literataTile),
      220,
      scrollable: find.descendant(
        of: settingsPanel,
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(literataTile));
    await tester.pumpAndSettle();

    expect(rssConfigService.fontFamily, ReaderFonts.literata);
    expect(bookConfigService.fontFamily, ReaderFonts.defaultFamily);
  });

  testWidgets('wide RSS detail loads readable original page content', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final article = RssArticle(
      id: 'summary-only',
      feedUrl: 'https://example.com/rss.xml',
      feedTitle: 'Example',
      title: 'Summary only article',
      link: 'https://example.com/full-story',
      description: 'Short RSS summary.',
      content: 'Short RSS summary.',
      bodyBlocks: const [
        RssArticleTextBlock(
          type: RssArticleTextBlockType.paragraph,
          text: 'Short RSS summary.',
        ),
      ],
    );
    final service = _FakeRssFeedService(
      subscriptions: [
        RssFeedSubscription(
          url: 'https://example.com/rss.xml',
          title: 'Example',
        ),
      ],
      articles: [article],
    );
    final webContentService = _FakeWebContentService({
      'https://example.com/full-story': WebPageContent(
        url: Uri.parse('https://example.com/full-story'),
        title: 'Readable Full Story',
        paragraphs: const [
          'Full article body appears after loading the original page.',
          'A second readable paragraph confirms this is not only the RSS summary.',
        ],
      ),
    });
    final settings = await createTestSettingsService();

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          rssFeedServiceProvider.overrideWithValue(service),
          rssReadingConfigServiceProvider.overrideWithValue(
            _FakeReadingConfigService(),
          ),
          webContentServiceProvider.overrideWithValue(webContentService),
          settingsProvider.overrideWith((ref) => settings),
          wordLevelServiceProvider.overrideWithValue(fakeWordLevelService()),
          wordLookupNotifierProvider.overrideWith(_RssLookupNotifier.new),
          vocabularyNotifierProvider.overrideWith(_RssVocabularyNotifier.new),
        ],
        child: const MaterialApp(home: Scaffold(body: RssScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(webContentService.fetchedUrls, ['https://example.com/full-story']);
    expect(
      _richTextContaining(
        'Full article body appears after loading the original page.',
      ),
      findsOneWidget,
    );
    expect(
      _richTextContaining(
        'A second readable paragraph confirms this is not only the RSS summary.',
      ),
      findsOneWidget,
    );
  });
}

void _tapRichTextSpan(WidgetTester tester, String text) {
  for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
    final recognizer = _findTapRecognizer(richText.text, text);
    if (recognizer != null) {
      recognizer.onTap!();
      return;
    }
  }
  fail('Could not find tappable span "$text".');
}

TapGestureRecognizer? _findTapRecognizer(InlineSpan span, String text) {
  if (span is! TextSpan) return null;
  final recognizer = span.recognizer;
  if (span.text == text && recognizer is TapGestureRecognizer) {
    return recognizer;
  }
  final children = span.children;
  if (children == null) return null;
  for (final child in children) {
    final match = _findTapRecognizer(child, text);
    if (match != null) return match;
  }
  return null;
}

Finder _richTextContaining(String text) {
  return find.byWidgetPredicate((widget) {
    return widget is RichText && widget.text.toPlainText().contains(text);
  });
}

class _FakeRssFeedService implements RssFeedService {
  _FakeRssFeedService({
    required List<RssFeedSubscription> subscriptions,
    required List<RssArticle> articles,
  }) : _subscriptions = subscriptions,
       _articles = articles;

  final List<RssFeedSubscription> _subscriptions;
  final List<RssArticle> _articles;
  final List<String> readArticleIds = [];

  @override
  Future<void> init() async {}

  @override
  List<RssFeedSubscription> get subscriptions => _subscriptions;

  @override
  Future<RssFeedSubscription> addSubscription(String url) async {
    throw UnimplementedError();
  }

  @override
  Future<RssFeedSubscription?> updateSubscription({
    required String originalUrl,
    required String url,
    required String title,
    String? description,
    bool refreshMetadata = false,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> removeSubscription(String url) async {}

  @override
  Future<List<RssArticle>> fetchArticles(
    String feedUrl, {
    bool forceRefresh = false,
  }) async {
    return _articles;
  }

  @override
  Future<List<RssArticle>> fetchLatestArticles({
    bool forceRefresh = false,
  }) async {
    return _articles;
  }

  @override
  Future<void> markAsRead(String articleId) async {
    readArticleIds.add(articleId);
    for (final article in _articles) {
      if (article.id == articleId) {
        article.isRead = true;
        return;
      }
    }
  }

  @override
  Future<void> markAsUnread(String articleId) async {
    for (final article in _articles) {
      if (article.id == articleId) {
        article.isRead = false;
        return;
      }
    }
  }

  @override
  Future<void> setArticleFavorite(String articleId, bool isFavorite) async {
    for (final article in _articles) {
      if (article.id == articleId) {
        article.isFavorite = isFavorite;
        return;
      }
    }
  }

  @override
  Future<void> setArticleReadLater(String articleId, bool isReadLater) async {
    for (final article in _articles) {
      if (article.id == articleId) {
        article.isReadLater = isReadLater;
        return;
      }
    }
  }

  @override
  void clearArticleCache([String? feedUrl]) {}
}

class _FakeWebContentService extends WebContentService {
  _FakeWebContentService(this._pages);

  final Map<String, WebPageContent> _pages;
  final List<String> fetchedUrls = [];

  @override
  Future<WebPageContent> fetch(String inputUrl) async {
    fetchedUrls.add(inputUrl);
    final page = _pages[inputUrl];
    if (page == null) {
      throw StateError('No fake page for $inputUrl');
    }
    return page;
  }
}

class _FakeReadingConfigService extends ReadingConfigService {
  _FakeReadingConfigService() : super(repository: _MemoryReadingConfigRepo());
}

class _MemoryReadingConfigRepo implements ReadingConfigRepository {
  final Map<String, String> _values = {};

  @override
  Future<void> init() async {}

  @override
  String getString(String key, {required String defaultValue}) {
    return _values[key] ?? defaultValue;
  }

  @override
  Future<void> putString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> close() async {}
}

class _RssLookupNotifier extends WordLookupNotifier {
  @override
  WordLookupState build() => const WordLookupState();

  @override
  Future<void> lookupWord(
    String word, {
    String? canonicalForm,
    String? languageCode,
    String? reading,
    String? contextText,
    int? contextWordStart,
    int? contextWordEnd,
    bool trackReadingLookup = false,
    MemorySourceRef? memorySourceRef,
  }) async {
    state = WordLookupState(
      selectedWord: word,
      selectedWordTranslation: '河流',
      selectedWordContext: contextText,
      selectedWordContextStart: contextWordStart,
      selectedWordContextEnd: contextWordEnd,
    );
  }

  @override
  List<WordContextExample> importedExamplesFor(String word) => const [];

  @override
  Future<void> speakWord(String word) async {}

  @override
  Future<void> lookupRelatedWord(String word) async {}

  @override
  void goBackWordLookup() {}

  @override
  Future<void> retryWordLookup() async {}

  @override
  bool get canGenerateBookGlossaryExplanation => false;

  @override
  Future<void> generateBookGlossaryExplanation() async {}

  @override
  Future<bool> saveBookGlossaryExplanation({String? explanation}) async {
    return false;
  }
}

class _RssVocabularyNotifier extends VocabularyNotifier {
  @override
  VocabularyState build() => const VocabularyState();

  @override
  LanguageModule get activeLanguageModule => const EnglishLanguageModule();

  @override
  UserVocabularyService? get userVocabulary => null;

  @override
  UserWordStatus? getWordStatus(String word) => null;

  @override
  Future<void> markWordKnown(String word, {Offset? celebrationOrigin}) async {}

  @override
  Future<void> markWordLearning(String word) async {}

  @override
  Future<void> markWordUnknown(String word) async {}
}

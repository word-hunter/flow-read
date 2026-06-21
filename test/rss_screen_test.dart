import 'package:flow_ai/flow_ai.dart';
import 'package:flow_language/english/english.dart';
import 'package:flow_language/flow_language.dart';
import 'package:flow_read/models/reader_font.dart';
import 'package:flow_read/models/reading_memory.dart';
import 'package:flow_read/models/user_vocabulary.dart';
import 'package:flow_read/models/word_context_example.dart';
import 'package:flow_read/providers/reading/current_book_notifier.dart';
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
import 'package:flow_read/widgets/reader_shell/reader_right_assistant_panel.dart';
import 'package:flow_read/widgets/reader_shell/reader_workspace_controller.dart';
import 'package:flow_read/widgets/selected_text_action_toolbar.dart';
import 'package:flow_read/widgets/word_bottom_sheet.dart';
import 'package:flow_rss/flow_rss.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
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

    expect(find.byType(ReaderRightAssistantPanel), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reader-right-tab-dictionary')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('reader-right-tab-ai')), findsOneWidget);
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

  testWidgets('wide RSS AI tab opens assistant with article context', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final actionController = _RecordingAIActionController();
    final assistantController = AIAssistantController(
      registry: const AIAssistantActionRegistry(
        promptBuilder: PromptBuilder(),
      ),
      automationSettings: const AIAutomationSettings(),
      insightProfile: const ReadingInsightProfile(),
      actionController: actionController,
    );
    addTearDown(actionController.dispose);
    addTearDown(assistantController.dispose);

    final article = RssArticle(
      id: 'ai-story',
      feedUrl: 'https://example.com/rss.xml',
      feedTitle: 'Example',
      title: 'AI story',
      link: 'https://example.com/full-ai-story',
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
      'https://example.com/full-ai-story': WebPageContent(
        url: Uri.parse('https://example.com/full-ai-story'),
        title: 'Readable Full AI Story',
        paragraphs: const [
          'Full AI article body should be sent into the assistant context.',
          'The second paragraph proves that RSS did not use only the summary.',
        ],
      ),
    });
    final settings = await createTestSettingsService();
    await settings.setAIProvider('openai_compatible');
    await settings.setAIBaseUrl('https://llm.example.com/v1');
    await settings.setAIModel('reader-model');
    await settings.setApiKey('test-key');

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
          aiAssistantControllerProvider.overrideWithValue(assistantController),
        ],
        child: const MaterialApp(home: Scaffold(body: RssScreen())),
      ),
    );
    await tester.pumpAndSettle();

    _tapRichTextSpan(tester, 'Full');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    final rightPanel = tester.widget<ReaderRightAssistantPanel>(
      find.byType(ReaderRightAssistantPanel),
    );
    rightPanel.onTabSelected?.call(ReaderRightPanelTab.ai);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.text('文章助手'), findsOneWidget);
    expect(find.text('AI story'), findsWidgets);

    await tester.tap(find.widgetWithText(ActionChip, '总结'));
    await tester.pump();

    expect(actionController.lastAction, AIAssistantActionType.summary);
    expect(
      actionController.lastPrompt?.userPrompt,
      contains(
        'Full AI article body should be sent into the assistant context.',
      ),
    );
    expect(
      actionController.lastPrompt?.userPrompt,
      contains(
        'The second paragraph proves that RSS did not use only the summary.',
      ),
    );
    expect(
      actionController.lastPrompt?.userPrompt,
      isNot(contains('Short RSS summary.')),
    );
  });

  testWidgets('wide RSS selected text action opens AI assistant panel', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final actionController = _RecordingAIActionController();
    final assistantController = AIAssistantController(
      registry: const AIAssistantActionRegistry(
        promptBuilder: PromptBuilder(),
      ),
      automationSettings: const AIAutomationSettings(),
      insightProfile: const ReadingInsightProfile(),
      actionController: actionController,
    );
    addTearDown(actionController.dispose);
    addTearDown(assistantController.dispose);

    final service = _FakeRssFeedService(
      subscriptions: [
        RssFeedSubscription(
          url: 'https://example.com/rss.xml',
          title: 'Example',
        ),
      ],
      articles: [
        RssArticle(
          id: 'selected-ai',
          feedUrl: 'https://example.com/rss.xml',
          feedTitle: 'Example',
          title: 'Selected AI article',
          content:
              'The selected sentence should be explained by AI inside RSS.',
          bodyBlocks: const [
            RssArticleTextBlock(
              type: RssArticleTextBlockType.paragraph,
              text:
                  'The selected sentence should be explained by AI inside RSS.',
            ),
          ],
        ),
      ],
    );
    final settings = await createTestSettingsService();
    await settings.setAIProvider('openai_compatible');
    await settings.setAIBaseUrl('https://llm.example.com/v1');
    await settings.setAIModel('reader-model');
    await settings.setApiKey('test-key');

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
          aiAssistantControllerProvider.overrideWithValue(assistantController),
        ],
        child: const MaterialApp(home: Scaffold(body: RssScreen())),
      ),
    );
    await tester.pumpAndSettle();

    final selectedRegion = tester.widget<SelectedTextActionRegion>(
      find.byType(SelectedTextActionRegion),
    );
    var closedToolbar = false;
    final actions = selectedRegion.actionsBuilder(
      tester.element(find.byType(SelectedTextActionRegion)),
      'selected sentence',
      () => closedToolbar = true,
    );
    expect(actions.map((action) => action.tooltip), contains('AI 解析'));
    expect(actions.map((action) => action.tooltip), isNot(contains('解析选中内容')));

    final aiAction = actions.singleWhere(
      (action) => action.tooltip == 'AI 解析',
    );
    expect(aiAction.enabled, isTrue);
    await aiAction.onPressed?.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(closedToolbar, isTrue);
    expect(find.byType(ReaderRightAssistantPanel), findsOneWidget);
    expect(find.text('单句分析'), findsOneWidget);
    expect(actionController.lastAction, AIAssistantActionType.explain);
    expect(
      actionController.lastPrompt?.userPrompt,
      contains('selected sentence'),
    );
    expect(
      actionController.lastPrompt?.userPrompt,
      contains(
        'The selected sentence should be explained by AI inside RSS.',
      ),
    );
  });

  testWidgets('wide RSS clears selected text when switching articles', (
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
          id: 'first',
          feedUrl: 'https://example.com/rss.xml',
          feedTitle: 'Example',
          title: 'First article',
          content: 'The first article has selectable text.',
          bodyBlocks: const [
            RssArticleTextBlock(
              type: RssArticleTextBlockType.paragraph,
              text: 'The first article has selectable text.',
            ),
          ],
        ),
        RssArticle(
          id: 'second',
          feedUrl: 'https://example.com/rss.xml',
          feedTitle: 'Example',
          title: 'Second article',
          content: 'The second article replaces the first one.',
          bodyBlocks: const [
            RssArticleTextBlock(
              type: RssArticleTextBlockType.paragraph,
              text: 'The second article replaces the first one.',
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
          vocabularyNotifierProvider.overrideWith(_RssVocabularyNotifier.new),
        ],
        child: const MaterialApp(home: Scaffold(body: RssScreen())),
      ),
    );
    await tester.pumpAndSettle();

    final selectedRegion = tester.state<SelectedTextActionRegionState>(
      find.byType(SelectedTextActionRegion),
    );
    selectedRegion.onSelectionChanged(
      const SelectedContent(plainText: 'first article'),
    );
    expect(selectedRegion.selectedText, 'first article');

    await tester.tap(find.byTooltip('下一篇'));
    await tester.pumpAndSettle();

    final nextSelectedRegion = tester.state<SelectedTextActionRegionState>(
      find.byType(SelectedTextActionRegion),
    );
    expect(nextSelectedRegion.selectedText, isEmpty);
  });

  testWidgets('wide RSS clears selected text when leaving RSS tab', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final currentBook = _RssCurrentBookNotifier();
    final service = _FakeRssFeedService(
      subscriptions: [
        RssFeedSubscription(
          url: 'https://example.com/rss.xml',
          title: 'Example',
        ),
      ],
      articles: [
        RssArticle(
          id: 'current',
          feedUrl: 'https://example.com/rss.xml',
          feedTitle: 'Example',
          title: 'Current article',
          content: 'The RSS tab has selected text.',
          bodyBlocks: const [
            RssArticleTextBlock(
              type: RssArticleTextBlockType.paragraph,
              text: 'The RSS tab has selected text.',
            ),
          ],
        ),
      ],
    );
    final settings = await createTestSettingsService();

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          currentBookNotifierProvider.overrideWith(() => currentBook),
          rssFeedServiceProvider.overrideWithValue(service),
          rssReadingConfigServiceProvider.overrideWithValue(
            _FakeReadingConfigService(),
          ),
          settingsProvider.overrideWith((ref) => settings),
          wordLevelServiceProvider.overrideWithValue(fakeWordLevelService()),
          vocabularyNotifierProvider.overrideWith(_RssVocabularyNotifier.new),
        ],
        child: const MaterialApp(home: Scaffold(body: RssScreen())),
      ),
    );
    await tester.pumpAndSettle();

    final selectedRegion = tester.state<SelectedTextActionRegionState>(
      find.byType(SelectedTextActionRegion),
    );
    selectedRegion.onSelectionChanged(
      const SelectedContent(plainText: 'RSS tab'),
    );
    expect(selectedRegion.selectedText, 'RSS tab');

    currentBook.switchTab(0);
    await tester.pumpAndSettle();

    final resetSelectedRegion = tester.state<SelectedTextActionRegionState>(
      find.byType(SelectedTextActionRegion),
    );
    expect(resetSelectedRegion.selectedText, isEmpty);
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
  Future<List<RssArticle>> cachedArticlesForFeed(String feedUrl) async {
    return _articles.where((article) => article.feedUrl == feedUrl).toList();
  }

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

class _RssCurrentBookNotifier extends CurrentBookNotifier {
  @override
  CurrentBookState build() => const CurrentBookState(currentTab: 1);
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

class _RecordingAIActionController extends AIActionController {
  _RecordingAIActionController()
    : super(
        aiService: AIService(
          LLMClient(
            () => const AIProviderConfig(
              definition: AIProviders.openAICompatible,
              apiKey: 'test-key',
              baseUrl: 'https://llm.example.com/v1',
              model: 'reader-model',
            ),
          ),
        ),
      );

  AIAssistantActionType? lastAction;
  PromptBuildResult? lastPrompt;

  @override
  Future<void> enqueue(
    PromptBuildResult prompt,
    AIAssistantActionType action, {
    bool bypassCache = false,
  }) async {
    lastAction = action;
    lastPrompt = prompt;
  }
}

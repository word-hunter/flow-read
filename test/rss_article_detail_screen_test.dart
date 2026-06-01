import 'package:flow_read/widgets/word_bottom_sheet.dart';
import 'package:flutter/gestures.dart';
import 'package:flow_read/models/rss_models.dart';
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/providers/rss_provider.dart';
import 'package:flow_read/screens/rss_article_detail_screen.dart';
import 'package:flow_read/screens/rss_screen.dart';
import 'package:flow_read/services/rss_service.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('RSS screen opens a dedicated article detail reading view', (
    tester,
  ) async {
    final articles = [
      RssArticle(
        feedUrl: 'https://example.com/rss.xml',
        feedTitle: 'Example',
        title: 'First article',
        content: 'First body for focused RSS reading.',
        id: 'first',
      ),
    ];
    final provider = await _createProvider(articles);

    await tester.pumpWidget(
      _buildApp(provider, const Scaffold(body: RssScreen())),
    );

    await tester.tap(find.text('First article'));
    await tester.pumpAndSettle();

    expect(find.text('RSS 阅读'), findsOneWidget);
    expect(
      _richTextContaining('First body for focused RSS reading.'),
      findsOneWidget,
    );
    expect(articles.first.isRead, isTrue);
  });

  testWidgets('article detail supports navigation and article state actions', (
    tester,
  ) async {
    final articles = [
      RssArticle(
        feedUrl: 'https://example.com/rss.xml',
        feedTitle: 'Example',
        title: 'First article',
        content: 'First body.',
        id: 'first',
      ),
      RssArticle(
        feedUrl: 'https://example.com/rss.xml',
        feedTitle: 'Example',
        title: 'Second article',
        content: 'Second body.',
        id: 'second',
      ),
    ];
    final provider = await _createProvider(articles);

    await tester.pumpWidget(
      _buildApp(
        provider,
        RssArticleDetailScreen(
          articles: provider.visibleArticles,
          initialArticleId: 'first',
          showFeedName: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(articles.first.isRead, isTrue);
    expect(_richTextContaining('First body.'), findsOneWidget);

    await tester.tap(find.byTooltip('下一篇'));
    await tester.pumpAndSettle();

    expect(_richTextContaining('Second body.'), findsOneWidget);
    expect(articles.last.isRead, isTrue);

    await tester.tap(find.byTooltip('收藏'));
    await tester.pumpAndSettle();
    expect(articles.last.isFavorite, isTrue);
    expect(find.byTooltip('取消收藏'), findsOneWidget);

    await tester.tap(find.byTooltip('稍后读'));
    await tester.pumpAndSettle();
    expect(articles.last.isReadLater, isTrue);
    expect(find.byTooltip('移出稍后读'), findsOneWidget);

    await tester.tap(find.byTooltip('标记未读'));
    await tester.pumpAndSettle();
    expect(articles.last.isRead, isFalse);
    expect(find.byTooltip('标记已读'), findsOneWidget);

    await tester.tap(find.byTooltip('上一篇'));
    await tester.pumpAndSettle();
    expect(_richTextContaining('First body.'), findsOneWidget);
  });

  testWidgets('article detail inline word opens the shared dictionary sheet', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final articles = [
      RssArticle(
        feedUrl: 'https://example.com/rss.xml',
        feedTitle: 'Example',
        title: 'Vocabulary article',
        content: 'Curious readers improve fluency through practice.',
        id: 'vocab',
      ),
    ];
    final rssProvider = await _createProvider(articles);
    final readingProvider = ReadingProvider();
    addTearDown(readingProvider.dispose);

    await tester.pumpWidget(
      _buildApp(
        rssProvider,
        RssArticleDetailScreen(
          articles: rssProvider.visibleArticles,
          initialArticleId: 'vocab',
          showFeedName: false,
        ),
        readingProvider: readingProvider,
      ),
    );
    await tester.pumpAndSettle();

    final fluencySpan = _findTextSpan(tester, 'fluency');
    expect(fluencySpan.recognizer, isA<TapGestureRecognizer>());

    (fluencySpan.recognizer! as TapGestureRecognizer).onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(WordBottomSheet), findsOneWidget);
    expect(readingProvider.selectedWord?.toLowerCase(), 'fluency');
    expect(readingProvider.selectedWordContext, contains('fluency'));
  });
}

Future<RssProvider> _createProvider(List<RssArticle> articles) async {
  final provider = RssProvider(
    service: _FakeRssFeedService(
      subscriptions: [
        RssFeedSubscription(
          url: 'https://example.com/rss.xml',
          title: 'Example',
        ),
      ],
      articles: articles,
    ),
  );
  await provider.init();
  addTearDown(provider.dispose);
  return provider;
}

Widget _buildApp(
  RssProvider provider,
  Widget child, {
  ReadingProvider? readingProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<RssProvider>.value(value: provider),
      readingProvider == null
          ? ChangeNotifierProvider(create: (_) => ReadingProvider())
          : ChangeNotifierProvider<ReadingProvider>.value(
              value: readingProvider,
            ),
      ChangeNotifierProvider(create: (_) => SettingsService()),
    ],
    child: MaterialApp(home: child),
  );
}

Finder _richTextContaining(String text) {
  return find.byWidgetPredicate((widget) {
    return widget is RichText && widget.text.toPlainText().contains(text);
  });
}

TextSpan _findTextSpan(WidgetTester tester, String text) {
  for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
    final span = _findSpan(richText.text, text);
    if (span != null) return span;
  }
  fail('TextSpan containing "$text" was not found.');
}

TextSpan? _findSpan(InlineSpan span, String text) {
  if (span is! TextSpan) return null;
  if (span.text?.contains(text) == true) return span;
  for (final child in span.children ?? const <InlineSpan>[]) {
    final found = _findSpan(child, text);
    if (found != null) return found;
  }
  return null;
}

class _FakeRssFeedService implements RssFeedService {
  _FakeRssFeedService({
    required List<RssFeedSubscription> subscriptions,
    required List<RssArticle> articles,
  }) : _subscriptions = subscriptions,
       _articles = articles;

  final List<RssFeedSubscription> _subscriptions;
  final List<RssArticle> _articles;

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
    return _articles
        .where((article) => article.feedUrl == feedUrl)
        .toList(growable: false);
  }

  @override
  Future<List<RssArticle>> fetchLatestArticles({
    bool forceRefresh = false,
  }) async {
    return _articles;
  }

  @override
  Future<void> markAsRead(String articleId) async {
    _updateArticle(articleId, (article) => article.isRead = true);
  }

  @override
  Future<void> markAsUnread(String articleId) async {
    _updateArticle(articleId, (article) => article.isRead = false);
  }

  @override
  Future<void> setArticleFavorite(String articleId, bool isFavorite) async {
    _updateArticle(articleId, (article) => article.isFavorite = isFavorite);
  }

  @override
  Future<void> setArticleReadLater(String articleId, bool isReadLater) async {
    _updateArticle(articleId, (article) => article.isReadLater = isReadLater);
  }

  @override
  void clearArticleCache([String? feedUrl]) {}

  void _updateArticle(String articleId, void Function(RssArticle) update) {
    for (final article in _articles) {
      if (article.id == articleId) update(article);
    }
  }
}

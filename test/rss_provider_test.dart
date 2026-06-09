import 'package:flow_rss/flow_rss.dart';
import 'package:flow_read/providers/rss_provider.dart';
import 'package:flow_rss/flow_rss.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('provider surfaces fetch failures from an injected service', () async {
    final provider = RssProvider(
      service: _FakeRssFeedService(
        subscriptions: [
          RssFeedSubscription(
            url: 'https://example.com/rss.xml',
            title: 'Example',
          ),
        ],
        latestError: StateError('network down'),
      ),
    );
    addTearDown(provider.dispose);

    await provider.init();

    expect(provider.isLoading, isFalse);
    expect(provider.subscriptionStatus, RssLoadStatus.loaded);
    expect(provider.articlesStatus, RssLoadStatus.error);
    expect(provider.articlesError?.type, RssErrorType.network);
    expect(provider.articlesError?.detail, contains('network down'));
    expect(provider.articles, isEmpty);
  });

  test('provider tracks empty subscription and article states', () async {
    final provider = RssProvider(service: _FakeRssFeedService());
    addTearDown(provider.dispose);

    await provider.init();

    expect(provider.subscriptionStatus, RssLoadStatus.empty);
    expect(provider.articlesStatus, RssLoadStatus.empty);
    expect(provider.subscriptions, isEmpty);
    expect(provider.articles, isEmpty);
  });

  test('retry refetches articles after an article error', () async {
    final service = _FakeRssFeedService(
      subscriptions: [
        RssFeedSubscription(
          url: 'https://example.com/rss.xml',
          title: 'Example',
        ),
      ],
      articles: [
        RssArticle(
          feedUrl: 'https://example.com/rss.xml',
          title: 'Recovered article',
          id: 'recovered',
        ),
      ],
      latestError: StateError('network down'),
    );
    final provider = RssProvider(service: service);
    addTearDown(provider.dispose);

    await provider.init();
    expect(provider.articlesStatus, RssLoadStatus.error);

    service.latestError = null;
    await provider.retry();

    expect(provider.articlesStatus, RssLoadStatus.loaded);
    expect(provider.articles.map((article) => article.id), ['recovered']);
    expect(provider.articlesError, isNull);
  });

  test('provider filters searched articles by list state', () async {
    final service = _FakeRssFeedService(
      subscriptions: [
        RssFeedSubscription(
          url: 'https://example.com/rss.xml',
          title: 'Example',
        ),
      ],
      articles: [
        RssArticle(
          feedUrl: 'https://example.com/rss.xml',
          title: 'Unread article',
          id: 'unread',
        ),
        RssArticle(
          feedUrl: 'https://example.com/rss.xml',
          title: 'Favorite article',
          isRead: true,
          isFavorite: true,
          id: 'favorite',
        ),
        RssArticle(
          feedUrl: 'https://example.com/rss.xml',
          title: 'Read later article',
          isRead: true,
          isReadLater: true,
          id: 'later',
        ),
      ],
    );
    final provider = RssProvider(service: service);
    addTearDown(provider.dispose);

    await provider.init();

    expect(provider.visibleArticles.map((article) => article.id), [
      'unread',
      'favorite',
      'later',
    ]);

    provider.updateArticleFilter(RssArticleFilter.favorite);
    expect(provider.visibleArticles.map((article) => article.id), ['favorite']);

    provider.updateArticleFilter(RssArticleFilter.readLater);
    expect(provider.visibleArticles.map((article) => article.id), ['later']);

    provider.updateArticleFilter(RssArticleFilter.unread);
    expect(provider.visibleArticles.map((article) => article.id), ['unread']);

    provider.updateArticleQuery('favorite');
    expect(provider.visibleArticles, isEmpty);
    expect(provider.articleCountForFilter(RssArticleFilter.favorite), 1);
  });
}

class _FakeRssFeedService implements RssFeedService {
  _FakeRssFeedService({
    List<RssFeedSubscription>? subscriptions,
    List<RssArticle>? articles,
    this.latestError,
  }) : _subscriptions = subscriptions ?? [],
       _articles = articles ?? [];

  final List<RssFeedSubscription> _subscriptions;
  final List<RssArticle> _articles;
  Object? latestError;

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
    final error = latestError;
    if (error != null) throw error;
    return _articles;
  }

  @override
  Future<void> markAsRead(String articleId) async {}

  @override
  Future<void> markAsUnread(String articleId) async {}

  @override
  Future<void> setArticleFavorite(String articleId, bool isFavorite) async {
    for (final article in _articles) {
      if (article.id == articleId) article.isFavorite = isFavorite;
    }
  }

  @override
  Future<void> setArticleReadLater(String articleId, bool isReadLater) async {
    for (final article in _articles) {
      if (article.id == articleId) article.isReadLater = isReadLater;
    }
  }

  @override
  void clearArticleCache([String? feedUrl]) {}
}

import 'package:flow_rss/flow_rss.dart';
import 'package:flow_read/providers/rss_riverpod_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<RssNotifier> _createNotifier(
  ProviderContainer container, {
  List<RssFeedSubscription>? subscriptions,
  List<RssArticle>? articles,
  Object? latestError,
}) async {
  final notifier = container.read(rssNotifierProvider.notifier);
  await notifier.init();
  return notifier;
}

ProviderContainer _createContainer(
  List<RssFeedSubscription> subscriptions,
  List<RssArticle> articles,
  Object? latestError,
) {
  return ProviderContainer(
    overrides: [
      rssFeedServiceProvider.overrideWithValue(
        _FakeRssFeedService(
          subscriptions: subscriptions,
          articles: articles,
          latestError: latestError,
        ),
      ),
    ],
  );
}

void main() {
  test('provider surfaces fetch failures from an injected service', () async {
    final container = _createContainer(
      [
        RssFeedSubscription(
          url: 'https://example.com/rss.xml',
          title: 'Example',
        ),
      ],
      [],
      StateError('network down'),
    );
    addTearDown(container.dispose);

    final notifier = container.read(rssNotifierProvider.notifier);
    await notifier.init();
    final state = container.read(rssNotifierProvider);

    expect(state.isLoading, isFalse);
    expect(state.subscriptionStatus, RssLoadStatus.loaded);
    expect(state.articlesStatus, RssLoadStatus.error);
    expect(state.articlesError?.type, RssErrorType.network);
    expect(state.articlesError?.detail, contains('network down'));
    expect(state.articles, isEmpty);
  });

  test('provider tracks empty subscription and article states', () async {
    final container = _createContainer([], [], null);
    addTearDown(container.dispose);

    final notifier = container.read(rssNotifierProvider.notifier);
    await notifier.init();
    final state = container.read(rssNotifierProvider);

    expect(state.subscriptionStatus, RssLoadStatus.empty);
    expect(state.articlesStatus, RssLoadStatus.empty);
    expect(state.subscriptions, isEmpty);
    expect(state.articles, isEmpty);
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
    final container = ProviderContainer(
      overrides: [
        rssFeedServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(rssNotifierProvider.notifier);
    await notifier.init();
    expect(container.read(rssNotifierProvider).articlesStatus,
        RssLoadStatus.error);

    service.latestError = null;
    await notifier.retry();

    final state = container.read(rssNotifierProvider);
    expect(state.articlesStatus, RssLoadStatus.loaded);
    expect(state.articles.map((article) => article.id), ['recovered']);
    expect(state.articlesError, isNull);
  });

  test('provider filters searched articles by list state', () async {
    final container = _createContainer(
      [
        RssFeedSubscription(
          url: 'https://example.com/rss.xml',
          title: 'Example',
        ),
      ],
      [
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
      null,
    );
    addTearDown(container.dispose);

    final notifier = container.read(rssNotifierProvider.notifier);
    await notifier.init();

    expect(
      container.read(rssNotifierProvider).visibleArticles
          .map((article) => article.id),
      ['unread', 'favorite', 'later'],
    );

    notifier.updateArticleFilter(RssArticleFilter.favorite);
    expect(
      container.read(rssNotifierProvider).visibleArticles
          .map((article) => article.id),
      ['favorite'],
    );

    notifier.updateArticleFilter(RssArticleFilter.readLater);
    expect(
      container.read(rssNotifierProvider).visibleArticles
          .map((article) => article.id),
      ['later'],
    );

    notifier.updateArticleFilter(RssArticleFilter.unread);
    expect(
      container.read(rssNotifierProvider).visibleArticles
          .map((article) => article.id),
      ['unread'],
    );

    notifier.updateArticleQuery('favorite');
    expect(container.read(rssNotifierProvider).visibleArticles, isEmpty);
    expect(
      container.read(rssNotifierProvider).articleCountForFilter(
            RssArticleFilter.favorite,
          ),
      1,
    );
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

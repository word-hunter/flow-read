import 'package:flow_rss/flow_rss.dart';
import 'package:flow_read/models/reading_memory.dart';
import 'package:flow_read/providers/reading/services_provider.dart';
import 'package:flow_read/providers/rss_riverpod_provider.dart';
import 'package:flow_read/services/reading_memory/reading_memory_ids.dart';
import 'package:flow_read/services/reading_memory/reading_memory_service.dart';
import 'package:flow_read/services/reading_memory/source_scope_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_memory_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(
      container.read(rssNotifierProvider).articlesStatus,
      RssLoadStatus.error,
    );

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
      container
          .read(rssNotifierProvider)
          .visibleArticles
          .map((article) => article.id),
      ['unread', 'favorite', 'later'],
    );

    notifier.updateArticleFilter(RssArticleFilter.favorite);
    expect(
      container
          .read(rssNotifierProvider)
          .visibleArticles
          .map((article) => article.id),
      ['favorite'],
    );

    notifier.updateArticleFilter(RssArticleFilter.readLater);
    expect(
      container
          .read(rssNotifierProvider)
          .visibleArticles
          .map((article) => article.id),
      ['later'],
    );

    notifier.updateArticleFilter(RssArticleFilter.unread);
    expect(
      container
          .read(rssNotifierProvider)
          .visibleArticles
          .map((article) => article.id),
      ['unread'],
    );

    notifier.updateArticleQuery('favorite');
    expect(container.read(rssNotifierProvider).visibleArticles, isEmpty);
    expect(
      container
          .read(rssNotifierProvider)
          .articleCountForFilter(
            RssArticleFilter.favorite,
          ),
      1,
    );
  });

  test('removeFeed uses source scope default retention policy', () async {
    final db = await AppDatabase.createInMemory();
    addTearDown(db.close);

    final memoryRepository = DriftReadingMemoryRepository(
      db.readingMemoryDao,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 21, 9),
    );
    final sourceScope = SourceScopeService(
      repository: memoryRepository,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 21, 10),
      defaultEvidenceRetentionPolicy: EvidenceRetentionPolicy.keepMetadataOnly,
    );
    final memory = ReadingMemoryService(
      repository: memoryRepository,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 21, 9),
    );

    const feedUrl = 'https://example.com/rss.xml';
    final article = RssArticle(
      id: 'rss-article-1',
      feedUrl: feedUrl,
      feedTitle: 'Flow News',
      title: 'Article One',
    );
    final source = await sourceScope.upsertRssSource(
      articleId: article.id,
      title: article.title,
    );
    await sourceScope.upsertSourceScopeCache(
      sourceId: source.id,
      cacheType: 'article_reading_context',
      payload: '{"outline":[]}',
    );
    await memory.recordLookup(
      targetText: 'resilient',
      canonical: 'resilient',
      sourceRef: MemorySourceRef(
        sourceId: source.id,
        sourceKind: SourceKind.rss,
        sourceTitleSnapshot: article.title,
      ),
      sentence: 'A resilient habit lasts.',
    );

    final service = _FakeRssFeedService(
      subscriptions: [
        RssFeedSubscription(url: feedUrl, title: 'Flow News'),
      ],
      articles: [article],
      cachedArticlesByFeed: {
        feedUrl: [article],
      },
    );
    final container = ProviderContainer(
      overrides: [
        rssFeedServiceProvider.overrideWithValue(service),
        sourceScopeServiceProvider.overrideWithValue(sourceScope),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(rssNotifierProvider.notifier);
    await notifier.init();
    await notifier.removeFeed(feedUrl);

    expect(service.removedSubscriptionUrls, [feedUrl]);
    expect(service.clearedArticleCacheUrls, [feedUrl]);
    expect(container.read(rssNotifierProvider).subscriptions, isEmpty);
    expect(container.read(rssNotifierProvider).articles, isEmpty);

    final sourceId = ReadingMemoryIds.source(SourceKind.rss, article.id);
    final deletedSource = await memoryRepository.sourceRecord(sourceId);
    expect(deletedSource?.availability, SourceAvailability.deleted);
    expect(deletedSource?.deletedAt, DateTime.utc(2026, 6, 21, 10));
    expect(await memoryRepository.sourceScopeCacheForSource(sourceId), isEmpty);

    final evidences = await memoryRepository.evidencesForSource(sourceId);
    expect(evidences.single.shortExcerpt, isEmpty);
    expect(evidences.single.sourceAvailability, SourceAvailability.deleted);
    expect(
      evidences.single.retentionPolicy,
      EvidenceRetentionPolicy.keepMetadataOnly,
    );
    expect(
      await memoryRepository.eventCountForCanonical(
        languageCode: 'en',
        canonicalKey: 'resilient',
        type: MemoryEventType.lookup,
      ),
      1,
    );
  });
}

class _FakeRssFeedService implements RssFeedService {
  _FakeRssFeedService({
    List<RssFeedSubscription>? subscriptions,
    List<RssArticle>? articles,
    Map<String, List<RssArticle>>? cachedArticlesByFeed,
    this.latestError,
  }) : _subscriptions = subscriptions ?? [],
       _articles = articles ?? [],
       _cachedArticlesByFeed = cachedArticlesByFeed ?? const {};

  final List<RssFeedSubscription> _subscriptions;
  final List<RssArticle> _articles;
  final Map<String, List<RssArticle>> _cachedArticlesByFeed;
  final List<String> removedSubscriptionUrls = [];
  final List<String> clearedArticleCacheUrls = [];
  int clearAllArticleCacheCount = 0;
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
  Future<List<RssArticle>> cachedArticlesForFeed(String feedUrl) async {
    return _cachedArticlesByFeed[feedUrl] ?? const [];
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
  Future<void> removeSubscription(String url) async {
    removedSubscriptionUrls.add(url);
    _subscriptions.removeWhere((subscription) => subscription.url == url);
    _articles.removeWhere((article) => article.feedUrl == url);
  }

  @override
  void clearArticleCache([String? feedUrl]) {
    if (feedUrl == null) {
      clearAllArticleCacheCount += 1;
    } else {
      clearedArticleCacheUrls.add(feedUrl);
    }
  }
}

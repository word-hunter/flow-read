import 'dart:convert';

import 'package:flow_rss/flow_rss.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('parses RSS feed metadata and articles with injected time', () async {
    final now = DateTime.utc(2026, 5, 20, 10, 30);
    final repository = _MemoryRssRepository();
    final service = RssService(
      repository: repository,
      clock: () => now,
      httpGet: _respondWith(_rssFeed),
    );
    await service.init();

    final subscription = await service.addSubscription(
      'https://example.com/rss.xml',
    );
    final articles = await service.fetchArticles(subscription.url);

    expect(subscription.title, 'Flow News');
    expect(subscription.description, 'Reading updates');
    expect(subscription.imageUrl, 'https://example.com/logo.png');
    expect(subscription.lastFetchedAt, now);
    expect(repository.lastFetchedUpdate, now);
    expect(articles.map((article) => article.title), [
      'First Article',
      'Second Article',
    ]);
    expect(articles.first.feedTitle, 'Flow News');
    expect(articles.first.link, 'https://example.com/first');
    expect(articles.first.description, 'Summary one');
    expect(articles.first.content, 'Full content');
    expect(articles.first.images, hasLength(3));
    expect(articles.first.images[0].url, 'https://example.com/images/full.png');
    expect(articles.first.images[0].alt, 'Full image');
    expect(articles.first.images[0].width, 640);
    expect(articles.first.images[0].height, 320);
    expect(
      articles.first.images[1].url,
      'https://cdn.example.com/media/thumb.jpg',
    );
    expect(
      articles.first.images[2].url,
      'https://example.com/downloads/enclosure.webp',
    );
    expect(articles.first.author, 'Ada');
    expect(articles.first.pubDate?.toUtc(), DateTime.utc(2026, 5, 20, 7));
    expect(
      repository.cachedArticles[subscription.url]?.map((article) => article.id),
      articles.map((article) => article.id),
    );
  });

  test('parses Atom metadata and alternate article links', () async {
    final repository = _MemoryRssRepository();
    final service = RssService(
      repository: repository,
      clock: () => DateTime.utc(2026, 5, 20, 9),
      httpGet: _respondWith(_atomFeed),
    );
    await service.init();

    final subscription = await service.addSubscription('example.com/atom.xml');
    final articles = await service.fetchArticles(subscription.url);

    expect(subscription.url, 'https://example.com/atom.xml');
    expect(subscription.title, 'Atom Flow');
    expect(subscription.description, 'Atom reading updates');
    expect(subscription.imageUrl, 'https://example.com/atom-logo.png');
    expect(articles, hasLength(1));
    expect(articles.single.title, 'Atom Entry');
    expect(articles.single.link, 'https://example.com/atom-entry');
    expect(articles.single.description, 'Atom summary');
    expect(articles.single.content, 'Atom full content');
    expect(articles.single.images, hasLength(2));
    expect(
      articles.single.images[0].url,
      'https://example.com/images/atom.png',
    );
    expect(articles.single.images[0].alt, 'Atom image');
    expect(
      articles.single.images[1].url,
      'https://cdn.example.com/atom-thumb.png',
    );
    expect(articles.single.author, 'Grace');
    expect(articles.single.pubDate?.toUtc(), DateTime.utc(2026, 5, 20, 7, 10));
  });

  test(
    'returns cached articles on HTTP failure without updating fetched time',
    () async {
      final repository = _MemoryRssRepository()
        ..subscriptions.add(
          RssFeedSubscription(
            url: 'https://example.com/rss.xml',
            title: 'Flow News',
          ),
        );
      var requestCount = 0;
      final service = RssService(
        repository: repository,
        clock: () => DateTime.utc(2026, 5, 20, 8, requestCount),
        httpGet: (uri, {headers}) async {
          requestCount += 1;
          if (requestCount == 1) return _response(_rssFeed);
          return http.Response('Server error', 500);
        },
      );
      await service.init();

      final initial = await service.fetchArticles(
        'https://example.com/rss.xml',
      );
      final fallback = await service.fetchArticles(
        'https://example.com/rss.xml',
        forceRefresh: true,
      );

      expect(initial, hasLength(2));
      expect(fallback.map((article) => article.title), [
        'First Article',
        'Second Article',
      ]);
      await expectLater(
        service.fetchArticles(
          'https://example.com/uncached.xml',
          forceRefresh: true,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('HTTP 500'),
          ),
        ),
      );
      expect(repository.updateLastFetchedCalls, 1);
    },
  );

  test('surfaces HTTP failures while adding a subscription', () async {
    final service = RssService(
      repository: _MemoryRssRepository(),
      httpGet: (uri, {headers}) async => http.Response('Not found', 404),
    );
    await service.init();

    await expectLater(
      service.addSubscription('https://example.com/rss.xml'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('HTTP 404'),
        ),
      ),
    );
  });

  test(
    'persists favorite and read-later article state across refreshes',
    () async {
      final repository = _MemoryRssRepository()
        ..subscriptions.add(
          RssFeedSubscription(
            url: 'https://example.com/rss.xml',
            title: 'Flow News',
          ),
        );
      final service = RssService(
        repository: repository,
        httpGet: _respondWith(_rssFeed),
      );
      await service.init();

      final firstFetch = await service.fetchArticles(
        'https://example.com/rss.xml',
      );
      final articleId = firstFetch.first.id;

      await service.setArticleFavorite(articleId, true);
      await service.setArticleReadLater(articleId, true);
      service.clearArticleCache('https://example.com/rss.xml');
      final secondFetch = await service.fetchArticles(
        'https://example.com/rss.xml',
      );

      expect(repository.favoriteArticleIds, {articleId});
      expect(repository.readLaterArticleIds, {articleId});
      expect(secondFetch.first.isFavorite, isTrue);
      expect(secondFetch.first.isReadLater, isTrue);

      await service.setArticleFavorite(articleId, false);
      await service.setArticleReadLater(articleId, false);

      expect(repository.favoriteArticleIds, isEmpty);
      expect(repository.readLaterArticleIds, isEmpty);
    },
  );
}

RssHttpGet _respondWith(String body) {
  return (uri, {headers}) async => _response(body);
}

http.Response _response(String body) {
  return http.Response.bytes(
    utf8.encode(body),
    200,
    headers: {'content-type': 'application/xml; charset=utf-8'},
  );
}

class _MemoryRssRepository implements RssRepository {
  @override
  final List<RssFeedSubscription> subscriptions = [];
  Set<String> _readArticleIds = {};
  Set<String> _favoriteArticleIds = {};
  Set<String> _readLaterArticleIds = {};
  final Map<String, List<RssArticle>> cachedArticles = {};
  int updateLastFetchedCalls = 0;
  DateTime? lastFetchedUpdate;

  @override
  Future<void> init() async {}

  @override
  RssFeedSubscription? findSubscriptionByUrl(String url) {
    return subscriptions
        .where((subscription) => subscription.url == url)
        .firstOrNull;
  }

  @override
  Future<void> addSubscription(RssFeedSubscription subscription) async {
    subscriptions.add(subscription);
  }

  @override
  Future<RssFeedSubscription?> replaceSubscription(
    String originalUrl,
    RssFeedSubscription subscription,
  ) async {
    final index = subscriptions.indexWhere((item) => item.url == originalUrl);
    if (index < 0) return null;
    subscriptions[index] = subscription;
    return subscription;
  }

  @override
  Future<bool> deleteSubscriptionByUrl(String url) async {
    final before = subscriptions.length;
    subscriptions.removeWhere((subscription) => subscription.url == url);
    return subscriptions.length != before;
  }

  @override
  Future<void> cacheArticles(
    String feedUrl,
    Iterable<RssArticle> articles,
  ) async {
    cachedArticles[feedUrl] = articles
        .map((article) => article.copyWith())
        .toList(growable: false);
  }

  @override
  Set<String> get readArticleIds => _readArticleIds;

  @override
  Future<void> putReadArticleIds(Set<String> ids) async {
    _readArticleIds = ids.toSet();
  }

  @override
  Set<String> get favoriteArticleIds => _favoriteArticleIds;

  @override
  Future<void> putFavoriteArticleIds(Set<String> ids) async {
    _favoriteArticleIds = ids.toSet();
  }

  @override
  Set<String> get readLaterArticleIds => _readLaterArticleIds;

  @override
  Future<void> putReadLaterArticleIds(Set<String> ids) async {
    _readLaterArticleIds = ids.toSet();
  }

  @override
  Future<void> updateLastFetched(String url, DateTime fetchedAt) async {
    final subscription = findSubscriptionByUrl(url);
    if (subscription == null) return;
    updateLastFetchedCalls += 1;
    lastFetchedUpdate = fetchedAt;
    subscription.lastFetchedAt = fetchedAt;
  }

  @override
  Future<void> close() async {}
}

const _rssFeed = '''
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0"
  xmlns:content="http://purl.org/rss/1.0/modules/content/"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:media="http://search.yahoo.com/mrss/">
  <channel>
    <title>Flow News</title>
    <description><![CDATA[<p>Reading <b>updates</b></p>]]></description>
    <image>
      <url>https://example.com/logo.png</url>
    </image>
    <item>
      <title>First Article</title>
      <link>https://example.com/first</link>
      <description><![CDATA[<p>Summary <b>one</b></p>]]></description>
      <content:encoded><![CDATA[<p>Full <em>content</em></p><img src="/images/full.png#size" alt="Full image" width="640" height="320" />]]></content:encoded>
      <media:thumbnail url="https://cdn.example.com/media/thumb.jpg" width="120" height="80" />
      <enclosure url="/downloads/enclosure.webp" type="image/webp" />
      <pubDate>Wed, 20 May 2026 15:00:00 +0800</pubDate>
      <guid>first-guid</guid>
      <dc:creator>Ada</dc:creator>
    </item>
    <item>
      <title>Second Article</title>
      <link>https://example.com/second</link>
      <description>Second summary</description>
      <pubDate>Tue, 19 May 2026 12:00:00 GMT</pubDate>
      <guid>second-guid</guid>
      <author>Bob</author>
    </item>
  </channel>
</rss>
''';

const _atomFeed = '''
<?xml version="1.0" encoding="UTF-8" ?>
<feed xmlns="http://www.w3.org/2005/Atom"
  xmlns:media="http://search.yahoo.com/mrss/">
  <title>Atom Flow</title>
  <subtitle><![CDATA[<p>Atom <strong>reading</strong> updates</p>]]></subtitle>
  <logo>https://example.com/atom-logo.png</logo>
  <entry>
    <title>Atom Entry</title>
    <link rel="self" href="https://example.com/atom-entry/self" />
    <link rel="alternate" href="https://example.com/atom-entry" />
    <id>tag:example.com,2026:atom-entry</id>
    <updated>2026-05-20T07:10:00Z</updated>
    <author>
      <name>Grace</name>
    </author>
    <summary type="html">&lt;p&gt;Atom summary&lt;/p&gt;</summary>
    <content type="html">&lt;p&gt;Atom full content&lt;/p&gt;&lt;img src="/images/atom.png" alt="Atom image" /&gt;</content>
    <media:thumbnail url="https://cdn.example.com/atom-thumb.png" />
  </entry>
</feed>
''';

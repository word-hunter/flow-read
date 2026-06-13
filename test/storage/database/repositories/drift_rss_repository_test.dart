import 'dart:convert';

import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_rss_repository.dart';
import 'package:flow_rss/flow_rss.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.createInMemory();
    await db.customStatement('PRAGMA foreign_keys = ON');
  });

  tearDown(() async {
    await db.close();
  });

  test('persists subscriptions and last fetched updates', () async {
    final repo = DriftRssRepository(db.rssDao);
    await repo.init();

    await repo.addSubscription(
      RssFeedSubscription(
        url: 'https://example.com/rss.xml',
        title: 'Example',
        description: 'Reading updates',
        imageUrl: 'https://example.com/logo.png',
        lastFetchedAt: DateTime.utc(2026, 6, 13, 8),
      ),
    );
    await repo.updateLastFetched(
      'https://example.com/rss.xml',
      DateTime.utc(2026, 6, 13, 9),
    );

    final reloaded = DriftRssRepository(db.rssDao);
    await reloaded.init();
    final subscription = reloaded.findSubscriptionByUrl(
      'https://example.com/rss.xml',
    );

    expect(subscription?.title, 'Example');
    expect(subscription?.description, 'Reading updates');
    expect(subscription?.imageUrl, 'https://example.com/logo.png');
    expect(subscription?.lastFetchedAt, DateTime.utc(2026, 6, 13, 9));

    final replaced = await reloaded.replaceSubscription(
      'https://example.com/rss.xml',
      RssFeedSubscription(
        url: 'https://example.com/renamed.xml',
        title: 'Renamed',
      ),
    );

    expect(replaced?.url, 'https://example.com/renamed.xml');
    expect(
      reloaded.findSubscriptionByUrl('https://example.com/rss.xml'),
      isNull,
    );
    expect(
      reloaded.findSubscriptionByUrl('https://example.com/renamed.xml')?.title,
      'Renamed',
    );

    expect(
      await reloaded.deleteSubscriptionByUrl('https://example.com/renamed.xml'),
      isTrue,
    );

    final empty = DriftRssRepository(db.rssDao);
    await empty.init();
    expect(empty.subscriptions, isEmpty);
  });

  test('caches articles and persists read state columns', () async {
    final repo = DriftRssRepository(db.rssDao);
    await repo.init();
    await repo.addSubscription(
      RssFeedSubscription(
        url: 'https://example.com/rss.xml',
        title: 'Example',
      ),
    );

    await repo.cacheArticles('https://example.com/rss.xml', [
      RssArticle(
        id: 'article-1',
        feedUrl: 'https://example.com/rss.xml',
        feedTitle: 'Example',
        title: 'First',
        link: 'https://example.com/first',
        description: 'Summary',
        content: 'Body',
        bodyBlocks: const [
          RssArticleTextBlock(
            type: RssArticleTextBlockType.heading,
            text: 'First',
            headingLevel: 2,
          ),
          RssArticleImageBlock(
            RssArticleImage(
              url: 'https://example.com/body.png',
              alt: 'Body image',
              width: 640,
              height: 320,
            ),
          ),
        ],
        images: const [
          RssArticleImage(
            url: 'https://example.com/thumb.png',
            alt: 'Thumb',
            width: 120,
            height: 80,
          ),
        ],
        pubDate: DateTime.utc(2026, 6, 13, 8),
        author: 'Ada',
      ),
    ]);
    await repo.putReadArticleIds({'article-1'});
    await repo.putFavoriteArticleIds({'article-1'});
    await repo.putReadLaterArticleIds({'article-1'});

    final subscription = await db.rssDao.findSubscriptionByUrl(
      'https://example.com/rss.xml',
    );
    final rows = await db.rssDao.articlesForSubscription(subscription!.id);
    final row = rows.single;

    expect(row.feedTitle, 'Example');
    expect(row.title, 'First');
    expect(row.link, 'https://example.com/first');
    expect(row.content, 'Body');
    expect(row.isRead, isTrue);
    expect(row.isFavorite, isTrue);
    expect(row.isReadLater, isTrue);
    expect(jsonDecode(row.bodyBlocks) as List<dynamic>, hasLength(2));
    expect(jsonDecode(row.images) as List<dynamic>, hasLength(1));

    final reloaded = DriftRssRepository(db.rssDao);
    await reloaded.init();

    expect(reloaded.readArticleIds, {'article-1'});
    expect(reloaded.favoriteArticleIds, {'article-1'});
    expect(reloaded.readLaterArticleIds, {'article-1'});

    await reloaded.putReadArticleIds({});
    await reloaded.putFavoriteArticleIds({});
    await reloaded.putReadLaterArticleIds({});

    final updatedRows = await db.rssDao.articlesForSubscription(
      subscription.id,
    );
    expect(updatedRows.single.isRead, isFalse);
    expect(updatedRows.single.isFavorite, isFalse);
    expect(updatedRows.single.isReadLater, isFalse);
  });
}

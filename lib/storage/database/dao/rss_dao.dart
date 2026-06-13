import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'rss_dao.g.dart';

@DriftAccessor(tables: [RssSubscriptions, RssArticles])
class RssDao extends DatabaseAccessor<AppDatabase> with _$RssDaoMixin {
  RssDao(super.db);

  // ---- Subscriptions ----

  Future<List<RssSubscriptionEntry>> allSubscriptions() =>
      select(rssSubscriptions).get();

  Future<RssSubscriptionEntry?> findSubscriptionByUrl(String url) {
    final q = select(rssSubscriptions)..where((r) => r.url.equals(url));
    return q.getSingleOrNull();
  }

  Future<void> insertSubscription(RssSubscriptionsCompanion entry) =>
      into(rssSubscriptions).insertOnConflictUpdate(entry);

  Future<void> deleteSubscription(String id) =>
      (delete(rssSubscriptions)..where((r) => r.id.equals(id))).go();

  Future<void> deleteSubscriptionByUrl(String url) =>
      (delete(rssSubscriptions)..where((r) => r.url.equals(url))).go();

  Future<void> deleteAllSubscriptions() => delete(rssSubscriptions).go();

  Future<void> updateLastFetched(String url, DateTime fetchedAt) {
    final iso = fetchedAt.toUtc().toIso8601String();
    return (update(rssSubscriptions)..where((r) => r.url.equals(url))).write(
      RssSubscriptionsCompanion(lastFetchedAt: Value(iso)),
    );
  }

  // ---- Articles ----

  Future<List<RssArticleEntry>> articlesForSubscription(
    String subscriptionId,
  ) =>
      (select(rssArticles)
            ..where((r) => r.subscriptionId.equals(subscriptionId))
            ..orderBy([(r) => OrderingTerm.desc(r.pubDate)]))
          .get();

  Future<void> upsertArticle(RssArticlesCompanion entry) =>
      into(rssArticles).insertOnConflictUpdate(entry);

  Future<void> upsertArticles(List<RssArticlesCompanion> entries) => batch((b) {
    b.insertAllOnConflictUpdate(rssArticles, entries);
  });

  Future<void> deleteArticlesForSubscription(String subscriptionId) => (delete(
    rssArticles,
  )..where((r) => r.subscriptionId.equals(subscriptionId))).go();

  Future<void> deleteAllArticles() => delete(rssArticles).go();

  Future<Set<String>> readArticleIds() async {
    final rows = await (select(
      rssArticles,
    )..where((r) => r.isRead.equals(true))).get();
    return rows.map((r) => r.id).toSet();
  }

  Future<Set<String>> favoriteArticleIds() async {
    final rows = await (select(
      rssArticles,
    )..where((r) => r.isFavorite.equals(true))).get();
    return rows.map((r) => r.id).toSet();
  }

  Future<Set<String>> readLaterArticleIds() async {
    final rows = await (select(
      rssArticles,
    )..where((r) => r.isReadLater.equals(true))).get();
    return rows.map((r) => r.id).toSet();
  }

  Future<void> markRead(String articleId) =>
      (update(rssArticles)..where((r) => r.id.equals(articleId))).write(
        const RssArticlesCompanion(isRead: Value(true)),
      );

  Future<void> markUnread(String articleId) =>
      (update(rssArticles)..where((r) => r.id.equals(articleId))).write(
        const RssArticlesCompanion(isRead: Value(false)),
      );

  Future<void> toggleFavorite(String articleId, bool favorite) =>
      (update(rssArticles)..where((r) => r.id.equals(articleId))).write(
        RssArticlesCompanion(isFavorite: Value(favorite)),
      );

  Future<void> toggleReadLater(String articleId, bool readLater) =>
      (update(rssArticles)..where((r) => r.id.equals(articleId))).write(
        RssArticlesCompanion(isReadLater: Value(readLater)),
      );
}

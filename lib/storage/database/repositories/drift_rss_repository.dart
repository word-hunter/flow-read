import '../app_database.dart';
import '../dao/rss_dao.dart';

final class DriftRssRepository {
  final RssDao _dao;

  DriftRssRepository(this._dao);

  Future<List<RssSubscriptionEntry>> allSubscriptions() =>
      _dao.allSubscriptions();

  Future<RssSubscriptionEntry?> findByUrl(String url) => _dao.findSubscriptionByUrl(url);

  Future<void> insertSubscription(RssSubscriptionsCompanion entry) =>
      _dao.insertSubscription(entry);

  Future<void> deleteSubscription(String id) => _dao.deleteSubscription(id);

  Future<void> deleteSubscriptionByUrl(String url) =>
      _dao.deleteSubscriptionByUrl(url);

  Future<void> updateLastFetched(String url, DateTime fetchedAt) =>
      _dao.updateLastFetched(url, fetchedAt);

  Future<List<RssArticleEntry>> articlesForSubscription(String subscriptionId) =>
      _dao.articlesForSubscription(subscriptionId);

  Future<void> upsertArticle(RssArticlesCompanion entry) =>
      _dao.upsertArticle(entry);

  Future<void> upsertArticles(List<RssArticlesCompanion> entries) =>
      _dao.upsertArticles(entries);

  Future<void> deleteArticlesForSubscription(String subscriptionId) =>
      _dao.deleteArticlesForSubscription(subscriptionId);

  Future<Set<String>> readArticleIds() => _dao.readArticleIds();

  Future<Set<String>> favoriteArticleIds() => _dao.favoriteArticleIds();

  Future<Set<String>> readLaterArticleIds() => _dao.readLaterArticleIds();

  Future<void> markRead(String articleId) => _dao.markRead(articleId);

  Future<void> markUnread(String articleId) => _dao.markUnread(articleId);

  Future<void> toggleFavorite(String articleId, bool favorite) =>
      _dao.toggleFavorite(articleId, favorite);

  Future<void> toggleReadLater(String articleId, bool readLater) =>
      _dao.toggleReadLater(articleId, readLater);
}

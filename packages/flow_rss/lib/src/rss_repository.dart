import 'rss_models.dart';

abstract class RssRepository {
  Future<void> init();
  Iterable<RssFeedSubscription> get subscriptions;
  RssFeedSubscription? findSubscriptionByUrl(String url);
  Future<void> addSubscription(RssFeedSubscription subscription);
  Future<RssFeedSubscription?> replaceSubscription(
    String originalUrl,
    RssFeedSubscription subscription,
  );
  Future<bool> deleteSubscriptionByUrl(String url);
  Future<void> cacheArticles(String feedUrl, Iterable<RssArticle> articles);
  Future<List<RssArticle>> cachedArticlesForFeed(String feedUrl);
  Set<String> get readArticleIds;
  Future<void> putReadArticleIds(Set<String> ids);
  Set<String> get favoriteArticleIds;
  Future<void> putFavoriteArticleIds(Set<String> ids);
  Set<String> get readLaterArticleIds;
  Future<void> putReadLaterArticleIds(Set<String> ids);
  Future<void> updateLastFetched(String url, DateTime fetchedAt);
  Future<void> close();
}

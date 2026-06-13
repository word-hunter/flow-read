import 'dart:convert';

import 'package:hive/hive.dart';

import 'rss_models.dart';

Box<T> _requireOpenBox<T>(String name) {
  if (!Hive.isBoxOpen(name)) throw StateError('Hive box "$name" not open');
  return Hive.box<T>(name);
}

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
  Set<String> get readArticleIds;
  Future<void> putReadArticleIds(Set<String> ids);
  Set<String> get favoriteArticleIds;
  Future<void> putFavoriteArticleIds(Set<String> ids);
  Set<String> get readLaterArticleIds;
  Future<void> putReadLaterArticleIds(Set<String> ids);
  Future<void> updateLastFetched(String url, DateTime fetchedAt);
  Future<void> close();
}

class HiveRssRepository implements RssRepository {
  HiveRssRepository({Box<RssFeedSubscription>? feedBox, Box<dynamic>? metaBox})
    : _feedBox = feedBox,
      _metaBox = metaBox;

  static const _readArticlesKey = 'rss_read_articles';
  static const _favoriteArticlesKey = 'rss_favorite_articles';
  static const _readLaterArticlesKey = 'rss_read_later_articles';

  Box<RssFeedSubscription>? _feedBox;
  Box<dynamic>? _metaBox;

  Box<RssFeedSubscription> get _feedStorage {
    return _feedBox ??
        _requireOpenBox<RssFeedSubscription>('rss_subscriptions');
  }

  Box<dynamic> get _metaStorage {
    return _metaBox ?? _requireOpenBox<dynamic>('settings');
  }

  @override
  Future<void> init() async {
    _feedBox ??= _requireOpenBox<RssFeedSubscription>(
      'rss_subscriptions',
    );
    _metaBox ??= _requireOpenBox<dynamic>('settings');
  }

  @override
  Iterable<RssFeedSubscription> get subscriptions => _feedStorage.values;

  @override
  RssFeedSubscription? findSubscriptionByUrl(String url) {
    final key = _keyForUrl(url);
    return key == null ? null : _feedStorage.get(key);
  }

  @override
  Future<void> addSubscription(RssFeedSubscription subscription) async {
    await _feedStorage.add(subscription);
  }

  @override
  Future<RssFeedSubscription?> replaceSubscription(
    String originalUrl,
    RssFeedSubscription subscription,
  ) async {
    final key = _keyForUrl(originalUrl);
    if (key == null) return null;
    await _feedStorage.put(key, subscription);
    return subscription;
  }

  @override
  Future<bool> deleteSubscriptionByUrl(String url) async {
    final key = _keyForUrl(url);
    if (key == null) return false;
    await _feedStorage.delete(key);
    return true;
  }

  @override
  Future<void> cacheArticles(
    String feedUrl,
    Iterable<RssArticle> articles,
  ) async {}

  @override
  Set<String> get readArticleIds {
    return _readStringSet(_readArticlesKey);
  }

  @override
  Future<void> putReadArticleIds(Set<String> ids) async {
    await _writeStringSet(_readArticlesKey, ids);
  }

  @override
  Set<String> get favoriteArticleIds {
    return _readStringSet(_favoriteArticlesKey);
  }

  @override
  Future<void> putFavoriteArticleIds(Set<String> ids) async {
    await _writeStringSet(_favoriteArticlesKey, ids);
  }

  @override
  Set<String> get readLaterArticleIds {
    return _readStringSet(_readLaterArticlesKey);
  }

  @override
  Future<void> putReadLaterArticleIds(Set<String> ids) async {
    await _writeStringSet(_readLaterArticlesKey, ids);
  }

  Set<String> _readStringSet(String key) {
    final encoded = _metaStorage.get(key);
    if (encoded is! String || encoded.isEmpty) return {};
    try {
      final list = jsonDecode(encoded) as List<dynamic>;
      return list.whereType<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeStringSet(String key, Set<String> ids) async {
    final sorted = ids.toList()..sort();
    await _metaStorage.put(key, jsonEncode(sorted));
  }

  @override
  Future<void> updateLastFetched(String url, DateTime fetchedAt) async {
    final key = _keyForUrl(url);
    if (key == null) return;
    final current = _feedStorage.get(key);
    if (current == null) return;

    await _feedStorage.put(
      key,
      RssFeedSubscription(
        url: current.url,
        title: current.title,
        description: current.description,
        imageUrl: current.imageUrl,
        lastFetchedAt: fetchedAt,
      ),
    );
  }

  @override
  Future<void> close() async {}

  dynamic _keyForUrl(String url) {
    for (final key in _feedStorage.keys) {
      if (_feedStorage.get(key)?.url == url) return key;
    }
    return null;
  }
}

import 'dart:convert';

import 'package:hive/hive.dart';

import '../../models/rss_models.dart';
import '../hive_box_names.dart';
import 'hive_repository_box.dart';

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
  Set<String> get readArticleIds;
  Future<void> putReadArticleIds(Set<String> ids);
  Future<void> updateLastFetched(String url, DateTime fetchedAt);
  Future<void> close();
}

class HiveRssRepository implements RssRepository {
  HiveRssRepository({Box<RssFeedSubscription>? feedBox, Box<dynamic>? metaBox})
    : _feedBox = feedBox,
      _metaBox = metaBox;

  static const _readArticlesKey = 'rss_read_articles';

  Box<RssFeedSubscription>? _feedBox;
  Box<dynamic>? _metaBox;

  Box<RssFeedSubscription> get _feedStorage {
    return _feedBox ??
        requireOpenHiveBox<RssFeedSubscription>(HiveBoxNames.rssSubscriptions);
  }

  Box<dynamic> get _metaStorage {
    return _metaBox ?? requireOpenHiveBox<dynamic>(HiveBoxNames.settings);
  }

  @override
  Future<void> init() async {
    _feedBox ??= requireOpenHiveBox<RssFeedSubscription>(
      HiveBoxNames.rssSubscriptions,
    );
    _metaBox ??= requireOpenHiveBox<dynamic>(HiveBoxNames.settings);
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
  Set<String> get readArticleIds {
    final encoded = _metaStorage.get(_readArticlesKey);
    if (encoded is! String || encoded.isEmpty) return {};
    try {
      final list = jsonDecode(encoded) as List<dynamic>;
      return list.whereType<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> putReadArticleIds(Set<String> ids) async {
    await _metaStorage.put(_readArticlesKey, jsonEncode(ids.toList()));
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

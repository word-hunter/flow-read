import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flow_rss/flow_rss.dart';

import '../app_database.dart';
import '../dao/rss_dao.dart';

final class DriftRssRepository implements RssRepository {
  DriftRssRepository(this._dao);

  final RssDao _dao;
  final Map<String, RssFeedSubscription> _subscriptionsByUrl = {};
  final Map<String, String> _subscriptionIdsByUrl = {};
  Set<String> _readArticleIds = {};
  Set<String> _favoriteArticleIds = {};
  Set<String> _readLaterArticleIds = {};

  static String subscriptionIdForUrl(String url) {
    final encoded = base64Url.encode(utf8.encode(url)).replaceAll('=', '');
    return 'url:$encoded';
  }

  @override
  Future<void> init() async {
    final entries = await _dao.allSubscriptions();
    _subscriptionsByUrl
      ..clear()
      ..addEntries(
        entries.map(
          (entry) => MapEntry(entry.url, _subscriptionFromEntry(entry)),
        ),
      );
    _subscriptionIdsByUrl
      ..clear()
      ..addEntries(entries.map((entry) => MapEntry(entry.url, entry.id)));
    _readArticleIds = await _dao.readArticleIds();
    _favoriteArticleIds = await _dao.favoriteArticleIds();
    _readLaterArticleIds = await _dao.readLaterArticleIds();
  }

  @override
  Iterable<RssFeedSubscription> get subscriptions => _subscriptionsByUrl.values;

  @override
  RssFeedSubscription? findSubscriptionByUrl(String url) {
    return _subscriptionsByUrl[url];
  }

  @override
  Future<void> addSubscription(RssFeedSubscription subscription) async {
    final id =
        await _idForUrl(subscription.url) ??
        subscriptionIdForUrl(subscription.url);
    await _upsertSubscription(id, subscription);
  }

  @override
  Future<RssFeedSubscription?> replaceSubscription(
    String originalUrl,
    RssFeedSubscription subscription,
  ) async {
    final originalId = await _idForUrl(originalUrl);
    if (originalId == null) return null;

    if (originalUrl != subscription.url) {
      await _dao.deleteArticlesForSubscription(originalId);
      await _dao.deleteSubscription(originalId);
      _subscriptionsByUrl.remove(originalUrl);
      _subscriptionIdsByUrl.remove(originalUrl);
      await _upsertSubscription(
        subscriptionIdForUrl(subscription.url),
        subscription,
      );
    } else {
      await _upsertSubscription(originalId, subscription);
    }

    return subscription;
  }

  @override
  Future<bool> deleteSubscriptionByUrl(String url) async {
    final id = await _idForUrl(url);
    if (id == null) return false;
    await _dao.deleteArticlesForSubscription(id);
    await _dao.deleteSubscription(id);
    _subscriptionsByUrl.remove(url);
    _subscriptionIdsByUrl.remove(url);
    return true;
  }

  @override
  Future<void> cacheArticles(
    String feedUrl,
    Iterable<RssArticle> articles,
  ) async {
    final subscriptionId = await _idForUrl(feedUrl);
    if (subscriptionId == null) return;

    final entries = articles
        .map((article) {
          _syncStatusSets(article);
          return RssArticlesCompanion.insert(
            id: article.id,
            subscriptionId: subscriptionId,
            feedUrl: article.feedUrl,
            title: article.title,
            isRead: article.isRead,
            isFavorite: article.isFavorite,
            isReadLater: article.isReadLater,
            feedTitle: Value(article.feedTitle),
            link: Value(article.link),
            description: Value(article.description),
            content: Value(article.content),
            bodyBlocks: Value(_encodeBodyBlocks(article.bodyBlocks)),
            images: Value(_encodeImages(article.images)),
            pubDate: Value(_dateToIso(article.pubDate)),
            author: Value(article.author),
          );
        })
        .toList(growable: false);
    if (entries.isEmpty) return;
    await _dao.upsertArticles(entries);
  }

  @override
  Set<String> get readArticleIds => _readArticleIds.toSet();

  @override
  Future<void> putReadArticleIds(Set<String> ids) async {
    final next = ids.toSet();
    await _toggleIds(
      current: _readArticleIds,
      next: next,
      enable: _dao.markRead,
      disable: _dao.markUnread,
    );
    _readArticleIds = next;
  }

  @override
  Set<String> get favoriteArticleIds => _favoriteArticleIds.toSet();

  @override
  Future<void> putFavoriteArticleIds(Set<String> ids) async {
    final next = ids.toSet();
    await _toggleIds(
      current: _favoriteArticleIds,
      next: next,
      enable: (id) => _dao.toggleFavorite(id, true),
      disable: (id) => _dao.toggleFavorite(id, false),
    );
    _favoriteArticleIds = next;
  }

  @override
  Set<String> get readLaterArticleIds => _readLaterArticleIds.toSet();

  @override
  Future<void> putReadLaterArticleIds(Set<String> ids) async {
    final next = ids.toSet();
    await _toggleIds(
      current: _readLaterArticleIds,
      next: next,
      enable: (id) => _dao.toggleReadLater(id, true),
      disable: (id) => _dao.toggleReadLater(id, false),
    );
    _readLaterArticleIds = next;
  }

  @override
  Future<void> updateLastFetched(String url, DateTime fetchedAt) async {
    await _dao.updateLastFetched(url, fetchedAt);
    final current = _subscriptionsByUrl[url];
    if (current == null) return;
    _subscriptionsByUrl[url] = current.copyWith(lastFetchedAt: fetchedAt);
  }

  @override
  Future<void> close() async {}

  Future<void> _upsertSubscription(
    String id,
    RssFeedSubscription subscription,
  ) async {
    await _dao.insertSubscription(
      RssSubscriptionsCompanion.insert(
        id: id,
        url: subscription.url,
        title: Value(subscription.title),
        description: Value(subscription.description),
        imageUrl: Value(subscription.imageUrl),
        lastFetchedAt: Value(_dateToIso(subscription.lastFetchedAt)),
      ),
    );
    _subscriptionsByUrl[subscription.url] = subscription;
    _subscriptionIdsByUrl[subscription.url] = id;
  }

  Future<String?> _idForUrl(String url) async {
    final cached = _subscriptionIdsByUrl[url];
    if (cached != null) return cached;
    final entry = await _dao.findSubscriptionByUrl(url);
    if (entry == null) return null;
    _subscriptionsByUrl[url] = _subscriptionFromEntry(entry);
    _subscriptionIdsByUrl[url] = entry.id;
    return entry.id;
  }

  void _syncStatusSets(RssArticle article) {
    _setMembership(_readArticleIds, article.id, article.isRead);
    _setMembership(_favoriteArticleIds, article.id, article.isFavorite);
    _setMembership(_readLaterArticleIds, article.id, article.isReadLater);
  }

  Future<void> _toggleIds({
    required Set<String> current,
    required Set<String> next,
    required Future<void> Function(String id) enable,
    required Future<void> Function(String id) disable,
  }) async {
    for (final id in next.difference(current)) {
      await enable(id);
    }
    for (final id in current.difference(next)) {
      await disable(id);
    }
  }
}

RssFeedSubscription _subscriptionFromEntry(RssSubscriptionEntry entry) {
  return RssFeedSubscription(
    url: entry.url,
    title: entry.title,
    description: entry.description,
    imageUrl: entry.imageUrl,
    lastFetchedAt: _dateFromIso(entry.lastFetchedAt),
  );
}

String? _dateToIso(DateTime? value) => value?.toUtc().toIso8601String();

DateTime? _dateFromIso(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

void _setMembership(Set<String> ids, String id, bool included) {
  if (included) {
    ids.add(id);
  } else {
    ids.remove(id);
  }
}

String _encodeBodyBlocks(Iterable<RssArticleBodyBlock> blocks) {
  return jsonEncode(
    blocks
        .map((block) {
          return switch (block) {
            RssArticleTextBlock() => {
              'type': 'text',
              'textType': block.type.name,
              'text': block.text,
              'headingLevel': block.headingLevel,
              'indent': block.indent,
            },
            RssArticleImageBlock() => {
              'type': 'image',
              'image': _imageToJson(block.image),
            },
          };
        })
        .toList(growable: false),
  );
}

String _encodeImages(Iterable<RssArticleImage> images) {
  return jsonEncode(images.map(_imageToJson).toList(growable: false));
}

Map<String, Object?> _imageToJson(RssArticleImage image) {
  return {
    'url': image.url,
    'alt': image.alt,
    'width': image.width,
    'height': image.height,
  };
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import 'rss_models.dart';
import 'rss_repository.dart';
import 'package:flutter/foundation.dart';
import 'feed_document_parser.dart';

typedef RssHttpGet =
    Future<http.Response> Function(Uri uri, {Map<String, String>? headers});

abstract class RssFeedService {
  Future<void> init();
  List<RssFeedSubscription> get subscriptions;
  Future<RssFeedSubscription> addSubscription(String url);
  Future<RssFeedSubscription?> updateSubscription({
    required String originalUrl,
    required String url,
    required String title,
    String? description,
    bool refreshMetadata = false,
  });
  Future<void> removeSubscription(String url);
  Future<List<RssArticle>> fetchArticles(
    String feedUrl, {
    bool forceRefresh = false,
  });
  Future<List<RssArticle>> fetchLatestArticles({bool forceRefresh = false});
  Future<void> markAsRead(String articleId);
  Future<void> markAsUnread(String articleId);
  Future<void> setArticleFavorite(String articleId, bool isFavorite);
  Future<void> setArticleReadLater(String articleId, bool isReadLater);
  void clearArticleCache([String? feedUrl]);
}

class RssService implements RssFeedService {
  RssService({
    RssRepository? repository,
    RssHttpGet? httpGet,
    DateTime Function()? clock,
    RssFeedDocumentParser parser = const RssFeedDocumentParser(),
  }) : _repository = repository ?? HiveRssRepository(),
       _httpGet = httpGet ?? http.get,
       _clock = clock ?? DateTime.now,
       _parser = parser;

  static const _requestHeaders = {
    'Accept':
        'application/rss+xml, application/atom+xml, application/xml;q=0.9, text/xml;q=0.8, */*;q=0.5',
    'User-Agent': 'FlowRead/1.0 RSS Reader',
  };
  final RssRepository _repository;
  final RssHttpGet _httpGet;
  final DateTime Function() _clock;
  final RssFeedDocumentParser _parser;
  final Map<String, List<RssArticle>> _articleCache = {};
  final Set<String> _readArticleIds = {};
  final Set<String> _favoriteArticleIds = {};
  final Set<String> _readLaterArticleIds = {};

  @override
  Future<void> init() async {
    await _repository.init();
    _readArticleIds
      ..clear()
      ..addAll(_repository.readArticleIds);
    _favoriteArticleIds
      ..clear()
      ..addAll(_repository.favoriteArticleIds);
    _readLaterArticleIds
      ..clear()
      ..addAll(_repository.readLaterArticleIds);
  }

  @override
  List<RssFeedSubscription> get subscriptions {
    final list = _repository.subscriptions.toList();
    list.sort((a, b) => a.title.compareTo(b.title));
    return list;
  }

  @override
  Future<RssFeedSubscription> addSubscription(String url) async {
    final normalizedUrl = _normalizeUrl(url);
    _validateUrl(normalizedUrl);
    final existing = subscriptions
        .where((s) => s.url == normalizedUrl)
        .firstOrNull;
    if (existing != null) return existing;

    final document = await _fetchFeedDocument(normalizedUrl);
    final info = _feedMetadata(document);
    final sub = RssFeedSubscription(
      url: normalizedUrl,
      title: info.title ?? normalizedUrl,
      description: info.description,
      imageUrl: info.imageUrl,
      lastFetchedAt: _clock(),
    );
    await _repository.addSubscription(sub);
    return sub;
  }

  @override
  Future<RssFeedSubscription?> updateSubscription({
    required String originalUrl,
    required String url,
    required String title,
    String? description,
    bool refreshMetadata = false,
  }) async {
    final normalizedUrl = _normalizeUrl(url);
    _validateUrl(normalizedUrl);
    final duplicate = subscriptions
        .where((s) => s.url == normalizedUrl && s.url != originalUrl)
        .firstOrNull;
    if (duplicate != null) {
      throw StateError('订阅地址已存在');
    }

    final current = _repository.findSubscriptionByUrl(originalUrl);
    if (current == null) return null;

    var nextTitle = title.trim().isEmpty ? normalizedUrl : title.trim();
    var nextDescription = description?.trim();
    String? imageUrl = current.imageUrl;
    DateTime? lastFetchedAt = current.lastFetchedAt;

    if (refreshMetadata || normalizedUrl != originalUrl) {
      final document = await _fetchFeedDocument(normalizedUrl);
      final info = _feedMetadata(document);
      nextTitle = title.trim().isEmpty
          ? (info.title ?? normalizedUrl)
          : title.trim();
      nextDescription = nextDescription?.isNotEmpty == true
          ? nextDescription
          : info.description;
      imageUrl = info.imageUrl;
      lastFetchedAt = _clock();
    }

    final updated = RssFeedSubscription(
      url: normalizedUrl,
      title: nextTitle,
      description: nextDescription?.isEmpty == true ? null : nextDescription,
      imageUrl: imageUrl,
      lastFetchedAt: lastFetchedAt,
    );
    await _repository.replaceSubscription(originalUrl, updated);
    _articleCache.remove(originalUrl);
    if (normalizedUrl != originalUrl) {
      _articleCache.remove(normalizedUrl);
    }
    return updated;
  }

  @override
  Future<void> removeSubscription(String url) async {
    final removed = await _repository.deleteSubscriptionByUrl(url);
    if (removed) {
      _articleCache.remove(url);
    }
  }

  @override
  Future<List<RssArticle>> fetchArticles(
    String feedUrl, {
    bool forceRefresh = false,
  }) async {
    final cached = _articleCache[feedUrl];
    if (cached != null && !forceRefresh) return cached;

    try {
      final document = await _fetchFeedDocument(feedUrl);
      final articles = _parser.parseArticles(
        document,
        feedUrl: feedUrl,
        fallbackFeedTitle:
            subscriptions.where((s) => s.url == feedUrl).firstOrNull?.title ??
            '',
      );

      for (final a in articles) {
        _applyArticleState(a);
      }

      _articleCache[feedUrl] = articles;
      await _updateLastFetched(feedUrl);
      return articles;
    } catch (error, stackTrace) {
      debugPrint('[rss_service] fetch failed: $error');
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<List<RssArticle>> fetchLatestArticles({
    bool forceRefresh = false,
  }) async {
    final groups = await Future.wait(
      subscriptions.map(
        (s) => fetchArticles(s.url, forceRefresh: forceRefresh),
      ),
    );
    final articles = groups.expand((group) => group).toList()
      ..sort(RssFeedDocumentParser.compareArticlesByDateDesc);
    return articles;
  }

  @override
  Future<void> markAsRead(String articleId) async {
    _readArticleIds.add(articleId);
    await _repository.putReadArticleIds(_readArticleIds);
    _updateCachedArticle(articleId, (article) => article.isRead = true);
  }

  @override
  Future<void> markAsUnread(String articleId) async {
    _readArticleIds.remove(articleId);
    await _repository.putReadArticleIds(_readArticleIds);
    _updateCachedArticle(articleId, (article) => article.isRead = false);
  }

  @override
  Future<void> setArticleFavorite(String articleId, bool isFavorite) async {
    if (isFavorite) {
      _favoriteArticleIds.add(articleId);
    } else {
      _favoriteArticleIds.remove(articleId);
    }
    await _repository.putFavoriteArticleIds(_favoriteArticleIds);
    _updateCachedArticle(
      articleId,
      (article) => article.isFavorite = isFavorite,
    );
  }

  @override
  Future<void> setArticleReadLater(String articleId, bool isReadLater) async {
    if (isReadLater) {
      _readLaterArticleIds.add(articleId);
    } else {
      _readLaterArticleIds.remove(articleId);
    }
    await _repository.putReadLaterArticleIds(_readLaterArticleIds);
    _updateCachedArticle(
      articleId,
      (article) => article.isReadLater = isReadLater,
    );
  }

  void _applyArticleState(RssArticle article) {
    article.isRead = _readArticleIds.contains(article.id);
    article.isFavorite = _favoriteArticleIds.contains(article.id);
    article.isReadLater = _readLaterArticleIds.contains(article.id);
  }

  void _updateCachedArticle(
    String articleId,
    void Function(RssArticle article) update,
  ) {
    for (final articles in _articleCache.values) {
      for (final a in articles) {
        if (a.id == articleId) update(a);
      }
    }
  }

  @override
  void clearArticleCache([String? feedUrl]) {
    if (feedUrl != null) {
      _articleCache.remove(feedUrl);
    } else {
      _articleCache.clear();
    }
  }

  // ---- private helpers ----

  String _normalizeUrl(String url) {
    var normalized = url.trim();
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }
    return normalized;
  }

  void _validateUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.trim().isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ArgumentError('请输入有效的 RSS 地址');
    }
  }

  Future<XmlDocument> _fetchFeedDocument(String url) async {
    final response = await _httpGet(
      Uri.parse(url),
      headers: _requestHeaders,
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('RSS 源响应异常: HTTP ${response.statusCode}');
    }

    final body = utf8.decode(response.bodyBytes);
    return XmlDocument.parse(body);
  }

  ParsedFeedMetadata _feedMetadata(XmlDocument document) {
    return _parser.parseMetadata(document);
  }

  Future<void> _updateLastFetched(String url) async {
    await _repository.updateLastFetched(url, _clock());
  }
}

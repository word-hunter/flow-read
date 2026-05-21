import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../models/rss_models.dart';
import '../storage/repositories/rss_repository.dart';

typedef RssHttpGet =
    Future<http.Response> Function(Uri uri, {Map<String, String>? headers});

class RssService {
  RssService({
    RssRepository? repository,
    RssHttpGet? httpGet,
    DateTime Function()? clock,
  }) : _repository = repository ?? HiveRssRepository(),
       _httpGet = httpGet ?? http.get,
       _clock = clock ?? DateTime.now;

  static const _requestHeaders = {
    'Accept':
        'application/rss+xml, application/atom+xml, application/xml;q=0.9, text/xml;q=0.8, */*;q=0.5',
    'User-Agent': 'FlowRead/1.0 RSS Reader',
  };
  final RssRepository _repository;
  final RssHttpGet _httpGet;
  final DateTime Function() _clock;
  final Map<String, List<RssArticle>> _articleCache = {};
  final Set<String> _readArticleIds = {};

  Future<void> init() async {
    await _repository.init();
    _readArticleIds
      ..clear()
      ..addAll(_repository.readArticleIds);
  }

  List<RssFeedSubscription> get subscriptions {
    final list = _repository.subscriptions.toList();
    list.sort((a, b) => a.title.compareTo(b.title));
    return list;
  }

  Future<RssFeedSubscription> addSubscription(String url) async {
    final normalizedUrl = _normalizeUrl(url);
    _validateUrl(normalizedUrl);
    final existing = subscriptions
        .where((s) => s.url == normalizedUrl)
        .firstOrNull;
    if (existing != null) return existing;

    final document = await _fetchFeedDocument(normalizedUrl);
    _ensureFeedDocument(document);
    final info = _extractFeedInfo(document);
    final sub = RssFeedSubscription(
      url: normalizedUrl,
      title: info['title'] ?? normalizedUrl,
      description: info['description'],
      imageUrl: info['imageUrl'],
      lastFetchedAt: _clock(),
    );
    await _repository.addSubscription(sub);
    return sub;
  }

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
      _ensureFeedDocument(document);
      final info = _extractFeedInfo(document);
      nextTitle = title.trim().isEmpty
          ? (info['title'] ?? normalizedUrl)
          : title.trim();
      nextDescription = nextDescription?.isNotEmpty == true
          ? nextDescription
          : info['description'];
      imageUrl = info['imageUrl'];
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

  Future<void> removeSubscription(String url) async {
    final removed = await _repository.deleteSubscriptionByUrl(url);
    if (removed) {
      _articleCache.remove(url);
    }
  }

  Future<List<RssArticle>> fetchArticles(
    String feedUrl, {
    bool forceRefresh = false,
  }) async {
    final cached = _articleCache[feedUrl];
    if (cached != null && !forceRefresh) return cached;

    try {
      final document = await _fetchFeedDocument(feedUrl);
      final articles = _parseFeed(document, feedUrl);

      for (final a in articles) {
        if (_readArticleIds.contains(a.id)) {
          a.isRead = true;
        }
      }

      _articleCache[feedUrl] = articles;
      await _updateLastFetched(feedUrl);
      return articles;
    } catch (e) {
      debugPrint('RSS fetch failed for $feedUrl: $e');
      return cached ?? [];
    }
  }

  Future<List<RssArticle>> fetchLatestArticles({
    bool forceRefresh = false,
  }) async {
    final groups = await Future.wait(
      subscriptions.map(
        (s) => fetchArticles(s.url, forceRefresh: forceRefresh),
      ),
    );
    final articles = groups.expand((group) => group).toList()
      ..sort(_compareArticlesByDateDesc);
    return articles;
  }

  Future<void> markAsRead(String articleId) async {
    _readArticleIds.add(articleId);
    await _repository.putReadArticleIds(_readArticleIds);
    for (final articles in _articleCache.values) {
      for (final a in articles) {
        if (a.id == articleId) a.isRead = true;
      }
    }
  }

  Future<void> markAsUnread(String articleId) async {
    _readArticleIds.remove(articleId);
    await _repository.putReadArticleIds(_readArticleIds);
    for (final articles in _articleCache.values) {
      for (final a in articles) {
        if (a.id == articleId) a.isRead = false;
      }
    }
  }

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

  Map<String, String?> _extractFeedInfo(XmlDocument document) {
    final channel = document.findAllElements('channel').firstOrNull;
    final feedEl = document.findAllElements('feed').firstOrNull;

    if (channel != null) {
      return {
        'title': _childText(channel, ['title']),
        'description': _cleanText(_childText(channel, ['description'])),
        'imageUrl': channel
            .findElements('image')
            .firstOrNull
            ?.findElements('url')
            .firstOrNull
            ?.innerText,
      };
    }
    if (feedEl != null) {
      return {
        'title': _childText(feedEl, ['title']),
        'description': _cleanText(_childText(feedEl, ['subtitle'])),
        'imageUrl': _childText(feedEl, ['logo', 'icon']),
      };
    }
    return {};
  }

  void _ensureFeedDocument(XmlDocument document) {
    if (document.findAllElements('channel').isEmpty &&
        document.findAllElements('feed').isEmpty) {
      throw StateError('未识别到 RSS/Atom 内容');
    }
  }

  List<RssArticle> _parseFeed(XmlDocument document, String feedUrl) {
    if (document.findAllElements('channel').isNotEmpty) {
      return _parseRss(document, feedUrl);
    }
    if (document.findAllElements('feed').isNotEmpty) {
      return _parseAtom(document, feedUrl);
    }
    return [];
  }

  List<RssArticle> _parseRss(XmlDocument document, String feedUrl) {
    final feedTitle =
        document
            .findAllElements('channel')
            .firstOrNull
            ?.findElements('title')
            .firstOrNull
            ?.innerText ??
        subscriptions.where((s) => s.url == feedUrl).firstOrNull?.title ??
        '';
    final items = document.findAllElements('item');
    final articles = items.map((item) {
      final description = _childText(item, ['description']);
      final content = _childText(item, ['content:encoded', 'encoded']);
      final link = _childText(item, ['link']);
      final pubDate = _parseDate(_childText(item, ['pubDate', 'date']));
      final guid = _childText(item, ['guid']);
      return RssArticle(
        feedUrl: feedUrl,
        feedTitle: feedTitle,
        title: _childText(item, ['title']) ?? 'Untitled',
        link: link,
        description: description != null ? _stripHtml(description) : null,
        content: _cleanArticleContent(content ?? description),
        pubDate: pubDate,
        author: _childText(item, ['author', 'dc:creator', 'creator']),
        id: guid?.isNotEmpty == true
            ? '${feedUrl.hashCode}_${guid.hashCode}'
            : '${feedUrl.hashCode}_${(link ?? _childText(item, ['title']) ?? '').hashCode}_${pubDate?.millisecondsSinceEpoch ?? 0}',
      );
    }).toList();
    articles.sort(_compareArticlesByDateDesc);
    return articles;
  }

  List<RssArticle> _parseAtom(XmlDocument document, String feedUrl) {
    final feedEl = document.findAllElements('feed').firstOrNull;
    final feedTitle =
        feedEl?.findElements('title').firstOrNull?.innerText ??
        subscriptions.where((s) => s.url == feedUrl).firstOrNull?.title ??
        '';
    final entries = document.findAllElements('entry');
    final articles = entries.map((entry) {
      final summary = _childText(entry, ['summary']);
      final content = _childText(entry, ['content']);
      final link = _atomLink(entry);
      final pubDate = _parseDate(
        _childText(entry, ['published', 'updated', 'modified']),
      );
      final id = _childText(entry, ['id']);
      return RssArticle(
        feedUrl: feedUrl,
        feedTitle: feedTitle,
        title: _childText(entry, ['title']) ?? 'Untitled',
        link: link,
        description: summary != null ? _stripHtml(summary) : null,
        content: _cleanArticleContent(content ?? summary),
        pubDate: pubDate,
        author: entry
            .findElements('author')
            .firstOrNull
            ?.findElements('name')
            .firstOrNull
            ?.innerText,
        id: id?.isNotEmpty == true
            ? '${feedUrl.hashCode}_${id.hashCode}'
            : '${feedUrl.hashCode}_${(link ?? _childText(entry, ['title']) ?? '').hashCode}_${pubDate?.millisecondsSinceEpoch ?? 0}',
      );
    }).toList();
    articles.sort(_compareArticlesByDateDesc);
    return articles;
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr).toLocal();
    } catch (_) {
      return _parseRfc822Date(dateStr);
    }
  }

  DateTime? _parseRfc822Date(String value) {
    final cleaned = value
        .replaceFirst(RegExp(r'^[A-Za-z]{3},\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final match = RegExp(
      r'^(\d{1,2})\s+([A-Za-z]{3})\s+(\d{2,4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([A-Za-z]{1,4}|[+-]\d{4})?$',
    ).firstMatch(cleaned);
    if (match == null) return null;

    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    final month = months[match.group(2)!.toLowerCase()];
    if (month == null) return null;

    var year = int.parse(match.group(3)!);
    if (year < 100) year += year >= 70 ? 1900 : 2000;
    final day = int.parse(match.group(1)!);
    final hour = int.parse(match.group(4)!);
    final minute = int.parse(match.group(5)!);
    final second = int.tryParse(match.group(6) ?? '0') ?? 0;
    final zone = (match.group(7) ?? 'GMT').toUpperCase();
    final offset = _timezoneOffset(zone);
    final utc = DateTime.utc(
      year,
      month,
      day,
      hour,
      minute,
      second,
    ).subtract(offset);
    return utc.toLocal();
  }

  Duration _timezoneOffset(String zone) {
    const named = {
      'UT': Duration.zero,
      'UTC': Duration.zero,
      'GMT': Duration.zero,
      'Z': Duration.zero,
      'EST': Duration(hours: -5),
      'EDT': Duration(hours: -4),
      'CST': Duration(hours: -6),
      'CDT': Duration(hours: -5),
      'MST': Duration(hours: -7),
      'MDT': Duration(hours: -6),
      'PST': Duration(hours: -8),
      'PDT': Duration(hours: -7),
    };
    final upper = zone.toUpperCase();
    if (named.containsKey(upper)) return named[upper]!;
    final match = RegExp(r'^([+-])(\d{2})(\d{2})$').firstMatch(upper);
    if (match == null) return Duration.zero;
    final sign = match.group(1) == '-' ? -1 : 1;
    final hours = int.parse(match.group(2)!);
    final minutes = int.parse(match.group(3)!);
    return Duration(minutes: sign * (hours * 60 + minutes));
  }

  String _stripHtml(String htmlText) {
    try {
      final document = html.parse(htmlText);
      final text = document.body?.text ?? htmlText;
      return text.replaceAll(RegExp(r'\s+'), ' ').trim();
    } catch (_) {
      return htmlText.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    }
  }

  String? _cleanArticleContent(String? value) {
    final text = _cleanText(value);
    if (text == null || text.isEmpty) return null;
    return text;
  }

  String? _cleanText(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return _stripHtml(trimmed);
  }

  String? _childText(XmlElement element, List<String> names) {
    for (final child in element.childElements) {
      final qualified = child.name.qualified;
      final local = child.name.local;
      for (final name in names) {
        final expectedLocal = name.contains(':') ? name.split(':').last : name;
        if (qualified == name || local == name || local == expectedLocal) {
          final text = child.innerText.trim();
          if (text.isNotEmpty) return text;
        }
      }
    }
    return null;
  }

  String? _atomLink(XmlElement entry) {
    final links = entry.findElements('link').toList();
    final alternate = links.where((e) {
      final rel = e.getAttribute('rel');
      return rel == null || rel == 'alternate';
    }).firstOrNull;
    final selected = alternate ?? links.firstOrNull;
    return selected?.getAttribute('href') ?? selected?.innerText;
  }

  int _compareArticlesByDateDesc(RssArticle a, RssArticle b) {
    final aTime = a.pubDate?.millisecondsSinceEpoch ?? 0;
    final bTime = b.pubDate?.millisecondsSinceEpoch ?? 0;
    if (aTime != bTime) return bTime.compareTo(aTime);
    return a.title.compareTo(b.title);
  }

  Future<void> _updateLastFetched(String url) async {
    await _repository.updateLastFetched(url, _clock());
  }
}

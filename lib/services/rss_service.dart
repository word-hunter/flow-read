import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../models/rss_models.dart';

class RssService {
  static const _boxName = 'rss_subscriptions';
  static const _readArticlesKey = 'rss_read_articles';
  Box<RssFeedSubscription>? _feedBox;
  Box? _metaBox;
  final Map<String, List<RssArticle>> _articleCache = {};
  final Set<String> _readArticleIds = {};

  Future<void> init() async {
    _feedBox = Hive.box<RssFeedSubscription>(_boxName);
    _metaBox = Hive.box('settings');

    final readIdsJson = _metaBox?.get(_readArticlesKey);
    if (readIdsJson != null && readIdsJson.isNotEmpty) {
      final list = jsonDecode(readIdsJson) as List<dynamic>;
      _readArticleIds.addAll(list.cast<String>());
    }
  }

  List<RssFeedSubscription> get subscriptions =>
      _feedBox?.values.toList() ?? [];

  Future<RssFeedSubscription> addSubscription(String url) async {
    final normalizedUrl = _normalizeUrl(url);
    final existing = subscriptions
        .where((s) => s.url == normalizedUrl)
        .firstOrNull;
    if (existing != null) return existing;

    final info = await _fetchFeedInfo(normalizedUrl);
    final sub = RssFeedSubscription(
      url: normalizedUrl,
      title: info['title'] ?? normalizedUrl,
      description: info['description'],
      imageUrl: info['imageUrl'],
      lastFetchedAt: DateTime.now(),
    );
    await _feedBox?.add(sub);
    return sub;
  }

  Future<void> removeSubscription(String url) async {
    final box = _feedBox;
    if (box == null) return;
    final key = box.keys.firstWhere(
      (k) => box.get(k)?.url == url,
      orElse: () => -1,
    );
    if (key != -1) {
      await box.delete(key);
      _articleCache.remove(url);
    }
  }

  Future<List<RssArticle>> fetchArticles(String feedUrl) async {
    final cached = _articleCache[feedUrl];
    if (cached != null) return cached;

    try {
      final response = await http
          .get(Uri.parse(feedUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];

      final body = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(body);
      final articles = _parseFeed(document, feedUrl);

      for (final a in articles) {
        if (_readArticleIds.contains(a.id)) {
          a.isRead = true;
        }
      }

      _articleCache[feedUrl] = articles;
      _updateLastFetched(feedUrl);
      return articles;
    } catch (_) {
      return cached ?? [];
    }
  }

  Future<void> markAsRead(String articleId) async {
    _readArticleIds.add(articleId);
    await _metaBox?.put(_readArticlesKey, jsonEncode(_readArticleIds.toList()));
    for (final articles in _articleCache.values) {
      for (final a in articles) {
        if (a.id == articleId) a.isRead = true;
      }
    }
  }

  Future<void> markAsUnread(String articleId) async {
    _readArticleIds.remove(articleId);
    await _metaBox?.put(_readArticlesKey, jsonEncode(_readArticleIds.toList()));
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

  Future<Map<String, String?>> _fetchFeedInfo(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return {};

      final body = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(body);

      final channel = document.findAllElements('channel').firstOrNull;
      final feedEl = document.findAllElements('feed').firstOrNull;

      if (channel != null) {
        return {
          'title': channel.findElements('title').firstOrNull?.innerText,
          'description': channel
              .findElements('description')
              .firstOrNull
              ?.innerText,
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
          'title': feedEl.findElements('title').firstOrNull?.innerText,
          'description': feedEl.findElements('subtitle').firstOrNull?.innerText,
          'imageUrl': feedEl.findElements('logo').firstOrNull?.innerText,
        };
      }
    } catch (_) {}
    return {};
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
    final items = document.findAllElements('item');
    return items.map((item) {
      final description = item
          .findElements('description')
          .firstOrNull
          ?.innerText;
      return RssArticle(
        feedUrl: feedUrl,
        title: item.findElements('title').firstOrNull?.innerText ?? 'Untitled',
        link: item.findElements('link').firstOrNull?.innerText,
        description: description != null ? _stripHtml(description) : null,
        pubDate: _parseDate(
          item.findElements('pubDate').firstOrNull?.innerText,
        ),
        author:
            item.findElements('author').firstOrNull?.innerText ??
            item.findElements('dc:creator').firstOrNull?.innerText,
      );
    }).toList();
  }

  List<RssArticle> _parseAtom(XmlDocument document, String feedUrl) {
    final entries = document.findAllElements('entry');
    return entries.map((entry) {
      final summary =
          entry.findElements('summary').firstOrNull?.innerText ??
          entry.findElements('content').firstOrNull?.innerText;
      return RssArticle(
        feedUrl: feedUrl,
        title: entry.findElements('title').firstOrNull?.innerText ?? 'Untitled',
        link: entry.findElements('link').firstOrNull?.getAttribute('href'),
        description: summary != null ? _stripHtml(summary) : null,
        pubDate: _parseDate(
          entry.findElements('published').firstOrNull?.innerText ??
              entry.findElements('updated').firstOrNull?.innerText,
        ),
        author: entry
            .findElements('author')
            .firstOrNull
            ?.findElements('name')
            .firstOrNull
            ?.innerText,
      );
    }).toList();
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        final cleaned = dateStr
            .replaceAll(
              RegExp(r'\s+(?:GMT|UTC|EST|EDT|CST|CDT|MST|MDT|PST|PDT)$'),
              '',
            )
            .replaceAll(RegExp(r'\s+[+-]\d{4}$'), '')
            .trim();
        return DateTime.parse(cleaned);
      } catch (_) {
        return null;
      }
    }
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

  void _updateLastFetched(String url) {
    final box = _feedBox;
    if (box == null) return;
    final key = box.keys.firstWhere(
      (k) => box.get(k)?.url == url,
      orElse: () => -1,
    );
    if (key != -1) {
      final sub = box.get(key);
      if (sub != null) {
        sub.lastFetchedAt = DateTime.now();
        sub.save();
      }
    }
  }
}

import 'package:flutter/foundation.dart';

import '../models/rss_models.dart';
import '../services/app_logger.dart';
import '../services/rss_service.dart';

class RssProvider extends ChangeNotifier {
  RssProvider({RssFeedService? service}) : _service = service ?? RssService();

  final RssFeedService _service;

  List<RssFeedSubscription> _subscriptions = [];
  String? _selectedFeedUrl;
  List<RssArticle> _articles = [];
  bool _isLoading = false;
  bool _isFetchingArticles = false;
  String? _errorMessage;
  String _articleQuery = '';

  // ---- getters ----

  List<RssFeedSubscription> get subscriptions => _subscriptions;
  String? get selectedFeedUrl => _selectedFeedUrl;
  bool get isLatestSelected => _selectedFeedUrl == null;
  RssFeedSubscription? get selectedFeed {
    if (_selectedFeedUrl == null) return null;
    return _subscriptions.where((s) => s.url == _selectedFeedUrl).firstOrNull;
  }

  List<RssArticle> get articles => _articles;
  List<RssArticle> get visibleArticles {
    final query = _articleQuery.trim().toLowerCase();
    if (query.isEmpty) return _articles;
    return _articles.where((article) {
      return article.title.toLowerCase().contains(query) ||
          (article.description?.toLowerCase().contains(query) ?? false) ||
          (article.content?.toLowerCase().contains(query) ?? false) ||
          article.feedTitle.toLowerCase().contains(query);
    }).toList();
  }

  bool get isLoading => _isLoading;
  bool get isFetchingArticles => _isFetchingArticles;
  String? get errorMessage => _errorMessage;
  String get articleQuery => _articleQuery;
  int get unreadCount => visibleArticles.where((a) => !a.isRead).length;
  String get currentTitle =>
      isLatestSelected ? '最新内容' : (selectedFeed?.title ?? 'RSS');

  // ---- init ----

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.init();
      _subscriptions = _service.subscriptions;
      if (_subscriptions.isNotEmpty) {
        _articles = await _service.fetchLatestArticles();
      }
    } catch (error, stackTrace) {
      AppLogger.instance.event(
        'rss.init_failed',
        level: AppLogLevel.warning,
        source: 'rss_provider',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = '加载 RSS 失败: $error';
    }
    _isLoading = false;
    notifyListeners();
  }

  // ---- actions ----

  Future<void> addFeed(String url) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      final sub = await _service.addSubscription(url);
      _subscriptions = _service.subscriptions;
      _selectedFeedUrl = sub.url;
      _articleQuery = '';
      await fetchArticlesForSelectedFeed();
    } catch (error, stackTrace) {
      AppLogger.instance.event(
        'rss.add_feed_failed',
        level: AppLogLevel.warning,
        source: 'rss_provider',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = '添加订阅失败: $error';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateFeed({
    required String originalUrl,
    required String url,
    required String title,
    String? description,
    bool refreshMetadata = false,
  }) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      final updated = await _service.updateSubscription(
        originalUrl: originalUrl,
        url: url,
        title: title,
        description: description,
        refreshMetadata: refreshMetadata,
      );
      _subscriptions = _service.subscriptions;
      if (_selectedFeedUrl == originalUrl) {
        _selectedFeedUrl = updated?.url;
        await fetchArticlesForSelectedFeed();
      } else if (_selectedFeedUrl == null) {
        await fetchArticlesForSelectedFeed();
      }
    } catch (error, stackTrace) {
      AppLogger.instance.event(
        'rss.update_feed_failed',
        level: AppLogLevel.warning,
        source: 'rss_provider',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = '更新订阅失败: $error';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> removeFeed(String url) async {
    await _service.removeSubscription(url);
    _service.clearArticleCache(url);
    _subscriptions = _service.subscriptions;
    if (_selectedFeedUrl == url) {
      _selectedFeedUrl = null;
      _articles = [];
      if (_subscriptions.isNotEmpty) {
        await fetchArticlesForSelectedFeed();
      }
    } else if (_selectedFeedUrl == null) {
      await fetchArticlesForSelectedFeed();
    }
    notifyListeners();
  }

  void selectLatest() {
    if (_selectedFeedUrl == null) return;
    _selectedFeedUrl = null;
    _articles = [];
    notifyListeners();
    fetchArticlesForSelectedFeed();
  }

  void selectFeed(String url) {
    if (url == _selectedFeedUrl) return;
    _selectedFeedUrl = url;
    _articles = [];
    notifyListeners();
    fetchArticlesForSelectedFeed();
  }

  Future<void> fetchArticlesForSelectedFeed() async {
    if (_subscriptions.isEmpty) {
      _articles = [];
      notifyListeners();
      return;
    }
    _isFetchingArticles = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _articles = _selectedFeedUrl == null
          ? await _service.fetchLatestArticles()
          : await _service.fetchArticles(_selectedFeedUrl!);
    } catch (error, stackTrace) {
      AppLogger.instance.event(
        'rss.fetch_articles_failed',
        level: AppLogLevel.warning,
        source: 'rss_provider',
        metadata: {'mode': _selectedFeedUrl == null ? 'latest' : 'feed'},
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = '获取文章失败: $error';
    }
    _isFetchingArticles = false;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    if (_selectedFeedUrl == null) {
      _service.clearArticleCache();
    } else {
      _service.clearArticleCache(_selectedFeedUrl);
    }
    await fetchArticlesForSelectedFeed();
  }

  Future<void> markAsRead(String articleId) async {
    await _service.markAsRead(articleId);
    notifyListeners();
  }

  Future<void> markAsUnread(String articleId) async {
    await _service.markAsUnread(articleId);
    notifyListeners();
  }

  void updateArticleQuery(String query) {
    _articleQuery = query;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

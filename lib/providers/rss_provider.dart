import 'package:flutter/foundation.dart';

import '../models/rss_models.dart';
import '../services/rss_service.dart';

class RssProvider extends ChangeNotifier {
  final RssService _service = RssService();

  List<RssFeedSubscription> _subscriptions = [];
  String? _selectedFeedUrl;
  List<RssArticle> _articles = [];
  bool _isLoading = false;
  bool _isFetchingArticles = false;
  String? _errorMessage;

  // ---- getters ----

  List<RssFeedSubscription> get subscriptions => _subscriptions;
  String? get selectedFeedUrl => _selectedFeedUrl;
  RssFeedSubscription? get selectedFeed {
    if (_selectedFeedUrl == null) return null;
    return _subscriptions.where((s) => s.url == _selectedFeedUrl).firstOrNull;
  }
  List<RssArticle> get articles => _articles;
  bool get isLoading => _isLoading;
  bool get isFetchingArticles => _isFetchingArticles;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _articles.where((a) => !a.isRead).length;

  // ---- init ----

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    await _service.init();
    _subscriptions = _service.subscriptions;
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
      await fetchArticlesForSelectedFeed();
    } catch (e) {
      _errorMessage = '添加订阅失败: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> removeFeed(String url) async {
    await _service.removeSubscription(url);
    _service.clearArticleCache(url);
    _subscriptions = _service.subscriptions;
    if (_selectedFeedUrl == url) {
      _selectedFeedUrl = _subscriptions.firstOrNull?.url;
      _articles = [];
      if (_selectedFeedUrl != null) {
        await fetchArticlesForSelectedFeed();
      }
    }
    notifyListeners();
  }

  void selectFeed(String url) {
    if (url == _selectedFeedUrl) return;
    _selectedFeedUrl = url;
    _articles = [];
    notifyListeners();
    fetchArticlesForSelectedFeed();
  }

  Future<void> fetchArticlesForSelectedFeed() async {
    if (_selectedFeedUrl == null) return;
    _isFetchingArticles = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _articles = await _service.fetchArticles(_selectedFeedUrl!);
    } catch (e) {
      _errorMessage = '获取文章失败: $e';
    }
    _isFetchingArticles = false;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    _service.clearArticleCache();
    if (_selectedFeedUrl != null) {
      await fetchArticlesForSelectedFeed();
    }
  }

  void markAsRead(String articleId) {
    _service.markAsRead(articleId);
    notifyListeners();
  }

  void markAsUnread(String articleId) {
    _service.markAsUnread(articleId);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flow_rss/flow_rss.dart';
import '../services/app_logger.dart';
import 'package:flow_rss/flow_rss.dart';

class RssProvider extends ChangeNotifier {
  RssProvider({RssFeedService? service}) : _service = service ?? RssService();

  final RssFeedService _service;

  List<RssFeedSubscription> _subscriptions = [];
  String? _selectedFeedUrl;
  List<RssArticle> _articles = [];
  RssLoadStatus _subscriptionStatus = RssLoadStatus.idle;
  RssLoadStatus _articlesStatus = RssLoadStatus.idle;
  RssError? _subscriptionError;
  RssError? _articlesError;
  String _articleQuery = '';
  RssArticleFilter _articleFilter = RssArticleFilter.all;

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
    return _filteredArticles(_articleFilter);
  }

  List<RssArticle> _queryMatchedArticles() {
    final query = _articleQuery.trim().toLowerCase();
    if (query.isEmpty) return _articles;
    return _articles.where((article) {
      return article.title.toLowerCase().contains(query) ||
          (article.description?.toLowerCase().contains(query) ?? false) ||
          (article.content?.toLowerCase().contains(query) ?? false) ||
          article.feedTitle.toLowerCase().contains(query);
    }).toList();
  }

  List<RssArticle> _filteredArticles(RssArticleFilter filter) {
    return _queryMatchedArticles().where((article) {
      return switch (filter) {
        RssArticleFilter.all => true,
        RssArticleFilter.unread => !article.isRead,
        RssArticleFilter.favorite => article.isFavorite,
        RssArticleFilter.readLater => article.isReadLater,
      };
    }).toList();
  }

  RssLoadStatus get subscriptionStatus => _subscriptionStatus;
  RssLoadStatus get articlesStatus => _articlesStatus;
  RssError? get subscriptionError => _subscriptionError;
  RssError? get articlesError => _articlesError;
  bool get isLoading =>
      _subscriptionStatus == RssLoadStatus.loading ||
      _articlesStatus == RssLoadStatus.loading;
  bool get isFetchingArticles => _articlesStatus == RssLoadStatus.loading;
  String? get errorMessage =>
      _subscriptionError?.message ?? _articlesError?.message;
  String get articleQuery => _articleQuery;
  RssArticleFilter get articleFilter => _articleFilter;
  int get unreadCount => visibleArticles.where((a) => !a.isRead).length;
  int articleCountForFilter(RssArticleFilter filter) {
    return _filteredArticles(filter).length;
  }

  String get currentTitle =>
      isLatestSelected ? '最新内容' : (selectedFeed?.title ?? 'RSS');

  // ---- init ----

  Future<void> init() async {
    _subscriptionStatus = RssLoadStatus.loading;
    _articlesStatus = RssLoadStatus.idle;
    _subscriptionError = null;
    _articlesError = null;
    notifyListeners();
    try {
      await _service.init();
    } catch (error, stackTrace) {
      AppLogger.instance.event(
        'rss.init_failed',
        level: AppLogLevel.warning,
        source: 'rss_provider',
        error: error,
        stackTrace: stackTrace,
      );
      _subscriptionStatus = RssLoadStatus.error;
      _subscriptionError = _classifyError(error, stackTrace);
      notifyListeners();
      return;
    }

    _subscriptions = _service.subscriptions;
    _subscriptionStatus = _statusForItems(_subscriptions);
    _subscriptionError = null;
    if (_subscriptions.isEmpty) {
      _articles = [];
      _articlesStatus = RssLoadStatus.empty;
      notifyListeners();
      return;
    }

    notifyListeners();
    await _loadArticles();
  }

  // ---- actions ----

  Future<void> addFeed(String url) async {
    _subscriptionError = null;
    _articlesError = null;
    _subscriptionStatus = RssLoadStatus.loading;
    notifyListeners();
    try {
      final sub = await _service.addSubscription(url);
      _subscriptions = _service.subscriptions;
      _selectedFeedUrl = sub.url;
      _articleQuery = '';
      _articleFilter = RssArticleFilter.all;
      _subscriptionStatus = RssLoadStatus.loaded;
      _subscriptionError = null;
      notifyListeners();
      await fetchArticlesForSelectedFeed();
    } catch (error, stackTrace) {
      AppLogger.instance.event(
        'rss.add_feed_failed',
        level: AppLogLevel.warning,
        source: 'rss_provider',
        error: error,
        stackTrace: stackTrace,
      );
      _subscriptionStatus = RssLoadStatus.error;
      _subscriptionError = _classifyError(
        error,
        stackTrace,
        fallbackMessage: '添加订阅失败',
      );
      notifyListeners();
    }
  }

  Future<void> updateFeed({
    required String originalUrl,
    required String url,
    required String title,
    String? description,
    bool refreshMetadata = false,
  }) async {
    _subscriptionError = null;
    _articlesError = null;
    _subscriptionStatus = RssLoadStatus.loading;
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
        _subscriptionStatus = _statusForItems(_subscriptions);
        notifyListeners();
        await fetchArticlesForSelectedFeed();
      } else if (_selectedFeedUrl == null) {
        _subscriptionStatus = _statusForItems(_subscriptions);
        notifyListeners();
        await fetchArticlesForSelectedFeed();
      } else {
        _subscriptionStatus = _statusForItems(_subscriptions);
        notifyListeners();
      }
    } catch (error, stackTrace) {
      AppLogger.instance.event(
        'rss.update_feed_failed',
        level: AppLogLevel.warning,
        source: 'rss_provider',
        error: error,
        stackTrace: stackTrace,
      );
      _subscriptionStatus = RssLoadStatus.error;
      _subscriptionError = _classifyError(
        error,
        stackTrace,
        fallbackMessage: '更新订阅失败',
      );
      notifyListeners();
    }
  }

  Future<void> removeFeed(String url) async {
    _subscriptionError = null;
    _articlesError = null;
    _subscriptionStatus = RssLoadStatus.loading;
    notifyListeners();
    try {
      await _service.removeSubscription(url);
      _service.clearArticleCache(url);
      _subscriptions = _service.subscriptions;
      _subscriptionStatus = _statusForItems(_subscriptions);
      if (_selectedFeedUrl == url) {
        _selectedFeedUrl = null;
        _articles = [];
        _articlesStatus = _subscriptions.isEmpty
            ? RssLoadStatus.empty
            : RssLoadStatus.idle;
        notifyListeners();
        if (_subscriptions.isNotEmpty) {
          await fetchArticlesForSelectedFeed();
        }
      } else if (_selectedFeedUrl == null) {
        notifyListeners();
        await fetchArticlesForSelectedFeed();
      } else {
        notifyListeners();
      }
    } catch (error, stackTrace) {
      AppLogger.instance.event(
        'rss.remove_feed_failed',
        level: AppLogLevel.warning,
        source: 'rss_provider',
        error: error,
        stackTrace: stackTrace,
      );
      _subscriptionStatus = RssLoadStatus.error;
      _subscriptionError = _classifyError(
        error,
        stackTrace,
        fallbackMessage: '移除订阅失败',
      );
      notifyListeners();
    }
  }

  void selectLatest() {
    if (_selectedFeedUrl == null) return;
    _selectedFeedUrl = null;
    _articles = [];
    _articleFilter = RssArticleFilter.all;
    notifyListeners();
    fetchArticlesForSelectedFeed();
  }

  void selectFeed(String url) {
    if (url == _selectedFeedUrl) return;
    _selectedFeedUrl = url;
    _articles = [];
    _articleFilter = RssArticleFilter.all;
    notifyListeners();
    fetchArticlesForSelectedFeed();
  }

  Future<void> fetchArticlesForSelectedFeed() async {
    await _loadArticles();
  }

  Future<void> _loadArticles({bool forceRefresh = false}) async {
    if (_subscriptions.isEmpty) {
      _articles = [];
      _articlesStatus = RssLoadStatus.empty;
      _articlesError = null;
      notifyListeners();
      return;
    }
    _articlesStatus = RssLoadStatus.loading;
    _articlesError = null;
    notifyListeners();
    try {
      _articles = _selectedFeedUrl == null
          ? await _service.fetchLatestArticles(forceRefresh: forceRefresh)
          : await _service.fetchArticles(
              _selectedFeedUrl!,
              forceRefresh: forceRefresh,
            );
      _articlesStatus = _articles.isEmpty
          ? RssLoadStatus.empty
          : RssLoadStatus.loaded;
      _articlesError = null;
    } catch (error, stackTrace) {
      AppLogger.instance.event(
        'rss.fetch_articles_failed',
        level: AppLogLevel.warning,
        source: 'rss_provider',
        metadata: {'mode': _selectedFeedUrl == null ? 'latest' : 'feed'},
        error: error,
        stackTrace: stackTrace,
      );
      _articlesStatus = RssLoadStatus.error;
      _articlesError = _classifyError(
        error,
        stackTrace,
        fallbackMessage: '获取文章失败',
      );
    }
    notifyListeners();
  }

  Future<void> refreshAll() async {
    if (_selectedFeedUrl == null) {
      _service.clearArticleCache();
    } else {
      _service.clearArticleCache(_selectedFeedUrl);
    }
    await _loadArticles(forceRefresh: true);
  }

  Future<void> retry() async {
    if (_subscriptionStatus == RssLoadStatus.error) {
      await init();
      return;
    }
    if (_articlesStatus == RssLoadStatus.error) {
      await fetchArticlesForSelectedFeed();
    }
  }

  Future<void> markAsRead(String articleId) async {
    await _service.markAsRead(articleId);
    notifyListeners();
  }

  Future<void> markAsUnread(String articleId) async {
    await _service.markAsUnread(articleId);
    notifyListeners();
  }

  Future<void> setArticleFavorite(String articleId, bool isFavorite) async {
    await _service.setArticleFavorite(articleId, isFavorite);
    notifyListeners();
  }

  Future<void> setArticleReadLater(String articleId, bool isReadLater) async {
    await _service.setArticleReadLater(articleId, isReadLater);
    notifyListeners();
  }

  void updateArticleQuery(String query) {
    _articleQuery = query;
    notifyListeners();
  }

  void updateArticleFilter(RssArticleFilter filter) {
    if (_articleFilter == filter) return;
    _articleFilter = filter;
    notifyListeners();
  }

  void clearError() {
    _subscriptionError = null;
    _articlesError = null;
    if (_subscriptionStatus == RssLoadStatus.error) {
      _subscriptionStatus = _statusForItems(_subscriptions);
    }
    if (_articlesStatus == RssLoadStatus.error) {
      _articlesStatus = _statusForItems(_articles);
    }
    notifyListeners();
  }

  RssLoadStatus _statusForItems(List<Object?> items) {
    return items.isEmpty ? RssLoadStatus.empty : RssLoadStatus.loaded;
  }

  RssError _classifyError(
    Object error,
    StackTrace stackTrace, {
    String fallbackMessage = '加载失败',
  }) {
    final detail = error.toString();
    final normalized = detail.toLowerCase();
    if (error is SocketException ||
        error is HandshakeException ||
        error is TimeoutException ||
        normalized.contains('socketexception') ||
        normalized.contains('handshakeexception') ||
        normalized.contains('timeoutexception') ||
        normalized.contains('connection refused') ||
        normalized.contains('network')) {
      return RssError(
        type: RssErrorType.network,
        message: _networkErrorMessage(),
        detail: detail,
      );
    }
    if (error is FormatException ||
        normalized.contains('xmlparser') ||
        normalized.contains('format') ||
        normalized.contains('parse')) {
      return RssError(
        type: RssErrorType.parse,
        message: '无法解析该 RSS 源，格式可能不支持',
        detail: detail,
      );
    }
    return RssError(
      type: RssErrorType.unknown,
      message: '$fallbackMessage：$detail',
      detail: detail,
    );
  }

  String _networkErrorMessage() {
    if (!kIsWeb && Platform.isMacOS) {
      return '网络连接失败。请检查网络设置，或前往 设置 → 关于 → 系统权限 排查。';
    }
    return '网络连接失败，请检查网络设置';
  }
}

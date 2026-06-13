import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flow_rss/flow_rss.dart';
import '../services/app_logger.dart';
import '../storage/database/repositories/drift_rss_repository.dart';
import '../storage/hive_storage.dart';

final rssFeedServiceProvider = Provider<RssFeedService>((ref) {
  final db = appDatabase;
  if (db == null) return RssService();
  return RssService(repository: DriftRssRepository(db.rssDao));
});

@immutable
class RssState {
  const RssState({
    this.subscriptions = const [],
    this.selectedFeedUrl,
    this.articles = const [],
    this.subscriptionStatus = RssLoadStatus.idle,
    this.articlesStatus = RssLoadStatus.idle,
    this.subscriptionError,
    this.articlesError,
    this.articleQuery = '',
    this.articleFilter = RssArticleFilter.all,
  });

  final List<RssFeedSubscription> subscriptions;
  final String? selectedFeedUrl;
  final List<RssArticle> articles;
  final RssLoadStatus subscriptionStatus;
  final RssLoadStatus articlesStatus;
  final RssError? subscriptionError;
  final RssError? articlesError;
  final String articleQuery;
  final RssArticleFilter articleFilter;

  bool get isLatestSelected => selectedFeedUrl == null;
  bool get isLoading =>
      subscriptionStatus == RssLoadStatus.loading ||
      articlesStatus == RssLoadStatus.loading;
  bool get isFetchingArticles => articlesStatus == RssLoadStatus.loading;
  String? get errorMessage =>
      subscriptionError?.message ?? articlesError?.message;

  RssFeedSubscription? get selectedFeed {
    if (selectedFeedUrl == null) return null;
    return subscriptions.where((s) => s.url == selectedFeedUrl).firstOrNull;
  }

  String get currentTitle =>
      isLatestSelected ? '最新内容' : (selectedFeed?.title ?? 'RSS');

  List<RssArticle> get visibleArticles => _filteredArticles(articleFilter);

  int get unreadCount => visibleArticles.where((a) => !a.isRead).length;

  List<RssArticle> _queryMatchedArticles() {
    final query = articleQuery.trim().toLowerCase();
    if (query.isEmpty) return articles;
    return articles.where((article) {
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

  int articleCountForFilter(RssArticleFilter filter) {
    return _filteredArticles(filter).length;
  }

  RssState copyWith({
    List<RssFeedSubscription>? subscriptions,
    String? selectedFeedUrl,
    bool clearSelectedFeedUrl = false,
    List<RssArticle>? articles,
    RssLoadStatus? subscriptionStatus,
    RssLoadStatus? articlesStatus,
    RssError? subscriptionError,
    bool clearSubscriptionError = false,
    RssError? articlesError,
    bool clearArticlesError = false,
    String? articleQuery,
    RssArticleFilter? articleFilter,
  }) {
    return RssState(
      subscriptions: subscriptions ?? this.subscriptions,
      selectedFeedUrl: clearSelectedFeedUrl
          ? null
          : (selectedFeedUrl ?? this.selectedFeedUrl),
      articles: articles ?? this.articles,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      articlesStatus: articlesStatus ?? this.articlesStatus,
      subscriptionError: clearSubscriptionError
          ? null
          : (subscriptionError ?? this.subscriptionError),
      articlesError: clearArticlesError
          ? null
          : (articlesError ?? this.articlesError),
      articleQuery: articleQuery ?? this.articleQuery,
      articleFilter: articleFilter ?? this.articleFilter,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RssState &&
        other.subscriptions == subscriptions &&
        other.selectedFeedUrl == selectedFeedUrl &&
        other.articles == articles &&
        other.subscriptionStatus == subscriptionStatus &&
        other.articlesStatus == articlesStatus &&
        other.subscriptionError == subscriptionError &&
        other.articlesError == articlesError &&
        other.articleQuery == articleQuery &&
        other.articleFilter == articleFilter;
  }

  @override
  int get hashCode => Object.hash(
    subscriptions,
    selectedFeedUrl,
    articles,
    subscriptionStatus,
    articlesStatus,
    subscriptionError,
    articlesError,
    articleQuery,
    articleFilter,
  );
}

class RssNotifier extends Notifier<RssState> {
  RssFeedService get _service => ref.read(rssFeedServiceProvider);

  @override
  RssState build() {
    return const RssState();
  }

  // ---- init ----

  Future<void> init() async {
    state = state.copyWith(
      subscriptionStatus: RssLoadStatus.loading,
      articlesStatus: RssLoadStatus.idle,
      clearSubscriptionError: true,
      clearArticlesError: true,
    );
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
      state = state.copyWith(
        subscriptionStatus: RssLoadStatus.error,
        subscriptionError: _classifyError(error, stackTrace),
      );
      return;
    }

    final subs = _service.subscriptions;
    state = state.copyWith(
      subscriptions: subs,
      subscriptionStatus: _statusForItems(subs),
      clearSubscriptionError: true,
    );
    if (subs.isEmpty) {
      state = state.copyWith(
        articles: const [],
        articlesStatus: RssLoadStatus.empty,
      );
      return;
    }
    await _loadArticles();
  }

  // ---- actions ----

  Future<void> addFeed(String url) async {
    state = state.copyWith(
      clearSubscriptionError: true,
      clearArticlesError: true,
      subscriptionStatus: RssLoadStatus.loading,
    );
    try {
      final sub = await _service.addSubscription(url);
      final subs = _service.subscriptions;
      state = state.copyWith(
        subscriptions: subs,
        selectedFeedUrl: sub.url,
        articleQuery: '',
        articleFilter: RssArticleFilter.all,
        subscriptionStatus: RssLoadStatus.loaded,
        clearSubscriptionError: true,
      );
      await fetchArticlesForSelectedFeed();
    } catch (error, stackTrace) {
      AppLogger.instance.event(
        'rss.add_feed_failed',
        level: AppLogLevel.warning,
        source: 'rss_provider',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        subscriptionStatus: RssLoadStatus.error,
        subscriptionError: _classifyError(
          error,
          stackTrace,
          fallbackMessage: '添加订阅失败',
        ),
      );
    }
  }

  Future<void> updateFeed({
    required String originalUrl,
    required String url,
    required String title,
    String? description,
    bool refreshMetadata = false,
  }) async {
    state = state.copyWith(
      clearSubscriptionError: true,
      clearArticlesError: true,
      subscriptionStatus: RssLoadStatus.loading,
    );
    try {
      final updated = await _service.updateSubscription(
        originalUrl: originalUrl,
        url: url,
        title: title,
        description: description,
        refreshMetadata: refreshMetadata,
      );
      final subs = _service.subscriptions;
      if (state.selectedFeedUrl == originalUrl) {
        state = state.copyWith(
          subscriptions: subs,
          selectedFeedUrl: updated?.url,
          subscriptionStatus: _statusForItems(subs),
        );
        await fetchArticlesForSelectedFeed();
      } else if (state.selectedFeedUrl == null) {
        state = state.copyWith(
          subscriptions: subs,
          subscriptionStatus: _statusForItems(subs),
        );
        await fetchArticlesForSelectedFeed();
      } else {
        state = state.copyWith(
          subscriptions: subs,
          subscriptionStatus: _statusForItems(subs),
        );
      }
    } catch (error, stackTrace) {
      AppLogger.instance.event(
        'rss.update_feed_failed',
        level: AppLogLevel.warning,
        source: 'rss_provider',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        subscriptionStatus: RssLoadStatus.error,
        subscriptionError: _classifyError(
          error,
          stackTrace,
          fallbackMessage: '更新订阅失败',
        ),
      );
    }
  }

  Future<void> removeFeed(String url) async {
    state = state.copyWith(
      clearSubscriptionError: true,
      clearArticlesError: true,
      subscriptionStatus: RssLoadStatus.loading,
    );
    try {
      await _service.removeSubscription(url);
      _service.clearArticleCache(url);
      final subs = _service.subscriptions;
      if (state.selectedFeedUrl == url) {
        state = state.copyWith(
          subscriptions: subs,
          clearSelectedFeedUrl: true,
          articles: const [],
          articlesStatus: subs.isEmpty
              ? RssLoadStatus.empty
              : RssLoadStatus.idle,
          subscriptionStatus: _statusForItems(subs),
        );
        if (subs.isNotEmpty) {
          await fetchArticlesForSelectedFeed();
        }
      } else if (state.selectedFeedUrl == null) {
        state = state.copyWith(
          subscriptions: subs,
          subscriptionStatus: _statusForItems(subs),
        );
        await fetchArticlesForSelectedFeed();
      } else {
        state = state.copyWith(
          subscriptions: subs,
          subscriptionStatus: _statusForItems(subs),
        );
      }
    } catch (error, stackTrace) {
      AppLogger.instance.event(
        'rss.remove_feed_failed',
        level: AppLogLevel.warning,
        source: 'rss_provider',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        subscriptionStatus: RssLoadStatus.error,
        subscriptionError: _classifyError(
          error,
          stackTrace,
          fallbackMessage: '移除订阅失败',
        ),
      );
    }
  }

  void selectLatest() {
    if (state.selectedFeedUrl == null) return;
    state = state.copyWith(
      clearSelectedFeedUrl: true,
      articles: const [],
      articleFilter: RssArticleFilter.all,
    );
    fetchArticlesForSelectedFeed();
  }

  void selectFeed(String url) {
    if (url == state.selectedFeedUrl) return;
    state = state.copyWith(
      selectedFeedUrl: url,
      articles: const [],
      articleFilter: RssArticleFilter.all,
    );
    fetchArticlesForSelectedFeed();
  }

  Future<void> fetchArticlesForSelectedFeed() async {
    await _loadArticles();
  }

  Future<void> _loadArticles({bool forceRefresh = false}) async {
    if (state.subscriptions.isEmpty) {
      state = state.copyWith(
        articles: const [],
        articlesStatus: RssLoadStatus.empty,
        clearArticlesError: true,
      );
      return;
    }
    state = state.copyWith(
      articlesStatus: RssLoadStatus.loading,
      clearArticlesError: true,
    );
    try {
      final loadedArticles = state.selectedFeedUrl == null
          ? await _service.fetchLatestArticles(forceRefresh: forceRefresh)
          : await _service.fetchArticles(
              state.selectedFeedUrl!,
              forceRefresh: forceRefresh,
            );
      state = state.copyWith(
        articles: loadedArticles,
        articlesStatus: loadedArticles.isEmpty
            ? RssLoadStatus.empty
            : RssLoadStatus.loaded,
        clearArticlesError: true,
      );
    } catch (error, stackTrace) {
      AppLogger.instance.event(
        'rss.fetch_articles_failed',
        level: AppLogLevel.warning,
        source: 'rss_provider',
        metadata: {'mode': state.selectedFeedUrl == null ? 'latest' : 'feed'},
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        articlesStatus: RssLoadStatus.error,
        articlesError: _classifyError(
          error,
          stackTrace,
          fallbackMessage: '获取文章失败',
        ),
      );
    }
  }

  Future<void> refreshAll() async {
    if (state.selectedFeedUrl == null) {
      _service.clearArticleCache();
    } else {
      _service.clearArticleCache(state.selectedFeedUrl);
    }
    await _loadArticles(forceRefresh: true);
  }

  Future<void> retry() async {
    if (state.subscriptionStatus == RssLoadStatus.error) {
      await init();
      return;
    }
    if (state.articlesStatus == RssLoadStatus.error) {
      await fetchArticlesForSelectedFeed();
    }
  }

  Future<void> markAsRead(String articleId) async {
    await _service.markAsRead(articleId);
    _refreshArticlesFromService();
  }

  Future<void> markAsUnread(String articleId) async {
    await _service.markAsUnread(articleId);
    _refreshArticlesFromService();
  }

  Future<void> setArticleFavorite(String articleId, bool isFavorite) async {
    await _service.setArticleFavorite(articleId, isFavorite);
    _refreshArticlesFromService();
  }

  Future<void> setArticleReadLater(String articleId, bool isReadLater) async {
    await _service.setArticleReadLater(articleId, isReadLater);
    _refreshArticlesFromService();
  }

  void updateArticleQuery(String query) {
    state = state.copyWith(articleQuery: query);
  }

  void updateArticleFilter(RssArticleFilter filter) {
    if (state.articleFilter == filter) return;
    state = state.copyWith(articleFilter: filter);
  }

  void clearError() {
    state = _clearErrorState(state);
  }

  RssState _clearErrorState(RssState s) {
    return s.copyWith(
      clearSubscriptionError: true,
      clearArticlesError: true,
      subscriptionStatus: s.subscriptionStatus == RssLoadStatus.error
          ? _statusForItems(s.subscriptions)
          : null,
      articlesStatus: s.articlesStatus == RssLoadStatus.error
          ? _statusForItems(s.articles)
          : null,
    );
  }

  void _refreshArticlesFromService() {
    state = state.copyWith(
      articles: List<RssArticle>.from(state.articles),
    );
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

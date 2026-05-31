import 'package:flow_read/models/rss_models.dart';
import 'package:flow_read/providers/rss_provider.dart';
import 'package:flow_read/services/rss_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('provider surfaces fetch failures from an injected service', () async {
    final provider = RssProvider(
      service: _FakeRssFeedService(
        subscriptions: [
          RssFeedSubscription(
            url: 'https://example.com/rss.xml',
            title: 'Example',
          ),
        ],
        latestError: StateError('network down'),
      ),
    );
    addTearDown(provider.dispose);

    await provider.init();

    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, contains('network down'));
    expect(provider.articles, isEmpty);
  });
}

class _FakeRssFeedService implements RssFeedService {
  _FakeRssFeedService({
    List<RssFeedSubscription>? subscriptions,
    this.latestError,
  }) : _subscriptions = subscriptions ?? [];

  final List<RssFeedSubscription> _subscriptions;
  final Object? latestError;

  @override
  Future<void> init() async {}

  @override
  List<RssFeedSubscription> get subscriptions => _subscriptions;

  @override
  Future<RssFeedSubscription> addSubscription(String url) async {
    throw UnimplementedError();
  }

  @override
  Future<RssFeedSubscription?> updateSubscription({
    required String originalUrl,
    required String url,
    required String title,
    String? description,
    bool refreshMetadata = false,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> removeSubscription(String url) async {}

  @override
  Future<List<RssArticle>> fetchArticles(
    String feedUrl, {
    bool forceRefresh = false,
  }) async {
    return const [];
  }

  @override
  Future<List<RssArticle>> fetchLatestArticles({
    bool forceRefresh = false,
  }) async {
    final error = latestError;
    if (error != null) throw error;
    return const [];
  }

  @override
  Future<void> markAsRead(String articleId) async {}

  @override
  Future<void> markAsUnread(String articleId) async {}

  @override
  void clearArticleCache([String? feedUrl]) {}
}

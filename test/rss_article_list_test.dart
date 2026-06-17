import 'package:flow_rss/flow_rss.dart';
import 'package:flow_read/widgets/rss/rss_article_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('article list opens article from card tap', (tester) async {
    RssArticle? opened;
    final article = RssArticle(
      feedUrl: 'https://example.com/rss.xml',
      feedTitle: 'Example',
      title: 'Readable article',
      link: 'https://example.com/article',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RssArticleList(
            articles: [article],
            feedTitle: 'Example',
            unreadCount: 1,
            query: '',
            filter: RssArticleFilter.all,
            filterCounts: _filterCounts([article]),
            articlesStatus: RssLoadStatus.loaded,
            hasCachedArticles: true,
            showFeedName: false,
            onRefresh: () async {},
            onRetry: () {},
            onSearchChanged: (_) {},
            onFilterChanged: (_) {},
            onMarkRead: (_) async {},
            onOpenArticle: (value) => opened = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Readable article'));
    await tester.pump();

    expect(opened, article);
    expect(find.byTooltip('查看原文'), findsNothing);
    expect(find.byTooltip('标记已读'), findsNothing);
    expect(find.byTooltip('标记未读'), findsNothing);
  });

  testWidgets('article list keeps cards compact with source and time', (
    tester,
  ) async {
    final publishedAt = DateTime.now().subtract(const Duration(hours: 2));
    final article = RssArticle(
      feedUrl: 'https://example.com/rss.xml',
      feedTitle: 'Feed label',
      title: 'Compact article',
      link: 'https://example.com/article',
      description: 'Description preview should stay in the detail pane.',
      content: 'Body paragraph should stay out of the list card.',
      author: 'Sarah Perez',
      pubDate: publishedAt,
      images: const [
        RssArticleImage(
          url: 'https://example.com/images/photo.png',
          alt: 'Photo',
          width: 800,
          height: 400,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RssArticleList(
            articles: [article],
            feedTitle: 'Example',
            unreadCount: 1,
            query: '',
            filter: RssArticleFilter.all,
            filterCounts: _filterCounts([article]),
            articlesStatus: RssLoadStatus.loaded,
            hasCachedArticles: true,
            showFeedName: true,
            showTitleRow: false,
            onRefresh: () async {},
            onRetry: () {},
            onSearchChanged: (_) {},
            onFilterChanged: (_) {},
            onMarkRead: (_) async {},
          ),
        ),
      ),
    );

    expect(find.text('Compact article'), findsOneWidget);
    expect(find.text('Feed label'), findsOneWidget);
    expect(find.text('2h'), findsOneWidget);
    expect(
      find.text('Description preview should stay in the detail pane.'),
      findsNothing,
    );
    expect(
      find.text('Body paragraph should stay out of the list card.'),
      findsNothing,
    );
    expect(find.text('Sarah Perez'), findsNothing);
    expect(find.byTooltip('查看原文'), findsNothing);
    expect(find.byTooltip('标记已读'), findsNothing);
    expect(find.byTooltip('标记未读'), findsNothing);
  });

  testWidgets('article list exposes primary filters and read action', (
    tester,
  ) async {
    RssArticleFilter? selectedFilter;
    String? markedReadArticleId;
    final article = RssArticle(
      feedUrl: 'https://example.com/rss.xml',
      feedTitle: 'Example',
      title: 'Action article',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RssArticleList(
            articles: [article],
            feedTitle: 'Example',
            unreadCount: 1,
            query: '',
            filter: RssArticleFilter.all,
            filterCounts: _filterCounts([article]),
            articlesStatus: RssLoadStatus.loaded,
            hasCachedArticles: true,
            showFeedName: false,
            onRefresh: () async {},
            onRetry: () {},
            onSearchChanged: (_) {},
            onFilterChanged: (filter) => selectedFilter = filter,
            onMarkRead: (id) async => markedReadArticleId = id,
          ),
        ),
      ),
    );

    expect(find.text('全部 1'), findsOneWidget);
    expect(find.text('未读 1'), findsOneWidget);
    expect(find.text('收藏'), findsNothing);
    expect(find.text('稍后读'), findsNothing);

    await tester.tap(find.text('未读 1'));
    await tester.pump();
    expect(selectedFilter, RssArticleFilter.unread);

    await tester.tap(find.text('Action article'));
    await tester.pump();
    expect(markedReadArticleId, article.id);
  });
}

Map<RssArticleFilter, int> _filterCounts(List<RssArticle> articles) {
  return {
    RssArticleFilter.all: articles.length,
    RssArticleFilter.unread: articles
        .where((article) => !article.isRead)
        .length,
    RssArticleFilter.favorite: articles
        .where((article) => article.isFavorite)
        .length,
    RssArticleFilter.readLater: articles
        .where((article) => article.isReadLater)
        .length,
  };
}

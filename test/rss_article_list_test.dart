import 'package:flow_read/models/rss_models.dart';
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/widgets/rss/rss_article_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_read_image_viewer/flow_read_image_viewer.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('article list exposes original article action', (tester) async {
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
            showFeedName: false,
            onRefresh: () {},
            onSearchChanged: (_) {},
            onFilterChanged: (_) {},
            onMarkRead: (_) async {},
            onMarkUnread: (_) async {},
            onSetFavorite: (_, _) async {},
            onSetReadLater: (_, _) async {},
            onOpenOriginal: (value) => opened = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('查看原文'));
    await tester.pump();

    expect(opened, article);
  });

  testWidgets('expanded article image opens the shared image viewer', (
    tester,
  ) async {
    final article = RssArticle(
      feedUrl: 'https://example.com/rss.xml',
      feedTitle: 'Example',
      title: 'Picture article',
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
            showFeedName: false,
            onRefresh: () {},
            onSearchChanged: (_) {},
            onFilterChanged: (_) {},
            onMarkRead: (_) async {},
            onMarkUnread: (_) async {},
            onSetFavorite: (_, _) async {},
            onSetReadLater: (_, _) async {},
            onOpenOriginal: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Picture article'));
    await tester.pumpAndSettle();

    expect(find.byType(ReadableImagePreview), findsOneWidget);

    await tester.tap(find.byType(ReadableImagePreview));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byTooltip('下载图片'), findsOneWidget);
  });

  testWidgets('expanded article renders structured body blocks in order', (
    tester,
  ) async {
    final article = RssArticle(
      feedUrl: 'https://example.com/rss.xml',
      feedTitle: 'Example',
      title: 'Structured article',
      content:
          'Section title\n\nFirst paragraph.\n\nFirst point\n\nQuoted line',
      bodyBlocks: const [
        RssArticleTextBlock(
          type: RssArticleTextBlockType.heading,
          text: 'Section title',
          headingLevel: 2,
        ),
        RssArticleTextBlock(
          type: RssArticleTextBlockType.paragraph,
          text: 'First paragraph.',
        ),
        RssArticleTextBlock(
          type: RssArticleTextBlockType.listItem,
          text: 'First point',
          indent: 1,
        ),
        RssArticleTextBlock(
          type: RssArticleTextBlockType.blockquote,
          text: 'Quoted line',
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ReadingProvider()),
          ChangeNotifierProvider(create: (_) => SettingsService()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RssArticleList(
              articles: [article],
              feedTitle: 'Example',
              unreadCount: 1,
              query: '',
              filter: RssArticleFilter.all,
              filterCounts: _filterCounts([article]),
              showFeedName: false,
              onRefresh: () {},
              onSearchChanged: (_) {},
              onFilterChanged: (_) {},
              onMarkRead: (_) async {},
              onMarkUnread: (_) async {},
              onSetFavorite: (_, _) async {},
              onSetReadLater: (_, _) async {},
              onOpenOriginal: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Structured article'));
    await tester.pumpAndSettle();

    expect(_richTextContaining('Section title'), findsOneWidget);
    expect(_richTextContaining('First paragraph.'), findsOneWidget);
    expect(_richTextContaining('First point'), findsOneWidget);
    expect(_richTextContaining('Quoted line'), findsOneWidget);
    expect(find.text('•'), findsOneWidget);
  });

  testWidgets('article list exposes filters and article state actions', (
    tester,
  ) async {
    RssArticleFilter? selectedFilter;
    String? favoriteArticleId;
    bool? favoriteValue;
    String? readLaterArticleId;
    bool? readLaterValue;
    final article = RssArticle(
      feedUrl: 'https://example.com/rss.xml',
      feedTitle: 'Example',
      title: 'Action article',
      isFavorite: false,
      isReadLater: true,
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
            showFeedName: false,
            onRefresh: () {},
            onSearchChanged: (_) {},
            onFilterChanged: (filter) => selectedFilter = filter,
            onMarkRead: (_) async {},
            onMarkUnread: (_) async {},
            onSetFavorite: (id, value) async {
              favoriteArticleId = id;
              favoriteValue = value;
            },
            onSetReadLater: (id, value) async {
              readLaterArticleId = id;
              readLaterValue = value;
            },
            onOpenOriginal: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('收藏'));
    await tester.pump();
    expect(selectedFilter, RssArticleFilter.favorite);

    await tester.tap(find.byTooltip('收藏'));
    await tester.pump();
    expect(favoriteArticleId, article.id);
    expect(favoriteValue, isTrue);

    await tester.tap(find.byTooltip('移出稍后读'));
    await tester.pump();
    expect(readLaterArticleId, article.id);
    expect(readLaterValue, isFalse);
  });
}

Finder _richTextContaining(String text) {
  return find.byWidgetPredicate((widget) {
    return widget is RichText && widget.text.toPlainText().contains(text);
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

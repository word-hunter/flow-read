import 'package:flow_read/models/rss_models.dart';
import 'package:flow_read/widgets/rss/rss_article_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
            showFeedName: false,
            onRefresh: () {},
            onSearchChanged: (_) {},
            onMarkRead: (_) async {},
            onMarkUnread: (_) async {},
            onOpenOriginal: (value) => opened = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('查看原文'));
    await tester.pump();

    expect(opened, article);
  });
}

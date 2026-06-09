import 'package:flow_rss/flow_rss.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  const parser = RssFeedDocumentParser();

  test('RSS adapter parses metadata, date, cleaned text, and images', () {
    final document = XmlDocument.parse(_rssFeed);

    final metadata = parser.parseMetadata(document);
    final articles = parser.parseArticles(
      document,
      feedUrl: 'https://example.com/rss.xml',
    );

    expect(metadata.title, 'Flow News');
    expect(metadata.description, 'Reading updates');
    expect(metadata.imageUrl, 'https://example.com/logo.png');
    expect(articles.single.feedTitle, 'Flow News');
    expect(articles.single.description, 'Summary one');
    expect(articles.single.content, 'Full content');
    expect(articles.single.bodyBlocks, hasLength(2));
    expect(
      (articles.single.bodyBlocks[0] as RssArticleTextBlock).type,
      RssArticleTextBlockType.paragraph,
    );
    expect(
      (articles.single.bodyBlocks[0] as RssArticleTextBlock).text,
      'Full content',
    );
    expect(
      (articles.single.bodyBlocks[1] as RssArticleImageBlock).image.url,
      'https://example.com/images/full.png',
    );
    expect(articles.single.pubDate?.toUtc(), DateTime.utc(2026, 5, 20, 7));
    expect(articles.single.images.map((image) => image.url), [
      'https://example.com/images/full.png',
      'https://cdn.example.com/thumb.jpg',
    ]);
  });

  test('RSS adapter preserves structured article body blocks', () {
    final document = XmlDocument.parse(_structuredBodyFeed);

    final article = parser
        .parseArticles(document, feedUrl: 'https://example.com/rss.xml')
        .single;
    final textBlocks = article.bodyBlocks.whereType<RssArticleTextBlock>();

    expect(
      article.content,
      [
        'Section title',
        'First paragraph with emphasis.',
        'First point',
        'Quoted line',
      ].join('\n\n'),
    );
    expect(textBlocks.map((block) => block.type), [
      RssArticleTextBlockType.heading,
      RssArticleTextBlockType.paragraph,
      RssArticleTextBlockType.listItem,
      RssArticleTextBlockType.blockquote,
    ]);
    expect(textBlocks.map((block) => block.text), [
      'Section title',
      'First paragraph with emphasis.',
      'First point',
      'Quoted line',
    ]);
  });

  test('Atom adapter parses metadata, alternate links, and ISO dates', () {
    final document = XmlDocument.parse(_atomFeed);

    final metadata = parser.parseMetadata(document);
    final articles = parser.parseArticles(
      document,
      feedUrl: 'https://example.com/atom.xml',
      fallbackFeedTitle: 'Fallback',
    );

    expect(metadata.title, 'Atom Flow');
    expect(metadata.description, 'Atom reading updates');
    expect(metadata.imageUrl, 'https://example.com/atom-logo.png');
    expect(articles.single.feedTitle, 'Atom Flow');
    expect(articles.single.link, 'https://example.com/atom-entry');
    expect(articles.single.description, 'Atom summary');
    expect(articles.single.content, 'Atom full content');
    expect(articles.single.pubDate?.toUtc(), DateTime.utc(2026, 5, 20, 7, 10));
  });

  test('unsupported documents fail at the parser boundary', () {
    final document = XmlDocument.parse('<html><body>No feed</body></html>');

    expect(
      () => parser.parseMetadata(document),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('RSS/Atom'),
        ),
      ),
    );
  });
}

const _rssFeed = '''
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0"
  xmlns:content="http://purl.org/rss/1.0/modules/content/"
  xmlns:media="http://search.yahoo.com/mrss/">
  <channel>
    <title>Flow News</title>
    <description><![CDATA[<p>Reading <b>updates</b></p>]]></description>
    <image>
      <url>https://example.com/logo.png</url>
    </image>
    <item>
      <title>First Article</title>
      <link>https://example.com/first</link>
      <description><![CDATA[<p>Summary <b>one</b></p>]]></description>
      <content:encoded><![CDATA[<p>Full <em>content</em></p><img src="/images/full.png#size" alt="Full image" width="640" height="320" />]]></content:encoded>
      <media:thumbnail url="https://cdn.example.com/thumb.jpg" width="120" height="80" />
      <pubDate>Wed, 20 May 2026 15:00:00 +0800</pubDate>
      <guid>first-guid</guid>
    </item>
  </channel>
</rss>
''';

const _atomFeed = '''
<?xml version="1.0" encoding="UTF-8" ?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Atom Flow</title>
  <subtitle><![CDATA[<p>Atom <strong>reading</strong> updates</p>]]></subtitle>
  <logo>https://example.com/atom-logo.png</logo>
  <entry>
    <title>Atom Entry</title>
    <link rel="self" href="https://example.com/atom-entry/self" />
    <link rel="alternate" href="https://example.com/atom-entry" />
    <id>tag:example.com,2026:atom-entry</id>
    <updated>2026-05-20T07:10:00Z</updated>
    <summary type="html">&lt;p&gt;Atom summary&lt;/p&gt;</summary>
    <content type="html">&lt;p&gt;Atom full content&lt;/p&gt;</content>
  </entry>
</feed>
''';

const _structuredBodyFeed = '''
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/">
  <channel>
    <title>Flow News</title>
    <item>
      <title>Structured Article</title>
      <link>https://example.com/structured</link>
      <content:encoded><![CDATA[
        <article>
          <h2>Section title</h2>
          <p>First paragraph with <em>emphasis</em>.</p>
          <ul><li>First point</li></ul>
          <blockquote><p>Quoted line</p></blockquote>
        </article>
      ]]></content:encoded>
      <guid>structured-guid</guid>
    </item>
  </channel>
</rss>
''';

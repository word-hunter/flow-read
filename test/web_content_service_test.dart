import 'package:flow_read/services/web_content_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes bare web addresses', () {
    expect(
      WebContentService.normalizeUri('example.com/article').toString(),
      'https://example.com/article',
    );
  });

  test('parses readable article content and removes page chrome', () {
    final page = WebContentService.parse('''
      <html>
        <head><title>Original Title</title><script>ignored()</script></head>
        <body>
          <nav>Navigation should not remain</nav>
          <article>
            <h1>Readable Title</h1>
            <p>The wolves were running through the valley.</p>
            <p>Another paragraph gives more context for the reader.</p>
          </article>
        </body>
      </html>
      ''', Uri.parse('https://example.com/story'));

    expect(page.title, 'Original Title');
    expect(page.paragraphs, contains('Readable Title'));
    expect(
      page.paragraphs,
      contains('The wolves were running through the valley.'),
    );
    expect(page.plainText, isNot(contains('Navigation should not remain')));
  });
}

import 'package:flow_read/models/book.dart';
import 'package:flow_read/models/chapter.dart';
import 'package:flow_read/models/content_block.dart';
import 'package:flow_read/models/reading_search_result.dart';
import 'package:flow_read/services/reading_search_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('search stops after the collapsed result limit', () async {
    final book = Book(
      title: 'Fixture',
      author: 'Tester',
      chapters: [
        Chapter(
          title: 'Many',
          plainText: List.filled(102, 'needle').join(' '),
          rawHtml: '',
        ),
      ],
    );

    final events = await ReadingSearchService.search(
      book,
      'needle',
      limit: 100,
    ).toList();

    final results = events
        .map((event) => event.result)
        .whereType<ReadingSearchResult>()
        .toList();

    expect(results, hasLength(100));
    expect(events.last.stoppedAtLimit, isTrue);
  });

  test('search maps text block hits to rendered content indexes', () async {
    final book = Book(
      title: 'Fixture',
      author: 'Tester',
      chapters: [
        Chapter(
          title: 'Blocks',
          plainText: 'Alpha needle beta',
          rawHtml: '',
          blocks: [
            ImageBlock(src: 'cover.png'),
            TextBlock(
              type: BlockType.paragraph,
              spans: const [StyledText('Alpha needle beta')],
            ),
          ],
        ),
      ],
    );

    final events = await ReadingSearchService.search(book, 'needle').toList();
    final result = events.single.result!;

    expect(result.chapterIndex, 0);
    expect(result.itemIndex, 1);
    expect(
      result.snippet.substring(
        result.snippetMatchStart,
        result.snippetMatchEnd,
      ),
      'needle',
    );
  });
}

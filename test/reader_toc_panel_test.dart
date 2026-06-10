import 'package:epub_reader_core/epub_reader_core.dart';
import 'package:flow_read/models/book.dart';
import 'package:flow_read/models/chapter.dart';
import 'package:flow_read/models/content_block.dart';
import 'package:flow_read/widgets/reader_shell/reader_toc_panel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildReaderTocItems', () {
    test('uses EPUB TOC labels and maps fragment hrefs to chapters', () {
      final book = Book(
        title: 'Fixture',
        author: 'Author',
        chapters: const [
          Chapter(
            title: 'Spine One',
            plainText: 'First chapter.',
            rawHtml: '',
            href: 'Text/chapter1.xhtml',
          ),
          Chapter(
            title: 'Spine Two',
            plainText: 'Second chapter.',
            rawHtml: '',
            href: 'Text/chapter2.xhtml',
          ),
        ],
        toc: const [
          EpubTocEntry(
            label: 'Part One',
            href: 'Text/chapter1.xhtml#start',
            playOrder: 1,
          ),
          EpubTocEntry(
            label: 'Scene One',
            href: 'OEBPS/Text/chapter2.xhtml#scene',
            playOrder: 2,
            level: 1,
          ),
        ],
      );

      final items = buildReaderTocItems(book);

      expect(items.map((item) => item.title), ['Part One', 'Scene One']);
      expect(items.map((item) => item.targetChapterIndex), [0, 1]);
      expect(items.map((item) => item.level), [0, 1]);
    });

    test('falls back to readable chapter labels when EPUB TOC is missing', () {
      final book = Book(
        title: 'Fixture',
        author: 'Author',
        chapters: [
          Chapter(
            title: 'Chapter 1',
            plainText: 'A bright morning opened the story with a quiet room.',
            rawHtml: '',
            blocks: [
              TextBlock(
                type: BlockType.paragraph,
                spans: [
                  StyledText(
                    'A bright morning opened the story with a quiet room.',
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final items = buildReaderTocItems(book);

      expect(items, hasLength(1));
      expect(
        items.single.title,
        'A bright morning opened the story with a...',
      );
      expect(items.single.subtitle, 'Chapter 1');
      expect(items.single.targetChapterIndex, 0);
    });
  });

  group('selectedReaderTocIndexForChapter', () {
    test('selects the first TOC item that targets the current chapter', () {
      const items = [
        ReaderTocItem(title: 'One', targetChapterIndex: 0, ordinal: 1),
        ReaderTocItem(title: 'Two A', targetChapterIndex: 1, ordinal: 2),
        ReaderTocItem(title: 'Two B', targetChapterIndex: 1, ordinal: 3),
      ];

      expect(selectedReaderTocIndexForChapter(items, 1), 1);
    });

    test('clamps to visible item range when no target chapter matches', () {
      const items = [
        ReaderTocItem(title: 'One', targetChapterIndex: 0, ordinal: 1),
        ReaderTocItem(title: 'Two', targetChapterIndex: 1, ordinal: 2),
      ];

      expect(selectedReaderTocIndexForChapter(items, 6), 1);
    });
  });
}

import 'dart:typed_data';

import 'package:flow_read/models/book.dart';
import 'package:flow_read/models/chapter.dart';
import 'package:flow_read/models/content_block.dart';
import 'package:flow_read/services/book_insight_chapter_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps only analyzable body chapters for story map', () {
    final catalog = BookInsightChapterCatalog.fromBook(
      Book(
        title: 'Fixture Book',
        author: 'Author',
        chapters: [
          const Chapter(
            title: 'Preface',
            plainText:
                'This preface explains how the book was edited and prepared.',
            rawHtml: '',
          ),
          Chapter(
            title: '题图',
            plainText: 'A map of the old city.',
            rawHtml: '',
            blocks: [
              ImageBlock(
                src: 'images/map.jpg',
                bytes: Uint8List(0),
                caption: 'A map of the old city.',
              ),
            ],
          ),
          const Chapter(
            title: 'Chapter One',
            plainText:
                'Alice finds the old map and walks into the valley before dawn.',
            rawHtml: '',
          ),
          const Chapter(
            title: 'The River Road',
            plainText:
                'The river runs through the valley. Alice follows the road and '
                'notices a hidden bridge beside the mill.',
            rawHtml: '',
          ),
          const Chapter(
            title: 'contents',
            plainText: 'Chapter One Chapter Two Chapter Three',
            rawHtml: '',
          ),
        ],
      ),
    );

    expect(catalog.rawChapterIndexes, {2, 3});
    expect(catalog.entries.map((entry) => entry.displayNumber), [1, 2]);
    expect(catalog.entries.map((entry) => entry.title), [
      'Chapter One',
      'The River Road',
    ]);
    expect(catalog.readCountForRawChapter(2), 1);
    expect(catalog.firstLockedAfter(2)?.rawChapterIndex, 3);
  });
}

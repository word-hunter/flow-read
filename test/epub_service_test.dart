import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:epub_reader_core/epub_reader_core.dart' as core;
import 'package:flow_read/models/content_block.dart';
import 'package:flow_read/services/epub_parse_worker.dart';
import 'package:flow_read/services/epub_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EPUB parser keeps block structure and extracts images', () async {
    final epubBytes = _buildEpub({
      'OEBPS/Text/chapter1.xhtml': '''
        <html xmlns="http://www.w3.org/1999/xhtml">
          <head><title>Chapter One</title></head>
          <body>
            <span>Loose</span><span> inline text.</span>
            <div>
              <span>The</span><span> first</span><span> paragraph.</span>
            </div>
            <p>Second <strong>bold</strong> paragraph.</p>
            <ul>
              <li><p>First item</p></li>
              <li>Second item<ul><li>Nested item</li></ul></li>
            </ul>
            <blockquote><p>Quoted line.</p></blockquote>
            <figure>
              <img src="../Images/pic.png#cover" alt="Map" width="640" height="320" />
              <figcaption>Map caption</figcaption>
            </figure>
            <table>
              <tr><th>Name</th><th>Value</th></tr>
              <tr><td>North</td><td>Winter</td></tr>
            </table>
          </body>
        </html>
      ''',
      'OEBPS/Images/pic.png': String.fromCharCodes([1, 2, 3, 4]),
    });

    final book = await EpubService.parseBytes(epubBytes);

    expect(book.language, 'en-US');
    expect(book.chapters, hasLength(1));
    expect(book.chapters.single.title, 'Chapter One');
    expect(book.chapters.single.plainText, contains('Map caption'));

    final blocks = book.chapters.single.blocks;
    expect(blocks.whereType<TextBlock>().map((b) => b.plainText), [
      'Loose inline text.',
      'The first paragraph.',
      'Second bold paragraph.',
      'First item',
      'Second item',
      'Nested item',
      'Quoted line.',
      'Name | Value',
      'North | Winter',
    ]);

    final secondParagraph = blocks.whereType<TextBlock>().elementAt(2);
    expect(
      secondParagraph.spans.any((s) => s.text == 'bold' && s.style.bold),
      isTrue,
    );

    final listItems = blocks.whereType<TextBlock>().where(
      (block) => block.type == BlockType.listItem,
    );
    expect(listItems.map((block) => block.indent), [1, 1, 2]);

    final quote = blocks.whereType<TextBlock>().firstWhere(
      (block) => block.type == BlockType.blockquote,
    );
    expect(quote.plainText, 'Quoted line.');
    expect(quote.indent, 1);

    final image = blocks.whereType<ImageBlock>().single;
    expect(image.src, '../Images/pic.png');
    expect(image.alt, 'Map');
    expect(image.bytes, Uint8List.fromList([1, 2, 3, 4]));
    expect(image.width, 640);
    expect(image.height, 320);
    expect(image.aspectRatio, 2);
    expect(image.caption, 'Map caption');
  });

  test(
    'EPUB parse worker parses file and bytes off the caller isolate',
    () async {
      final epubBytes = _buildEpub({
        'OEBPS/Text/chapter1.xhtml': '''
        <html xmlns="http://www.w3.org/1999/xhtml">
          <head><title>Chapter One</title></head>
          <body><p>Background parsing keeps the UI isolate free.</p></body>
        </html>
      ''',
      });
      final tempDir = await Directory.systemTemp.createTemp(
        'flow_read_epub_worker_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final epubFile = File('${tempDir.path}/fixture.epub');
      await epubFile.writeAsBytes(epubBytes);
      final events = <core.EpubParseEvent>[];

      final fromFile = await EpubParseWorker.parseInIsolate(
        epubFile.path,
        onProgress: events.add,
      );
      final fromBytes = await EpubParseWorker.parseBytesInIsolate(epubBytes);

      expect(fromFile.title, 'Fixture Book');
      expect(fromFile.chapters.single.title, 'Chapter One');
      expect(
        fromFile.chapters.single.plainText,
        'Background parsing keeps the UI isolate free.',
      );
      expect(fromBytes.title, fromFile.title);
      expect(
        fromBytes.chapters.single.plainText,
        fromFile.chapters.single.plainText,
      );
      expect(
        events.map((event) => event.phase),
        containsAllInOrder([
          core.EpubParsePhase.extractingMetadata,
          core.EpubParsePhase.parsingChapter,
          core.EpubParsePhase.buildingBlocks,
          core.EpubParsePhase.complete,
        ]),
      );
      expect(events.last.progress, 1);
    },
  );

  test(
    'EPUB parser applies safe CSS subset and ignores complex selectors',
    () async {
      final epubBytes = _buildEpub({
        'OEBPS/Text/chapter1.xhtml': '''
        <html xmlns="http://www.w3.org/1999/xhtml">
          <head>
            <title>Chapter One</title>
            <link rel="stylesheet" href="../Styles/book.css" />
            <style>
              p { text-align: justify; }
              .scaled { font-size: 150%; margin-bottom: 2em; }
              .emph { font-style: italic; }
              #hero { width: 50%; max-width: 300px; }
              .outer span { font-weight: bold; }
            </style>
          </head>
          <body>
            <p class="scaled">Scaled paragraph.</p>
            <p><span class="emph external">Styled word.</span></p>
            <p style="text-align: center">
              <img id="hero" src="../Images/pic.png" style="height: 120px" />
            </p>
            <p class="outer"><span>Complex ignored.</span></p>
          </body>
        </html>
      ''',
        'OEBPS/Styles/book.css': '.external { font-weight: 700; }',
        'OEBPS/Images/pic.png': String.fromCharCodes([1, 2, 3, 4]),
      });

      final book = await EpubService.parseBytes(epubBytes);
      final blocks = book.chapters.single.blocks;

      final scaled = blocks.whereType<TextBlock>().elementAt(0);
      expect(scaled.style.textAlign, ReaderTextAlign.justify);
      expect(scaled.style.fontSizeScale, 1.5);
      expect(scaled.style.marginBottom, isA<CssEm>());

      final styled = blocks.whereType<TextBlock>().elementAt(1);
      expect(styled.spans.single.style.italic, isTrue);
      expect(styled.spans.single.style.bold, isTrue);

      final image = blocks.whereType<ImageBlock>().single;
      expect(image.style.width, isA<CssPercent>());
      expect(image.style.height, isA<CssPx>());
      expect(image.style.maxWidth, isA<CssPx>());
      expect(image.style.alignment, ReaderTextAlign.center);

      final complexIgnored = blocks.whereType<TextBlock>().elementAt(2);
      expect(complexIgnored.spans.single.style.bold, isFalse);
    },
  );

  test('EPUB parser treats svg image as an image block', () async {
    final epubBytes = _buildEpub({
      'OEBPS/Text/chapter1.xhtml': '''
        <html xmlns="http://www.w3.org/1999/xhtml">
          <head><title>Chapter One</title></head>
          <body>
            <svg><image href="../Images/pic.png" width="200" height="100" /></svg>
          </body>
        </html>
      ''',
      'OEBPS/Images/pic.png': String.fromCharCodes([1, 2, 3, 4]),
    });

    final book = await EpubService.parseBytes(epubBytes);
    final image = book.chapters.single.blocks.whereType<ImageBlock>().single;

    expect(image.src, '../Images/pic.png');
    expect(image.declaredWidth, 200);
    expect(image.declaredHeight, 100);
  });

  test(
    'EPUB parser avoids reusing the book title as every section title',
    () async {
      final epubBytes = _buildEpub({
        'OEBPS/Text/chapter1.xhtml': '''
        <html xmlns="http://www.w3.org/1999/xhtml">
          <head><title>Fixture Book</title></head>
          <body>
            <p>CONTENTS</p>
            <p>Diving Under</p>
            <p>The Sycamore Tree</p>
          </body>
        </html>
      ''',
      });

      final book = await EpubService.parseBytes(epubBytes);

      expect(book.chapters.single.title, 'CONTENTS');
    },
  );

  test('EPUB parser prefers body titles over generic HTML titles', () async {
    final epubBytes = _buildEpub({
      'OEBPS/Text/chapter1.xhtml': '''
        <html xmlns="http://www.w3.org/1999/xhtml">
          <head><title>Chapter 1</title></head>
          <body>
            <p>Diving Under</p>
            <p>The first paragraph starts here.</p>
          </body>
        </html>
      ''',
    });

    final book = await EpubService.parseBytes(epubBytes);

    expect(book.chapters.single.title, 'Diving Under');
  });

  test('EPUB parser names image-only spine items as cover', () async {
    final epubBytes = _buildEpub({
      'OEBPS/Text/chapter1.xhtml': '''
        <html xmlns="http://www.w3.org/1999/xhtml">
          <head><title>Fixture Book</title></head>
          <body>
            <img src="../Images/cover.png" />
          </body>
        </html>
      ''',
      'OEBPS/Images/cover.png': String.fromCharCodes([5, 6, 7, 8]),
    });

    final book = await EpubService.parseBytes(epubBytes);

    expect(book.chapters.single.title, '封面');
  });

  test(
    'EPUB service keeps chapter href and prefers TOC labels with fragments',
    () async {
      final epubBytes = _buildEpub(
        {
          'OEBPS/Text/chapter1.xhtml': '''
        <html xmlns="http://www.w3.org/1999/xhtml">
          <head><title>Chapter One</title></head>
          <body><p>First chapter body.</p></body>
        </html>
      ''',
          'OEBPS/toc.ncx': '''
        <ncx xmlns="http://www.daisy.org/z3986/2005/ncx/">
          <navMap>
            <navPoint id="chapter-1" playOrder="1">
              <navLabel><text>Reader TOC Title</text></navLabel>
              <content src="Text/chapter1.xhtml#opening"/>
            </navPoint>
          </navMap>
        </ncx>
      ''',
        },
        manifestItems: '''
        <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
      ''',
        spineAttributes: 'toc="ncx"',
      );

      final book = await EpubService.parseBytes(epubBytes);

      expect(book.toc.single.label, 'Reader TOC Title');
      expect(book.chapters.single.href, 'Text/chapter1.xhtml');
      expect(book.chapters.single.title, 'Reader TOC Title');
    },
  );
}

Uint8List _buildEpub(
  Map<String, String> extraFiles, {
  String manifestItems = '',
  String spineAttributes = '',
  String spineItems = '<itemref idref="chapter1"/>',
}) {
  final archive = Archive();
  void addString(String path, String content) {
    archive.addFile(ArchiveFile.string(path, content));
  }

  addString('META-INF/container.xml', '''
      <?xml version="1.0"?>
      <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
        <rootfiles>
          <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
        </rootfiles>
      </container>
    ''');

  addString('OEBPS/content.opf', '''
      <?xml version="1.0" encoding="UTF-8"?>
      <package xmlns="http://www.idpf.org/2007/opf" unique-identifier="bookid" version="3.0">
        <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
          <dc:title>Fixture Book</dc:title>
          <dc:creator>Fixture Author</dc:creator>
          <dc:language>en-US</dc:language>
        </metadata>
        <manifest>
          <item id="chapter1" href="Text/chapter1.xhtml" media-type="application/xhtml+xml"/>
          <item id="pic" href="Images/pic.png" media-type="image/png"/>
          $manifestItems
        </manifest>
        <spine $spineAttributes>
          $spineItems
        </spine>
      </package>
    ''');

  for (final entry in extraFiles.entries) {
    archive.addFile(
      ArchiveFile(
        entry.key,
        utf8.encode(entry.value).length,
        utf8.encode(entry.value),
      ),
    );
  }

  return ZipEncoder().encodeBytes(archive);
}

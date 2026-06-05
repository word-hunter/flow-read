import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:epub_reader_core/epub_reader_core.dart';
import 'package:test/test.dart';

void main() {
  test('parses EPUB spine content into neutral reader blocks', () async {
    final epubBytes = _buildEpub(
      {
        'OEBPS/Text/chapter1.xhtml': '''
        <html xmlns="http://www.w3.org/1999/xhtml">
          <head>
            <title>Chapter One</title>
            <style>
              .center { text-align: center; }
              #hero { width: 50%; max-width: 300px; }
              .emph { font-style: italic; font-weight: 700; }
              .outer span { font-weight: bold; }
            </style>
          </head>
          <body>
            <h1>Heading</h1>
            <p><span class="emph">Styled word.</span></p>
            <figure class="center">
              <img id="hero" src="../Images/pic.png" />
              <figcaption>Map caption</figcaption>
            </figure>
            <p class="outer"><span>Complex ignored.</span></p>
          </body>
        </html>
      ''',
      },
      extraBytes: {'OEBPS/Images/pic.png': _oneByOnePng},
    );

    final book = await EpubParser.parseBytes(epubBytes);

    expect(book.title, 'Fixture Book');
    expect(book.language, 'en-US');
    expect(book.chapters, hasLength(1));
    expect(book.chapters.single.documentTitle, 'Chapter One');

    final blocks = book.chapters.single.blocks;
    final heading = blocks.whereType<ParsedTextBlock>().first;
    expect(heading.type, ParsedBlockType.heading);
    expect(heading.plainText, 'Heading');

    final styled = blocks.whereType<ParsedTextBlock>().elementAt(1);
    expect(styled.spans.single.style.bold, isTrue);
    expect(styled.spans.single.style.italic, isTrue);

    final image = blocks.whereType<ParsedImageBlock>().single;
    expect(image.caption, 'Map caption');
    expect(image.naturalWidth, 1);
    expect(image.naturalHeight, 1);
    expect(image.style.width, isA<CssPercent>());
    expect(image.style.maxWidth, isA<CssPx>());
    expect(image.style.alignment, ReaderTextAlign.center);

    final complexIgnored = blocks.whereType<ParsedTextBlock>().last;
    expect(complexIgnored.spans.single.style.bold, isFalse);
  });

  test('reports metadata, chapter, image, and completion progress', () {
    final events = <EpubParseEvent>[];
    final epubBytes = _buildEpub(
      {
        'OEBPS/Text/chapter1.xhtml': '''
        <html xmlns="http://www.w3.org/1999/xhtml">
          <head><title>Chapter One</title></head>
          <body>
            <p>Progress callbacks should track visible parser work.</p>
            <img src="../Images/pic.png" />
          </body>
        </html>
      ''',
      },
      extraBytes: {'OEBPS/Images/pic.png': _oneByOnePng},
    );

    final book = EpubParser.parseBytesSync(epubBytes, onProgress: events.add);

    expect(book.chapters, hasLength(1));
    expect(
      events.map((event) => event.phase),
      containsAllInOrder([
        EpubParsePhase.extractingMetadata,
        EpubParsePhase.parsingChapter,
        EpubParsePhase.buildingBlocks,
        EpubParsePhase.loadingImage,
        EpubParsePhase.complete,
      ]),
    );
    expect(events.last.phase, EpubParsePhase.complete);
    expect(events.last.progress, 1);
    expect(events.skip(1).every((event) => event.totalChapters == 1), isTrue);

    final chapterEvent = events.firstWhere(
      (event) => event.phase == EpubParsePhase.buildingBlocks,
    );
    expect(chapterEvent.chapterIndex, 0);
    expect(chapterEvent.chapterTitle, 'Chapter One');
    expect(_isMonotonic(events.map((event) => event.progress)), isTrue);
  });
}

bool _isMonotonic(Iterable<double> values) {
  var previous = 0.0;
  for (final value in values) {
    if (value < previous) return false;
    previous = value;
  }
  return true;
}

Uint8List _buildEpub(
  Map<String, String> extraFiles, {
  Map<String, List<int>> extraBytes = const {},
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
        </manifest>
        <spine>
          <itemref idref="chapter1"/>
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
  for (final entry in extraBytes.entries) {
    archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
  }

  return ZipEncoder().encodeBytes(archive);
}

const _oneByOnePng = [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
];

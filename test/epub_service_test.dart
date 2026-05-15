import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flow_read/models/content_block.dart';
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
              <img src="../Images/pic.png#cover" alt="Map" />
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

    expect(book.chapters, hasLength(1));
    expect(book.chapters.single.title, 'Chapter One');

    final blocks = book.chapters.single.blocks;
    expect(blocks.whereType<TextBlock>().map((b) => b.plainText), [
      'Loose inline text.',
      'The first paragraph.',
      'Second bold paragraph.',
      'First item',
      'Second item',
      'Nested item',
      'Quoted line.',
      'Map caption',
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
  });
}

Uint8List _buildEpub(Map<String, String> extraFiles) {
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

  return ZipEncoder().encodeBytes(archive);
}

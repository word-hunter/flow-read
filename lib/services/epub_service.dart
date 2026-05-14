import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:xml/xml.dart';

import '../models/book.dart';
import '../models/chapter.dart';
import '../models/content_block.dart';

class EpubService {
  static Future<Book> parseFile(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return parseBytes(bytes);
  }

  static Future<Book> parseBytes(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);

    final containerXml = _readFile(archive, 'META-INF/container.xml');
    if (containerXml == null) {
      throw const FormatException('Invalid EPUB: missing container.xml');
    }

    final containerDoc = XmlDocument.parse(containerXml);
    final rootfileEl = containerDoc.findAllElements('rootfile').firstOrNull;
    if (rootfileEl == null) {
      throw const FormatException('Invalid EPUB: missing rootfile element');
    }

    final opfPath = rootfileEl.getAttribute('full-path')!;
    final opfDir = opfPath.contains('/')
        ? '${opfPath.substring(0, opfPath.lastIndexOf('/'))}/'
        : '';

    final opfContent = _readFile(archive, opfPath);
    if (opfContent == null) {
      throw FormatException('Invalid EPUB: missing OPF file at $opfPath');
    }

    final opfDoc = XmlDocument.parse(opfContent);
    final package = opfDoc.rootElement;

    final title = _findDcElement(package, 'title') ?? 'Unknown Title';
    final author = _findDcElement(package, 'creator') ?? 'Unknown Author';

    final manifest = <String, ({String href, String mediaType, String? properties})>{};
    for (final item in package.findAllElements('item')) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      final mediaType = item.getAttribute('media-type') ?? '';
      final properties = item.getAttribute('properties');
      if (id != null && href != null) {
        manifest[id] = (href: href, mediaType: mediaType, properties: properties);
      }
    }

    // Extract cover image
    Uint8List? coverBytes;
    final coverId = _findCoverId(package, manifest);
    if (coverId != null && manifest.containsKey(coverId)) {
      final coverHref = manifest[coverId]!.href;
      coverBytes = _readFileBytes(archive, '$opfDir$coverHref');
    }

    // Read chapters in spine order
    final spineEl = package.findAllElements('spine').firstOrNull;
    final chapters = <Chapter>[];

    if (spineEl != null) {
      for (final itemref in spineEl.findElements('itemref')) {
        final idref = itemref.getAttribute('idref');
        if (idref == null || !manifest.containsKey(idref)) continue;

        final entry = manifest[idref]!;
        if (!entry.mediaType.contains('html')) continue;

        final chapterHref = '$opfDir${entry.href}';
        final chapterDir = chapterHref.contains('/')
            ? '${chapterHref.substring(0, chapterHref.lastIndexOf('/'))}/'
            : opfDir;

        final html = _readFile(archive, chapterHref);
        if (html == null) continue;

        final document = html_parser.parse(html);
        final plainText = _extractText(document);

        if (plainText.trim().isNotEmpty) {
          final contentDoc = html_parser.parse(html);
          _removeUnwantedElements(contentDoc.body!);
          final blocks = _parseContentBlocks(contentDoc, archive, chapterDir);
          final split = _trySplitMetadata(
            document, plainText, html, chapters.length, title,
            blocks: blocks,
          );
          chapters.addAll(split);
        }
      }
    }

    if (chapters.isEmpty) {
      chapters.add(
        const Chapter(
          title: 'Content',
          plainText: '(No readable content found)',
          rawHtml: '',
        ),
      );
    }

    return Book(
      title: title,
      author: author,
      chapters: chapters,
      coverBytes: coverBytes,
    );
  }

  static String? _findDcElement(XmlElement package, String name) {
    for (final el in package.findAllElements('dc:$name')) {
      final text = el.innerText.trim();
      if (text.isNotEmpty) return text;
    }
    for (final el in package.findAllElements(name)) {
      if (el.name.namespaceUri?.contains('dc') ?? false) {
        final text = el.innerText.trim();
        if (text.isNotEmpty) return text;
      }
    }
    return null;
  }

  static String? _findCoverId(
    XmlElement package,
    Map<String, ({String href, String mediaType, String? properties})> manifest,
  ) {
    // EPUB3: item with properties="cover-image"
    for (final entry in manifest.entries) {
      if (entry.value.properties?.contains('cover-image') ?? false) {
        return entry.key;
      }
    }
    // EPUB2: <meta name="cover" content="cover-image-id"/>
    for (final meta in package.findAllElements('meta')) {
      if (meta.getAttribute('name') == 'cover') {
        return meta.getAttribute('content');
      }
    }
    return null;
  }

  static String? _readFile(Archive archive, String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    for (final file in archive) {
      final filePath =
          file.name.startsWith('/') ? file.name.substring(1) : file.name;
      if (filePath.toLowerCase() == normalized.toLowerCase()) {
        return utf8.decode(file.content as List<int>, allowMalformed: true);
      }
    }
    return null;
  }

  static Uint8List? _readFileBytes(Archive archive, String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    for (final file in archive) {
      final filePath =
          file.name.startsWith('/') ? file.name.substring(1) : file.name;
      if (filePath.toLowerCase() == normalized.toLowerCase()) {
        return Uint8List.fromList(file.content as List<int>);
      }
    }
    return null;
  }

  static String _extractText(dom.Document document) {
    final body = document.body;
    if (body == null) return '';

    _removeUnwantedElements(body);

    return body.text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static void _removeUnwantedElements(dom.Element element) {
    element
        .querySelectorAll('script, style, nav, .nav')
        .forEach((e) => e.remove());

    for (final child in element.children) {
      _removeUnwantedElements(child);
    }
  }

  static String _extractTitle(
    dom.Document document,
    int index,
    String bookTitle,
  ) {
    final h1 = document.querySelector('h1');
    if (h1 != null && h1.text.trim().isNotEmpty) {
      return h1.text.trim();
    }

    final h2 = document.querySelector('h2');
    if (h2 != null && h2.text.trim().isNotEmpty) {
      return h2.text.trim();
    }

    final titleTag = document.querySelector('title');
    if (titleTag != null && titleTag.text.trim().isNotEmpty) {
      return titleTag.text.trim();
    }

    return 'Chapter ${index + 1}';
  }

  static final _metadataPattern = RegExp(
    r'ISBN|CIP|图书在版编目|出版社|印刷|定价|版次|印次|字数.*千字|开本',
  );

  static const _blockTags = {
    'p', 'div', 'section', 'article', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
    'ul', 'ol', 'li', 'blockquote', 'table', 'figure', 'hr', 'pre',
  };

  static List<Chapter> _trySplitMetadata(
    dom.Document document,
    String fullText,
    String rawHtml,
    int index,
    String bookTitle, {
    List<ContentBlock> blocks = const [],
  }) {
    final body = document.body;
    if (body == null) {
      return [
        Chapter(
          title: _extractTitle(document, index, bookTitle),
          plainText: fullText,
          rawHtml: rawHtml,
          blocks: blocks,
        ),
      ];
    }

    final elements = body.children
        .where((el) => el.text.trim().isNotEmpty)
        .toList();

    if (elements.length < 3) {
      return [
        Chapter(
          title: _extractTitle(document, index, bookTitle),
          plainText: fullText,
          rawHtml: rawHtml,
          blocks: blocks,
        ),
      ];
    }

    // Find the last block that contains metadata markers
    int lastMetaIndex = -1;
    for (int i = 0; i < elements.length; i++) {
      if (_metadataPattern.hasMatch(elements[i].text)) {
        lastMetaIndex = i;
      }
    }

    // No metadata found, or metadata is at the very end (unlikely to be mixed)
    if (lastMetaIndex == -1 || lastMetaIndex >= elements.length - 1) {
      return [
        Chapter(
          title: _extractTitle(document, index, bookTitle),
          plainText: fullText,
          rawHtml: rawHtml,
          blocks: blocks,
        ),
      ];
    }

    // Split: metadata portion vs content portion
    final metaText = elements
        .sublist(0, lastMetaIndex + 1)
        .map((e) => e.text.trim())
        .where((t) => t.isNotEmpty)
        .join(' ');
    final contentText = elements
        .sublist(lastMetaIndex + 1)
        .map((e) => e.text.trim())
        .where((t) => t.isNotEmpty)
        .join(' ');

    if (metaText.isEmpty || contentText.isEmpty) {
      return [
        Chapter(
          title: _extractTitle(document, index, bookTitle),
          plainText: fullText,
          rawHtml: rawHtml,
          blocks: blocks,
        ),
      ];
    }

    final chapterTitle = _extractTitle(document, index, bookTitle);
    // Split blocks too: metadata blocks vs content blocks
    final metaBlockCount = lastMetaIndex + 1;
    final metaBlocks = blocks.length > metaBlockCount
        ? blocks.sublist(0, metaBlockCount)
        : blocks;
    final contentBlocks = blocks.length > metaBlockCount
        ? blocks.sublist(metaBlockCount)
        : <ContentBlock>[];

    return [
      Chapter(title: '版权信息', plainText: metaText, rawHtml: '', blocks: metaBlocks),
      Chapter(title: chapterTitle, plainText: contentText, rawHtml: rawHtml, blocks: contentBlocks),
    ];
  }

  static List<ContentBlock> _parseContentBlocks(
    dom.Document document,
    Archive archive,
    String baseDir,
  ) {
    final body = document.body;
    if (body == null) return [];

    final result = <ContentBlock>[];
    for (final element in body.children) {
      _parseElement(element, result, archive, baseDir, 0);
    }
    return result;
  }

  static void _parseElement(
    dom.Element element,
    List<ContentBlock> result,
    Archive archive,
    String baseDir,
    int indent,
  ) {
    final tag = element.localName?.toLowerCase() ?? '';

    if (tag == 'img') {
      final src = element.attributes['src'];
      if (src != null) {
        final resolvedPath = _resolveHref(baseDir, src);
        final bytes = _readFileBytes(archive, resolvedPath);
        result.add(ImageBlock(src: src, alt: element.attributes['alt'], bytes: bytes));
      }
      return;
    }

    if (tag.startsWith('h') && tag.length == 2) {
      final level = int.tryParse(tag[1]);
      if (level != null && level >= 1 && level <= 6) {
        final spans = _parseInlineContent(element, InlineStyle.normal);
        if (spans.any((s) => s.text.trim().isNotEmpty)) {
          result.add(TextBlock(
            type: BlockType.heading,
            headingLevel: level,
            spans: spans,
          ));
        }
        return;
      }
    }

    if (tag == 'ul' || tag == 'ol') {
      for (final li in element.children) {
        if (li.localName?.toLowerCase() == 'li') {
          final spans = _parseInlineContent(li, InlineStyle.normal);
          if (spans.any((s) => s.text.trim().isNotEmpty)) {
            result.add(TextBlock(
              type: BlockType.listItem,
              spans: spans,
              indent: indent + 1,
            ));
          }
        }
      }
      return;
    }

    if (tag == 'blockquote') {
      final spans = _parseInlineContent(element, InlineStyle.normal);
      if (spans.any((s) => s.text.trim().isNotEmpty)) {
        result.add(TextBlock(
          type: BlockType.blockquote,
          spans: spans,
          indent: indent + 1,
        ));
      }
      return;
    }

    // Check for inline images inside this element
    final imgs = element.querySelectorAll('img');
    if (imgs.isNotEmpty) {
      // Parse text before/between/after images by processing child nodes
      _parseElementWithImages(element, result, archive, baseDir, indent);
      return;
    }

    if (tag == 'p') {
      final spans = _parseInlineContent(element, InlineStyle.normal);
      if (spans.any((s) => s.text.trim().isNotEmpty)) {
        result.add(TextBlock(type: BlockType.paragraph, spans: spans));
      }
      return;
    }

    if (tag == 'div' || tag == 'section' || tag == 'article') {
      final hasBlockChildren = element.children.any((child) {
        final childTag = child.localName?.toLowerCase() ?? '';
        return _blockTags.contains(childTag);
      });
      if (hasBlockChildren) {
        for (final child in element.children) {
          _parseElement(child, result, archive, baseDir, indent);
        }
      } else {
        final spans = _parseInlineContent(element, InlineStyle.normal);
        if (spans.any((s) => s.text.trim().isNotEmpty)) {
          result.add(TextBlock(type: BlockType.paragraph, spans: spans));
        }
      }
      return;
    }

    // For other block-level elements, try to recurse into children
    if (element.children.isNotEmpty) {
      for (final child in element.children) {
        _parseElement(child, result, archive, baseDir, indent);
      }
    } else {
      final spans = _parseInlineContent(element, InlineStyle.normal);
      if (spans.any((s) => s.text.trim().isNotEmpty)) {
        result.add(TextBlock(type: BlockType.paragraph, spans: spans));
      }
    }
  }

  static void _parseElementWithImages(
    dom.Element element,
    List<ContentBlock> result,
    Archive archive,
    String baseDir,
    int indent,
  ) {
    var currentSpans = <StyledText>[];

    for (final node in element.nodes) {
      if (node is dom.Element && node.localName?.toLowerCase() == 'img') {
        if (currentSpans.any((s) => s.text.trim().isNotEmpty)) {
          result.add(TextBlock(type: BlockType.paragraph, spans: currentSpans));
          currentSpans = [];
        }
        final src = node.attributes['src'];
        if (src != null) {
          final resolvedPath = _resolveHref(baseDir, src);
          final bytes = _readFileBytes(archive, resolvedPath);
          result.add(ImageBlock(src: src, alt: node.attributes['alt'], bytes: bytes));
        }
      } else if (node is dom.Element) {
        currentSpans.addAll(_parseInlineContent(node, InlineStyle.normal));
      } else if (node is dom.Text) {
        final text = node.text;
        if (text.isNotEmpty) {
          currentSpans.add(StyledText(text));
        }
      }
    }

    if (currentSpans.any((s) => s.text.trim().isNotEmpty)) {
      result.add(TextBlock(type: BlockType.paragraph, spans: currentSpans));
    }
  }

  static List<StyledText> _parseInlineContent(
    dom.Element element,
    InlineStyle parentStyle,
  ) {
    final result = <StyledText>[];

    for (final node in element.nodes) {
      if (node is dom.Text) {
        final text = node.text;
        if (text.isNotEmpty) {
          result.add(StyledText(text, parentStyle));
        }
      } else if (node is dom.Element) {
        final tag = node.localName?.toLowerCase() ?? '';
        InlineStyle childStyle = parentStyle;

        if (tag == 'b' || tag == 'strong') {
          childStyle = parentStyle.merge(const InlineStyle(bold: true));
        } else if (tag == 'i' || tag == 'em' || tag == 'cite') {
          childStyle = parentStyle.merge(const InlineStyle(italic: true));
        } else if (tag == 'br') {
          result.add(StyledText('\n', parentStyle));
          continue;
        }

        result.addAll(_parseInlineContent(node, childStyle));
      }
    }

    return result;
  }

  static String _resolveHref(String baseDir, String href) {
    if (href.startsWith('/')) return href.substring(1);

    final parts = <String>[];
    final baseParts = baseDir.split('/').where((p) => p.isNotEmpty).toList();
    parts.addAll(baseParts);

    for (final segment in href.split('/')) {
      if (segment == '..') {
        if (parts.isNotEmpty) parts.removeLast();
      } else if (segment != '.' && segment.isNotEmpty) {
        parts.add(segment);
      }
    }

    return parts.join('/');
  }
}

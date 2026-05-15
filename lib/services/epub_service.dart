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

    final manifest =
        <String, ({String href, String mediaType, String? properties})>{};
    for (final item in package.findAllElements('item')) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      final mediaType = item.getAttribute('media-type') ?? '';
      final properties = item.getAttribute('properties');
      if (id != null && href != null) {
        manifest[id] = (
          href: href,
          mediaType: mediaType,
          properties: properties,
        );
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

        final contentDoc = html_parser.parse(html);
        final body = contentDoc.body;
        if (body == null) continue;

        _removeUnwantedElements(body);
        final blocks = _parseContentBlocks(contentDoc, archive, chapterDir);
        final plainText = _plainTextFromBlocks(blocks);

        if (plainText.trim().isNotEmpty || blocks.any((b) => b is ImageBlock)) {
          final split = _trySplitMetadata(
            contentDoc,
            plainText,
            html,
            chapters.length,
            title,
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
      final filePath = file.name.startsWith('/')
          ? file.name.substring(1)
          : file.name;
      if (filePath.toLowerCase() == normalized.toLowerCase()) {
        return utf8.decode(file.content as List<int>, allowMalformed: true);
      }
    }
    return null;
  }

  static Uint8List? _readFileBytes(Archive archive, String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    for (final file in archive) {
      final filePath = file.name.startsWith('/')
          ? file.name.substring(1)
          : file.name;
      if (filePath.toLowerCase() == normalized.toLowerCase()) {
        return Uint8List.fromList(file.content as List<int>);
      }
    }
    return null;
  }

  static void _removeUnwantedElements(dom.Element element) {
    element
        .querySelectorAll('script, style, nav, .nav, [hidden]')
        .forEach((e) => e.remove());

    for (final child in element.children) {
      _removeUnwantedElements(child);
    }
  }

  static String _extractTitle(
    dom.Document document,
    int index,
    String bookTitle,
    List<ContentBlock> blocks,
    String plainText,
  ) {
    final headingTitle = _firstBlockTitle(blocks, headingOnly: true);
    if (headingTitle != null) return headingTitle;

    final hasText = blocks.any(
      (block) => block is TextBlock && block.plainText.trim().isNotEmpty,
    );
    if (!hasText && blocks.any((block) => block is ImageBlock)) {
      return '封面';
    }

    final bodyTitle = _firstBlockTitle(blocks, headingOnly: false);
    if (bodyTitle != null) return bodyTitle;

    final titleTag = _normalizePlainText(
      document.querySelector('title')?.text ?? '',
    );
    if (titleTag.isNotEmpty &&
        !_sameNormalizedText(titleTag, bookTitle) &&
        !_looksLikeFileTitle(titleTag)) {
      return titleTag;
    }

    final normalizedText = _normalizePlainText(plainText);
    if (_looksLikeTitleLine(normalizedText)) return normalizedText;

    return 'Section ${index + 1}';
  }

  static String? _firstBlockTitle(
    List<ContentBlock> blocks, {
    required bool headingOnly,
  }) {
    for (final block in blocks.take(4)) {
      if (block is! TextBlock) continue;
      if (headingOnly && block.type != BlockType.heading) continue;

      final text = _normalizePlainText(block.plainText);
      if (text.isEmpty) continue;
      if (headingOnly) return text;
      return _looksLikeTitleLine(text) ? text : null;
    }
    return null;
  }

  static bool _looksLikeTitleLine(String text) {
    final normalized = _normalizePlainText(text);
    if (normalized.isEmpty || normalized.length > 80) return false;

    final lower = normalized.toLowerCase();
    if (RegExp(
      r'^(contents|cover|preface|foreword|prologue|epilogue|acknowledg(e)?ments|introduction|part|book|chapter)\b',
    ).hasMatch(lower)) {
      return true;
    }
    if (RegExp(r'^(目录|封面|前言|序言|序|引子|楔子|后记|版权)').hasMatch(normalized)) {
      return true;
    }
    if (RegExp(r'[.!?。！？]$').hasMatch(normalized)) return false;

    final wordCount = normalized.split(RegExp(r'\s+')).length;
    return wordCount <= 8;
  }

  static bool _sameNormalizedText(String a, String b) {
    return _normalizePlainText(a).toLowerCase() ==
        _normalizePlainText(b).toLowerCase();
  }

  static bool _looksLikeFileTitle(String title) {
    final lower = title.toLowerCase();
    return lower.endsWith('.xhtml') ||
        lower.endsWith('.html') ||
        RegExp(
          r'^(text/)?(chapter|part|section|page|body|nav)\d*$',
        ).hasMatch(lower);
  }

  static final _metadataPattern = RegExp(
    r'ISBN|CIP|图书在版编目|出版社|印刷|定价|版次|印次|字数.*千字|开本',
  );

  static const _blockTags = {
    'address',
    'article',
    'aside',
    'blockquote',
    'body',
    'caption',
    'center',
    'dd',
    'details',
    'dialog',
    'dir',
    'div',
    'dl',
    'dt',
    'fieldset',
    'figcaption',
    'figure',
    'footer',
    'form',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'header',
    'hgroup',
    'hr',
    'li',
    'main',
    'nav',
    'ol',
    'p',
    'pre',
    'section',
    'table',
    'tbody',
    'td',
    'tfoot',
    'th',
    'thead',
    'tr',
    'ul',
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
          title: _extractTitle(document, index, bookTitle, blocks, fullText),
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
          title: _extractTitle(document, index, bookTitle, blocks, fullText),
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
          title: _extractTitle(document, index, bookTitle, blocks, fullText),
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
          title: _extractTitle(document, index, bookTitle, blocks, fullText),
          plainText: fullText,
          rawHtml: rawHtml,
          blocks: blocks,
        ),
      ];
    }

    // Split blocks too: metadata blocks vs content blocks
    final metaBlockCount = lastMetaIndex + 1;
    final metaBlocks = blocks.length > metaBlockCount
        ? blocks.sublist(0, metaBlockCount)
        : blocks;
    final contentBlocks = blocks.length > metaBlockCount
        ? blocks.sublist(metaBlockCount)
        : <ContentBlock>[];
    final chapterTitle = _extractTitle(
      document,
      index,
      bookTitle,
      contentBlocks,
      contentText,
    );

    return [
      Chapter(
        title: '版权信息',
        plainText: metaText,
        rawHtml: '',
        blocks: metaBlocks,
      ),
      Chapter(
        title: chapterTitle,
        plainText: contentText,
        rawHtml: rawHtml,
        blocks: contentBlocks,
      ),
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
    _parseNodesAsBlocks(body.nodes, result, archive, baseDir, 0);
    return result;
  }

  static void _parseNodesAsBlocks(
    Iterable<dom.Node> nodes,
    List<ContentBlock> result,
    Archive archive,
    String baseDir,
    int indent,
  ) {
    final inlineRun = <dom.Node>[];

    void flushInlineRun() {
      if (inlineRun.isEmpty) return;
      _appendInlineNodesAsBlocks(
        inlineRun,
        result,
        archive,
        baseDir,
        BlockType.paragraph,
        indent: indent,
      );
      inlineRun.clear();
    }

    for (final node in nodes) {
      if (node is dom.Text) {
        if (node.text.trim().isNotEmpty) {
          inlineRun.add(node);
        }
        continue;
      }

      if (node is! dom.Element) continue;

      if (_isBlockElement(node) || _isImageElement(node)) {
        flushInlineRun();
        _parseBlockElement(node, result, archive, baseDir, indent);
      } else {
        inlineRun.add(node);
      }
    }

    flushInlineRun();
  }

  static void _parseBlockElement(
    dom.Element element,
    List<ContentBlock> result,
    Archive archive,
    String baseDir,
    int indent,
  ) {
    final tag = element.localName?.toLowerCase() ?? '';

    if (_isImageElement(element)) {
      _addImageBlock(element, result, archive, baseDir);
      return;
    }

    if (tag.startsWith('h') && tag.length == 2) {
      final level = int.tryParse(tag[1]);
      if (level != null && level >= 1 && level <= 6) {
        _appendInlineNodesAsBlocks(
          element.nodes,
          result,
          archive,
          baseDir,
          BlockType.heading,
          headingLevel: level,
          indent: indent,
        );
        return;
      }
    }

    if (tag == 'ul' || tag == 'ol') {
      for (final li in element.children) {
        if (li.localName?.toLowerCase() == 'li') {
          _parseListItem(li, result, archive, baseDir, indent + 1);
        }
      }
      return;
    }

    if (tag == 'blockquote') {
      _parseBlockquote(element, result, archive, baseDir, indent + 1);
      return;
    }

    if (tag == 'table') {
      _parseTable(element, result, archive, baseDir, indent);
      return;
    }

    if (tag == 'hr') {
      return;
    }

    if (tag == 'pre') {
      final text = element.text.trimRight();
      if (text.trim().isNotEmpty) {
        result.add(
          TextBlock(type: BlockType.paragraph, spans: [StyledText(text)]),
        );
      }
      return;
    }

    if (tag == 'p' || !_hasDirectBlockChild(element)) {
      _appendInlineNodesAsBlocks(
        element.nodes,
        result,
        archive,
        baseDir,
        BlockType.paragraph,
        indent: indent,
      );
    } else {
      _parseNodesAsBlocks(element.nodes, result, archive, baseDir, indent);
    }
  }

  static void _parseBlockquote(
    dom.Element element,
    List<ContentBlock> result,
    Archive archive,
    String baseDir,
    int indent,
  ) {
    final inlineRun = <dom.Node>[];

    void flushQuoteLine() {
      if (inlineRun.isEmpty) return;
      _appendInlineNodesAsBlocks(
        inlineRun,
        result,
        archive,
        baseDir,
        BlockType.blockquote,
        indent: indent,
      );
      inlineRun.clear();
    }

    for (final node in element.nodes) {
      if (node is dom.Text) {
        if (node.text.trim().isNotEmpty) {
          inlineRun.add(node);
        }
        continue;
      }

      if (node is! dom.Element) continue;
      final tag = node.localName?.toLowerCase() ?? '';

      if ((tag == 'p' || tag == 'div') && !_hasDirectBlockChild(node)) {
        flushQuoteLine();
        _appendInlineNodesAsBlocks(
          node.nodes,
          result,
          archive,
          baseDir,
          BlockType.blockquote,
          indent: indent,
        );
      } else if (_isBlockElement(node) || _isImageElement(node)) {
        flushQuoteLine();
        _parseBlockElement(node, result, archive, baseDir, indent);
      } else {
        inlineRun.add(node);
      }
    }

    flushQuoteLine();
  }

  static void _parseListItem(
    dom.Element element,
    List<ContentBlock> result,
    Archive archive,
    String baseDir,
    int indent,
  ) {
    final inlineRun = <dom.Node>[];
    var emittedOwnLine = false;

    void flushOwnLine() {
      if (inlineRun.isEmpty) return;
      final before = result.length;
      _appendInlineNodesAsBlocks(
        inlineRun,
        result,
        archive,
        baseDir,
        BlockType.listItem,
        indent: indent,
      );
      emittedOwnLine = emittedOwnLine || result.length > before;
      inlineRun.clear();
    }

    for (final node in element.nodes) {
      if (node is dom.Text) {
        if (node.text.trim().isNotEmpty) {
          inlineRun.add(node);
        }
        continue;
      }

      if (node is! dom.Element) continue;
      final tag = node.localName?.toLowerCase() ?? '';

      if (tag == 'ul' || tag == 'ol') {
        flushOwnLine();
        _parseBlockElement(node, result, archive, baseDir, indent);
      } else if (_isBlockElement(node) || _isImageElement(node)) {
        if (!emittedOwnLine && _canRepresentAsListItem(node)) {
          flushOwnLine();
          final before = result.length;
          _appendInlineNodesAsBlocks(
            node.nodes,
            result,
            archive,
            baseDir,
            BlockType.listItem,
            indent: indent,
          );
          emittedOwnLine = emittedOwnLine || result.length > before;
        } else {
          flushOwnLine();
          _parseBlockElement(node, result, archive, baseDir, indent);
        }
      } else {
        inlineRun.add(node);
      }
    }

    flushOwnLine();
  }

  static void _parseTable(
    dom.Element table,
    List<ContentBlock> result,
    Archive archive,
    String baseDir,
    int indent,
  ) {
    final caption = table.querySelector('caption');
    if (caption != null) {
      _appendInlineNodesAsBlocks(
        caption.nodes,
        result,
        archive,
        baseDir,
        BlockType.paragraph,
        indent: indent,
      );
    }

    final rows = table.querySelectorAll('tr');
    for (final row in rows) {
      final cells = row
          .querySelectorAll('th, td')
          .map((cell) => _normalizePlainText(cell.text))
          .where((text) => text.isNotEmpty)
          .toList();
      if (cells.isEmpty) continue;
      result.add(
        TextBlock(
          type: BlockType.paragraph,
          spans: [StyledText(cells.join(' | '))],
          indent: indent,
        ),
      );
    }
  }

  static void _appendInlineNodesAsBlocks(
    Iterable<dom.Node> nodes,
    List<ContentBlock> result,
    Archive archive,
    String baseDir,
    BlockType blockType, {
    int headingLevel = 0,
    int indent = 0,
  }) {
    var spans = <StyledText>[];

    void flushTextBlock() {
      final normalized = _normalizeSpans(spans);
      if (normalized.any((span) => span.text.trim().isNotEmpty)) {
        result.add(
          TextBlock(
            type: blockType,
            headingLevel: headingLevel,
            spans: normalized,
            indent: indent,
          ),
        );
      }
      spans = [];
    }

    void visit(dom.Node node, InlineStyle style) {
      if (node is dom.Text) {
        if (node.text.isNotEmpty) {
          _appendStyledSpan(spans, StyledText(node.text, style));
        }
        return;
      }

      if (node is! dom.Element) return;

      final tag = node.localName?.toLowerCase() ?? '';
      if (_isImageElement(node)) {
        flushTextBlock();
        _addImageBlock(node, result, archive, baseDir);
        return;
      }

      if (_isBlockElement(node) && tag != 'br') {
        flushTextBlock();
        _parseBlockElement(node, result, archive, baseDir, indent);
        return;
      }

      if (tag == 'br') {
        _appendStyledSpan(spans, StyledText('\n', style));
        return;
      }

      var childStyle = style;
      if (tag == 'b' || tag == 'strong') {
        childStyle = style.merge(const InlineStyle(bold: true));
      } else if (tag == 'i' || tag == 'em' || tag == 'cite') {
        childStyle = style.merge(const InlineStyle(italic: true));
      }

      for (final child in node.nodes) {
        visit(child, childStyle);
      }
    }

    for (final node in nodes) {
      visit(node, InlineStyle.normal);
    }
    flushTextBlock();
  }

  static bool _isBlockElement(dom.Element element) {
    final tag = element.localName?.toLowerCase() ?? '';
    return _blockTags.contains(tag);
  }

  static bool _hasDirectBlockChild(dom.Element element) {
    return element.children.any((child) {
      if (_isImageElement(child)) return true;
      final tag = child.localName?.toLowerCase() ?? '';
      return _blockTags.contains(tag);
    });
  }

  static bool _canRepresentAsListItem(dom.Element element) {
    if (_isImageElement(element)) return false;
    final tag = element.localName?.toLowerCase() ?? '';
    return (tag == 'p' || tag == 'div' || tag == 'span') &&
        !_hasDirectBlockChild(element);
  }

  static bool _isImageElement(dom.Element element) {
    final tag = element.localName?.toLowerCase() ?? '';
    if (tag == 'img') return true;
    if (tag == 'image') {
      return _imageSource(element) != null;
    }
    return false;
  }

  static void _addImageBlock(
    dom.Element element,
    List<ContentBlock> result,
    Archive archive,
    String baseDir,
  ) {
    final src = _imageSource(element);
    if (src == null || src.trim().isEmpty) return;

    final resolvedPath = _resolveHref(baseDir, src);
    final bytes = _readFileBytes(archive, resolvedPath);
    result.add(
      ImageBlock(src: src, alt: element.attributes['alt'], bytes: bytes),
    );
  }

  static String? _imageSource(dom.Element element) {
    final src =
        element.attributes['src'] ??
        element.attributes['data-src'] ??
        element.attributes['href'] ??
        element.attributes['xlink:href'];
    if (src != null && src.trim().isNotEmpty) {
      return _stripHrefFragment(src.trim());
    }

    final srcset = element.attributes['srcset'];
    if (srcset == null || srcset.trim().isEmpty) return null;
    final first = srcset.split(',').first.trim();
    if (first.isEmpty) return null;
    return _stripHrefFragment(first.split(RegExp(r'\s+')).first);
  }

  static String _stripHrefFragment(String href) {
    final hashIndex = href.indexOf('#');
    return hashIndex == -1 ? href : href.substring(0, hashIndex);
  }

  static List<StyledText> _normalizeSpans(List<StyledText> spans) {
    final result = <StyledText>[];
    for (final span in spans) {
      var text = span.text
          .replaceAll('\u00A0', ' ')
          .replaceAll(RegExp(r'\s+'), ' ');

      if (text.isEmpty) continue;
      if (result.isEmpty) {
        text = text.trimLeft();
      } else if (result.last.text.endsWith(' ') && text.startsWith(' ')) {
        text = text.trimLeft();
      }
      if (text.isEmpty) continue;
      _appendStyledSpan(result, StyledText(text, span.style));
    }

    if (result.isEmpty) return result;
    final last = result.removeLast();
    final trimmed = last.text.trimRight();
    if (trimmed.isNotEmpty) {
      _appendStyledSpan(result, StyledText(trimmed, last.style));
    }
    return result;
  }

  static void _appendStyledSpan(List<StyledText> spans, StyledText span) {
    if (span.text.isEmpty) return;
    if (spans.isNotEmpty && _sameStyle(spans.last.style, span.style)) {
      final last = spans.removeLast();
      spans.add(StyledText('${last.text}${span.text}', last.style));
    } else {
      spans.add(span);
    }
  }

  static bool _sameStyle(InlineStyle a, InlineStyle b) {
    return a.bold == b.bold && a.italic == b.italic;
  }

  static String _plainTextFromBlocks(List<ContentBlock> blocks) {
    return blocks
        .map((block) {
          switch (block) {
            case TextBlock():
              return _normalizePlainText(block.plainText);
            case ImageBlock():
              return _normalizePlainText(block.alt ?? '');
          }
        })
        .where((text) => text.isNotEmpty)
        .join('\n\n');
  }

  static String _normalizePlainText(String text) {
    return text
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _decodeHref(String href) {
    try {
      return Uri.decodeFull(href);
    } catch (_) {
      return href;
    }
  }

  static String _resolveHref(String baseDir, String href) {
    final cleanHref = _decodeHref(_stripHrefFragment(href));
    if (cleanHref.startsWith('data:')) return cleanHref;
    if (cleanHref.startsWith('/')) return cleanHref.substring(1);

    final uri = Uri.tryParse(cleanHref);
    if (uri != null && uri.hasScheme) {
      return cleanHref;
    }

    final parts = <String>[];
    final baseParts = baseDir.split('/').where((p) => p.isNotEmpty).toList();
    parts.addAll(baseParts);

    for (final segment in cleanHref.split('/')) {
      if (segment == '..') {
        if (parts.isNotEmpty) parts.removeLast();
      } else if (segment != '.' && segment.isNotEmpty) {
        parts.add(segment);
      }
    }

    return parts.join('/');
  }
}

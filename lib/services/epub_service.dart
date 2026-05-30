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
    final archive = _EpubArchive(ZipDecoder().decodeBytes(bytes));

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

        final css = _buildStyleCascade(contentDoc, archive, chapterDir);
        _removeUnwantedElements(body);
        final blocks = _parseContentBlocks(
          contentDoc,
          archive,
          chapterDir,
          css,
        );
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

  static String? _readFile(_EpubArchive archive, String path) {
    return archive.readText(path);
  }

  static Uint8List? _readFileBytes(_EpubArchive archive, String path) {
    return archive.readBytes(path);
  }

  static void _removeUnwantedElements(dom.Element element) {
    element
        .querySelectorAll('script, style, nav, .nav, [hidden]')
        .forEach((e) => e.remove());

    for (final child in element.children) {
      _removeUnwantedElements(child);
    }
  }

  static _CssCascade _buildStyleCascade(
    dom.Document document,
    _EpubArchive archive,
    String baseDir,
  ) {
    final css = StringBuffer();

    for (final link in document.querySelectorAll('link')) {
      final rel = link.attributes['rel']?.toLowerCase() ?? '';
      final href = link.attributes['href'];
      if (!rel.split(RegExp(r'\s+')).contains('stylesheet') ||
          href == null ||
          href.trim().isEmpty) {
        continue;
      }
      final resolved = _resolveHref(baseDir, href);
      final linkedCss = _readFile(archive, resolved);
      if (linkedCss != null) {
        css.writeln(linkedCss);
      }
    }

    for (final style in document.querySelectorAll('style')) {
      css.writeln(style.text);
    }

    return _CssCascade.parse(css.toString());
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
    _EpubArchive archive,
    String baseDir,
    _CssCascade css,
  ) {
    final body = document.body;
    if (body == null) return [];

    final result = <ContentBlock>[];
    _parseNodesAsBlocks(body.nodes, result, archive, baseDir, 0, css);
    return result;
  }

  static void _parseNodesAsBlocks(
    Iterable<dom.Node> nodes,
    List<ContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    int indent,
    _CssCascade css,
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
        css: css,
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
        _parseBlockElement(node, result, archive, baseDir, indent, css);
      } else {
        inlineRun.add(node);
      }
    }

    flushInlineRun();
  }

  static void _parseBlockElement(
    dom.Element element,
    List<ContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    int indent,
    _CssCascade css,
  ) {
    final tag = element.localName?.toLowerCase() ?? '';
    final elementStyle = css.declarationFor(element);
    final blockStyle = elementStyle.blockStyle;

    if (_isImageElement(element)) {
      _addImageBlock(element, result, archive, baseDir, css);
      return;
    }

    if (tag == 'figure') {
      _parseFigure(element, result, archive, baseDir, indent, css);
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
          style: blockStyle,
          css: css,
        );
        return;
      }
    }

    if (tag == 'ul' || tag == 'ol') {
      for (final li in element.children) {
        if (li.localName?.toLowerCase() == 'li') {
          _parseListItem(li, result, archive, baseDir, indent + 1, css);
        }
      }
      return;
    }

    if (tag == 'blockquote') {
      _parseBlockquote(element, result, archive, baseDir, indent + 1, css);
      return;
    }

    if (tag == 'table') {
      _parseTable(element, result, archive, baseDir, indent, css);
      return;
    }

    if (tag == 'hr') {
      return;
    }

    if (tag == 'pre') {
      final text = element.text.trimRight();
      if (text.trim().isNotEmpty) {
        result.add(
          TextBlock(
            type: BlockType.paragraph,
            spans: [StyledText(text)],
            style: blockStyle,
          ),
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
        style: blockStyle,
        css: css,
      );
    } else {
      _parseNodesAsBlocks(element.nodes, result, archive, baseDir, indent, css);
    }
  }

  static void _parseFigure(
    dom.Element element,
    List<ContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    int indent,
    _CssCascade css,
  ) {
    final image = _firstImageDescendant(element);
    final caption = _normalizePlainText(
      element.querySelector('figcaption')?.text ?? '',
    );
    if (image != null) {
      _addImageBlock(
        image,
        result,
        archive,
        baseDir,
        css,
        parentBlockStyle: css.declarationFor(element).blockStyle,
        caption: caption,
      );
      return;
    }

    _parseNodesAsBlocks(element.nodes, result, archive, baseDir, indent, css);
  }

  static void _parseBlockquote(
    dom.Element element,
    List<ContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    int indent,
    _CssCascade css,
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
        style: css.declarationFor(element).blockStyle,
        css: css,
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
          style: css.declarationFor(node).blockStyle,
          css: css,
        );
      } else if (_isBlockElement(node) || _isImageElement(node)) {
        flushQuoteLine();
        _parseBlockElement(node, result, archive, baseDir, indent, css);
      } else {
        inlineRun.add(node);
      }
    }

    flushQuoteLine();
  }

  static void _parseListItem(
    dom.Element element,
    List<ContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    int indent,
    _CssCascade css,
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
        style: css.declarationFor(element).blockStyle,
        css: css,
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
        _parseBlockElement(node, result, archive, baseDir, indent, css);
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
            style: css.declarationFor(node).blockStyle,
            css: css,
          );
          emittedOwnLine = emittedOwnLine || result.length > before;
        } else {
          flushOwnLine();
          _parseBlockElement(node, result, archive, baseDir, indent, css);
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
    _EpubArchive archive,
    String baseDir,
    int indent,
    _CssCascade css,
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
        style: css.declarationFor(caption).blockStyle,
        css: css,
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
          style: css.declarationFor(row).blockStyle,
        ),
      );
    }
  }

  static void _appendInlineNodesAsBlocks(
    Iterable<dom.Node> nodes,
    List<ContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    BlockType blockType, {
    int headingLevel = 0,
    int indent = 0,
    ReaderBlockStyle style = ReaderBlockStyle.none,
    required _CssCascade css,
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
            style: style,
          ),
        );
      }
      spans = [];
    }

    void visit(dom.Node node, InlineStyle inlineStyle) {
      if (node is dom.Text) {
        if (node.text.isNotEmpty) {
          _appendStyledSpan(spans, StyledText(node.text, inlineStyle));
        }
        return;
      }

      if (node is! dom.Element) return;

      final tag = node.localName?.toLowerCase() ?? '';
      if (_isImageElement(node)) {
        flushTextBlock();
        _addImageBlock(
          node,
          result,
          archive,
          baseDir,
          css,
          parentBlockStyle: style,
        );
        return;
      }

      if (_isBlockElement(node) && tag != 'br') {
        flushTextBlock();
        _parseBlockElement(node, result, archive, baseDir, indent, css);
        return;
      }

      if (tag == 'br') {
        _appendStyledSpan(spans, StyledText('\n', inlineStyle));
        return;
      }

      var childStyle = inlineStyle.merge(css.declarationFor(node).inlineStyle);
      if (tag == 'b' || tag == 'strong') {
        childStyle = childStyle.merge(const InlineStyle(bold: true));
      } else if (tag == 'i' || tag == 'em' || tag == 'cite') {
        childStyle = childStyle.merge(const InlineStyle(italic: true));
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

  static dom.Element? _firstImageDescendant(dom.Element element) {
    for (final child in element.children) {
      if (_isImageElement(child)) return child;
      final nested = _firstImageDescendant(child);
      if (nested != null) return nested;
    }
    return null;
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
    _EpubArchive archive,
    String baseDir,
    _CssCascade css, {
    ReaderBlockStyle parentBlockStyle = ReaderBlockStyle.none,
    String? caption,
  }) {
    final src = _imageSource(element);
    if (src == null || src.trim().isEmpty) return;

    final resolvedPath = _resolveHref(baseDir, src);
    final bytes = _readFileBytes(archive, resolvedPath);
    final naturalDimensions = _imageDimensionsFromBytes(bytes);
    final declaredWidth = CssLength.parse(
      element.attributes['width'],
      allowUnitlessPx: true,
    );
    final declaredHeight = CssLength.parse(
      element.attributes['height'],
      allowUnitlessPx: true,
    );
    var imageStyle = css.declarationFor(element).imageStyle;
    if (imageStyle.width == null && declaredWidth is! CssPx) {
      imageStyle = imageStyle.merge(ImageStyleData(width: declaredWidth));
    }
    if (imageStyle.height == null && declaredHeight is! CssPx) {
      imageStyle = imageStyle.merge(ImageStyleData(height: declaredHeight));
    }
    if (imageStyle.alignment == null && parentBlockStyle.textAlign != null) {
      imageStyle = imageStyle.merge(
        ImageStyleData(alignment: parentBlockStyle.textAlign),
      );
    }

    result.add(
      ImageBlock(
        src: src,
        alt: element.attributes['alt'],
        bytes: bytes,
        declaredWidth: _cssPxValue(declaredWidth),
        declaredHeight: _cssPxValue(declaredHeight),
        naturalWidth: naturalDimensions?.width.toDouble(),
        naturalHeight: naturalDimensions?.height.toDouble(),
        style: imageStyle,
        caption: caption == null || caption.trim().isEmpty
            ? null
            : caption.trim(),
      ),
    );
  }

  static double? _cssPxValue(CssLength? length) {
    return switch (length) {
      CssPx(:final value) when value > 0 => value,
      _ => null,
    };
  }

  static ({int width, int height})? _imageDimensionsFromBytes(
    Uint8List? bytes,
  ) {
    if (bytes == null || bytes.length < 10) return null;
    return _pngDimensions(bytes) ??
        _jpegDimensions(bytes) ??
        _gifDimensions(bytes);
  }

  static ({int width, int height})? _pngDimensions(Uint8List bytes) {
    if (bytes.length < 24) return null;
    const signature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    for (var i = 0; i < signature.length; i += 1) {
      if (bytes[i] != signature[i]) return null;
    }
    return (
      width: _readUint32BigEndian(bytes, 16),
      height: _readUint32BigEndian(bytes, 20),
    );
  }

  static ({int width, int height})? _gifDimensions(Uint8List bytes) {
    if (bytes.length < 10) return null;
    final header = ascii.decode(bytes.sublist(0, 6), allowInvalid: true);
    if (header != 'GIF87a' && header != 'GIF89a') return null;
    return (
      width: _readUint16LittleEndian(bytes, 6),
      height: _readUint16LittleEndian(bytes, 8),
    );
  }

  static ({int width, int height})? _jpegDimensions(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      return null;
    }

    var offset = 2;
    while (offset + 9 < bytes.length) {
      if (bytes[offset] != 0xFF) {
        offset += 1;
        continue;
      }
      var marker = bytes[offset + 1];
      while (marker == 0xFF && offset + 2 < bytes.length) {
        offset += 1;
        marker = bytes[offset + 1];
      }
      if (marker == 0xD9 || marker == 0xDA) return null;
      if (offset + 4 >= bytes.length) return null;
      final segmentLength = _readUint16BigEndian(bytes, offset + 2);
      if (segmentLength < 2 || offset + 2 + segmentLength > bytes.length) {
        return null;
      }
      if (_isJpegStartOfFrame(marker)) {
        return (
          height: _readUint16BigEndian(bytes, offset + 5),
          width: _readUint16BigEndian(bytes, offset + 7),
        );
      }
      offset += 2 + segmentLength;
    }
    return null;
  }

  static bool _isJpegStartOfFrame(int marker) {
    return (marker >= 0xC0 && marker <= 0xC3) ||
        (marker >= 0xC5 && marker <= 0xC7) ||
        (marker >= 0xC9 && marker <= 0xCB) ||
        (marker >= 0xCD && marker <= 0xCF);
  }

  static int _readUint16BigEndian(Uint8List bytes, int offset) {
    return (bytes[offset] << 8) | bytes[offset + 1];
  }

  static int _readUint16LittleEndian(Uint8List bytes, int offset) {
    return bytes[offset] | (bytes[offset + 1] << 8);
  }

  static int _readUint32BigEndian(Uint8List bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
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
              return _normalizePlainText(
                [block.alt, block.caption]
                    .whereType<String>()
                    .where((text) => text.trim().isNotEmpty)
                    .join(' '),
              );
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

class _CssCascade {
  final Map<String, List<_CssRule>> _tagRules;
  final Map<String, List<_CssRule>> _classRules;
  final Map<String, List<_CssRule>> _idRules;

  const _CssCascade._(this._tagRules, this._classRules, this._idRules);

  static _CssCascade parse(String css) {
    final cleaned = css.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    final tagRules = <String, List<_CssRule>>{};
    final classRules = <String, List<_CssRule>>{};
    final idRules = <String, List<_CssRule>>{};
    var order = 0;
    for (final match in RegExp(r'([^{}]+)\{([^{}]*)\}').allMatches(cleaned)) {
      final selectorText = match.group(1)?.trim() ?? '';
      final declaration = _CssDeclaration.parse(match.group(2) ?? '');
      if (declaration.isEmpty) continue;

      for (final rawSelector in selectorText.split(',')) {
        final selector = _CssSelector.parse(rawSelector.trim());
        if (selector == null) continue;
        final rule = _CssRule(selector, declaration, order++);
        switch (selector.kind) {
          case _CssSelectorKind.tag:
            (tagRules[selector.value] ??= []).add(rule);
          case _CssSelectorKind.className:
            (classRules[selector.value] ??= []).add(rule);
          case _CssSelectorKind.id:
            (idRules[selector.value] ??= []).add(rule);
        }
      }
    }
    return _CssCascade._(tagRules, classRules, idRules);
  }

  _CssDeclaration declarationFor(dom.Element element) {
    var declaration = const _CssDeclaration();

    for (final rule
        in _tagRules[element.localName?.toLowerCase() ?? ''] ??
            const <_CssRule>[]) {
      declaration = declaration.merge(rule.declaration);
    }

    final classMatches = <_CssRule>[];
    for (final className
        in (element.attributes['class'] ?? '').toLowerCase().split(
          RegExp(r'\s+'),
        )) {
      classMatches.addAll(_classRules[className] ?? const <_CssRule>[]);
    }
    classMatches.sort((a, b) => a.order.compareTo(b.order));
    for (final rule in classMatches) {
      declaration = declaration.merge(rule.declaration);
    }

    for (final rule
        in _idRules[element.attributes['id']?.toLowerCase() ?? ''] ??
            const <_CssRule>[]) {
      declaration = declaration.merge(rule.declaration);
    }

    return declaration.merge(
      _CssDeclaration.parse(element.attributes['style'] ?? ''),
    );
  }
}

class _CssRule {
  final _CssSelector selector;
  final _CssDeclaration declaration;
  final int order;

  const _CssRule(this.selector, this.declaration, this.order);
}

enum _CssSelectorKind { tag, className, id }

class _CssSelector {
  final _CssSelectorKind kind;
  final String value;

  const _CssSelector(this.kind, this.value);

  static _CssSelector? parse(String selector) {
    if (selector.isEmpty ||
        selector.contains(RegExp(r'[\s>+~:\[\]*=]')) ||
        selector.startsWith('@')) {
      return null;
    }
    if (selector.startsWith('.')) {
      final value = selector.substring(1).trim().toLowerCase();
      return _validIdentifier(value)
          ? _CssSelector(_CssSelectorKind.className, value)
          : null;
    }
    if (selector.startsWith('#')) {
      final value = selector.substring(1).trim().toLowerCase();
      return _validIdentifier(value)
          ? _CssSelector(_CssSelectorKind.id, value)
          : null;
    }
    final tag = selector.toLowerCase();
    return RegExp(r'^[a-z][a-z0-9-]*$').hasMatch(tag)
        ? _CssSelector(_CssSelectorKind.tag, tag)
        : null;
  }

  static bool _validIdentifier(String value) {
    return RegExp(r'^[a-z0-9_-]+$').hasMatch(value);
  }
}

class _CssDeclaration {
  final InlineStyle inlineStyle;
  final ReaderBlockStyle blockStyle;
  final ImageStyleData imageStyle;

  const _CssDeclaration({
    this.inlineStyle = InlineStyle.normal,
    this.blockStyle = ReaderBlockStyle.none,
    this.imageStyle = ImageStyleData.none,
  });

  bool get isEmpty =>
      inlineStyle.bold == false &&
      inlineStyle.italic == false &&
      identical(blockStyle, ReaderBlockStyle.none) &&
      identical(imageStyle, ImageStyleData.none);

  static _CssDeclaration parse(String source) {
    var inlineStyle = InlineStyle.normal;
    var blockStyle = ReaderBlockStyle.none;
    var imageStyle = ImageStyleData.none;
    CssLength? marginLeft;
    CssLength? marginRight;

    for (final declaration in source.split(';')) {
      final colon = declaration.indexOf(':');
      if (colon <= 0) continue;
      final property = declaration.substring(0, colon).trim().toLowerCase();
      final value = declaration.substring(colon + 1).trim().toLowerCase();
      if (value.isEmpty) continue;

      switch (property) {
        case 'font-style':
          if (value == 'italic' || value == 'oblique') {
            inlineStyle = inlineStyle.merge(const InlineStyle(italic: true));
          }
        case 'font-weight':
          if (value == 'bold' ||
              value == 'bolder' ||
              ((int.tryParse(value) ?? 0) >= 600)) {
            inlineStyle = inlineStyle.merge(const InlineStyle(bold: true));
          }
        case 'text-align':
          blockStyle = blockStyle.merge(
            ReaderBlockStyle(textAlign: _parseTextAlign(value)),
          );
        case 'text-indent':
          blockStyle = blockStyle.merge(
            ReaderBlockStyle(
              textIndent: CssLength.parse(value, allowUnitlessPx: true),
            ),
          );
        case 'line-height':
          blockStyle = blockStyle.merge(
            ReaderBlockStyle(lineHeight: _parseLineHeight(value)),
          );
        case 'font-size':
          blockStyle = blockStyle.merge(
            ReaderBlockStyle(fontSizeScale: _parseFontSizeScale(value)),
          );
        case 'margin-top':
          blockStyle = blockStyle.merge(
            ReaderBlockStyle(
              marginTop: CssLength.parse(value, allowUnitlessPx: true),
            ),
          );
        case 'margin-bottom':
          blockStyle = blockStyle.merge(
            ReaderBlockStyle(
              marginBottom: CssLength.parse(value, allowUnitlessPx: true),
            ),
          );
        case 'padding-left':
          blockStyle = blockStyle.merge(
            ReaderBlockStyle(
              paddingLeft: CssLength.parse(value, allowUnitlessPx: true),
            ),
          );
        case 'padding-right':
          blockStyle = blockStyle.merge(
            ReaderBlockStyle(
              paddingRight: CssLength.parse(value, allowUnitlessPx: true),
            ),
          );
        case 'width':
          imageStyle = imageStyle.merge(
            ImageStyleData(
              width: CssLength.parse(value, allowUnitlessPx: true),
            ),
          );
        case 'height':
          imageStyle = imageStyle.merge(
            ImageStyleData(
              height: CssLength.parse(value, allowUnitlessPx: true),
            ),
          );
        case 'max-width':
          imageStyle = imageStyle.merge(
            ImageStyleData(
              maxWidth: CssLength.parse(value, allowUnitlessPx: true),
            ),
          );
        case 'max-height':
          imageStyle = imageStyle.merge(
            ImageStyleData(
              maxHeight: CssLength.parse(value, allowUnitlessPx: true),
            ),
          );
        case 'margin-left':
          marginLeft = CssLength.parse(value, allowUnitlessPx: true);
          imageStyle = imageStyle.merge(ImageStyleData(marginLeft: marginLeft));
        case 'margin-right':
          marginRight = CssLength.parse(value, allowUnitlessPx: true);
          imageStyle = imageStyle.merge(
            ImageStyleData(marginRight: marginRight),
          );
        case 'display':
          if (value == 'block' || value == 'inline-block') {
            imageStyle = imageStyle.merge(
              const ImageStyleData(displayBlock: true),
            );
          }
      }
    }

    final textAlign = blockStyle.textAlign;
    if (textAlign != null) {
      imageStyle = imageStyle.merge(ImageStyleData(alignment: textAlign));
    }
    if (marginLeft is CssAuto && marginRight is CssAuto) {
      imageStyle = imageStyle.merge(
        const ImageStyleData(alignment: ReaderTextAlign.center),
      );
    }

    return _CssDeclaration(
      inlineStyle: inlineStyle,
      blockStyle: blockStyle,
      imageStyle: imageStyle,
    );
  }

  _CssDeclaration merge(_CssDeclaration other) {
    return _CssDeclaration(
      inlineStyle: inlineStyle.merge(other.inlineStyle),
      blockStyle: blockStyle.merge(other.blockStyle),
      imageStyle: imageStyle.merge(other.imageStyle),
    );
  }

  static ReaderTextAlign? _parseTextAlign(String value) {
    return switch (value) {
      'center' => ReaderTextAlign.center,
      'right' || 'end' => ReaderTextAlign.end,
      'justify' => ReaderTextAlign.justify,
      'left' || 'start' => ReaderTextAlign.start,
      _ => null,
    };
  }

  static double? _parseLineHeight(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed.isFinite && parsed > 0) {
      return parsed.clamp(1.0, 3.0).toDouble();
    }
    final length = CssLength.parse(value);
    return switch (length) {
      CssEm(:final value) || CssRem(:final value)
          when value.isFinite && value > 0 =>
        value.clamp(1.0, 3.0).toDouble(),
      CssPercent(:final value) when value.isFinite && value > 0 =>
        (value / 100).clamp(1.0, 3.0).toDouble(),
      _ => null,
    };
  }

  static double? _parseFontSizeScale(String value) {
    final length = CssLength.parse(value, allowUnitlessPx: true);
    final scale = switch (length) {
      CssEm(:final value) || CssRem(:final value) => value,
      CssPercent(:final value) => value / 100,
      CssPx(:final value) => value / 16,
      _ => null,
    };
    if (scale == null || !scale.isFinite || scale <= 0) return null;
    return scale.clamp(0.75, 1.8).toDouble();
  }
}

class _EpubArchive {
  final Map<String, ArchiveFile> _filesByPath;

  _EpubArchive(Archive archive)
    : _filesByPath = {
        for (final file in archive) _normalizePath(file.name): file,
      };

  String? readText(String path) {
    final bytes = readBytes(path);
    if (bytes == null) return null;
    return utf8.decode(bytes, allowMalformed: true);
  }

  Uint8List? readBytes(String path) {
    final file = _filesByPath[_normalizePath(path)];
    if (file == null) return null;
    return Uint8List.fromList(file.content as List<int>);
  }

  static String _normalizePath(String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return normalized.toLowerCase();
  }
}

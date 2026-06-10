import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:xml/xml.dart';

import 'epub_models.dart';

typedef EpubParseProgressCallback = void Function(EpubParseEvent event);
typedef EpubParseProfileCallback = void Function(EpubParseProfileEvent event);

enum EpubParsePhase {
  extractingMetadata,
  parsingChapter,
  buildingBlocks,
  loadingImage,
  complete,
}

class EpubParseEvent {
  const EpubParseEvent({
    required this.phase,
    this.chapterIndex,
    required this.totalChapters,
    this.chapterTitle,
    required this.progress,
  }) : assert(progress >= 0 && progress <= 1);

  final EpubParsePhase phase;
  final int? chapterIndex;
  final int totalChapters;
  final String? chapterTitle;
  final double progress;
}

class EpubParseProfileEvent {
  const EpubParseProfileEvent({
    required this.stage,
    required this.elapsed,
    this.chapterIndex,
    this.detail,
  });

  final String stage;
  final Duration elapsed;
  final int? chapterIndex;
  final String? detail;
}

class EpubParser {
  static Future<ParsedEpubBook> parseBytes(
    Uint8List bytes, {
    EpubParseProgressCallback? onProgress,
    EpubParseProfileCallback? onProfile,
  }) async {
    return parseBytesSync(bytes, onProgress: onProgress, onProfile: onProfile);
  }

  static ParsedEpubBook parseBytesSync(
    Uint8List bytes, {
    EpubParseProgressCallback? onProgress,
    EpubParseProfileCallback? onProfile,
  }) {
    T measure<T>(
      String stage,
      T Function() body, {
      int? chapterIndex,
      String? detail,
    }) {
      final stopwatch = Stopwatch()..start();
      try {
        return body();
      } finally {
        stopwatch.stop();
        onProfile?.call(
          EpubParseProfileEvent(
            stage: stage,
            elapsed: stopwatch.elapsed,
            chapterIndex: chapterIndex,
            detail: detail,
          ),
        );
      }
    }

    void profile(
      String stage,
      Duration elapsed, {
      int? chapterIndex,
      String? detail,
    }) {
      onProfile?.call(
        EpubParseProfileEvent(
          stage: stage,
          elapsed: elapsed,
          chapterIndex: chapterIndex,
          detail: detail,
        ),
      );
    }

    void report(
      EpubParsePhase phase, {
      int? chapterIndex,
      int totalChapters = 0,
      String? chapterTitle,
      required double progress,
    }) {
      onProgress?.call(
        EpubParseEvent(
          phase: phase,
          chapterIndex: chapterIndex,
          totalChapters: totalChapters,
          chapterTitle: chapterTitle,
          progress: progress.clamp(0.0, 1.0).toDouble(),
        ),
      );
    }

    report(EpubParsePhase.extractingMetadata, progress: 0);
    final archive = measure(
      'zip.decode',
      () => _EpubArchive(ZipDecoder().decodeBytes(bytes)),
    );

    final containerXml = measure(
      'metadata.container.read',
      () => _readFile(archive, 'META-INF/container.xml'),
    );
    if (containerXml == null) {
      throw const FormatException('Invalid EPUB: missing container.xml');
    }

    final containerDoc = measure(
      'metadata.container.xml',
      () => XmlDocument.parse(containerXml),
    );
    final rootfileEl = containerDoc.findAllElements('rootfile').firstOrNull;
    if (rootfileEl == null) {
      throw const FormatException('Invalid EPUB: missing rootfile element');
    }

    final opfPath = rootfileEl.getAttribute('full-path')!;
    final opfDir = opfPath.contains('/')
        ? '${opfPath.substring(0, opfPath.lastIndexOf('/'))}/'
        : '';

    final opfContent = measure(
      'metadata.opf.read',
      () => _readFile(archive, opfPath),
    );
    if (opfContent == null) {
      throw FormatException('Invalid EPUB: missing OPF file at $opfPath');
    }

    final opfDoc = measure(
      'metadata.opf.xml',
      () => XmlDocument.parse(opfContent),
    );
    final package = opfDoc.rootElement;

    final title = _findDcElement(package, 'title') ?? 'Unknown Title';
    final author = _findDcElement(package, 'creator') ?? 'Unknown Author';
    final language = _findDcElement(package, 'language');

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

    final spineItems = <({String idref, String href, String mediaType})>[];
    final spineEl = package.findAllElements('spine').firstOrNull;
    if (spineEl != null) {
      for (final itemref in spineEl.findElements('itemref')) {
        final idref = itemref.getAttribute('idref');
        if (idref == null || !manifest.containsKey(idref)) continue;

        final entry = manifest[idref]!;
        if (!entry.mediaType.contains('html')) continue;
        spineItems.add((
          idref: idref,
          href: entry.href,
          mediaType: entry.mediaType,
        ));
      }
    }
    final totalChapters = spineItems.length;
    report(
      EpubParsePhase.extractingMetadata,
      totalChapters: totalChapters,
      progress: totalChapters == 0 ? 0.5 : 0.05,
    );

    // Parse NCX for table of contents
    final toc = _parseNcx(archive, package, manifest, opfDir);

    // Extract cover image
    Uint8List? coverBytes;
    final coverId = _findCoverId(package, manifest);
    if (coverId != null && manifest.containsKey(coverId)) {
      final coverHref = manifest[coverId]!.href;
      coverBytes = measure(
        'cover.read',
        () => _readFileBytes(archive, '$opfDir$coverHref'),
      );
    }

    // Read chapters in spine order
    final chapters = <ParsedEpubChapter>[];
    final styleCache = <String, _CssCascade>{};

    if (spineItems.isNotEmpty) {
      for (var i = 0; i < spineItems.length; i += 1) {
        final entry = spineItems[i];
        final chapterHref = '$opfDir${entry.href}';
        final chapterDir = chapterHref.contains('/')
            ? '${chapterHref.substring(0, chapterHref.lastIndexOf('/'))}/'
            : opfDir;

        report(
          EpubParsePhase.parsingChapter,
          chapterIndex: i,
          totalChapters: totalChapters,
          progress: _chapterProgress(i, totalChapters, 0),
        );

        final html = measure(
          'chapter.read',
          () => _readFile(archive, chapterHref),
          chapterIndex: i,
          detail: entry.href,
        );
        if (html == null) {
          report(
            EpubParsePhase.parsingChapter,
            chapterIndex: i,
            totalChapters: totalChapters,
            progress: _chapterProgress(i, totalChapters, 1),
          );
          continue;
        }

        final chapterTitle = _extractDocumentTitleFast(html);
        report(
          EpubParsePhase.buildingBlocks,
          chapterIndex: i,
          totalChapters: totalChapters,
          chapterTitle: chapterTitle.isEmpty ? null : chapterTitle,
          progress: _chapterProgress(i, totalChapters, 0.45),
        );
        final parsedChapter = _parseChapter(
          html,
          archive,
          chapterHref,
          chapterDir,
          spineHref: entry.href,
          chapterIndex: i,
          styleCache: styleCache,
          profile: profile,
          onImageLoad: () {
            report(
              EpubParsePhase.loadingImage,
              chapterIndex: i,
              totalChapters: totalChapters,
              chapterTitle: chapterTitle.isEmpty ? null : chapterTitle,
              progress: _chapterProgress(i, totalChapters, 0.7),
            );
          },
        );

        if (parsedChapter != null) {
          chapters.add(parsedChapter);
        }
        report(
          EpubParsePhase.parsingChapter,
          chapterIndex: i,
          totalChapters: totalChapters,
          chapterTitle: parsedChapter?.documentTitle.isEmpty ?? true
              ? null
              : parsedChapter?.documentTitle,
          progress: _chapterProgress(i, totalChapters, 1),
        );
      }
    }

    if (chapters.isEmpty) {
      chapters.add(
        const ParsedEpubChapter(
          documentTitle: 'Content',
          plainText: '(No readable content found)',
          rawHtml: '',
        ),
      );
    }

    // Extract footnote content from spine items
    final footnoteMap = _extractFootnotes(archive, spineItems, opfDir);

    report(
      EpubParsePhase.complete,
      totalChapters: chapters.length,
      progress: 1,
    );

    return ParsedEpubBook(
      title: title,
      author: author,
      language: language,
      chapters: chapters,
      coverBytes: coverBytes,
      toc: toc,
      footnoteMap: footnoteMap,
    );
  }

  static ParsedEpubChapter? _parseChapter(
    String html,
    _EpubArchive archive,
    String chapterHref,
    String chapterDir, {
    required String spineHref,
    required Map<String, _CssCascade> styleCache,
    required int chapterIndex,
    void Function(
      String stage,
      Duration elapsed, {
      int? chapterIndex,
      String? detail,
    })?
    profile,
    void Function()? onImageLoad,
  }) {
    final fastStopwatch = Stopwatch()..start();
    try {
      final chapter = _parseChapterWithFastHtmlTree(
        html,
        archive,
        chapterDir,
        styleCache: styleCache,
        onImageLoad: onImageLoad,
      );
      fastStopwatch.stop();
      profile?.call(
        'chapter.fastHtml',
        fastStopwatch.elapsed,
        chapterIndex: chapterIndex,
        detail: chapterHref,
      );
      return chapter != null
          ? ParsedEpubChapter(
              documentTitle: chapter.documentTitle,
              plainText: chapter.plainText,
              rawHtml: chapter.rawHtml,
              blocks: chapter.blocks,
              href: spineHref,
            )
          : null;
    } catch (_) {
      fastStopwatch.stop();
      profile?.call(
        'chapter.fastHtmlFallback',
        fastStopwatch.elapsed,
        chapterIndex: chapterIndex,
        detail: chapterHref,
      );
    }

    final fallbackStopwatch = Stopwatch()..start();
    try {
      final chapter = _parseChapterWithDom(
        html,
        archive,
        chapterDir,
        styleCache: styleCache,
        onImageLoad: onImageLoad,
      );
      return chapter != null
          ? ParsedEpubChapter(
              documentTitle: chapter.documentTitle,
              plainText: chapter.plainText,
              rawHtml: chapter.rawHtml,
              blocks: chapter.blocks,
              href: spineHref,
            )
          : null;
    } finally {
      fallbackStopwatch.stop();
      profile?.call(
        'chapter.domFallback',
        fallbackStopwatch.elapsed,
        chapterIndex: chapterIndex,
        detail: chapterHref,
      );
    }
  }

  static ParsedEpubChapter? _parseChapterWithDom(
    String html,
    _EpubArchive archive,
    String chapterDir, {
    Map<String, _CssCascade>? styleCache,
    void Function()? onImageLoad,
  }) {
    final contentDoc = html_parser.parse(html);
    final body = contentDoc.body;
    if (body == null) return null;

    final documentTitle = _normalizePlainText(
      contentDoc.querySelector('title')?.text ?? '',
    );

    final css = _buildStyleCascade(
      contentDoc,
      archive,
      chapterDir,
      styleCache: styleCache,
    );
    _removeUnwantedElements(body);
    final blocks = _parseParsedContentBlocks(
      contentDoc,
      archive,
      chapterDir,
      css,
      onImageLoad: onImageLoad,
    );
    final plainText = _plainTextFromBlocks(blocks);

    if (plainText.trim().isEmpty && !blocks.any((b) => b is ParsedImageBlock)) {
      return null;
    }

    return ParsedEpubChapter(
      documentTitle: documentTitle,
      plainText: plainText,
      rawHtml: html,
      blocks: blocks,
    );
  }

  static String _extractDocumentTitleFast(String html) {
    final match = RegExp(
      r'<title[^>]*>(.*?)</title>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(html);
    return _normalizePlainText(match?.group(1) ?? '');
  }

  static double _chapterProgress(
    int chapterIndex,
    int totalChapters,
    double chapterProgress,
  ) {
    if (totalChapters <= 0) {
      return chapterProgress.clamp(0.0, 1.0).toDouble();
    }
    final normalizedChapterProgress =
        (chapterIndex.clamp(0, totalChapters) +
            chapterProgress.clamp(0.0, 1.0)) /
        totalChapters;
    final value = 0.05 + normalizedChapterProgress * 0.9;
    return value.clamp(0.0, 1.0).toDouble();
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

  static List<EpubTocEntry> _parseNcx(
    _EpubArchive archive,
    XmlElement package,
    Map<String, ({String href, String mediaType, String? properties})> manifest,
    String opfDir,
  ) {
    final ncxId = package
        .findAllElements('spine')
        .firstOrNull
        ?.getAttribute('toc');
    if (ncxId == null || !manifest.containsKey(ncxId)) return const [];
    final ncxHref = manifest[ncxId]!.href;
    final ncxContent = _readFile(archive, '$opfDir$ncxHref');
    if (ncxContent == null) return const [];
    final ncxDoc = XmlDocument.parse(ncxContent);
    final entries = <EpubTocEntry>[];

    void visitNavPoints(XmlElement parent, int level) {
      for (final navPoint in parent.findElements('navPoint')) {
        final label = navPoint.findElements('navLabel').firstOrNull;
        final labelText =
            label?.findElements('text').firstOrNull?.innerText.trim() ?? '';
        final content = navPoint.findElements('content').firstOrNull;
        final src = content?.getAttribute('src') ?? '';
        final playOrder =
            int.tryParse(navPoint.getAttribute('playOrder') ?? '') ?? 0;
        if (labelText.isNotEmpty && src.isNotEmpty) {
          entries.add(
            EpubTocEntry(
              label: labelText,
              href: src,
              playOrder: playOrder,
              level: level,
            ),
          );
        }
        visitNavPoints(navPoint, level + 1);
      }
    }

    final navMap = ncxDoc.rootElement.findAllElements('navMap').firstOrNull;
    if (navMap == null) {
      visitNavPoints(ncxDoc.rootElement, 0);
      return entries;
    }
    visitNavPoints(navMap, 0);
    return entries;
  }

  static Map<String, String> _extractFootnotes(
    _EpubArchive archive,
    List<({String idref, String href, String mediaType})> spineItems,
    String opfDir,
  ) {
    final footnoteMap = <String, String>{};
    for (final entry in spineItems) {
      final href = '$opfDir${entry.href}';
      final html = _readFile(archive, href);
      if (html == null ||
          !(html.contains('rearnote') || html.contains('noteref'))) {
        continue;
      }
      final doc = html_parser.parse(html);
      for (final aside in doc.querySelectorAll('aside[type="rearnote"]')) {
        final id = aside.attributes['id'];
        if (id == null) {
          continue;
        }
        final fullText = aside.text.trim();
        final cleanedText = fullText
            .replaceFirst(RegExp(r'^\[\d+\]\s*'), '')
            .trim();
        if (cleanedText.isNotEmpty) {
          footnoteMap[id] = cleanedText;
        }
      }
    }
    return footnoteMap;
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
    String baseDir, {
    Map<String, _CssCascade>? styleCache,
  }) {
    final linkedPaths = <String>[];
    final inlineStyles = <String>[];

    for (final link in document.querySelectorAll('link')) {
      final rel = link.attributes['rel']?.toLowerCase() ?? '';
      final href = link.attributes['href'];
      if (!rel.split(RegExp(r'\s+')).contains('stylesheet') ||
          href == null ||
          href.trim().isEmpty) {
        continue;
      }
      final resolved = _resolveHref(baseDir, href);
      linkedPaths.add(resolved);
    }

    for (final style in document.querySelectorAll('style')) {
      inlineStyles.add(style.text);
    }

    final cacheKey = _styleCacheKey(linkedPaths, inlineStyles);
    final cached = styleCache?[cacheKey];
    if (cached != null) return cached;

    final css = StringBuffer();
    for (final resolved in linkedPaths) {
      final linkedCss = _readFile(archive, resolved);
      if (linkedCss != null) {
        css.writeln(linkedCss);
      }
    }

    for (final style in inlineStyles) {
      css.writeln(style);
    }

    final cascade = _CssCascade.parse(css.toString());
    styleCache?[cacheKey] = cascade;
    return cascade;
  }

  static String _styleCacheKey(
    List<String> linkedPaths,
    List<String> inlineStyles,
  ) {
    final buffer = StringBuffer();
    for (final path in linkedPaths) {
      buffer
        ..write('link:')
        ..writeln(path);
    }
    for (final style in inlineStyles) {
      buffer
        ..write('inline:')
        ..write(style.length)
        ..write(':')
        ..writeln(style);
    }
    return buffer.toString();
  }

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

  static const _voidTags = {
    'area',
    'base',
    'br',
    'col',
    'embed',
    'hr',
    'img',
    'input',
    'link',
    'meta',
    'param',
    'source',
    'track',
    'wbr',
  };

  static List<ParsedContentBlock> _parseParsedContentBlocks(
    dom.Document document,
    _EpubArchive archive,
    String baseDir,
    _CssCascade css, {
    void Function()? onImageLoad,
  }) {
    final body = document.body;
    if (body == null) return [];

    final result = <ParsedContentBlock>[];
    _parseNodesAsBlocks(
      body.nodes,
      result,
      archive,
      baseDir,
      0,
      css,
      onImageLoad: onImageLoad,
    );
    return result;
  }

  static ParsedEpubChapter? _parseChapterWithFastHtmlTree(
    String html,
    _EpubArchive archive,
    String baseDir, {
    required Map<String, _CssCascade> styleCache,
    void Function()? onImageLoad,
  }) {
    final document = _buildFastHtmlTree(html);
    final body = document.firstDescendantByTag('body');
    if (body == null) {
      throw const FormatException('Fast HTML parse failed: missing body');
    }

    final documentTitle = _normalizePlainText(
      document.firstDescendantByTag('title')?.text ?? '',
    );
    final css = _buildFastStyleCascade(
      document,
      archive,
      baseDir,
      styleCache: styleCache,
    );
    final blocks = <ParsedContentBlock>[];
    _parseFastNodesAsBlocks(
      body.children,
      blocks,
      archive,
      baseDir,
      0,
      css,
      onImageLoad: onImageLoad,
    );
    final plainText = _plainTextFromBlocks(blocks);
    if (plainText.trim().isEmpty && !blocks.any((b) => b is ParsedImageBlock)) {
      return null;
    }

    return ParsedEpubChapter(
      documentTitle: documentTitle,
      plainText: plainText,
      rawHtml: html,
      blocks: blocks,
    );
  }

  static _XElement _buildFastHtmlTree(String html) {
    final root = _XElement('#document', const {});
    final stack = <_XElement>[root];
    var index = 0;

    void appendText(int start, int end) {
      if (end <= start) return;
      final text = _decodeHtmlEntities(html.substring(start, end));
      if (text.isNotEmpty) {
        stack.last.children.add(_XText(text));
      }
    }

    while (index < html.length) {
      final tagStart = html.indexOf('<', index);
      if (tagStart == -1) {
        appendText(index, html.length);
        break;
      }

      appendText(index, tagStart);

      if (html.startsWith('<!--', tagStart)) {
        final commentEnd = html.indexOf('-->', tagStart + 4);
        if (commentEnd == -1) {
          throw const FormatException('Fast HTML parse failed: open comment');
        }
        index = commentEnd + 3;
        continue;
      }

      if (html.startsWith('<![CDATA[', tagStart)) {
        final cdataEnd = html.indexOf(']]>', tagStart + 9);
        if (cdataEnd == -1) {
          throw const FormatException('Fast HTML parse failed: open cdata');
        }
        appendText(tagStart + 9, cdataEnd);
        index = cdataEnd + 3;
        continue;
      }

      if (html.startsWith('<?', tagStart)) {
        final processingEnd = html.indexOf('?>', tagStart + 2);
        if (processingEnd == -1) {
          throw const FormatException(
            'Fast HTML parse failed: open processing instruction',
          );
        }
        index = processingEnd + 2;
        continue;
      }

      final tagEnd = _findFastTagEnd(html, tagStart + 1);
      if (tagEnd == -1) {
        throw const FormatException('Fast HTML parse failed: open tag');
      }

      final tag = _parseFastTag(html, tagStart + 1, tagEnd);
      if (tag != null) {
        if (tag.isClosing) {
          for (var i = stack.length - 1; i > 0; i -= 1) {
            if (stack[i].tag == tag.name) {
              stack.removeRange(i, stack.length);
              break;
            }
          }
        } else {
          final element = _XElement(tag.name, tag.attributes);
          stack.last.children.add(element);
          if (!tag.isSelfClosing && !_voidTags.contains(tag.name)) {
            stack.add(element);
          }
        }
      }

      index = tagEnd + 1;
    }

    return root;
  }

  static int _findFastTagEnd(String html, int start) {
    String? quote;
    for (var i = start; i < html.length; i += 1) {
      final char = html[i];
      if (quote != null) {
        if (char == quote) quote = null;
      } else if (char == '"' || char == "'") {
        quote = char;
      } else if (char == '>') {
        return i;
      }
    }
    return -1;
  }

  static _FastTag? _parseFastTag(String html, int start, int end) {
    var index = start;
    while (index < end && _isWhitespaceUnit(html.codeUnitAt(index))) {
      index += 1;
    }
    if (index >= end) return null;
    if (html.codeUnitAt(index) == 33) return null;

    var isClosing = false;
    if (html.codeUnitAt(index) == 47) {
      isClosing = true;
      index += 1;
      while (index < end && _isWhitespaceUnit(html.codeUnitAt(index))) {
        index += 1;
      }
    }

    final nameStart = index;
    while (index < end && _isTagNameUnit(html.codeUnitAt(index))) {
      index += 1;
    }
    if (index == nameStart) return null;

    final name = _localHtmlName(html.substring(nameStart, index));
    if (name.isEmpty) return null;

    if (isClosing) {
      return _FastTag(name: name, isClosing: true);
    }

    var attributesEnd = end;
    var isSelfClosing = false;
    while (attributesEnd > index &&
        _isWhitespaceUnit(html.codeUnitAt(attributesEnd - 1))) {
      attributesEnd -= 1;
    }
    if (attributesEnd > index && html.codeUnitAt(attributesEnd - 1) == 47) {
      isSelfClosing = true;
      attributesEnd -= 1;
    }

    return _FastTag(
      name: name,
      attributes: _parseFastAttributes(html, index, attributesEnd),
      isSelfClosing: isSelfClosing,
    );
  }

  static Map<String, String> _parseFastAttributes(
    String html,
    int start,
    int end,
  ) {
    final result = <String, String>{};
    var index = start;
    while (index < end) {
      while (index < end && _isWhitespaceUnit(html.codeUnitAt(index))) {
        index += 1;
      }
      if (index >= end) break;

      final nameStart = index;
      while (index < end && _isAttributeNameUnit(html.codeUnitAt(index))) {
        index += 1;
      }
      if (index == nameStart) {
        index += 1;
        continue;
      }

      final rawName = html.substring(nameStart, index).toLowerCase();
      final name = _localHtmlName(rawName);
      while (index < end && _isWhitespaceUnit(html.codeUnitAt(index))) {
        index += 1;
      }

      var value = '';
      if (index < end && html.codeUnitAt(index) == 61) {
        index += 1;
        while (index < end && _isWhitespaceUnit(html.codeUnitAt(index))) {
          index += 1;
        }
        if (index < end &&
            (html.codeUnitAt(index) == 34 || html.codeUnitAt(index) == 39)) {
          final quote = html.codeUnitAt(index);
          index += 1;
          final valueStart = index;
          while (index < end && html.codeUnitAt(index) != quote) {
            index += 1;
          }
          value = html.substring(valueStart, index);
          if (index < end) index += 1;
        } else {
          final valueStart = index;
          while (index < end &&
              !_isWhitespaceUnit(html.codeUnitAt(index)) &&
              html.codeUnitAt(index) != 47) {
            index += 1;
          }
          value = html.substring(valueStart, index);
        }
      }

      final decoded = _decodeHtmlEntities(value);
      result[rawName] = decoded;
      result.putIfAbsent(name, () => decoded);
    }
    return result;
  }

  static String _localHtmlName(String name) {
    final index = name.lastIndexOf(':');
    return (index == -1 ? name : name.substring(index + 1)).toLowerCase();
  }

  static bool _isWhitespaceUnit(int unit) =>
      unit == 32 || unit == 9 || unit == 10 || unit == 13 || unit == 12;

  static bool _isTagNameUnit(int unit) =>
      (unit >= 65 && unit <= 90) ||
      (unit >= 97 && unit <= 122) ||
      (unit >= 48 && unit <= 57) ||
      unit == 45 ||
      unit == 58;

  static bool _isAttributeNameUnit(int unit) =>
      !_isWhitespaceUnit(unit) && unit != 61 && unit != 47 && unit != 62;

  static String _decodeHtmlEntities(String value) {
    if (!value.contains('&')) return value;
    return value.replaceAllMapped(RegExp(r'&(#x?[0-9a-fA-F]+|[a-zA-Z]+);'), (
      match,
    ) {
      final entity = match.group(1)!;
      if (entity.startsWith('#x') || entity.startsWith('#X')) {
        final codePoint = int.tryParse(entity.substring(2), radix: 16);
        return _decodeCodePoint(codePoint) ?? match.group(0)!;
      }
      if (entity.startsWith('#')) {
        final codePoint = int.tryParse(entity.substring(1));
        return _decodeCodePoint(codePoint) ?? match.group(0)!;
      }
      return switch (entity.toLowerCase()) {
        'amp' => '&',
        'lt' => '<',
        'gt' => '>',
        'quot' => '"',
        'apos' => "'",
        'nbsp' => '\u00A0',
        _ => match.group(0)!,
      };
    });
  }

  static String? _decodeCodePoint(int? codePoint) {
    if (codePoint == null || codePoint < 0 || codePoint > 0x10FFFF) {
      return null;
    }
    return String.fromCharCode(codePoint);
  }

  static _CssCascade _buildFastStyleCascade(
    _XElement document,
    _EpubArchive archive,
    String baseDir, {
    required Map<String, _CssCascade> styleCache,
  }) {
    final linkedPaths = <String>[];
    final inlineStyles = <String>[];

    for (final link in document.descendantsByTag('link')) {
      final rel = link.attributes['rel']?.toLowerCase() ?? '';
      final href = link.attributes['href'];
      if (!rel.split(RegExp(r'\s+')).contains('stylesheet') ||
          href == null ||
          href.trim().isEmpty) {
        continue;
      }
      final resolved = _resolveHref(baseDir, href);
      linkedPaths.add(resolved);
    }

    for (final style in document.descendantsByTag('style')) {
      inlineStyles.add(style.text);
    }

    final cacheKey = _styleCacheKey(linkedPaths, inlineStyles);
    final cached = styleCache[cacheKey];
    if (cached != null) return cached;

    final css = StringBuffer();
    for (final resolved in linkedPaths) {
      final linkedCss = _readFile(archive, resolved);
      if (linkedCss != null) {
        css.writeln(linkedCss);
      }
    }

    for (final style in inlineStyles) {
      css.writeln(style);
    }

    final cascade = _CssCascade.parse(css.toString());
    styleCache[cacheKey] = cascade;
    return cascade;
  }

  static void _parseFastNodesAsBlocks(
    Iterable<_XNode> nodes,
    List<ParsedContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    int indent,
    _CssCascade css, {
    void Function()? onImageLoad,
  }) {
    final inlineRun = <_XNode>[];

    void flushInlineRun() {
      if (inlineRun.isEmpty) return;
      _appendFastInlineNodesAsBlocks(
        inlineRun,
        result,
        archive,
        baseDir,
        ParsedBlockType.paragraph,
        indent: indent,
        css: css,
        onImageLoad: onImageLoad,
      );
      inlineRun.clear();
    }

    for (final node in nodes) {
      switch (node) {
        case _XText(:final text):
          if (text.trim().isNotEmpty) {
            inlineRun.add(node);
          }
        case _XElement():
          if (_shouldSkipFastElement(node)) continue;
          if (_isFastBlockElement(node) || _isFastImageElement(node)) {
            flushInlineRun();
            _parseFastBlockElement(
              node,
              result,
              archive,
              baseDir,
              indent,
              css,
              onImageLoad: onImageLoad,
            );
          } else {
            inlineRun.add(node);
          }
      }
    }

    flushInlineRun();
  }

  static void _parseFastBlockElement(
    _XElement element,
    List<ParsedContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    int indent,
    _CssCascade css, {
    void Function()? onImageLoad,
  }) {
    if (_shouldSkipFastElement(element)) return;

    final tag = element.tag;
    final elementStyle = css.declarationForFast(element);
    final blockStyle = elementStyle.blockStyle;

    if (_isFastImageElement(element)) {
      _addFastImageBlock(
        element,
        result,
        archive,
        baseDir,
        css,
        onImageLoad: onImageLoad,
      );
      return;
    }

    if (tag == 'figure') {
      _parseFastFigure(
        element,
        result,
        archive,
        baseDir,
        indent,
        css,
        onImageLoad: onImageLoad,
      );
      return;
    }

    if (tag.startsWith('h') && tag.length == 2) {
      final level = int.tryParse(tag[1]);
      if (level != null && level >= 1 && level <= 6) {
        _appendFastInlineNodesAsBlocks(
          element.children,
          result,
          archive,
          baseDir,
          ParsedBlockType.heading,
          headingLevel: level,
          indent: indent,
          style: blockStyle,
          css: css,
          onImageLoad: onImageLoad,
        );
        return;
      }
    }

    if (tag == 'ul' || tag == 'ol') {
      for (final li in element.childElements) {
        if (li.tag == 'li') {
          _parseFastListItem(
            li,
            result,
            archive,
            baseDir,
            indent + 1,
            css,
            onImageLoad: onImageLoad,
          );
        }
      }
      return;
    }

    if (tag == 'blockquote') {
      _parseFastBlockquote(
        element,
        result,
        archive,
        baseDir,
        indent + 1,
        css,
        onImageLoad: onImageLoad,
      );
      return;
    }

    if (tag == 'table') {
      _parseFastTable(element, result, archive, baseDir, indent, css);
      return;
    }

    if (tag == 'hr') return;

    if (tag == 'pre') {
      final text = element.text.trimRight();
      if (text.trim().isNotEmpty) {
        result.add(
          ParsedTextBlock(
            type: ParsedBlockType.paragraph,
            spans: [ParsedStyledText(text)],
            style: blockStyle,
          ),
        );
      }
      return;
    }

    if (tag == 'p' || !_hasDirectFastBlockChild(element)) {
      _appendFastInlineNodesAsBlocks(
        element.children,
        result,
        archive,
        baseDir,
        ParsedBlockType.paragraph,
        indent: indent,
        style: blockStyle,
        css: css,
        onImageLoad: onImageLoad,
      );
    } else {
      _parseFastNodesAsBlocks(
        element.children,
        result,
        archive,
        baseDir,
        indent,
        css,
        onImageLoad: onImageLoad,
      );
    }
  }

  static void _parseFastFigure(
    _XElement element,
    List<ParsedContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    int indent,
    _CssCascade css, {
    void Function()? onImageLoad,
  }) {
    final image = _firstFastImageDescendant(element);
    final caption = _normalizePlainText(
      element.firstDescendantByTag('figcaption')?.text ?? '',
    );
    if (image != null) {
      _addFastImageBlock(
        image,
        result,
        archive,
        baseDir,
        css,
        parentBlockStyle: css.declarationForFast(element).blockStyle,
        caption: caption,
        onImageLoad: onImageLoad,
      );
      return;
    }

    _parseFastNodesAsBlocks(
      element.children,
      result,
      archive,
      baseDir,
      indent,
      css,
      onImageLoad: onImageLoad,
    );
  }

  static void _parseFastBlockquote(
    _XElement element,
    List<ParsedContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    int indent,
    _CssCascade css, {
    void Function()? onImageLoad,
  }) {
    final inlineRun = <_XNode>[];

    void flushQuoteLine() {
      if (inlineRun.isEmpty) return;
      _appendFastInlineNodesAsBlocks(
        inlineRun,
        result,
        archive,
        baseDir,
        ParsedBlockType.blockquote,
        indent: indent,
        style: css.declarationForFast(element).blockStyle,
        css: css,
        onImageLoad: onImageLoad,
      );
      inlineRun.clear();
    }

    for (final node in element.children) {
      switch (node) {
        case _XText(:final text):
          if (text.trim().isNotEmpty) {
            inlineRun.add(node);
          }
        case _XElement():
          if (_shouldSkipFastElement(node)) continue;
          final tag = node.tag;
          if ((tag == 'p' || tag == 'div') && !_hasDirectFastBlockChild(node)) {
            flushQuoteLine();
            _appendFastInlineNodesAsBlocks(
              node.children,
              result,
              archive,
              baseDir,
              ParsedBlockType.blockquote,
              indent: indent,
              style: css.declarationForFast(node).blockStyle,
              css: css,
              onImageLoad: onImageLoad,
            );
          } else if (_isFastBlockElement(node) || _isFastImageElement(node)) {
            flushQuoteLine();
            _parseFastBlockElement(
              node,
              result,
              archive,
              baseDir,
              indent,
              css,
              onImageLoad: onImageLoad,
            );
          } else {
            inlineRun.add(node);
          }
      }
    }

    flushQuoteLine();
  }

  static void _parseFastListItem(
    _XElement element,
    List<ParsedContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    int indent,
    _CssCascade css, {
    void Function()? onImageLoad,
  }) {
    final inlineRun = <_XNode>[];
    var emittedOwnLine = false;

    void flushOwnLine() {
      if (inlineRun.isEmpty) return;
      final before = result.length;
      _appendFastInlineNodesAsBlocks(
        inlineRun,
        result,
        archive,
        baseDir,
        ParsedBlockType.listItem,
        indent: indent,
        style: css.declarationForFast(element).blockStyle,
        css: css,
        onImageLoad: onImageLoad,
      );
      emittedOwnLine = emittedOwnLine || result.length > before;
      inlineRun.clear();
    }

    for (final node in element.children) {
      switch (node) {
        case _XText(:final text):
          if (text.trim().isNotEmpty) {
            inlineRun.add(node);
          }
        case _XElement():
          if (_shouldSkipFastElement(node)) continue;
          final tag = node.tag;
          if (tag == 'ul' || tag == 'ol') {
            flushOwnLine();
            _parseFastBlockElement(
              node,
              result,
              archive,
              baseDir,
              indent,
              css,
              onImageLoad: onImageLoad,
            );
          } else if (_isFastBlockElement(node) || _isFastImageElement(node)) {
            if (!emittedOwnLine && _canRepresentAsFastListItem(node)) {
              flushOwnLine();
              final before = result.length;
              _appendFastInlineNodesAsBlocks(
                node.children,
                result,
                archive,
                baseDir,
                ParsedBlockType.listItem,
                indent: indent,
                style: css.declarationForFast(node).blockStyle,
                css: css,
                onImageLoad: onImageLoad,
              );
              emittedOwnLine = emittedOwnLine || result.length > before;
            } else {
              flushOwnLine();
              _parseFastBlockElement(
                node,
                result,
                archive,
                baseDir,
                indent,
                css,
                onImageLoad: onImageLoad,
              );
            }
          } else {
            inlineRun.add(node);
          }
      }
    }

    flushOwnLine();
  }

  static void _parseFastTable(
    _XElement table,
    List<ParsedContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    int indent,
    _CssCascade css,
  ) {
    final caption = table.firstDescendantByTag('caption');
    if (caption != null) {
      _appendFastInlineNodesAsBlocks(
        caption.children,
        result,
        archive,
        baseDir,
        ParsedBlockType.paragraph,
        indent: indent,
        style: css.declarationForFast(caption).blockStyle,
        css: css,
      );
    }

    for (final row in table.descendantsByTag('tr')) {
      final cells = row
          .descendantsWhere(
            (element) => element.tag == 'th' || element.tag == 'td',
          )
          .map((cell) => _normalizePlainText(cell.text))
          .where((text) => text.isNotEmpty)
          .toList();
      if (cells.isEmpty) continue;
      result.add(
        ParsedTextBlock(
          type: ParsedBlockType.paragraph,
          spans: [ParsedStyledText(cells.join(' | '))],
          indent: indent,
          style: css.declarationForFast(row).blockStyle,
        ),
      );
    }
  }

  static void _appendFastInlineNodesAsBlocks(
    Iterable<_XNode> nodes,
    List<ParsedContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    ParsedBlockType blockType, {
    int headingLevel = 0,
    int indent = 0,
    ReaderBlockStyle style = ReaderBlockStyle.none,
    required _CssCascade css,
    void Function()? onImageLoad,
  }) {
    var spans = <ParsedStyledText>[];

    void flushParsedTextBlock() {
      final normalized = _normalizeSpans(spans);
      if (normalized.any((span) => span.text.trim().isNotEmpty)) {
        result.add(
          ParsedTextBlock(
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

    void visit(_XNode node, InlineStyle inlineStyle, {String? footnoteTarget}) {
      switch (node) {
        case _XText(:final text):
          if (text.isNotEmpty) {
            _appendStyledSpan(
              spans,
              ParsedStyledText(text, inlineStyle, footnoteTarget),
            );
          }
        case _XElement():
          if (_shouldSkipFastElement(node)) return;
          final tag = node.tag;

          if (tag == 'a' && node.attributes['type'] == 'noteref') {
            final href = node.attributes['href'] ?? '';
            final fnTarget = href.contains('#')
                ? href.substring(href.indexOf('#') + 1)
                : '';
            var childStyle = inlineStyle.merge(
              css.declarationForFast(node).inlineStyle,
            );
            for (final child in node.children) {
              visit(
                child,
                childStyle,
                footnoteTarget: fnTarget.isNotEmpty ? fnTarget : null,
              );
            }
            return;
          }

          if (_isFastImageElement(node)) {
            flushParsedTextBlock();
            _addFastImageBlock(
              node,
              result,
              archive,
              baseDir,
              css,
              parentBlockStyle: style,
              onImageLoad: onImageLoad,
            );
            return;
          }

          if (_isFastBlockElement(node) && tag != 'br') {
            flushParsedTextBlock();
            _parseFastBlockElement(
              node,
              result,
              archive,
              baseDir,
              indent,
              css,
              onImageLoad: onImageLoad,
            );
            return;
          }

          if (tag == 'br') {
            _appendStyledSpan(
              spans,
              ParsedStyledText('\n', inlineStyle),
            );
            return;
          }

          var childStyle = inlineStyle.merge(
            css.declarationForFast(node).inlineStyle,
          );
          if (tag == 'b' || tag == 'strong') {
            childStyle = childStyle.merge(const InlineStyle(bold: true));
          } else if (tag == 'i' || tag == 'em' || tag == 'cite') {
            childStyle = childStyle.merge(const InlineStyle(italic: true));
          }

          for (final child in node.children) {
            visit(child, childStyle, footnoteTarget: footnoteTarget);
          }
      }
    }

    for (final node in nodes) {
      visit(node, InlineStyle.normal);
    }
    flushParsedTextBlock();
  }

  static bool _shouldSkipFastElement(_XElement element) {
    if (element.attributes.containsKey('hidden')) return true;
    if (element.tag == 'script' ||
        element.tag == 'style' ||
        element.tag == 'nav') {
      return true;
    }
    return (element.attributes['class'] ?? '')
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .contains('nav');
  }

  static bool _isFastBlockElement(_XElement element) {
    return _blockTags.contains(element.tag);
  }

  static bool _hasDirectFastBlockChild(_XElement element) {
    return element.childElements.any((child) {
      if (_isFastImageElement(child)) return true;
      return _blockTags.contains(child.tag);
    });
  }

  static bool _canRepresentAsFastListItem(_XElement element) {
    if (_isFastImageElement(element)) return false;
    final tag = element.tag;
    return (tag == 'p' || tag == 'div' || tag == 'span') &&
        !_hasDirectFastBlockChild(element);
  }

  static _XElement? _firstFastImageDescendant(_XElement element) {
    for (final child in element.childElements) {
      if (_isFastImageElement(child)) return child;
      final nested = _firstFastImageDescendant(child);
      if (nested != null) return nested;
    }
    return null;
  }

  static bool _isFastImageElement(_XElement element) {
    if (element.tag == 'img') return true;
    if (element.tag == 'image') {
      return _fastImageSource(element) != null;
    }
    return false;
  }

  static void _addFastImageBlock(
    _XElement element,
    List<ParsedContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    _CssCascade css, {
    ReaderBlockStyle parentBlockStyle = ReaderBlockStyle.none,
    String? caption,
    void Function()? onImageLoad,
  }) {
    final src = _fastImageSource(element);
    if (src == null || src.trim().isEmpty) return;

    final resolvedPath = _resolveHref(baseDir, src);
    onImageLoad?.call();
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
    var imageStyle = css.declarationForFast(element).imageStyle;
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
      ParsedImageBlock(
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

  static String? _fastImageSource(_XElement element) {
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

  static void _parseNodesAsBlocks(
    Iterable<dom.Node> nodes,
    List<ParsedContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    int indent,
    _CssCascade css, {
    void Function()? onImageLoad,
  }) {
    final inlineRun = <dom.Node>[];

    void flushInlineRun() {
      if (inlineRun.isEmpty) return;
      _appendInlineNodesAsBlocks(
        inlineRun,
        result,
        archive,
        baseDir,
        ParsedBlockType.paragraph,
        indent: indent,
        css: css,
        onImageLoad: onImageLoad,
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
        _parseBlockElement(
          node,
          result,
          archive,
          baseDir,
          indent,
          css,
          onImageLoad: onImageLoad,
        );
      } else {
        inlineRun.add(node);
      }
    }

    flushInlineRun();
  }

  static void _parseBlockElement(
    dom.Element element,
    List<ParsedContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    int indent,
    _CssCascade css, {
    void Function()? onImageLoad,
  }) {
    final tag = element.localName?.toLowerCase() ?? '';
    final elementStyle = css.declarationFor(element);
    final blockStyle = elementStyle.blockStyle;

    if (_isImageElement(element)) {
      _addParsedImageBlock(
        element,
        result,
        archive,
        baseDir,
        css,
        onImageLoad: onImageLoad,
      );
      return;
    }

    if (tag == 'figure') {
      _parseFigure(
        element,
        result,
        archive,
        baseDir,
        indent,
        css,
        onImageLoad: onImageLoad,
      );
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
          ParsedBlockType.heading,
          headingLevel: level,
          indent: indent,
          style: blockStyle,
          css: css,
          onImageLoad: onImageLoad,
        );
        return;
      }
    }

    if (tag == 'ul' || tag == 'ol') {
      for (final li in element.children) {
        if (li.localName?.toLowerCase() == 'li') {
          _parseListItem(
            li,
            result,
            archive,
            baseDir,
            indent + 1,
            css,
            onImageLoad: onImageLoad,
          );
        }
      }
      return;
    }

    if (tag == 'blockquote') {
      _parseBlockquote(
        element,
        result,
        archive,
        baseDir,
        indent + 1,
        css,
        onImageLoad: onImageLoad,
      );
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
          ParsedTextBlock(
            type: ParsedBlockType.paragraph,
            spans: [ParsedStyledText(text)],
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
        ParsedBlockType.paragraph,
        indent: indent,
        style: blockStyle,
        css: css,
        onImageLoad: onImageLoad,
      );
    } else {
      _parseNodesAsBlocks(
        element.nodes,
        result,
        archive,
        baseDir,
        indent,
        css,
        onImageLoad: onImageLoad,
      );
    }
  }

  static void _parseFigure(
    dom.Element element,
    List<ParsedContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    int indent,
    _CssCascade css, {
    void Function()? onImageLoad,
  }) {
    final image = _firstImageDescendant(element);
    final caption = _normalizePlainText(
      element.querySelector('figcaption')?.text ?? '',
    );
    if (image != null) {
      _addParsedImageBlock(
        image,
        result,
        archive,
        baseDir,
        css,
        parentBlockStyle: css.declarationFor(element).blockStyle,
        caption: caption,
        onImageLoad: onImageLoad,
      );
      return;
    }

    _parseNodesAsBlocks(
      element.nodes,
      result,
      archive,
      baseDir,
      indent,
      css,
      onImageLoad: onImageLoad,
    );
  }

  static void _parseBlockquote(
    dom.Element element,
    List<ParsedContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    int indent,
    _CssCascade css, {
    void Function()? onImageLoad,
  }) {
    final inlineRun = <dom.Node>[];

    void flushQuoteLine() {
      if (inlineRun.isEmpty) return;
      _appendInlineNodesAsBlocks(
        inlineRun,
        result,
        archive,
        baseDir,
        ParsedBlockType.blockquote,
        indent: indent,
        style: css.declarationFor(element).blockStyle,
        css: css,
        onImageLoad: onImageLoad,
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
          ParsedBlockType.blockquote,
          indent: indent,
          style: css.declarationFor(node).blockStyle,
          css: css,
          onImageLoad: onImageLoad,
        );
      } else if (_isBlockElement(node) || _isImageElement(node)) {
        flushQuoteLine();
        _parseBlockElement(
          node,
          result,
          archive,
          baseDir,
          indent,
          css,
          onImageLoad: onImageLoad,
        );
      } else {
        inlineRun.add(node);
      }
    }

    flushQuoteLine();
  }

  static void _parseListItem(
    dom.Element element,
    List<ParsedContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    int indent,
    _CssCascade css, {
    void Function()? onImageLoad,
  }) {
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
        ParsedBlockType.listItem,
        indent: indent,
        style: css.declarationFor(element).blockStyle,
        css: css,
        onImageLoad: onImageLoad,
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
        _parseBlockElement(
          node,
          result,
          archive,
          baseDir,
          indent,
          css,
          onImageLoad: onImageLoad,
        );
      } else if (_isBlockElement(node) || _isImageElement(node)) {
        if (!emittedOwnLine && _canRepresentAsListItem(node)) {
          flushOwnLine();
          final before = result.length;
          _appendInlineNodesAsBlocks(
            node.nodes,
            result,
            archive,
            baseDir,
            ParsedBlockType.listItem,
            indent: indent,
            style: css.declarationFor(node).blockStyle,
            css: css,
            onImageLoad: onImageLoad,
          );
          emittedOwnLine = emittedOwnLine || result.length > before;
        } else {
          flushOwnLine();
          _parseBlockElement(
            node,
            result,
            archive,
            baseDir,
            indent,
            css,
            onImageLoad: onImageLoad,
          );
        }
      } else {
        inlineRun.add(node);
      }
    }

    flushOwnLine();
  }

  static void _parseTable(
    dom.Element table,
    List<ParsedContentBlock> result,
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
        ParsedBlockType.paragraph,
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
        ParsedTextBlock(
          type: ParsedBlockType.paragraph,
          spans: [ParsedStyledText(cells.join(' | '))],
          indent: indent,
          style: css.declarationFor(row).blockStyle,
        ),
      );
    }
  }

  static void _appendInlineNodesAsBlocks(
    Iterable<dom.Node> nodes,
    List<ParsedContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    ParsedBlockType blockType, {
    int headingLevel = 0,
    int indent = 0,
    ReaderBlockStyle style = ReaderBlockStyle.none,
    required _CssCascade css,
    void Function()? onImageLoad,
  }) {
    var spans = <ParsedStyledText>[];

    void flushParsedTextBlock() {
      final normalized = _normalizeSpans(spans);
      if (normalized.any((span) => span.text.trim().isNotEmpty)) {
        result.add(
          ParsedTextBlock(
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

    void visit(
      dom.Node node,
      InlineStyle inlineStyle, {
      String? footnoteTarget,
    }) {
      if (node is dom.Text) {
        if (node.text.isNotEmpty) {
          _appendStyledSpan(
            spans,
            ParsedStyledText(node.text, inlineStyle, footnoteTarget),
          );
        }
        return;
      }

      if (node is! dom.Element) return;

      final tag = node.localName?.toLowerCase() ?? '';

      if (tag == 'a' && node.attributes['type'] == 'noteref') {
        final href = node.attributes['href'] ?? '';
        final fnTarget = href.contains('#')
            ? href.substring(href.indexOf('#') + 1)
            : '';
        var childStyle = inlineStyle.merge(
          css.declarationFor(node).inlineStyle,
        );
        for (final child in node.nodes) {
          visit(
            child,
            childStyle,
            footnoteTarget: fnTarget.isNotEmpty ? fnTarget : null,
          );
        }
        return;
      }

      if (_isImageElement(node)) {
        flushParsedTextBlock();
        _addParsedImageBlock(
          node,
          result,
          archive,
          baseDir,
          css,
          parentBlockStyle: style,
          onImageLoad: onImageLoad,
        );
        return;
      }

      if (_isBlockElement(node) && tag != 'br') {
        flushParsedTextBlock();
        _parseBlockElement(
          node,
          result,
          archive,
          baseDir,
          indent,
          css,
          onImageLoad: onImageLoad,
        );
        return;
      }

      if (tag == 'br') {
        _appendStyledSpan(
          spans,
          ParsedStyledText('\n', inlineStyle),
        );
        return;
      }

      var childStyle = inlineStyle.merge(css.declarationFor(node).inlineStyle);
      if (tag == 'b' || tag == 'strong') {
        childStyle = childStyle.merge(const InlineStyle(bold: true));
      } else if (tag == 'i' || tag == 'em' || tag == 'cite') {
        childStyle = childStyle.merge(const InlineStyle(italic: true));
      }

      for (final child in node.nodes) {
        visit(child, childStyle, footnoteTarget: footnoteTarget);
      }
    }

    for (final node in nodes) {
      visit(node, InlineStyle.normal);
    }
    flushParsedTextBlock();
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

  static void _addParsedImageBlock(
    dom.Element element,
    List<ParsedContentBlock> result,
    _EpubArchive archive,
    String baseDir,
    _CssCascade css, {
    ReaderBlockStyle parentBlockStyle = ReaderBlockStyle.none,
    String? caption,
    void Function()? onImageLoad,
  }) {
    final src = _imageSource(element);
    if (src == null || src.trim().isEmpty) return;

    final resolvedPath = _resolveHref(baseDir, src);
    onImageLoad?.call();
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
      ParsedImageBlock(
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

  static List<ParsedStyledText> _normalizeSpans(List<ParsedStyledText> spans) {
    final result = <ParsedStyledText>[];
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
      _appendStyledSpan(
        result,
        ParsedStyledText(text, span.style, span.footnoteTarget),
      );
    }

    if (result.isEmpty) return result;
    final last = result.removeLast();
    final trimmed = last.text.trimRight();
    if (trimmed.isNotEmpty) {
      _appendStyledSpan(
        result,
        ParsedStyledText(trimmed, last.style, last.footnoteTarget),
      );
    }
    return result;
  }

  static void _appendStyledSpan(
    List<ParsedStyledText> spans,
    ParsedStyledText span,
  ) {
    if (span.text.isEmpty) return;
    if (spans.isNotEmpty && _sameStyle(spans.last, span)) {
      final last = spans.removeLast();
      spans.add(
        ParsedStyledText(
          '${last.text}${span.text}',
          last.style,
          last.footnoteTarget,
        ),
      );
    } else {
      spans.add(span);
    }
  }

  static bool _sameStyle(ParsedStyledText a, ParsedStyledText b) {
    return a.style.bold == b.style.bold &&
        a.style.italic == b.style.italic &&
        a.footnoteTarget == b.footnoteTarget;
  }

  static String _plainTextFromBlocks(List<ParsedContentBlock> blocks) {
    return blocks
        .map((block) {
          switch (block) {
            case ParsedTextBlock():
              return _normalizePlainText(block.plainText);
            case ParsedImageBlock():
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

sealed class _XNode {
  const _XNode();
}

class _XText extends _XNode {
  final String text;

  const _XText(this.text);
}

class _XElement extends _XNode {
  final String tag;
  final Map<String, String> attributes;
  final List<_XNode> children = [];

  _XElement(this.tag, this.attributes);

  Iterable<_XElement> get childElements => children.whereType<_XElement>();

  String get text {
    final buffer = StringBuffer();
    void visit(_XNode node) {
      switch (node) {
        case _XText(:final text):
          buffer.write(text);
        case _XElement():
          for (final child in node.children) {
            visit(child);
          }
      }
    }

    for (final child in children) {
      visit(child);
    }
    return buffer.toString();
  }

  _XElement? firstDescendantByTag(String tag) {
    for (final child in childElements) {
      if (child.tag == tag) return child;
      final nested = child.firstDescendantByTag(tag);
      if (nested != null) return nested;
    }
    return null;
  }

  Iterable<_XElement> descendantsByTag(String tag) {
    return descendantsWhere((element) => element.tag == tag);
  }

  Iterable<_XElement> descendantsWhere(bool Function(_XElement) test) sync* {
    for (final child in childElements) {
      if (test(child)) yield child;
      yield* child.descendantsWhere(test);
    }
  }
}

class _FastTag {
  final String name;
  final Map<String, String> attributes;
  final bool isClosing;
  final bool isSelfClosing;

  const _FastTag({
    required this.name,
    this.attributes = const {},
    this.isClosing = false,
    this.isSelfClosing = false,
  });
}

class _CssCascade {
  final Map<String, List<_CssRule>> _tagRules;
  final Map<String, List<_CssRule>> _classRules;
  final Map<String, List<_CssRule>> _idRules;
  final Map<String, _CssDeclaration> _cache = {};

  _CssCascade._(this._tagRules, this._classRules, this._idRules);

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
        if (selector.id != null) {
          (idRules[selector.id!] ??= []).add(rule);
        } else if (selector.classes.isNotEmpty) {
          for (final className in selector.classes) {
            (classRules[className] ??= []).add(rule);
          }
        } else if (selector.tag != null) {
          (tagRules[selector.tag!] ??= []).add(rule);
        }
      }
    }
    return _CssCascade._(tagRules, classRules, idRules);
  }

  _CssDeclaration declarationFor(dom.Element element) {
    return _declarationFor(
      tag: element.localName?.toLowerCase() ?? '',
      attributes: {
        for (final entry in element.attributes.entries)
          entry.key.toString(): entry.value,
      },
    );
  }

  _CssDeclaration declarationForFast(_XElement element) {
    return _declarationFor(tag: element.tag, attributes: element.attributes);
  }

  _CssDeclaration _declarationFor({
    required String tag,
    required Map<String, String> attributes,
  }) {
    final classNames =
        (attributes['class'] ?? '')
            .toLowerCase()
            .split(RegExp(r'\s+'))
            .where((className) => className.isNotEmpty)
            .toList()
          ..sort();
    final id = attributes['id']?.toLowerCase() ?? '';
    final inlineStyle = attributes['style'] ?? '';
    final cacheKey = '$tag|${classNames.join('.')}|$id|$inlineStyle';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    var declaration = const _CssDeclaration();
    final matches = <_CssRule>[];
    final seenOrders = <int>{};

    void collect(Iterable<_CssRule> rules) {
      for (final rule in rules) {
        if (seenOrders.add(rule.order) &&
            rule.selector.matches(tag: tag, classNames: classNames, id: id)) {
          matches.add(rule);
        }
      }
    }

    collect(_tagRules[tag] ?? const <_CssRule>[]);
    for (final className in classNames) {
      collect(_classRules[className] ?? const <_CssRule>[]);
    }
    if (id.isNotEmpty) {
      collect(_idRules[id] ?? const <_CssRule>[]);
    }

    matches.sort((a, b) {
      final specificity = a.selector.specificity.compareTo(
        b.selector.specificity,
      );
      return specificity == 0 ? a.order.compareTo(b.order) : specificity;
    });
    for (final rule in matches) {
      declaration = declaration.merge(rule.declaration);
    }

    final resolved = declaration.merge(_CssDeclaration.parse(inlineStyle));
    _cache[cacheKey] = resolved;
    return resolved;
  }
}

class _CssRule {
  final _CssSelector selector;
  final _CssDeclaration declaration;
  final int order;

  const _CssRule(this.selector, this.declaration, this.order);
}

class _CssSelector {
  final String? tag;
  final String? id;
  final Set<String> classes;

  const _CssSelector({this.tag, this.id, this.classes = const {}});

  int get specificity =>
      (id == null ? 0 : 100) + classes.length * 10 + (tag == null ? 0 : 1);

  static _CssSelector? parse(String selector) {
    if (selector.isEmpty ||
        selector.contains(RegExp(r'[\s>+~:\[\]*=]')) ||
        selector.startsWith('@')) {
      return null;
    }
    final match = RegExp(
      r'^([a-z][a-z0-9-]*)?((?:[.#][a-z0-9_-]+)+)?$',
      caseSensitive: false,
    ).firstMatch(selector);
    if (match == null) return null;

    final tag = match.group(1)?.toLowerCase();
    final suffix = match.group(2) ?? '';
    String? id;
    final classes = <String>{};
    for (final part in RegExp(
      r'([.#])([a-z0-9_-]+)',
      caseSensitive: false,
    ).allMatches(suffix)) {
      final marker = part.group(1)!;
      final value = part.group(2)!.toLowerCase();
      if (!_validIdentifier(value)) return null;
      if (marker == '#') {
        if (id != null) return null;
        id = value;
      } else {
        classes.add(value);
      }
    }
    if (tag == null && id == null && classes.isEmpty) return null;
    return _CssSelector(tag: tag, id: id, classes: classes);
  }

  bool matches({
    required String tag,
    required List<String> classNames,
    required String id,
  }) {
    final expectedTag = this.tag;
    if (expectedTag != null && expectedTag != tag) return false;
    final expectedId = this.id;
    if (expectedId != null && expectedId != id) return false;
    if (classes.isEmpty) return true;
    return classNames.toSet().containsAll(classes);
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

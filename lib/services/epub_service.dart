import 'dart:io';
import 'dart:typed_data';

import 'package:epub_reader_core/epub_reader_core.dart' as core;

import '../models/book.dart';
import '../models/chapter.dart';
import '../models/content_block.dart';

class EpubService {
  static Future<Book> parseFile(
    String filePath, {
    core.EpubParseProgressCallback? onProgress,
  }) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return parseBytes(bytes, onProgress: onProgress);
  }

  static Future<Book> parseBytes(
    Uint8List bytes, {
    core.EpubParseProgressCallback? onProgress,
  }) async {
    return parseBytesSync(bytes, onProgress: onProgress);
  }

  static Book parseBytesSync(
    Uint8List bytes, {
    core.EpubParseProgressCallback? onProgress,
  }) {
    final parsed = core.EpubParser.parseBytesSync(
      bytes,
      onProgress: onProgress,
    );
    return fromParsed(parsed);
  }

  static Book fromParsed(core.ParsedEpubBook parsed) {
    final chapters = <Chapter>[];

    for (final parsedChapter in parsed.chapters) {
      chapters.addAll(
        _trySplitMetadata(parsedChapter, parsed.title, chapters.length),
      );
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
      title: parsed.title,
      author: parsed.author,
      language: parsed.language,
      chapters: chapters,
      coverBytes: parsed.coverBytes,
    );
  }

  static List<Chapter> _trySplitMetadata(
    core.ParsedEpubChapter parsed,
    String bookTitle,
    int index,
  ) {
    final blocks = _mapBlocks(parsed.blocks);
    final plainText = parsed.plainText;

    if (blocks.length < 3) {
      return [
        Chapter(
          title: _extractTitle(parsed, index, bookTitle, blocks, plainText),
          plainText: plainText,
          rawHtml: parsed.rawHtml,
          blocks: blocks,
        ),
      ];
    }

    var lastMetaIndex = -1;
    for (var i = 0; i < blocks.length; i += 1) {
      final block = blocks[i];
      if (block is TextBlock && _metadataPattern.hasMatch(block.plainText)) {
        lastMetaIndex = i;
      }
    }

    if (lastMetaIndex == -1 || lastMetaIndex >= blocks.length - 1) {
      return [
        Chapter(
          title: _extractTitle(parsed, index, bookTitle, blocks, plainText),
          plainText: plainText,
          rawHtml: parsed.rawHtml,
          blocks: blocks,
        ),
      ];
    }

    final metaBlocks = blocks.sublist(0, lastMetaIndex + 1);
    final contentBlocks = blocks.sublist(lastMetaIndex + 1);
    final metaText = _plainTextFromBlocks(metaBlocks);
    final contentText = _plainTextFromBlocks(contentBlocks);
    if (metaText.isEmpty || contentText.isEmpty) {
      return [
        Chapter(
          title: _extractTitle(parsed, index, bookTitle, blocks, plainText),
          plainText: plainText,
          rawHtml: parsed.rawHtml,
          blocks: blocks,
        ),
      ];
    }

    return [
      Chapter(
        title: '版权信息',
        plainText: metaText,
        rawHtml: '',
        blocks: metaBlocks,
      ),
      Chapter(
        title: _extractTitle(
          parsed,
          index,
          bookTitle,
          contentBlocks,
          contentText,
        ),
        plainText: contentText,
        rawHtml: parsed.rawHtml,
        blocks: contentBlocks,
      ),
    ];
  }

  static String _extractTitle(
    core.ParsedEpubChapter parsed,
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

    final documentTitle = _normalizePlainText(parsed.documentTitle);
    if (documentTitle.isNotEmpty &&
        !_sameNormalizedText(documentTitle, bookTitle) &&
        !_looksLikeFileTitle(documentTitle)) {
      return documentTitle;
    }

    final normalizedText = _normalizePlainText(plainText);
    if (_looksLikeTitleLine(normalizedText)) return normalizedText;

    return 'Section ${index + 1}';
  }

  static List<ContentBlock> _mapBlocks(List<core.ParsedContentBlock> blocks) {
    return blocks.map(_mapBlock).toList(growable: false);
  }

  static ContentBlock _mapBlock(core.ParsedContentBlock block) {
    return switch (block) {
      core.ParsedTextBlock() => TextBlock(
        type: _mapBlockType(block.type),
        headingLevel: block.headingLevel,
        spans: block.spans
            .map((span) => StyledText(span.text, span.style))
            .toList(growable: false),
        indent: block.indent,
        style: block.style,
      ),
      core.ParsedImageBlock() => ImageBlock(
        src: block.src,
        alt: block.alt,
        bytes: block.bytes,
        declaredWidth: block.declaredWidth,
        declaredHeight: block.declaredHeight,
        naturalWidth: block.naturalWidth,
        naturalHeight: block.naturalHeight,
        style: block.style,
        caption: block.caption,
      ),
    };
  }

  static BlockType _mapBlockType(core.ParsedBlockType type) {
    return switch (type) {
      core.ParsedBlockType.paragraph => BlockType.paragraph,
      core.ParsedBlockType.heading => BlockType.heading,
      core.ParsedBlockType.listItem => BlockType.listItem,
      core.ParsedBlockType.blockquote => BlockType.blockquote,
    };
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

  static final _metadataPattern = RegExp(
    r'ISBN|CIP|图书在版编目|出版社|印刷|定价|版次|印次|字数.*千字|开本',
  );
}

import 'dart:io';
import 'dart:typed_data';

import 'package:epubx/epubx.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:image/image.dart' as img;

import '../models/book.dart';
import '../models/chapter.dart';

class EpubService {
  static Future<Book> parseFile(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return parseBytes(bytes);
  }

  static Future<Book> parseBytes(Uint8List bytes) async {
    final epubBook = await EpubReader.readBook(bytes);

    final title = epubBook.Title ?? 'Unknown Title';
    final author = epubBook.Author ?? 'Unknown Author';

    Uint8List? coverBytes;
    if (epubBook.CoverImage != null) {
      coverBytes = Uint8List.fromList(img.encodePng(epubBook.CoverImage!));
    }

    final chapters = <Chapter>[];
    final content = epubBook.Content;

    if (content != null && content.Html != null) {
      final htmlEntries = content.Html!.values.toList();

      for (int i = 0; i < htmlEntries.length; i++) {
        final entry = htmlEntries[i];
        final htmlContent = entry.Content ?? '';

        final document = html_parser.parse(htmlContent);
        final plainText = _extractText(document);
        final chapterTitle = _extractTitle(document, i, title);

        if (plainText.trim().isNotEmpty) {
          chapters.add(
            Chapter(
              title: chapterTitle,
              plainText: plainText,
              rawHtml: htmlContent,
            ),
          );
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
}

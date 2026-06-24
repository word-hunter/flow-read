import '../models/book.dart';
import '../models/chapter.dart';
import '../models/content_block.dart';

class BookInsightChapterEntry {
  const BookInsightChapterEntry({
    required this.rawChapterIndex,
    required this.displayNumber,
    required this.title,
  });

  final int rawChapterIndex;
  final int displayNumber;
  final String title;
}

class BookInsightChapterCatalog {
  BookInsightChapterCatalog._(List<BookInsightChapterEntry> entries)
    : entries = List.unmodifiable(entries),
      rawChapterIndexes = Set.unmodifiable(
        entries.map((entry) => entry.rawChapterIndex),
      );

  factory BookInsightChapterCatalog.fromBook(Book book) {
    final entries = <BookInsightChapterEntry>[];
    for (var i = 0; i < book.chapters.length; i += 1) {
      final chapter = book.chapters[i];
      if (!isAnalyzableChapter(chapter)) continue;
      entries.add(
        BookInsightChapterEntry(
          rawChapterIndex: i,
          displayNumber: entries.length + 1,
          title: _displayTitle(chapter, entries.length + 1),
        ),
      );
    }
    return BookInsightChapterCatalog._(entries);
  }

  final List<BookInsightChapterEntry> entries;
  final Set<int> rawChapterIndexes;

  bool get isEmpty => entries.isEmpty;

  bool containsRawChapter(int chapterIndex) {
    return rawChapterIndexes.contains(chapterIndex);
  }

  int readCountForRawChapter(int currentRawChapter) {
    return entries
        .where((entry) => entry.rawChapterIndex <= currentRawChapter)
        .length;
  }

  BookInsightChapterEntry? firstLockedAfter(int rawBoundaryChapter) {
    for (final entry in entries) {
      if (entry.rawChapterIndex > rawBoundaryChapter) return entry;
    }
    return null;
  }
}

bool isAnalyzableChapter(Chapter chapter) {
  final title = _normalize(chapter.title);
  if (_isExcludedNavigationTitle(title)) return false;

  final text = _normalize(chapter.plainText);
  if (text.isEmpty || text == '(No readable content found)') return false;

  final hasTextBlock = chapter.blocks.any(
    (block) => block is TextBlock && _normalize(block.plainText).isNotEmpty,
  );
  final hasImageBlock = chapter.blocks.any((block) => block is ImageBlock);
  if (hasImageBlock && chapter.blocks.isNotEmpty && !hasTextBlock) {
    return false;
  }

  final meaningfulChars = _meaningfulCharacterCount(text);
  if (_looksLikeBodyChapterTitle(title) && meaningfulChars >= 20) {
    return true;
  }
  return meaningfulChars >= 40;
}

String _displayTitle(Chapter chapter, int displayNumber) {
  final title = _normalize(chapter.title);
  if (title.isNotEmpty) return title;
  return '第 $displayNumber 章';
}

bool _isExcludedNavigationTitle(String title) {
  if (title.isEmpty) return false;
  final lower = title.toLowerCase();
  return RegExp(
        r'^(cover|contents|table of contents|copyright|title page|dedication|'
        r'preface|foreword|introduction|acknowledg(e)?ments|'
        r'about the author|illustrations?|list of illustrations|maps?|'
        r'figures?|plates?|front matter|back matter)\b',
      ).hasMatch(lower) ||
      RegExp(
        r'^(封面|目录|版权|扉页|书名页|献词|致谢|前言|序言|译序|序|导读|'
        r'出版说明|题图|插图|地图|图版|后记|附录)',
      ).hasMatch(title);
}

bool _looksLikeBodyChapterTitle(String title) {
  if (title.isEmpty) return false;
  final lower = title.toLowerCase();
  return RegExp(
        r'^(chapter|ch\.|part|book|section)\s+([0-9ivxlcdm]+|one|two|three|'
        r'four|five|six|seven|eight|nine|ten)\b',
      ).hasMatch(lower) ||
      RegExp(r'^第\s*[0-9一二三四五六七八九十百千〇零]+\s*[章节回卷部]').hasMatch(title);
}

int _meaningfulCharacterCount(String text) {
  return RegExp(r'[A-Za-z0-9\u4e00-\u9fff]').allMatches(text).length;
}

String _normalize(String text) {
  return text.replaceAll('\u00A0', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

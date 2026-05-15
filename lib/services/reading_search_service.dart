import '../models/book.dart';
import '../models/chapter.dart';
import '../models/content_block.dart';
import '../models/reading_search_result.dart';

class ReadingSearchService {
  const ReadingSearchService._();

  static Stream<ReadingSearchProgress> search(
    Book book,
    String rawQuery, {
    int? limit,
  }) async* {
    final query = rawQuery.trim();
    if (query.isEmpty) return;

    final lowerQuery = query.toLowerCase();
    var resultCount = 0;

    for (
      var chapterIndex = 0;
      chapterIndex < book.chapters.length;
      chapterIndex++
    ) {
      final chapter = book.chapters[chapterIndex];
      final segments = _segmentsFor(chapter);

      for (final segment in segments) {
        final lowerText = segment.text.toLowerCase();
        var searchStart = 0;
        var matchIndex = 0;

        while (searchStart < segment.text.length) {
          final matchStart = lowerText.indexOf(lowerQuery, searchStart);
          if (matchStart < 0) break;

          if (limit != null && resultCount >= limit) {
            yield const ReadingSearchProgress.stoppedAtLimit();
            return;
          }

          final matchEnd = matchStart + query.length;
          final snippet = _buildSnippet(segment.text, matchStart, matchEnd);

          yield ReadingSearchProgress.result(
            ReadingSearchResult(
              query: query,
              chapterIndex: chapterIndex,
              itemIndex: segment.itemIndex,
              matchIndex: matchIndex,
              matchStart: matchStart,
              matchEnd: matchEnd,
              chapterTitle: chapter.title,
              snippet: snippet.text,
              snippetMatchStart: snippet.matchStart,
              snippetMatchEnd: snippet.matchEnd,
            ),
          );

          resultCount += 1;
          matchIndex += 1;
          searchStart = matchEnd;
          await Future<void>.delayed(Duration.zero);
        }
      }
    }
  }

  static List<_SearchSegment> _segmentsFor(Chapter chapter) {
    if (chapter.blocks.isNotEmpty) {
      final segments = <_SearchSegment>[];
      for (var i = 0; i < chapter.blocks.length; i++) {
        final block = chapter.blocks[i];
        if (block is TextBlock && block.plainText.trim().isNotEmpty) {
          segments.add(_SearchSegment(i, block.plainText));
        }
      }
      return segments;
    }

    final paragraphs = _splitIntoParagraphs(chapter.plainText);
    return [
      for (var i = 0; i < paragraphs.length; i++)
        _SearchSegment(i, paragraphs[i]),
    ];
  }

  static List<String> _splitIntoParagraphs(String text) {
    final paragraphs = <String>[];
    final blocks = text.split(RegExp(r'\n\s*\n'));
    for (final block in blocks) {
      final trimmed = block.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.length > 2000) {
        final sentences = trimmed.split(RegExp(r'(?<=[.!?])\s+'));
        var chunk = '';
        for (final sentence in sentences) {
          if (chunk.length + sentence.length > 2000 && chunk.isNotEmpty) {
            paragraphs.add(chunk.trim());
            chunk = sentence;
          } else {
            chunk += (chunk.isEmpty ? '' : ' ') + sentence;
          }
        }
        if (chunk.trim().isNotEmpty) {
          paragraphs.add(chunk.trim());
        }
      } else {
        paragraphs.add(trimmed);
      }
    }
    if (paragraphs.isEmpty) {
      final trimmed = text.trim();
      if (trimmed.isNotEmpty) {
        paragraphs.add(trimmed);
      }
    }
    return paragraphs;
  }

  static _SearchSnippet _buildSnippet(
    String text,
    int matchStart,
    int matchEnd,
  ) {
    const radius = 72;
    final snippetStart = (matchStart - radius).clamp(0, text.length);
    final snippetEnd = (matchEnd + radius).clamp(0, text.length);
    final prefix = snippetStart > 0 ? '...' : '';
    final suffix = snippetEnd < text.length ? '...' : '';
    final body = text
        .substring(snippetStart, snippetEnd)
        .replaceAll(RegExp(r'\s+'), ' ');
    final rawPrefixText = text.substring(snippetStart, matchStart);
    final normalizedPrefixText = rawPrefixText.replaceAll(RegExp(r'\s+'), ' ');
    final normalizedMatchText = text
        .substring(matchStart, matchEnd)
        .replaceAll(RegExp(r'\s+'), ' ');
    final normalizedMatchStart = prefix.length + normalizedPrefixText.length;
    final normalizedMatchEnd =
        normalizedMatchStart + normalizedMatchText.length;

    return _SearchSnippet(
      '$prefix$body$suffix',
      normalizedMatchStart,
      normalizedMatchEnd,
    );
  }
}

class _SearchSegment {
  final int itemIndex;
  final String text;

  const _SearchSegment(this.itemIndex, this.text);
}

class _SearchSnippet {
  final String text;
  final int matchStart;
  final int matchEnd;

  const _SearchSnippet(this.text, this.matchStart, this.matchEnd);
}

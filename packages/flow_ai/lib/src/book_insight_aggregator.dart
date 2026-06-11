import 'models/ai_summary.dart';
import 'models/book_insight.dart';

class BookInsightAggregator {
  const BookInsightAggregator();

  BookStoryline buildStoryline(
    String bookId,
    List<AISummary> summaries,
    int maxChapter,
  ) {
    final events = <StorylineEvent>[];
    for (final summary in summaries) {
      for (final event in summary.events) {
        events.add(
          StorylineEvent(
            chapterIndex: 0, // placeholder, set by caller
            description: event.description,
            significance: event.significance,
            source: event.source,
            confidence: event.confidence,
          ),
        );
      }
    }
    return BookStoryline(
      bookId: bookId,
      events: events,
      asOfChapter: maxChapter,
    );
  }

  BookStoryline buildStorylineFromChapters(
    String bookId,
    Map<int, AISummary> chapterSummaries,
    int maxChapter,
  ) {
    final events = <StorylineEvent>[];
    final sortedChapters = chapterSummaries.keys.toList()..sort();

    for (final chapterIndex in sortedChapters) {
      if (chapterIndex > maxChapter) break;
      final summary = chapterSummaries[chapterIndex];
      if (summary == null) continue;

      for (final event in summary.events) {
        events.add(
          StorylineEvent(
            chapterIndex: chapterIndex,
            description: event.description,
            significance: event.significance,
            source: event.source,
            confidence: event.confidence,
          ),
        );
      }
    }

    return BookStoryline(
      bookId: bookId,
      events: events,
      asOfChapter: maxChapter,
    );
  }

  List<BookCharacterCard> buildCharacterCards(
    String bookId,
    Map<int, AISummary> chapterSummaries,
    int maxChapter,
  ) {
    final nameToDevelopments = <String, List<ChapterDevelopmentEntry>>{};

    final sortedChapters = chapterSummaries.keys.toList()..sort();

    for (final chapterIndex in sortedChapters) {
      if (chapterIndex > maxChapter) break;
      final summary = chapterSummaries[chapterIndex];
      if (summary == null) continue;

      for (final cd in summary.characterDevelopments) {
        final name = cd.character.trim();
        if (name.isEmpty) continue;

        nameToDevelopments.putIfAbsent(name, () => []).add(
          ChapterDevelopmentEntry(
            chapterIndex: chapterIndex,
            development: cd,
          ),
        );
      }
    }

    return nameToDevelopments.entries.map((entry) {
      final developments = entry.value;
      developments.sort((a, b) => a.chapterIndex.compareTo(b.chapterIndex));

      return BookCharacterCard(
        canonicalName: entry.key,
        firstSeenChapter: developments.first.chapterIndex,
        developments: developments.map((e) => e.development).toList(),
        evidenceSnippets: developments
            .map((e) => e.development.source)
            .where((s) => s.isNotEmpty)
            .toList(),
      );
    }).toList()
      ..sort((a, b) => a.firstSeenChapter.compareTo(b.firstSeenChapter));
  }

  BookInsightCoverage buildCoverage(
    String bookId,
    int totalChapters,
    Set<int> cachedChapters,
    int readChapters,
    DateTime? lastGenerated,
  ) {
    final missing = <int>[];
    for (var i = 0; i < totalChapters; i++) {
      if (!cachedChapters.contains(i)) {
        missing.add(i);
      }
    }

    return BookInsightCoverage(
      summarizedChapters: cachedChapters.length,
      totalChapters: totalChapters,
      readChapters: readChapters,
      missingChapters: missing,
      lastGenerated: lastGenerated,
    );
  }
}

class ChapterDevelopmentEntry {
  final int chapterIndex;
  final CharacterDevelopment development;

  const ChapterDevelopmentEntry({
    required this.chapterIndex,
    required this.development,
  });
}

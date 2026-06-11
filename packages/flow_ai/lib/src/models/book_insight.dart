import 'ai_summary.dart';

class BookStoryline {
  final String bookId;
  final List<StorylineEvent> events;
  final int asOfChapter;

  const BookStoryline({
    required this.bookId,
    required this.events,
    required this.asOfChapter,
  });

  factory BookStoryline.empty(String bookId) =>
      BookStoryline(bookId: bookId, events: const [], asOfChapter: 0);

  bool get isEmpty => events.isEmpty;
}

class StorylineEvent {
  final int chapterIndex;
  final String description;
  final String? significance;
  final String? source;
  final String confidence;
  final String character;

  const StorylineEvent({
    required this.chapterIndex,
    required this.description,
    this.significance,
    this.source,
    required this.confidence,
    this.character = '',
  });
}

class BookCharacterCard {
  final String canonicalName;
  final int firstSeenChapter;
  final List<CharacterDevelopment> developments;
  final List<String> evidenceSnippets;

  const BookCharacterCard({
    required this.canonicalName,
    required this.firstSeenChapter,
    required this.developments,
    required this.evidenceSnippets,
  });

  String get currentState {
    if (developments.isEmpty) return '';
    return developments.last.change;
  }
}

class BookInsightCoverage {
  final int summarizedChapters;
  final int totalChapters;
  final int readChapters;
  final List<int> missingChapters;
  final DateTime? lastGenerated;

  const BookInsightCoverage({
    required this.summarizedChapters,
    required this.totalChapters,
    required this.readChapters,
    required this.missingChapters,
    this.lastGenerated,
  });

  double get percentage =>
      totalChapters > 0 ? summarizedChapters / totalChapters : 0;

  bool get isComplete => missingChapters.isEmpty && summarizedChapters > 0;
}

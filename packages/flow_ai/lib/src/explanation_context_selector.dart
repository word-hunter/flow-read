import 'models/book_insight.dart';

class ExplanationContextBundle {
  final String currentSentence;
  final String surroundingText;
  final List<String> sameWordOccurrences;
  final List<RelevantEvent> relatedEvents;
  final List<RelevantCharacter> mentionedCharacters;
  final List<String> historyLookups;

  const ExplanationContextBundle({
    required this.currentSentence,
    required this.surroundingText,
    this.sameWordOccurrences = const [],
    this.relatedEvents = const [],
    this.mentionedCharacters = const [],
    this.historyLookups = const [],
  });

  bool get isEmpty =>
      sameWordOccurrences.isEmpty &&
      relatedEvents.isEmpty &&
      mentionedCharacters.isEmpty &&
      historyLookups.isEmpty;

  String formatForPrompt() {
    final parts = <String>[];

    if (sameWordOccurrences.isNotEmpty) {
      parts.add('Earlier uses of the word in this book:');
      for (final occ in sameWordOccurrences.take(5)) {
        parts.add('  · $occ');
      }
    }

    if (relatedEvents.isNotEmpty) {
      parts.add('Related story events from earlier chapters:');
      for (final event in relatedEvents) {
        final sig = event.significance != null && event.significance!.isNotEmpty
            ? ' — ${event.significance}'
            : '';
        parts.add('  · [Ch${event.chapterIndex + 1}] ${event.description}$sig');
      }
    }

    if (mentionedCharacters.isNotEmpty) {
      parts.add('Characters mentioned in the current text:');
      for (final ch in mentionedCharacters) {
        final lines = <String>['  · ${ch.name}'];
        for (final dev in ch.developments.take(3)) {
          lines.add('      - $dev');
        }
        parts.addAll(lines);
      }
    }

    if (historyLookups.isNotEmpty) {
      parts.add('Previous word lookups in this book:');
      for (final lookup in historyLookups.take(3)) {
        parts.add('  · $lookup');
      }
    }

    return parts.join('\n');
  }
}

class RelevantEvent {
  final int chapterIndex;
  final String description;
  final String? significance;

  const RelevantEvent({
    required this.chapterIndex,
    required this.description,
    this.significance,
  });
}

class RelevantCharacter {
  final String name;
  final List<String> developments;

  const RelevantCharacter({
    required this.name,
    required this.developments,
  });
}

class ExplanationContextSelector {
  const ExplanationContextSelector();

  ExplanationContextBundle selectContext({
    required String selectedText,
    required int chapterIndex,
    BookStoryline? storyline,
    List<BookCharacterCard>? characterCards,
    List<String>? historyLookups,
  }) {
    final sameWord = _findSameWordOccurrences(selectedText, storyline);
    final events = _findRelatedEvents(selectedText, storyline, chapterIndex);
    final characters =
        _findMentionedCharacters(selectedText, characterCards, chapterIndex);
    final lookups = historyLookups ?? const [];

    return ExplanationContextBundle(
      currentSentence: selectedText,
      surroundingText: selectedText,
      sameWordOccurrences: sameWord,
      relatedEvents: events,
      mentionedCharacters: characters,
      historyLookups: lookups,
    );
  }

  static List<String> _findSameWordOccurrences(
    String text,
    BookStoryline? storyline,
  ) {
    if (storyline == null) return const [];
    final words =
        text.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 3).toSet();

    final occurrences = <String>[];
    for (final event in storyline.events) {
      final desc = event.description.toLowerCase();
      final sig = event.significance?.toLowerCase() ?? '';
      for (final word in words) {
        if (desc.contains(word) || sig.contains(word)) {
          occurrences.add(event.description);
          break;
        }
      }
    }
    return occurrences.take(5).toList();
  }

  static List<RelevantEvent> _findRelatedEvents(
    String text,
    BookStoryline? storyline,
    int currentChapter,
  ) {
    if (storyline == null) return const [];
    final keywords = _extractKeywords(text);

    final matches = <RelevantEvent>[];
    for (final event in storyline.events) {
      if (event.chapterIndex > currentChapter) continue;
      final desc = event.description.toLowerCase();
      for (final keyword in keywords) {
        if (desc.contains(keyword)) {
          matches.add(
            RelevantEvent(
              chapterIndex: event.chapterIndex,
              description: event.description,
              significance: event.significance,
            ),
          );
          break;
        }
      }
    }
    return matches.take(3).toList();
  }

  static List<RelevantCharacter> _findMentionedCharacters(
    String text,
    List<BookCharacterCard>? cards,
    int currentChapter,
  ) {
    if (cards == null) return const [];
    final lowerText = text.toLowerCase();
    final matches = <RelevantCharacter>[];

    for (final card in cards) {
      if (lowerText.contains(card.canonicalName.toLowerCase())) {
        final developments = card.developments
            .map((d) => d.change)
            .where((c) => c.isNotEmpty)
            .toList();
        if (developments.isNotEmpty) {
          matches.add(
            RelevantCharacter(
              name: card.canonicalName,
              developments: developments,
            ),
          );
        }
      }
    }
    return matches.take(2).toList();
  }

  static Set<String> _extractKeywords(String text) {
    final words =
        text.toLowerCase().split(RegExp(r'[^a-zA-Z]+')).where((w) => w.length > 3).toSet();
    // Remove common words
    final stopWords = {
      'that', 'this', 'with', 'from', 'were', 'they', 'have', 'been',
      'would', 'could', 'there', 'about', 'which', 'what', 'when',
    };
    words.removeAll(stopWords);
    return words;
  }
}

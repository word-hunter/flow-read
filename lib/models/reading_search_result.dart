class ReadingSearchResult {
  final String query;
  final int chapterIndex;
  final int itemIndex;
  final int matchIndex;
  final int matchStart;
  final int matchEnd;
  final String chapterTitle;
  final String snippet;
  final int snippetMatchStart;
  final int snippetMatchEnd;

  const ReadingSearchResult({
    required this.query,
    required this.chapterIndex,
    required this.itemIndex,
    required this.matchIndex,
    required this.matchStart,
    required this.matchEnd,
    required this.chapterTitle,
    required this.snippet,
    required this.snippetMatchStart,
    required this.snippetMatchEnd,
  });

  String get locationLabel => '位置 ${chapterIndex + 1}';

  @override
  bool operator ==(Object other) {
    return other is ReadingSearchResult &&
        other.query == query &&
        other.chapterIndex == chapterIndex &&
        other.itemIndex == itemIndex &&
        other.matchIndex == matchIndex &&
        other.matchStart == matchStart &&
        other.matchEnd == matchEnd;
  }

  @override
  int get hashCode => Object.hash(
    query,
    chapterIndex,
    itemIndex,
    matchIndex,
    matchStart,
    matchEnd,
  );
}

class ReadingSearchProgress {
  final ReadingSearchResult? result;
  final bool stoppedAtLimit;

  const ReadingSearchProgress.result(this.result) : stoppedAtLimit = false;

  const ReadingSearchProgress.stoppedAtLimit()
    : result = null,
      stoppedAtLimit = true;
}

class AggregatedVocabulary {
  final String word;
  final String meaning;
  final int firstChapter;
  final String context;
  final Set<int> chapterIndices;
  final String? level;

  const AggregatedVocabulary({
    required this.word,
    required this.meaning,
    required this.firstChapter,
    required this.context,
    this.chapterIndices = const {},
    this.level,
  });

  AggregatedVocabulary copyWith({
    String? meaning,
    int? firstChapter,
    String? context,
    Set<int>? chapterIndices,
    String? level,
  }) {
    return AggregatedVocabulary(
      word: word,
      meaning: meaning ?? this.meaning,
      firstChapter: firstChapter ?? this.firstChapter,
      context: context ?? this.context,
      chapterIndices: chapterIndices ?? this.chapterIndices,
      level: level ?? this.level,
    );
  }

  Set<int> updatedChapters(int newChapter) {
    return {...chapterIndices, newChapter};
  }
}

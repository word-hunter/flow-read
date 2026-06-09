class ChapterAISummaryCoverage {
  final int totalChapters;
  final Set<int> generatedChapterIndexes;

  ChapterAISummaryCoverage({
    required this.totalChapters,
    required Iterable<int> generatedChapterIndexes,
  }) : generatedChapterIndexes = Set.unmodifiable(
         generatedChapterIndexes.where(
           (index) => index >= 0 && index < totalChapters,
         ),
       );

  int get generatedCount => generatedChapterIndexes.length;

  int get missingCount => totalChapters - generatedCount;

  bool get hasGeneratedChapters => generatedChapterIndexes.isNotEmpty;

  bool isGenerated(int chapterIndex) {
    return generatedChapterIndexes.contains(chapterIndex);
  }

  List<int> get missingChapterIndexes {
    return [
      for (var index = 0; index < totalChapters; index++)
        if (!generatedChapterIndexes.contains(index)) index,
    ];
  }
}

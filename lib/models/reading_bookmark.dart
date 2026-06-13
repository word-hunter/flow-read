class ReadingBookmark {
  final int chapterIndex;
  final double progress;
  final String chapterTitle;
  final String excerpt;
  final DateTime createdAt;
  final String bookId;

  const ReadingBookmark({
    required this.chapterIndex,
    required this.progress,
    required this.chapterTitle,
    required this.excerpt,
    required this.createdAt,
    required this.bookId,
  });
}

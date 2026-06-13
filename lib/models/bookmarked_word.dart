class BookmarkedWord {
  final String word;
  final String translation;
  final String context;
  final DateTime addedAt;
  final String bookId;

  const BookmarkedWord({
    required this.word,
    required this.translation,
    required this.context,
    required this.addedAt,
    required this.bookId,
  });
}

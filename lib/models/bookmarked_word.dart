import 'package:hive/hive.dart';

part 'bookmarked_word.g.dart';

@HiveType(typeId: 1)
class BookmarkedWord {
  @HiveField(0)
  final String word;

  @HiveField(1)
  final String translation;

  @HiveField(2)
  final String context;

  @HiveField(3)
  final DateTime addedAt;

  @HiveField(4)
  final String bookId;

  const BookmarkedWord({
    required this.word,
    required this.translation,
    required this.context,
    required this.addedAt,
    required this.bookId,
  });
}

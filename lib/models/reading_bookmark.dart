import 'package:hive/hive.dart';

part 'reading_bookmark.g.dart';

@HiveType(typeId: 2)
class ReadingBookmark {
  @HiveField(0)
  final int chapterIndex;

  @HiveField(1)
  final double progress;

  @HiveField(2)
  final String chapterTitle;

  @HiveField(3)
  final String excerpt;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
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

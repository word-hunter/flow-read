import 'dart:typed_data';
import 'chapter.dart';

class Book {
  final String title;
  final String author;
  final List<Chapter> chapters;
  final Uint8List? coverBytes;

  const Book({
    required this.title,
    required this.author,
    required this.chapters,
    this.coverBytes,
  });
}

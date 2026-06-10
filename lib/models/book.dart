import 'dart:typed_data';
import 'chapter.dart';
import 'package:epub_reader_core/epub_reader_core.dart' show EpubTocEntry;

class Book {
  final String title;
  final String author;
  final String? language;
  final List<Chapter> chapters;
  final Uint8List? coverBytes;
  final List<EpubTocEntry> toc;
  final Map<String, String> footnoteMap;

  const Book({
    required this.title,
    required this.author,
    this.language,
    required this.chapters,
    this.coverBytes,
    this.toc = const [],
    this.footnoteMap = const {},
  });
}

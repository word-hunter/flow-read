import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/bookmarked_word.dart';
import '../../models/reading_bookmark.dart';
import '../reading_provider.dart';
import 'reading_provider_riverpod.dart';

class BookmarkController {
  const BookmarkController(this._reader);

  final ReadingProvider _reader;

  List<BookmarkedWord> get bookmarkedWords => _reader.bookmarkedWords;
  List<ReadingBookmark> get readingBookmarks => _reader.readingBookmarks;
  int get currentChapter => _reader.currentChapter;

  bool isBookmarked(String word) => _reader.isBookmarked(word);
  bool isCurrentPositionBookmarked() => _reader.isCurrentPositionBookmarked();

  void addBookmark(String word, String translation) {
    _reader.addBookmark(word, translation);
  }

  void removeBookmark(String word) {
    _reader.removeBookmark(word);
  }

  void addReadingBookmark() {
    _reader.addReadingBookmark();
  }

  void removeReadingBookmark(int index) {
    _reader.removeReadingBookmark(index);
  }

  void goToReadingBookmark(ReadingBookmark bookmark) {
    _reader.goToReadingBookmark(bookmark);
  }
}

final bookmarkProvider = Provider<BookmarkController>((ref) {
  return BookmarkController(ref.watch(readingProvider));
});

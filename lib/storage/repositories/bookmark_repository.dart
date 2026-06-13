abstract class BookmarkRepository {
  Future<void> init();
  String? getWordBookmarks(String bookId);
  Future<void> putWordBookmarks(String bookId, String encodedBookmarks);
  Future<void> deleteWordBookmarks(String bookId);
  String? getReadingBookmarks(String bookId);
  Future<void> putReadingBookmarks(String bookId, String encodedBookmarks);
  Future<void> deleteReadingBookmarks(String bookId);
  Future<void> close();
}

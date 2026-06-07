import '../models/book.dart';

class BookCache {
  static const _maxSize = 3;

  final _cache = <String, _CachedBook>{};
  final _accessOrder = <String>[];

  Book? get(String bookId) {
    final cached = _cache[bookId];
    if (cached != null) {
      _accessOrder.remove(bookId);
      _accessOrder.add(bookId);
      return cached.book;
    }
    return null;
  }

  void put(String bookId, Book book) {
    if (_cache.containsKey(bookId)) {
      _cache[bookId] = _CachedBook(book);
      _accessOrder.remove(bookId);
    } else {
      while (_cache.length >= _maxSize) {
        final oldest = _accessOrder.removeAt(0);
        _cache.remove(oldest);
      }
      _cache[bookId] = _CachedBook(book);
    }
    _accessOrder.add(bookId);
  }

  void remove(String bookId) {
    _cache.remove(bookId);
    _accessOrder.remove(bookId);
  }

  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }
}

class _CachedBook {
  final Book book;

  _CachedBook(this.book);
}

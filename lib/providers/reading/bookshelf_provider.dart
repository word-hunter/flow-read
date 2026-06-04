import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/book_metadata.dart';
import '../reading_provider.dart';
import 'reading_provider_riverpod.dart';

class BookshelfController {
  const BookshelfController(this._reader);

  final ReadingProvider _reader;

  List<BookMetadata> get allBooks => _reader.allBooks;
  int get bookCount => allBooks.length;
  bool get isLoading => _reader.isLoading;
  String? get errorMessage => _reader.errorMessage;

  Future<void> importBook(String filePath) {
    return _reader.importBook(filePath);
  }
}

final bookshelfProvider = Provider<BookshelfController>((ref) {
  return BookshelfController(ref.watch(readingProvider));
});

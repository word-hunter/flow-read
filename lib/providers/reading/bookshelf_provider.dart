import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/book_difficulty.dart';
import '../../models/book_metadata.dart';
import '../../services/epub_import_source.dart';
import '../reading_provider.dart';
import 'reading_provider_riverpod.dart';

class BookshelfController {
  const BookshelfController(this._reader);

  final ReadingProvider _reader;

  List<BookMetadata> get allBooks => _reader.allBooks;
  int get bookCount => allBooks.length;
  bool get isLoading => _reader.isLoading;
  String? get errorMessage => _reader.errorMessage;
  String get importStage => _reader.importStage;
  bool get isImportingBook => _reader.isImportingBook;
  bool get isCancellingImport => _reader.isCancellingImport;
  bool get canCancelImport => _reader.canCancelImport;
  double? get importProgress => _reader.importProgress;
  String? get importFileName => _reader.importFileName;
  bool get isLoadingBookDifficulties => _reader.isLoadingBookDifficulties;
  int get loadingBookDifficultyCount => _reader.loadingBookDifficultyCount;
  int get learningItemCount => _reader.learningItemCount;
  int get todayReviewDueCount => _reader.todayReviewDueCount;

  Uint8List? getCoverBytes(String bookId) {
    return _reader.getCoverBytes(bookId);
  }

  BookDifficultyRating? difficultyForBook(String bookId) {
    return _reader.difficultyForBook(bookId);
  }

  bool isBookDifficultyLoading(String bookId) {
    return _reader.isBookDifficultyLoading(bookId);
  }

  Future<void> ensureBookDifficulties(Iterable<BookMetadata> books) {
    return _reader.ensureBookDifficulties(books);
  }

  Future<bool> switchToBook(String bookId) {
    return _reader.switchToBook(bookId);
  }

  void enterReader() {
    _reader.enterReader();
  }

  Future<void> removeBook(String bookId) {
    return _reader.removeBook(bookId);
  }

  Future<void> renameBook(String bookId, String title) {
    return _reader.renameBook(bookId, title);
  }

  Future<BookImportResult> importBook(String filePath) {
    return _reader.importBook(filePath);
  }

  Future<BookImportResult> importBookFromSource(EpubImportSource source) {
    return _reader.importBookFromSource(source);
  }

  void cancelImport() {
    _reader.cancelImport();
  }

  Future<void> reloadAfterBackupRestore() {
    return _reader.reloadAfterBackupRestore();
  }

  Future<void> reloadAfterWordHunterImport() {
    return _reader.init();
  }

  void clearError() {
    _reader.clearError();
  }
}

final bookshelfProvider = Provider<BookshelfController>((ref) {
  return BookshelfController(ref.watch(readingProvider));
});

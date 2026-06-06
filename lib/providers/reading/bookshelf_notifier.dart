import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/book.dart';
import '../../models/book_difficulty.dart';
import '../../models/book_metadata.dart';
import '../../services/epub_import_source.dart';
import '../reading_provider.dart';
import 'reading_provider_riverpod.dart';

@immutable
class BookshelfState {
  const BookshelfState({
    this.books = const [],
    this.activeBookId,
    this.book,
    this.isLoading = false,
    this.errorMessage,
    this.importStage = '',
    this.isImportingBook = false,
    this.isCancellingImport = false,
    this.canCancelImport = false,
    this.importProgress,
    this.importFileName,
    this.lastImportResult = BookImportResult.ignored,
  });

  final List<BookMetadata> books;
  final String? activeBookId;
  final Book? book;
  final bool isLoading;
  final String? errorMessage;
  final String importStage;
  final bool isImportingBook;
  final bool isCancellingImport;
  final bool canCancelImport;
  final double? importProgress;
  final String? importFileName;
  final BookImportResult lastImportResult;

  int get chapterCount => book?.chapters.length ?? 0;

  BookshelfState copyWith({
    List<BookMetadata>? books,
    String? activeBookId,
    Book? book,
    bool? isLoading,
    String? errorMessage,
    String? importStage,
    bool? isImportingBook,
    bool? isCancellingImport,
    bool? canCancelImport,
    double? importProgress,
    String? importFileName,
    BookImportResult? lastImportResult,
    bool clearBook = false,
    bool clearError = false,
  }) {
    return BookshelfState(
      books: books ?? this.books,
      activeBookId: activeBookId ?? this.activeBookId,
      book: clearBook ? null : (book ?? this.book),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      importStage: importStage ?? this.importStage,
      isImportingBook: isImportingBook ?? this.isImportingBook,
      isCancellingImport: isCancellingImport ?? this.isCancellingImport,
      canCancelImport: canCancelImport ?? this.canCancelImport,
      importProgress: importProgress ?? this.importProgress,
      importFileName: importFileName ?? this.importFileName,
      lastImportResult: lastImportResult ?? this.lastImportResult,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BookshelfState &&
        other.books.length == books.length &&
        other.activeBookId == activeBookId &&
        identical(other.book, book) &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage &&
        other.importStage == importStage &&
        other.isImportingBook == isImportingBook &&
        other.isCancellingImport == isCancellingImport &&
        other.canCancelImport == canCancelImport &&
        other.importProgress == importProgress &&
        other.importFileName == importFileName &&
        other.lastImportResult == lastImportResult;
  }

  @override
  int get hashCode => Object.hash(
        books.length,
        activeBookId,
        book?.title,
        isLoading,
        errorMessage,
        importStage,
        isImportingBook,
        isCancellingImport,
        canCancelImport,
        importProgress,
        importFileName,
        lastImportResult,
      );
}

class BookshelfNotifier extends Notifier<BookshelfState> {
  @override
  BookshelfState build() {
    final reader = ref.watch(readingProvider);
    try {
      return BookshelfState(
        books: reader.allBooks,
        activeBookId: reader.activeBookId,
        book: reader.book,
        isLoading: reader.isLoading,
        errorMessage: reader.errorMessage,
        importStage: reader.importStage,
        isImportingBook: reader.isImportingBook,
        isCancellingImport: reader.isCancellingImport,
        canCancelImport: reader.canCancelImport,
        importProgress: reader.importProgress,
        importFileName: reader.importFileName,
        lastImportResult: reader.lastImportResult,
      );
    } catch (_) {
      return BookshelfState(
        book: reader.book,
        activeBookId: reader.activeBookId,
        isLoading: reader.isLoading,
      );
    }
  }

  // ---- Book Management ----

  List<BookMetadata> get allBooks {
    try {
      final reader = ref.read(readingProvider);
      return reader.allBooks;
    } catch (_) {
      return state.books;
    }
  }

  int get bookCount => allBooks.length;

  Uint8List? getCoverBytes(String bookId) {
    final reader = ref.read(readingProvider);
    return reader.getCoverBytes(bookId);
  }

  BookDifficultyRating? difficultyForBook(String bookId) {
    final reader = ref.read(readingProvider);
    return reader.difficultyForBook(bookId);
  }

  bool isBookDifficultyLoading(String bookId) {
    final reader = ref.read(readingProvider);
    return reader.isBookDifficultyLoading(bookId);
  }

  bool get isLoadingBookDifficulties {
    final reader = ref.read(readingProvider);
    return reader.isLoadingBookDifficulties;
  }

  int get loadingBookDifficultyCount {
    final reader = ref.read(readingProvider);
    return reader.loadingBookDifficultyCount;
  }

  int get learningItemCount {
    final reader = ref.read(readingProvider);
    return reader.learningItemCount;
  }

  int get todayReviewDueCount {
    final reader = ref.read(readingProvider);
    return reader.todayReviewDueCount;
  }

  Future<void> ensureBookDifficulties(Iterable<BookMetadata> books) {
    final reader = ref.read(readingProvider);
    return reader.ensureBookDifficulties(books);
  }

  Future<bool> switchToBook(String bookId) async {
    final reader = ref.read(readingProvider);
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await reader.switchToBook(bookId);
    state = state.copyWith(
      isLoading: false,
      activeBookId: reader.activeBookId,
      book: reader.book,
      errorMessage: reader.errorMessage,
    );
    return result;
  }

  void enterReader() {
    final reader = ref.read(readingProvider);
    reader.enterReader();
  }

  Future<void> removeBook(String bookId) async {
    final reader = ref.read(readingProvider);
    await reader.removeBook(bookId);
    state = state.copyWith(
      activeBookId: reader.activeBookId,
      clearBook: true,
    );
  }

  Future<void> renameBook(String bookId, String title) async {
    final reader = ref.read(readingProvider);
    await reader.renameBook(bookId, title);
    state = state.copyWith(books: reader.allBooks);
  }

  // ---- Import ----

  Future<BookImportResult> importBook(String filePath) {
    final reader = ref.read(readingProvider);
    return _importWrapper(() => reader.importBook(filePath));
  }

  Future<BookImportResult> importBookFromSource(EpubImportSource source) {
    final reader = ref.read(readingProvider);
    return _importWrapper(() => reader.importBookFromSource(source));
  }

  void cancelImport() {
    final reader = ref.read(readingProvider);
    reader.cancelImport();
    _syncImportState();
  }

  Future<BookImportResult> _importWrapper(
    Future<BookImportResult> Function() importFn,
  ) async {
    _syncImportState();
    final result = await importFn();
    _syncImportState();
    final reader = ref.read(readingProvider);
    state = state.copyWith(
      activeBookId: reader.activeBookId,
      book: reader.book,
      lastImportResult: result,
    );
    return result;
  }

  void _syncImportState() {
    final reader = ref.read(readingProvider);
    state = state.copyWith(
      isLoading: reader.isLoading,
      errorMessage: reader.errorMessage,
      importStage: reader.importStage,
      isImportingBook: reader.isImportingBook,
      isCancellingImport: reader.isCancellingImport,
      canCancelImport: reader.canCancelImport,
      importProgress: reader.importProgress,
      importFileName: reader.importFileName,
      lastImportResult: reader.lastImportResult,
    );
  }

  // ---- Global ----

  Future<void> reloadAfterBackupRestore() {
    final reader = ref.read(readingProvider);
    return reader.reloadAfterBackupRestore();
  }

  Future<void> reloadAfterWordHunterImport() {
    final reader = ref.read(readingProvider);
    return reader.init();
  }

  void clearError() {
    final reader = ref.read(readingProvider);
    reader.clearError();
    state = state.copyWith(clearError: true);
  }
}

final bookshelfNotifierProvider =
    NotifierProvider<BookshelfNotifier, BookshelfState>(
  BookshelfNotifier.new,
);

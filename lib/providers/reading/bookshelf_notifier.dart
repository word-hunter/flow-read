import 'dart:async';
import 'dart:io';

import 'package:epub_reader_core/epub_reader_core.dart' as core;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/book.dart';
import '../../models/book_difficulty.dart';
import '../../models/book_metadata.dart';
import '../../services/epub_import_source.dart';
import '../../services/epub_parse_worker.dart';
import 'package:flow_language/flow_language.dart';
import 'current_book_notifier.dart';
import 'services_provider.dart';
import 'vocabulary_notifier.dart';

class _ImportCancelledException implements Exception {
  const _ImportCancelledException();
}

enum BookImportResult { imported, cancelled, failed, ignored }

class ImportProgressState {
  const ImportProgressState({
    this.isImportingBook = false,
    this.isCancellingImport = false,
    this.canCancelImport = false,
    this.progress,
    this.fileName,
    this.stage = '',
  });

  static const idle = ImportProgressState();

  final bool isImportingBook;
  final bool isCancellingImport;
  final bool canCancelImport;
  final double? progress;
  final String? fileName;
  final String stage;

  @override
  bool operator ==(Object other) {
    return other is ImportProgressState &&
        other.isImportingBook == isImportingBook &&
        other.isCancellingImport == isCancellingImport &&
        other.canCancelImport == canCancelImport &&
        other.progress == progress &&
        other.fileName == fileName &&
        other.stage == stage;
  }

  @override
  int get hashCode => Object.hash(
    isImportingBook,
    isCancellingImport,
    canCancelImport,
    progress,
    fileName,
    stage,
  );
}

class ImportProgressNotifier extends ValueNotifier<ImportProgressState> {
  ImportProgressNotifier() : super(ImportProgressState.idle);
}

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
  static const _importCancelDelay = Duration(seconds: 3);
  static const _importParseProgressStart = 0.18;
  static const _importParseProgressEnd = 0.72;

  final ImportProgressNotifier _importProgressNotifier =
      ImportProgressNotifier();

  // Import internals
  bool _showImportCancel = false;
  bool _importCancellationRequested = false;
  Timer? _importCancelTimer;
  EpubParseTask? _activeImportParseTask;

  @override
  BookshelfState build() {
    final bookService = ref.read(bookServiceProvider);
    return BookshelfState(
      books: bookService.books,
    );
  }

  // ---- Book Management ----

  List<BookMetadata> get allBooks => ref.read(bookServiceProvider).books;

  int get bookCount => allBooks.length;

  Uint8List? getCoverBytes(String bookId) =>
      ref.read(bookServiceProvider).loadCover(bookId);

  BookDifficultyRating? difficultyForBook(String bookId) =>
      ref.read(vocabularyNotifierProvider.notifier).difficultyForBook(bookId);

  bool isBookDifficultyLoading(String bookId) => ref
      .read(vocabularyNotifierProvider.notifier)
      .isBookDifficultyLoading(bookId);

  bool get isLoadingBookDifficulties =>
      ref.read(vocabularyNotifierProvider.notifier).isLoadingBookDifficulties;

  int get loadingBookDifficultyCount =>
      ref.read(vocabularyNotifierProvider.notifier).loadingBookDifficultyCount;

  int get learningItemCount => ref.read(learningItemServiceProvider).count;

  int get todayReviewDueCount =>
      ref.read(reviewScheduleServiceProvider).dueCount();

  Future<void> ensureBookDifficulties(Iterable<BookMetadata> books) => ref
      .read(vocabularyNotifierProvider.notifier)
      .ensureBookDifficulties(books);

  Future<bool> switchToBook(String bookId) async {
    if (bookId == state.activeBookId && state.book != null) return true;

    final bookService = ref.read(bookServiceProvider);
    _saveCurrentProgress();

    final meta = bookService.books.where((b) => b.id == bookId).firstOrNull;
    if (meta == null) {
      state = state.copyWith(errorMessage: '打开书籍失败：书架中找不到这本书。');
      return false;
    }

    ref.read(vocabularyNotifierProvider.notifier).tryUseCachedDifficulty(meta);

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      importStage: '正在解析 EPUB...',
    );

    try {
      final book = await EpubParseWorker.parseInIsolate(meta.sourcePath);
      final currentChapter = meta.currentChapter.clamp(
        0,
        book.chapters.length - 1,
      );

      state = state.copyWith(
        book: book,
        activeBookId: bookId,
        importStage: '',
        isLoading: false,
      );

      ref
          .read(currentBookNotifierProvider.notifier)
          .invalidateChapterAnalysisCache();
      ref
          .read(currentBookNotifierProvider.notifier)
          .goToChapter(currentChapter);
      ref.read(aiAssistantControllerProvider).clear();

      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: '打开书籍失败：无法读取书籍文件。',
        isLoading: false,
        importStage: '',
      );
      return false;
    }
  }

  void enterReader() {
    ref.read(currentBookNotifierProvider.notifier).enterReader();
  }

  Future<void> removeBook(String bookId) async {
    final bookService = ref.read(bookServiceProvider);
    final bookmarkService = ref.read(bookmarkServiceProvider);
    final learningItemService = ref.read(learningItemServiceProvider);
    final aiCache = ref.read(aiCacheServiceProvider);

    await bookService.removeBook(bookId);
    await bookmarkService.deleteWordBookmarks(bookId);
    await bookmarkService.deleteReadingBookmarks(bookId);
    await learningItemService.deleteForBook(bookId);
    await aiCache.clearBookCache(bookId);

    if (state.activeBookId == bookId) {
      state = state.copyWith(
        activeBookId: null,
        clearBook: true,
      );
    }
    state = state.copyWith(books: bookService.books);
  }

  Future<void> renameBook(String bookId, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    await ref.read(bookServiceProvider).renameBook(bookId, trimmed);
    state = state.copyWith(books: ref.read(bookServiceProvider).books);
  }

  // ---- Import ----

  Future<BookImportResult> importBook(String filePath) {
    return importBookFromSource(EpubImportSource.path(filePath));
  }

  Future<BookImportResult> importBookFromSource(EpubImportSource source) async {
    if (state.isImportingBook) return BookImportResult.ignored;
    _beginImport(source.fileName);

    String? copiedPath;
    var shouldDeleteCopiedSource = true;

    try {
      final bookId = _generateBookId(source.fileName);
      var effectiveBookId = bookId;
      final bookService = ref.read(bookServiceProvider);
      copiedPath = await bookService.saveSource(bookId, source);
      _throwIfImportCancelled();

      _updateImportProgress('正在解析 EPUB...', 0.18);
      final parseTask = await EpubParseWorker.startParseInIsolate(
        copiedPath,
        onProgress: _handleImportParseProgress,
      );
      _activeImportParseTask = parseTask;
      if (_importCancellationRequested) {
        parseTask.cancel();
      }
      final book = await parseTask.future;
      _activeImportParseTask = null;
      _throwIfImportCancelled();

      _updateImportProgress('正在整理书籍信息...', 0.72);
      final restoredMeta = await _findMissingSourceRepairCandidate(book);
      if (restoredMeta != null) {
        effectiveBookId = restoredMeta.id;
        shouldDeleteCopiedSource = false;
        copiedPath = await bookService.replaceSourceFile(
          effectiveBookId,
          copiedPath,
        );
      }
      _throwIfImportCancelled();

      String? coverPath;
      if (book.coverBytes != null) {
        _updateImportProgress('正在保存封面...', 0.78);
        coverPath = await bookService.saveCover(
          effectiveBookId,
          book.coverBytes!,
        );
      }

      final sourceLanguage = LanguageRegistry.normalizeLanguageCode(
        book.language,
      );
      final languageConfidence = sourceLanguage == null ? null : 0.9;

      final metadata = restoredMeta == null
          ? BookMetadata(
              id: effectiveBookId,
              title: book.title,
              author: book.author,
              sourcePath: copiedPath,
              coverPath: coverPath,
              totalChapters: book.chapters.length,
              lastReadAt: DateTime.now(),
              sourceLanguage: sourceLanguage,
              languageConfidence: languageConfidence,
            )
          : restoredMeta.copyWith(
              title: book.title,
              author: book.author,
              sourcePath: copiedPath,
              coverPath: coverPath ?? restoredMeta.coverPath,
              totalChapters: book.chapters.length,
              sourceLanguage: sourceLanguage ?? restoredMeta.sourceLanguage,
              languageConfidence:
                  languageConfidence ?? restoredMeta.languageConfidence,
              currentChapter: _clampChapterIndex(
                restoredMeta.currentChapter,
                book.chapters.length,
              ),
            );

      _throwIfImportCancelled();
      _updateImportProgress('正在写入书架...', 0.84, canCancel: false);
      await bookService.addBook(metadata);
      shouldDeleteCopiedSource = false;

      _updateImportProgress('正在统计生词、分析句式...', 0.9, canCancel: false);
      state = state.copyWith(
        book: book,
        activeBookId: effectiveBookId,
        books: bookService.books,
      );

      _showImportCancel = false;
      _importCancelTimer?.cancel();
      _importCancelTimer = null;
      state = state.copyWith(
        importStage: '导入完成',
        importProgress: 1,
        lastImportResult: BookImportResult.imported,
      );
      _emitImportProgress();
      return BookImportResult.imported;
    } on EpubParseCancelledException {
      await _cleanupCancelledImport(
        copiedPath,
        deleteCopiedSource: shouldDeleteCopiedSource,
      );
      state = state.copyWith(
        lastImportResult: BookImportResult.cancelled,
      );
      return BookImportResult.cancelled;
    } on _ImportCancelledException {
      await _cleanupCancelledImport(
        copiedPath,
        deleteCopiedSource: shouldDeleteCopiedSource,
      );
      state = state.copyWith(
        lastImportResult: BookImportResult.cancelled,
      );
      return BookImportResult.cancelled;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to import book: $e',
        lastImportResult: BookImportResult.failed,
      );
      return BookImportResult.failed;
    } finally {
      _finishImport();
    }
  }

  void cancelImport() {
    if (!state.isImportingBook || state.isCancellingImport) return;
    _importCancellationRequested = true;
    state = state.copyWith(
      isCancellingImport: true,
      importStage: '正在取消导入...',
    );
    _activeImportParseTask?.cancel();
    _emitImportProgress();
  }

  // ---- Global ----

  Future<void> reloadAfterBackupRestore() async {
    final bookService = ref.read(bookServiceProvider);
    await bookService.init();
    final readingTime = ref.read(readingTimeServiceProvider);
    await readingTime.init();
    ref.read(bookCacheProvider).clear();
    bookService.clearCoverCache();
    state = state.copyWith(
      books: bookService.books,
      clearBook: true,
      activeBookId: null,
    );
  }

  Future<void> reloadAfterWordHunterImport() async {
    final bookService = ref.read(bookServiceProvider);
    await bookService.init();
    state = state.copyWith(books: bookService.books);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  ImportProgressNotifier get importProgressNotifier => _importProgressNotifier;

  BookMetadata? get activeBookMetadata {
    final bookId = state.activeBookId;
    if (bookId == null) return null;
    final bookService = ref.read(bookServiceProvider);
    return bookService.books.where((b) => b.id == bookId).firstOrNull;
  }

  Future<void> setBookSourceLanguageOverride(
    String bookId,
    String code,
  ) async {
    final normalized = LanguageRegistry.normalizeLanguageCode(code);
    if (normalized == null) return;
    final metadata = _metadataForBook(bookId);
    if (metadata == null) return;
    await _persistBookMetadataUpdate(
      metadata.copyWith(
        sourceLanguageOverride: normalized,
        languageConfidence: 1.0,
      ),
    );
  }

  Future<void> clearBookSourceLanguageOverride(String bookId) async {
    final metadata = _metadataForBook(bookId);
    if (metadata == null) return;
    final hasDetectedLanguage = metadata.sourceLanguage != null;
    final restoredConfidence = hasDetectedLanguage
        ? metadata.languageConfidence == 1.0
              ? 0.9
              : metadata.languageConfidence
        : null;
    await _persistBookMetadataUpdate(
      metadata.copyWith(
        clearSourceLanguageOverride: true,
        languageConfidence: restoredConfidence,
        clearLanguageConfidence: !hasDetectedLanguage,
      ),
    );
  }

  // ---- Internal: Book management ----

  void _saveCurrentProgress() {
    final bookId = state.activeBookId;
    if (bookId == null || state.book == null) return;
    final currentChapter = ref.read(currentBookNotifierProvider).currentChapter;
    final readingProgress = ref
        .read(currentBookNotifierProvider)
        .readingProgress;
    ref
        .read(bookServiceProvider)
        .updateProgress(
          bookId,
          currentChapter,
          readingProgress,
        );
  }

  int _clampChapterIndex(int index, int chapterCount) {
    if (chapterCount <= 0) return 0;
    return index.clamp(0, chapterCount - 1);
  }

  BookMetadata? _metadataForBook(String bookId) {
    final bookService = ref.read(bookServiceProvider);
    return bookService.books.where((b) => b.id == bookId).firstOrNull;
  }

  Future<void> _persistBookMetadataUpdate(BookMetadata metadata) async {
    final bookService = ref.read(bookServiceProvider);
    await bookService.addBook(metadata);
    state = state.copyWith(books: bookService.books);
  }

  // ---- Internal: Import helpers ----

  String _generateBookId(String fileName) {
    final stripped = fileName.split('/').last.split('\\').last;
    final base = stripped.replaceAll(RegExp(r'\s+'), '_');
    final normalized = base.replaceAll(RegExp(r'[^\w\-_.]'), '');
    final name = normalized.isNotEmpty ? normalized : 'imported_book';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${name}_$timestamp';
  }

  void _beginImport(String fileName) {
    _importCancelTimer?.cancel();
    _activeImportParseTask = null;
    _importCancellationRequested = false;
    _showImportCancel = false;
    state = state.copyWith(
      isLoading: true,
      isImportingBook: true,
      isCancellingImport: false,
      errorMessage: null,
      lastImportResult: BookImportResult.ignored,
      importFileName: fileName,
      importProgress: 0.06,
      importStage: '正在读取 EPUB 文件...',
    );
    _importCancelTimer = Timer(_importCancelDelay, () {
      if (!state.isImportingBook || state.isCancellingImport) return;
      _showImportCancel = true;
      _emitImportProgress();
    });
    _emitImportProgress();
  }

  void _handleImportParseProgress(core.EpubParseEvent event) {
    if (!state.isImportingBook || state.isCancellingImport) return;
    final currentProgress = state.importProgress ?? 0;
    final nextProgress = _mapImportParseProgress(event);
    _updateImportProgress(
      _importParseStage(event),
      nextProgress < currentProgress ? currentProgress : nextProgress,
    );
  }

  double _mapImportParseProgress(core.EpubParseEvent event) {
    return switch (event.phase) {
      core.EpubParsePhase.extractingMetadata => 0.1,
      core.EpubParsePhase.complete => _importParseProgressEnd,
      _ =>
        _importParseProgressStart +
            event.progress.clamp(0.0, 1.0).toDouble() *
                (_importParseProgressEnd - _importParseProgressStart),
    };
  }

  String _importParseStage(core.EpubParseEvent event) {
    return switch (event.phase) {
      core.EpubParsePhase.extractingMetadata => '正在读取书籍信息...',
      core.EpubParsePhase.parsingChapter ||
      core.EpubParsePhase.buildingBlocks ||
      core.EpubParsePhase.loadingImage => '正在解析 EPUB 内容...',
      core.EpubParsePhase.complete => '解析完成',
    };
  }

  void _updateImportProgress(
    String stage,
    double progress, {
    bool canCancel = true,
  }) {
    state = state.copyWith(
      importStage: stage,
      importProgress: progress.clamp(0.0, 1.0).toDouble(),
    );
    if (!canCancel) {
      _showImportCancel = false;
      _importCancelTimer?.cancel();
      _importCancelTimer = null;
    }
    _emitImportProgress();
  }

  void _emitImportProgress() {
    _importProgressNotifier.value = ImportProgressState(
      isImportingBook: state.isImportingBook,
      isCancellingImport: state.isCancellingImport,
      canCancelImport: _showImportCancel && !state.isCancellingImport,
      progress: state.importProgress,
      fileName: state.importFileName,
      stage: state.importStage,
    );
  }

  void _throwIfImportCancelled() {
    if (_importCancellationRequested) {
      throw const _ImportCancelledException();
    }
  }

  Future<void> _cleanupCancelledImport(
    String? copiedPath, {
    required bool deleteCopiedSource,
  }) async {
    if (!deleteCopiedSource || copiedPath == null) return;
    final file = File(copiedPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  void _finishImport() {
    _importCancelTimer?.cancel();
    _importCancelTimer = null;
    _activeImportParseTask = null;
    _importCancellationRequested = false;
    _showImportCancel = false;
    state = state.copyWith(
      isLoading: false,
      isImportingBook: false,
      isCancellingImport: false,
      importStage: '',
      importProgress: null,
      importFileName: null,
    );
    _emitImportProgress();
  }

  Future<BookMetadata?> _findMissingSourceRepairCandidate(Book book) async {
    final bookService = ref.read(bookServiceProvider);
    final existing = bookService.books;
    return existing.cast<BookMetadata?>().firstWhere(
      (meta) =>
          meta != null &&
          _normalizeBookIdentity(meta.title) ==
              _normalizeBookIdentity(book.title) &&
          meta.author == book.author,
      orElse: () => null,
    );
  }

  String _normalizeBookIdentity(String title) {
    return title.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

final bookshelfNotifierProvider =
    NotifierProvider<BookshelfNotifier, BookshelfState>(
      BookshelfNotifier.new,
    );

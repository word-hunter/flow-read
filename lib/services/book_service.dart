import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/book_metadata.dart';
import '../models/book_difficulty.dart';
import '../storage/repositories/book_metadata_repository.dart';
import 'epub_import_source.dart';

class BookService {
  BookService({
    BookMetadataRepository? repository,
    Future<Directory> Function()? documentsDirectoryProvider,
    DateTime Function()? clock,
  }) : _repository = repository ?? HiveBookMetadataRepository(),
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory,
       _clock = clock ?? DateTime.now;

  final BookMetadataRepository _repository;
  final Future<Directory> Function() _documentsDirectoryProvider;
  final DateTime Function() _clock;

  String? _booksDir;

  List<BookMetadata> get books => _repository.values.toList();

  Future<void> init() async {
    await _repository.init();
    final dir = await _documentsDirectoryProvider();
    _booksDir = '${dir.path}/books';
    final booksDir = Directory(_booksDir!);
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }
  }

  String get _requiredBooksDir {
    final booksDir = _booksDir;
    if (booksDir == null) {
      throw StateError('BookService.init must be called before file access.');
    }
    return booksDir;
  }

  String _coverFilePath(String bookId) =>
      '$_requiredBooksDir/${bookId}_cover.png';

  String _sourceFilePath(String bookId) => '$_requiredBooksDir/$bookId.epub';

  Future<String> saveSource(String bookId, EpubImportSource source) async {
    final path = _sourceFilePath(bookId);
    final tempPath = '$path.importing';
    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    try {
      await source.writeTo(tempPath);
      final targetFile = File(path);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tempFile.rename(path);
      return path;
    } catch (_) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }

  Future<String?> saveCover(String bookId, Uint8List bytes) async {
    final path = _coverFilePath(bookId);
    final file = File(path);
    await file.writeAsBytes(bytes);
    return path;
  }

  Uint8List? loadCover(String bookId) {
    final path = _coverFilePath(bookId);
    final file = File(path);
    if (!file.existsSync()) return null;
    return file.readAsBytesSync();
  }

  Future<void> addBook(BookMetadata metadata) async {
    await _repository.put(metadata.id, metadata);
  }

  Future<void> removeBook(String id) async {
    await _repository.delete(id);
    final coverFile = File(_coverFilePath(id));
    if (await coverFile.exists()) {
      await coverFile.delete();
    }
    final sourceFile = File(_sourceFilePath(id));
    if (await sourceFile.exists()) {
      await sourceFile.delete();
    }
  }

  Future<void> renameBook(String id, String title) async {
    final meta = _repository.get(id);
    if (meta == null) return;
    await _repository.put(id, meta.copyWith(title: title));
  }

  Future<void> updateDifficultyCache({
    required String id,
    required Set<String> studyWords,
    required BookDifficultyRating rating,
    required String vocabularySignature,
    DateTime? computedAt,
  }) async {
    final meta = _repository.get(id);
    if (meta == null) return;
    final sorted = studyWords.toList()..sort();
    await _repository.put(
      id,
      meta.copyWith(
        difficultyStudyWords: sorted,
        difficultyRatingJson: rating.toJson(),
        difficultyVocabularySignature: vocabularySignature,
        difficultyComputedAt: computedAt ?? _clock(),
      ),
    );
  }

  Future<void> updateProgress(
    String id,
    int currentChapter,
    double chapterProgress, {
    double? chapterScrollOffset,
  }) async {
    final meta = _repository.get(id);
    if (meta == null) return;

    final updated = meta.copyWith(
      currentChapter: currentChapter,
      chapterProgress: chapterProgress,
      chapterScrollOffset: chapterScrollOffset,
      lastReadAt: _clock(),
    );

    final chapters = updated.totalChapters;
    final globalProg = chapters > 0
        ? ((currentChapter + chapterProgress) / chapters).clamp(0.0, 1.0)
        : 0.0;

    await _repository.put(id, updated.copyWith(globalProgress: globalProg));
  }

  void removeCover(String bookId) {
    final file = File(_coverFilePath(bookId));
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  Future<void> close() async {
    await _repository.close();
  }
}

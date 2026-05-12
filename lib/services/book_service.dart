import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/book_metadata.dart';

class BookService {
  late Box<BookMetadata> _box;
  String? _booksDir;

  List<BookMetadata> get books => _box.values.toList();

  Future<void> init() async {
    _box = Hive.box<BookMetadata>('books');
    final dir = await getApplicationDocumentsDirectory();
    _booksDir = '${dir.path}/books';
    final booksDir = Directory(_booksDir!);
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }
  }

  String _coverFilePath(String bookId) => '$_booksDir/${bookId}_cover.png';

  String _sourceFilePath(String bookId) => '$_booksDir/$bookId.epub';

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
    await _box.put(metadata.id, metadata);
  }

  Future<void> removeBook(String id) async {
    await _box.delete(id);
    final coverFile = File(_coverFilePath(id));
    if (await coverFile.exists()) {
      await coverFile.delete();
    }
    final sourceFile = File(_sourceFilePath(id));
    if (await sourceFile.exists()) {
      await sourceFile.delete();
    }
  }

  Future<void> updateProgress(String id, int currentChapter, double chapterProgress) async {
    final meta = _box.get(id);
    if (meta == null) return;

    final updated = meta.copyWith(
      currentChapter: currentChapter,
      chapterProgress: chapterProgress,
      lastReadAt: DateTime.now(),
    );

    final chapters = updated.totalChapters;
    final globalProg = chapters > 0
        ? ((currentChapter + chapterProgress) / chapters).clamp(0.0, 1.0)
        : 0.0;

    await _box.put(id, updated.copyWith(globalProgress: globalProg));
  }

  void removeCover(String bookId) {
    final file = File(_coverFilePath(bookId));
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  Future<void> close() async {
    await _box.close();
  }
}

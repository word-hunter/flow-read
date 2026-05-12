import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AICacheService {
  String? _cacheDir;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _cacheDir = '${dir.path}/ai_cache';
    final cacheDir = Directory(_cacheDir!);
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
  }

  String _summaryPath(String bookId, int chapterIndex, String language) {
    return '$_cacheDir/$bookId/ch${chapterIndex}_summary_$language.json';
  }

  String _practicePath(String bookId, int chapterIndex) {
    return '$_cacheDir/$bookId/ch${chapterIndex}_practice.json';
  }

  Future<String?> loadSummary(
    String bookId,
    int chapterIndex,
    String language,
  ) async {
    final path = _summaryPath(bookId, chapterIndex, language);
    final file = File(path);
    if (!await file.exists()) return null;
    try {
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSummary(
    String bookId,
    int chapterIndex,
    String language,
    String jsonString,
  ) async {
    final path = _summaryPath(bookId, chapterIndex, language);
    await _ensureDir(File(path).parent.path);
    await File(path).writeAsString(jsonString);
  }

  Future<String?> loadPractice(String bookId, int chapterIndex) async {
    final path = _practicePath(bookId, chapterIndex);
    final file = File(path);
    if (!await file.exists()) return null;
    try {
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  Future<void> savePractice(
    String bookId,
    int chapterIndex,
    String jsonString,
  ) async {
    final path = _practicePath(bookId, chapterIndex);
    await _ensureDir(File(path).parent.path);
    await File(path).writeAsString(jsonString);
  }

  Future<void> clearBookCache(String bookId) async {
    final dir = Directory('$_cacheDir/$bookId');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> clearAllCache() async {
    final dir = Directory(_cacheDir!);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
  }

  Future<int> getCacheCount() async {
    if (_cacheDir == null) return 0;
    final dir = Directory(_cacheDir!);
    if (!await dir.exists()) return 0;
    int count = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.json')) {
        count++;
      }
    }
    return count;
  }

  Future<void> _ensureDir(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }
}

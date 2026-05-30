import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AICacheService {
  AICacheService({Future<Directory> Function()? documentsDirectoryProvider})
    : _documentsDirectoryProvider =
          documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _documentsDirectoryProvider;
  String? _cacheDir;

  Future<void> init() async {
    final dir = await _documentsDirectoryProvider();
    _cacheDir = '${dir.path}/ai_cache';
    final cacheDir = Directory(_cacheDir!);
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
  }

  static String contentHashFor(String content) {
    const offset = 0xcbf29ce484222325;
    const prime = 0x100000001b3;
    const mask = 0xffffffffffffffff;
    var hash = offset;
    for (final byte in utf8.encode(content)) {
      hash ^= byte;
      hash = (hash * prime) & mask;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  String _summaryPath(String bookId, int chapterIndex, String language) {
    return '$_cacheDir/$bookId/ch${chapterIndex}_summary_$language.json';
  }

  String _practicePath(String bookId, int chapterIndex) {
    return '$_cacheDir/$bookId/ch${chapterIndex}_practice.json';
  }

  String _keyedPath(AICacheKey key) {
    final book = _safePathSegment(key.bookId);
    final model = key.modelConfigFingerprint == null
        ? ''
        : '_model-${_safePathSegment(key.modelConfigFingerprint!)}';
    final fileName =
        '${key.kind}_v${key.promptVersion}_${key.sourceLanguage}_${key.outputLanguage}_${key.contentHash}$model.json';
    return '$_cacheDir/$book/ch${key.chapterIndex}/$fileName';
  }

  Future<String?> loadSummary(
    String bookId,
    int chapterIndex,
    String language, {
    String? contentHash,
    int? promptVersion,
    String sourceLanguage = 'en',
    String? outputLanguage,
    String? modelConfigFingerprint,
  }) async {
    if (contentHash != null && promptVersion != null) {
      final keyed = AICacheKey(
        kind: 'summary',
        bookId: bookId,
        chapterIndex: chapterIndex,
        contentHash: contentHash,
        promptVersion: promptVersion,
        sourceLanguage: sourceLanguage,
        outputLanguage: outputLanguage ?? language,
        modelConfigFingerprint: modelConfigFingerprint,
      );
      final cached = await _readFile(_keyedPath(keyed));
      if (cached != null) return cached;
    }

    final path = _summaryPath(bookId, chapterIndex, language);
    return _readFile(path);
  }

  Future<void> saveSummary(
    String bookId,
    int chapterIndex,
    String language,
    String jsonString, {
    String? contentHash,
    int? promptVersion,
    String sourceLanguage = 'en',
    String? outputLanguage,
    String? modelConfigFingerprint,
  }) async {
    final path = contentHash != null && promptVersion != null
        ? _keyedPath(
            AICacheKey(
              kind: 'summary',
              bookId: bookId,
              chapterIndex: chapterIndex,
              contentHash: contentHash,
              promptVersion: promptVersion,
              sourceLanguage: sourceLanguage,
              outputLanguage: outputLanguage ?? language,
              modelConfigFingerprint: modelConfigFingerprint,
            ),
          )
        : _summaryPath(bookId, chapterIndex, language);
    await _ensureDir(File(path).parent.path);
    await File(path).writeAsString(jsonString);
    if (contentHash != null && promptVersion != null) {
      await _writeMetadata(
        path,
        AICacheKey(
          kind: 'summary',
          bookId: bookId,
          chapterIndex: chapterIndex,
          contentHash: contentHash,
          promptVersion: promptVersion,
          sourceLanguage: sourceLanguage,
          outputLanguage: outputLanguage ?? language,
          modelConfigFingerprint: modelConfigFingerprint,
        ),
      );
    }
  }

  Future<String?> loadPractice(
    String bookId,
    int chapterIndex, {
    String? contentHash,
    int? promptVersion,
    String sourceLanguage = 'en',
    String outputLanguage = 'zh',
    String? modelConfigFingerprint,
  }) async {
    if (contentHash != null && promptVersion != null) {
      final keyed = AICacheKey(
        kind: 'practice',
        bookId: bookId,
        chapterIndex: chapterIndex,
        contentHash: contentHash,
        promptVersion: promptVersion,
        sourceLanguage: sourceLanguage,
        outputLanguage: outputLanguage,
        modelConfigFingerprint: modelConfigFingerprint,
      );
      final cached = await _readFile(_keyedPath(keyed));
      if (cached != null) return cached;
    }

    final path = _practicePath(bookId, chapterIndex);
    return _readFile(path);
  }

  Future<void> savePractice(
    String bookId,
    int chapterIndex,
    String jsonString, {
    String? contentHash,
    int? promptVersion,
    String sourceLanguage = 'en',
    String outputLanguage = 'zh',
    String? modelConfigFingerprint,
  }) async {
    final key = contentHash != null && promptVersion != null
        ? AICacheKey(
            kind: 'practice',
            bookId: bookId,
            chapterIndex: chapterIndex,
            contentHash: contentHash,
            promptVersion: promptVersion,
            sourceLanguage: sourceLanguage,
            outputLanguage: outputLanguage,
            modelConfigFingerprint: modelConfigFingerprint,
          )
        : null;
    final path = key == null
        ? _practicePath(bookId, chapterIndex)
        : _keyedPath(key);
    await _ensureDir(File(path).parent.path);
    await File(path).writeAsString(jsonString);
    if (key != null) {
      await _writeMetadata(path, key);
    }
  }

  Future<String?> loadChapterPreview(
    String bookId,
    int chapterIndex, {
    required String contentHash,
    required int promptVersion,
    required String sourceLanguage,
    String outputLanguage = 'zh',
    String? modelConfigFingerprint,
  }) async {
    return _readFile(
      _keyedPath(
        AICacheKey(
          kind: 'chapter_preview',
          bookId: bookId,
          chapterIndex: chapterIndex,
          contentHash: contentHash,
          promptVersion: promptVersion,
          sourceLanguage: sourceLanguage,
          outputLanguage: outputLanguage,
          modelConfigFingerprint: modelConfigFingerprint,
        ),
      ),
    );
  }

  Future<void> saveChapterPreview(
    String bookId,
    int chapterIndex,
    String jsonString, {
    required String contentHash,
    required int promptVersion,
    required String sourceLanguage,
    String outputLanguage = 'zh',
    String? modelConfigFingerprint,
  }) async {
    final key = AICacheKey(
      kind: 'chapter_preview',
      bookId: bookId,
      chapterIndex: chapterIndex,
      contentHash: contentHash,
      promptVersion: promptVersion,
      sourceLanguage: sourceLanguage,
      outputLanguage: outputLanguage,
      modelConfigFingerprint: modelConfigFingerprint,
    );
    final path = _keyedPath(key);
    await _ensureDir(File(path).parent.path);
    await File(path).writeAsString(jsonString);
    await _writeMetadata(path, key);
  }

  Future<String?> loadWordAnalysis(
    String bookId,
    int chapterIndex, {
    required String contentHash,
    required int promptVersion,
    required String sourceLanguage,
    String outputLanguage = 'zh-Hans',
    String? modelConfigFingerprint,
  }) async {
    return _readFile(
      _keyedPath(
        AICacheKey(
          kind: 'word_analysis',
          bookId: bookId,
          chapterIndex: chapterIndex,
          contentHash: contentHash,
          promptVersion: promptVersion,
          sourceLanguage: sourceLanguage,
          outputLanguage: outputLanguage,
          modelConfigFingerprint: modelConfigFingerprint,
        ),
      ),
    );
  }

  Future<void> saveWordAnalysis(
    String bookId,
    int chapterIndex,
    String jsonString, {
    required String contentHash,
    required int promptVersion,
    required String sourceLanguage,
    String outputLanguage = 'zh-Hans',
    String? modelConfigFingerprint,
  }) async {
    final key = AICacheKey(
      kind: 'word_analysis',
      bookId: bookId,
      chapterIndex: chapterIndex,
      contentHash: contentHash,
      promptVersion: promptVersion,
      sourceLanguage: sourceLanguage,
      outputLanguage: outputLanguage,
      modelConfigFingerprint: modelConfigFingerprint,
    );
    final path = _keyedPath(key);
    await _ensureDir(File(path).parent.path);
    await File(path).writeAsString(jsonString);
    await _writeMetadata(path, key);
  }

  Future<void> clearBookCache(String bookId) async {
    final paths = {
      '$_cacheDir/$bookId',
      '$_cacheDir/${_safePathSegment(bookId)}',
    };
    for (final path in paths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
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

  Future<String?> _readFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    try {
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeMetadata(String jsonPath, AICacheKey key) async {
    final metadataPath = '$jsonPath.meta';
    await File(metadataPath).writeAsString(
      jsonEncode({
        'kind': key.kind,
        'bookId': key.bookId,
        'chapterIndex': key.chapterIndex,
        'contentHash': key.contentHash,
        'promptVersion': key.promptVersion,
        'sourceLanguage': key.sourceLanguage,
        'outputLanguage': key.outputLanguage,
        'modelConfigFingerprint': key.modelConfigFingerprint,
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  String _safePathSegment(String input) {
    return input.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
  }
}

class AICacheKey {
  final String kind;
  final String bookId;
  final int chapterIndex;
  final String contentHash;
  final int promptVersion;
  final String sourceLanguage;
  final String outputLanguage;
  final String? modelConfigFingerprint;

  const AICacheKey({
    required this.kind,
    required this.bookId,
    required this.chapterIndex,
    required this.contentHash,
    required this.promptVersion,
    required this.sourceLanguage,
    required this.outputLanguage,
    this.modelConfigFingerprint,
  });
}

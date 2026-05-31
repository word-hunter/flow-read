import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/book_metadata.dart';
import '../models/learning_item.dart';
import '../models/rss_models.dart';
import '../models/word_context_example.dart';
import '../storage/hive_box_names.dart';
import 'backup_archive.dart' as archive;
import 'backup_folder_access.dart';
import 'settings_service.dart';

class BackupException implements Exception {
  final String message;

  const BackupException(this.message);

  @override
  String toString() => message;
}

class WordHunterImportResult {
  final int knownCount;
  final int learningCount;
  final int exampleCount;

  const WordHunterImportResult({
    required this.knownCount,
    required this.learningCount,
    required this.exampleCount,
  });
}

enum _ImportStage { validating, stagingFiles, restoringBoxes, committingFiles }

class BackupService extends ChangeNotifier {
  static const schemaVersion = 1;
  static const appId = 'flow_read';

  static const _localSettingKeys = <String>{
    'backupEnabled',
    'backupFolderPath',
    'backupFolderBookmark',
    'backupIntervalMinutes',
    'includeSecretsInBackup',
    'lastBackupAt',
    'lastBackupPath',
  };
  static const _secretSettingKeys = <String>{'apiKey', 'aiApiKeys'};

  // Regenerable caches stay out of this table: wordLevels and dictionaryCache.
  static final List<_BackupDataSegment> _backupDataSegments =
      List.unmodifiable([
        _BackupDataSegment.box<BookMetadata>(
          boxName: HiveBoxNames.books,
          box: () => Hive.box<BookMetadata>(HiveBoxNames.books),
          encode: (value) => value.toJson(),
          decode: (value) => BookMetadata.fromJson(_asStringKeyMap(value)),
        ),
        _BackupDataSegment.box<String>(
          boxName: HiveBoxNames.userVocabulary,
          box: () => Hive.box<String>(HiveBoxNames.userVocabulary),
        ),
        _BackupDataSegment.box<dynamic>(
          boxName: HiveBoxNames.settings,
          box: () => Hive.box<dynamic>(HiveBoxNames.settings),
          clearBeforeRestore: false,
          skipSnapshotKey: (key, includeSecretsInBackup) {
            if (_localSettingKeys.contains(key)) return true;
            return !includeSecretsInBackup && _secretSettingKeys.contains(key);
          },
          skipRestoreKey: (key) => _localSettingKeys.contains(key),
        ),
        _BackupDataSegment.box<String>(
          boxName: HiveBoxNames.wordBookmarks,
          box: () => Hive.box<String>(HiveBoxNames.wordBookmarks),
        ),
        _BackupDataSegment.box<String>(
          boxName: HiveBoxNames.readingBookmarks,
          box: () => Hive.box<String>(HiveBoxNames.readingBookmarks),
        ),
        _BackupDataSegment.box<String>(
          boxName: HiveBoxNames.readingConfig,
          box: () => Hive.box<String>(HiveBoxNames.readingConfig),
        ),
        _BackupDataSegment.box<int>(
          boxName: HiveBoxNames.readingTime,
          box: () => Hive.box<int>(HiveBoxNames.readingTime),
          decode: _decodeInt,
        ),
        _BackupDataSegment.box<RssFeedSubscription>(
          boxName: HiveBoxNames.rssSubscriptions,
          box: () =>
              Hive.box<RssFeedSubscription>(HiveBoxNames.rssSubscriptions),
          encode: _rssSubscriptionToJson,
          decode: (value) => _rssSubscriptionFromJson(_asStringKeyMap(value)),
        ),
        _BackupDataSegment.box<String>(
          boxName: HiveBoxNames.wordContexts,
          box: () => Hive.box<String>(HiveBoxNames.wordContexts),
        ),
        _BackupDataSegment.box<LearningItem>(
          boxName: HiveBoxNames.learningItems,
          box: () => Hive.box<LearningItem>(HiveBoxNames.learningItems),
          encode: (value) => value.toJson(),
          decode: (value) => LearningItem.fromJson(_asStringKeyMap(value)),
        ),
        _BackupDataSegment.box<int>(
          boxName: HiveBoxNames.learningAnalytics,
          box: () => Hive.box<int>(HiveBoxNames.learningAnalytics),
          decode: _decodeInt,
        ),
      ]);

  @visibleForTesting
  static List<String> get backupDataBoxNames {
    return List.unmodifiable(
      _backupDataSegments.map((segment) => segment.boxName),
    );
  }

  final SettingsService settings;
  final BackupFolderAccess _folderAccess;
  final Future<Directory> Function() _documentsDirectoryProvider;

  Timer? _timer;
  bool _isSyncing = false;
  String? _lastError;

  BackupService(
    this.settings, {
    BackupFolderAccess? folderAccess,
    Future<Directory> Function()? documentsDirectoryProvider,
  }) : _folderAccess = folderAccess ?? const BackupFolderAccess(),
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;

  Future<void> init() async {
    settings.addListener(_configureTimer);
    _configureTimer();
  }

  Future<String> exportNow({String? folderPath}) async {
    final targetFolder = (folderPath ?? settings.backupFolderPath).trim();
    if (targetFolder.isEmpty) {
      throw const BackupException('未选择备份文件夹');
    }
    if (_isSyncing) {
      throw const BackupException('备份正在进行');
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      final folderAccess = await _folderAccess.startAccessing(
        path: targetFolder,
        bookmark: settings.backupFolderBookmark,
      );
      try {
        final createdAt = DateTime.now();
        final bookFiles = await _collectBookFiles();
        final dataPayload = _buildDataPayload();
        final dataJson = const JsonEncoder().convert(dataPayload);
        final bookIds = bookFiles.books.keys.toList();
        final manifest = archive.buildManifest(
          appId: appId,
          formatVersion: archive.supportedManifestFormatVersion,
          createdAt: createdAt,
          bookIds: bookIds,
          bookHasCover: bookFiles.hasCover,
        );
        final manifestJson = const JsonEncoder().convert(manifest);

        final entries = <String, Map<String, dynamic>>{};
        for (final id in bookIds) {
          final file = bookFiles.books[id]!;
          entries[archive.bookSourceEntryPath(id)] = {
            'bytes': file.sourceBytes,
            'compress': false,
          };
          if (file.coverBytes != null) {
            entries[archive.bookCoverEntryPath(id)] = {
              'bytes': file.coverBytes!,
              'compress': false,
            };
          }
        }

        final zipBytes = await compute(archive.encodeZipArchive, {
          'manifestJson': manifestJson,
          'dataJson': dataJson,
          'entries': entries,
        });

        final filePath = await _writeBackupToFolder(
          folderPath: folderAccess.path,
          createdAt: createdAt,
          zipBytes: zipBytes,
          prefix: 'flow_read_backup',
        );
        await settings.setLastBackup(createdAt, filePath);
        return filePath;
      } finally {
        await folderAccess.stopAccessing();
      }
    } catch (e) {
      final message = _describeExportError(e);
      _lastError = message;
      throw BackupException(message);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> exportPreImportBackup() async {
    final configuredPath = settings.backupFolderPath.trim();
    if (configuredPath.isNotEmpty) {
      try {
        return await exportNow(folderPath: configuredPath);
      } catch (_) {
        // Fallback to documents directory.
      }
    }

    try {
      final documentsDir = await _documentsDirectoryProvider();
      final preImportDir = Directory(
        '${documentsDir.path}${Platform.pathSeparator}backups'
        '${Platform.pathSeparator}pre_import',
      );
      return await exportNow(folderPath: preImportDir.path);
    } catch (e) {
      return null;
    }
  }

  Future<void> importBackupFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const BackupException('备份文件不存在');
    }

    final headerBytes = await file.openRead(0, 4).first;
    if (headerBytes.length < 4 ||
        !archive.isZipFileHeader(Uint8List.fromList(headerBytes))) {
      throw const BackupException('不是 Flow Read 备份文件');
    }

    final zipBytes = await file.readAsBytes();
    if (zipBytes.isEmpty) {
      throw const BackupException('备份文件为空');
    }

    final decoded = await compute(archive.decodeZipArchive, zipBytes);
    final manifestJson = decoded['manifestJson'] as String;
    final dataJson = decoded['dataJson'] as String;
    final entryBytes = decoded['entryBytes'] as Map<String, dynamic>;

    final manifest = jsonDecode(manifestJson) as Map<String, dynamic>;
    final data = jsonDecode(dataJson) as Map<String, dynamic>;

    archive.validateManifest(manifest, appId);
    archive.validateDataSchema(data, schemaVersion);

    final manifestIds = archive.manifestBookIds(manifest);
    final boxes = data['boxes'] as Map<String, dynamic>;
    final booksBox = boxes[HiveBoxNames.books] as Map<String, dynamic>?;
    final bookEntries = booksBox?['entries'] as List<dynamic>? ?? [];
    final dataBookIds = bookEntries
        .whereType<Map>()
        .map((e) => _decodeKey(e['key']).toString())
        .toSet();

    if (!setEquals(manifestIds, dataBookIds)) {
      throw const BackupException('备份文件不完整：书籍索引与数据不一致');
    }

    final manifestBooks = manifest['books'] as Map<String, dynamic>;
    for (final id in manifestIds) {
      final bookEntry = manifestBooks[id] as Map<String, dynamic>;
      final sourcePath = bookEntry['source'] as String;
      final sourceBytes = entryBytes[sourcePath];
      if (sourceBytes is! Uint8List || sourceBytes.isEmpty) {
        throw BackupException('备份文件不完整，缺少书籍源文件：$id');
      }
      final coverPath = bookEntry['cover'];
      if (coverPath is String) {
        final coverBytes = entryBytes[coverPath];
        if (coverBytes is! Uint8List || coverBytes.isEmpty) {
          throw BackupException('备份文件不完整，缺少封面文件：$id');
        }
      }
    }

    final documentsDir = await _documentsDirectoryProvider();
    final booksDir = Directory(
      '${documentsDir.path}${Platform.pathSeparator}books',
    );

    var stage = _ImportStage.validating;

    try {
      stage = _ImportStage.stagingFiles;
      await booksDir.create(recursive: true);

      final stagingPaths = <String, ({String source, String? cover})>{};
      for (final id in manifestIds) {
        final bookEntry = manifestBooks[id] as Map<String, dynamic>;
        final sourcePath = bookEntry['source'] as String;
        final sourceBytes = entryBytes[sourcePath] as Uint8List;

        final canonicalSource = _bookSourcePath(booksDir, id);
        final stagingSource = '$canonicalSource.importing';
        await File(stagingSource).parent.create(recursive: true);
        await File(stagingSource).writeAsBytes(sourceBytes, flush: true);

        String? stagingCover;
        final coverPath = bookEntry['cover'];
        if (coverPath is String) {
          final coverBytes = entryBytes[coverPath] as Uint8List;
          final canonicalCover = _bookCoverPath(booksDir, id);
          stagingCover = '$canonicalCover.importing';
          await File(stagingCover).parent.create(recursive: true);
          await File(stagingCover).writeAsBytes(coverBytes, flush: true);
        }

        stagingPaths[id] = (source: stagingSource, cover: stagingCover);
      }

      stage = _ImportStage.restoringBoxes;
      for (final segment in _backupDataSegments) {
        final boxData = boxes[segment.boxName];
        if (boxData is Map) {
          await _restoreSegment(segment, _asStringKeyMap(boxData));
        }
      }

      stage = _ImportStage.committingFiles;
      final booksBoxRef = Hive.box<BookMetadata>(HiveBoxNames.books);
      for (final id in manifestIds) {
        final canonicalSource = _bookSourcePath(booksDir, id);
        final staging = stagingPaths[id]!;

        final sourceFile = File(staging.source);
        if (await sourceFile.exists()) {
          final target = File(canonicalSource);
          await _atomicRename(sourceFile, target);
        }

        if (staging.cover != null) {
          final coverFile = File(staging.cover!);
          if (await coverFile.exists()) {
            final canonicalCover = _bookCoverPath(booksDir, id);
            final target = File(canonicalCover);
            await _atomicRename(coverFile, target);
          }
        }

        final meta = booksBoxRef.get(id);
        if (meta != null) {
          await booksBoxRef.put(
            id,
            meta.copyWith(
              sourcePath: canonicalSource,
              coverPath: staging.cover != null
                  ? _bookCoverPath(booksDir, id)
                  : null,
            ),
          );
        }
      }

      await _cleanupStaleImportingFiles(booksDir);
      await settings.reloadFromStorage();
    } catch (_) {
      await _cleanupStaleImportingFiles(booksDir);
      if (stage == _ImportStage.validating) {
        throw const BackupException('导入失败，当前数据未更改。');
      }
      throw const BackupException(
        '导入失败，当前数据可能已部分更改。\n'
        '如需恢复，请使用上次导入前自动保存的备份。',
      );
    }
  }

  Future<WordHunterImportResult> importWordHunterBackupFile(
    String filePath,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const BackupException('Word Hunter 备份文件不存在');
    }
    late Map<String, dynamic> parsed;
    try {
      parsed = await compute(
        _parseWordHunterBackupSource,
        await file.readAsString(),
      );
    } catch (e) {
      throw BackupException('Word Hunter 备份格式无效：$e');
    }
    return importWordHunterPayload(parsed);
  }

  Future<WordHunterImportResult> importWordHunterPayload(
    Map<String, dynamic> payload,
  ) async {
    final parsed = _normalizeWordHunterPayload(payload);
    final knownWords = (parsed['knownWords'] as List<dynamic>).cast<String>();
    final learningWords = (parsed['learningWords'] as List<dynamic>)
        .cast<String>();
    final contexts = (parsed['contexts'] as Map<String, dynamic>).map(
      (word, value) => MapEntry(
        word,
        (value as List<dynamic>)
            .whereType<Map>()
            .map((item) => WordContextExample.fromJson(_asStringKeyMap(item)))
            .where((example) => example.text.isNotEmpty)
            .toList(),
      ),
    );

    if (knownWords.isEmpty && learningWords.isEmpty && contexts.isEmpty) {
      throw const BackupException('Word Hunter 备份中没有可导入的单词');
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      final vocabBox = Hive.box<String>(HiveBoxNames.userVocabulary);
      final currentKnown = <String>{
        for (final key in vocabBox.keys)
          if (vocabBox.get(key) == 'known') key.toString(),
      };

      await vocabBox.putAll({for (final word in knownWords) word: 'known'});
      currentKnown.addAll(knownWords);

      final learningUpdates = <String, String>{};
      for (final word in learningWords) {
        if (!currentKnown.contains(word)) {
          learningUpdates[word] = 'learning';
        }
      }
      if (learningUpdates.isNotEmpty) {
        await vocabBox.putAll(learningUpdates);
      }

      final contextBox = Hive.box<String>(HiveBoxNames.wordContexts);
      var exampleCount = 0;
      for (final entry in contexts.entries) {
        final merged = _mergeContextExamples(
          _decodeContextExamples(contextBox.get(entry.key)),
          entry.value,
        );
        if (merged.isEmpty) continue;
        exampleCount += entry.value.length;
        await contextBox.put(
          entry.key,
          jsonEncode(merged.map((example) => example.toJson()).toList()),
        );
      }

      return WordHunterImportResult(
        knownCount: knownWords.length,
        learningCount: learningUpdates.length,
        exampleCount: exampleCount,
      );
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _buildDataPayload() {
    return archive.buildDataPayload(
      schemaVersion: schemaVersion,
      boxes: {
        for (final segment in _backupDataSegments)
          segment.boxName: _snapshotSegment(segment),
      },
    );
  }

  Map<String, dynamic> _snapshotSegment(_BackupDataSegment segment) {
    final entries = <Map<String, dynamic>>[];
    for (final key in segment.keys()) {
      if (segment.shouldSkipSnapshotKey(
        key,
        includeSecretsInBackup: settings.includeSecretsInBackup,
      )) {
        continue;
      }
      final value = segment.getValue(key);
      entries.add({
        'key': _encodeKey(key),
        'value': segment.encodeValue(value),
      });
    }
    return {'entries': entries};
  }

  Future<_BookFilesCollection> _collectBookFiles() async {
    final books = <String, _BookFile>{};
    final hasCover = <String, bool>{};
    var totalBytes = 0;

    final booksBox = Hive.box<BookMetadata>(HiveBoxNames.books);
    for (final meta in booksBox.values) {
      final sourceFile = File(meta.sourcePath);
      if (!await sourceFile.exists()) {
        throw BackupException('备份失败：《${meta.title}》的 EPUB 文件缺失，请重新导入该书后再备份。');
      }
      final sourceLen = await sourceFile.length();
      if (sourceLen <= 0) {
        throw BackupException('备份失败：《${meta.title}》的 EPUB 文件为空。');
      }
      totalBytes += sourceLen;

      var coverBytes = Uint8List(0);
      var hasValidCover = false;
      final coverPath = meta.coverPath;
      if (coverPath != null) {
        final coverFile = File(coverPath);
        if (await coverFile.exists()) {
          final coverLen = await coverFile.length();
          if (coverLen > 0) {
            totalBytes += coverLen;
            coverBytes = await coverFile.readAsBytes();
            hasValidCover = true;
          }
        }
      }

      if (totalBytes > archive.maxBackupBookBytes) {
        throw const BackupException('备份内容较大，暂不支持一次性导出超过 500 MB 的书籍文件。');
      }

      books[meta.id] = _BookFile(
        sourceBytes: await sourceFile.readAsBytes(),
        coverBytes: hasValidCover ? coverBytes : null,
      );
      hasCover[meta.id] = hasValidCover;
    }

    return _BookFilesCollection(books: books, hasCover: hasCover);
  }

  Future<String> _writeBackupToFolder({
    required String folderPath,
    required DateTime createdAt,
    required Uint8List zipBytes,
    required String prefix,
  }) async {
    final dir = Directory(folderPath);
    await dir.create(recursive: true);

    final timestamp = _backupFilenameTimestamp(createdAt);

    await _cleanupPartFiles(dir, prefix);

    final finalPath =
        '${dir.path}${Platform.pathSeparator}${prefix}_$timestamp.flow.bak';
    final partPath = '$finalPath.part';

    await File(partPath).writeAsBytes(zipBytes, flush: true);

    try {
      await File(partPath).rename(finalPath);
    } catch (_) {
      try {
        if (await File(finalPath).exists()) {
          await File(finalPath).delete();
        }
        await File(partPath).rename(finalPath);
      } catch (_) {
        await File(partPath).copy(finalPath);
        await File(partPath).delete();
      }
    }

    return finalPath;
  }

  Future<void> _cleanupPartFiles(Directory dir, String prefix) async {
    try {
      final entries = dir.listSync();
      for (final entry in entries) {
        if (entry is File &&
            entry.path.endsWith('.flow.bak.part') &&
            _pathBasename(entry.path).startsWith(prefix)) {
          await entry.delete();
        }
      }
    } catch (_) {
      // Non-critical cleanup.
    }
  }

  Future<void> _cleanupStaleImportingFiles(Directory booksDir) async {
    try {
      final entries = booksDir.listSync();
      for (final entry in entries) {
        if (entry is File && entry.path.endsWith('.importing')) {
          await entry.delete();
        }
      }
    } catch (_) {
      // Best-effort cleanup.
    }
  }

  Future<void> _atomicRename(File source, File target) async {
    try {
      await source.rename(target.path);
    } catch (_) {
      try {
        if (await target.exists()) {
          await target.delete();
        }
        await source.rename(target.path);
      } catch (_) {
        await source.copy(target.path);
        await source.delete();
      }
    }
  }

  String _pathBasename(String path) {
    final separator = Platform.pathSeparator;
    final index = path.lastIndexOf(separator);
    return index >= 0 ? path.substring(index + 1) : path;
  }

  String _backupFilenameTimestamp(DateTime value) {
    final iso = value.toUtc().toIso8601String().split('.').first;
    final d = iso.substring(0, 10).replaceAll('-', '');
    final t = iso.substring(11, 19).replaceAll(':', '');
    return '${d}_$t';
  }

  String _bookSourcePath(Directory booksDir, String bookId) {
    return '${booksDir.path}${Platform.pathSeparator}$bookId.epub';
  }

  String _bookCoverPath(Directory booksDir, String bookId) {
    return '${booksDir.path}${Platform.pathSeparator}${bookId}_cover.png';
  }

  Future<void> _restoreSegment(
    _BackupDataSegment segment,
    Map<String, dynamic> data,
  ) async {
    final entries = data['entries'];
    if (entries is! List) {
      throw BackupException('${segment.boxName} 备份数据无效');
    }

    if (segment.clearBeforeRestore) {
      await segment.clear();
    }

    for (final entry in entries) {
      if (entry is! Map) continue;
      final key = _decodeKey(entry['key']);
      if (segment.shouldSkipRestoreKey(key)) {
        continue;
      }
      final value = segment.decodeValue(entry['value']);
      await segment.putValue(key, value);
    }
  }

  Map<String, dynamic> _encodeKey(dynamic key) {
    if (key is int) return {'type': 'int', 'value': key};
    return {'type': 'string', 'value': key.toString()};
  }

  dynamic _decodeKey(dynamic encoded) {
    if (encoded is Map && encoded['type'] == 'int') {
      final value = encoded['value'];
      return value is int ? value : int.parse(value.toString());
    }
    if (encoded is Map) return encoded['value'].toString();
    return encoded.toString();
  }

  static int _decodeInt(dynamic value) {
    return (value as num).toInt();
  }

  static Map<String, dynamic> _rssSubscriptionToJson(
    RssFeedSubscription value,
  ) {
    return {
      'url': value.url,
      'title': value.title,
      'description': value.description,
      'imageUrl': value.imageUrl,
      'lastFetchedAt': value.lastFetchedAt?.toIso8601String(),
    };
  }

  static RssFeedSubscription _rssSubscriptionFromJson(
    Map<String, dynamic> json,
  ) {
    return RssFeedSubscription(
      url: json['url'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      lastFetchedAt: json['lastFetchedAt'] == null
          ? null
          : DateTime.tryParse(json['lastFetchedAt'] as String),
    );
  }

  static Map<String, dynamic> _asStringKeyMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    throw const BackupException('备份数据格式无效');
  }

  static dynamic _encodeJsonValue(dynamic value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is DateTime) return value.toIso8601String();
    if (value is List) return value.map(_encodeJsonValue).toList();
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _encodeJsonValue(v)));
    }
    return value.toString();
  }

  List<WordContextExample> _decodeContextExamples(String? source) {
    if (source == null || source.isEmpty) return const [];
    try {
      final decoded = jsonDecode(source) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((item) => WordContextExample.fromJson(_asStringKeyMap(item)))
          .where((example) => example.text.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<WordContextExample> _mergeContextExamples(
    List<WordContextExample> existing,
    List<WordContextExample> incoming,
  ) {
    final result = <WordContextExample>[];
    final seen = <String>{};
    for (final example in [...existing, ...incoming]) {
      final key = '${example.text.trim()}|${example.url.trim()}';
      if (seen.add(key)) {
        result.add(example);
      }
    }
    return result;
  }

  void _configureTimer() {
    _timer?.cancel();
    _timer = null;

    if (!settings.backupEnabled || settings.backupFolderPath.trim().isEmpty) {
      return;
    }

    final interval = Duration(minutes: settings.backupIntervalMinutes);
    _timer = Timer.periodic(interval, (_) {
      if (!_isSyncing) {
        unawaited(exportNow());
      }
    });
  }

  String _describeExportError(Object error) {
    if (error is BackupException) return error.message;
    if (error is FileSystemException && _isPermissionError(error)) {
      return '无法写入备份文件夹。请重新选择备份文件夹，授予 macOS 访问权限后再备份。';
    }
    if (error is PlatformException && error.code.contains('BOOKMARK')) {
      return '无法保存备份文件夹访问权限。请重新选择备份文件夹后再备份。';
    }
    return error.toString();
  }

  bool _isPermissionError(FileSystemException error) {
    final osCode = error.osError?.errorCode;
    final message = error.message.toLowerCase();
    return osCode == 1 ||
        osCode == 13 ||
        message.contains('operation not permitted') ||
        message.contains('permission denied');
  }

  @override
  void dispose() {
    settings.removeListener(_configureTimer);
    _timer?.cancel();
    super.dispose();
  }
}

typedef _BackupSnapshotSkip =
    bool Function(dynamic key, bool includeSecretsInBackup);
typedef _BackupRestoreSkip = bool Function(dynamic key);

class _BackupDataSegment {
  _BackupDataSegment._({
    required this.boxName,
    required this.keys,
    required this.getValue,
    required this.clear,
    required this.putValue,
    required this.encodeValue,
    required this.decodeValue,
    required this.clearBeforeRestore,
    this.skipSnapshotKey,
    this.skipRestoreKey,
  });

  static _BackupDataSegment box<T>({
    required String boxName,
    required Box<T> Function() box,
    dynamic Function(T value)? encode,
    T Function(dynamic value)? decode,
    bool clearBeforeRestore = true,
    _BackupSnapshotSkip? skipSnapshotKey,
    _BackupRestoreSkip? skipRestoreKey,
  }) {
    return _BackupDataSegment._(
      boxName: boxName,
      keys: () => box().keys,
      getValue: (key) => box().get(key),
      clear: () => box().clear(),
      putValue: (key, value) => box().put(key, value as T),
      encodeValue: (value) {
        if (encode != null) return encode(value as T);
        return BackupService._encodeJsonValue(value);
      },
      decodeValue: (value) {
        if (decode != null) return decode(value);
        return value;
      },
      clearBeforeRestore: clearBeforeRestore,
      skipSnapshotKey: skipSnapshotKey,
      skipRestoreKey: skipRestoreKey,
    );
  }

  final String boxName;
  final Iterable<dynamic> Function() keys;
  final dynamic Function(dynamic key) getValue;
  final Future<int> Function() clear;
  final Future<void> Function(dynamic key, dynamic value) putValue;
  final dynamic Function(dynamic value) encodeValue;
  final dynamic Function(dynamic value) decodeValue;
  final bool clearBeforeRestore;
  final _BackupSnapshotSkip? skipSnapshotKey;
  final _BackupRestoreSkip? skipRestoreKey;

  bool shouldSkipSnapshotKey(
    dynamic key, {
    required bool includeSecretsInBackup,
  }) {
    final predicate = skipSnapshotKey;
    return predicate != null && predicate(key, includeSecretsInBackup);
  }

  bool shouldSkipRestoreKey(dynamic key) {
    final predicate = skipRestoreKey;
    return predicate != null && predicate(key);
  }
}

class _BookFile {
  final Uint8List sourceBytes;
  final Uint8List? coverBytes;

  const _BookFile({required this.sourceBytes, this.coverBytes});
}

class _BookFilesCollection {
  final Map<String, _BookFile> books;
  final Map<String, bool> hasCover;

  const _BookFilesCollection({required this.books, required this.hasCover});
}

Map<String, dynamic> _parseWordHunterBackupSource(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map) {
    throw const FormatException('根节点不是对象');
  }
  return _asStringKeyMapStatic(decoded);
}

Map<String, dynamic> _normalizeWordHunterPayload(Map<String, dynamic> payload) {
  final knownWords = _extractWordSet(payload['known']);
  final contexts = _parseWordHunterContexts(payload['context']);
  final learningWordSet = {
    ..._extractWordSet(payload['learning']),
    ..._extractWordSet(payload['learningWords']),
    ...contexts.keys,
  };
  final learningWords = learningWordSet
      .where((word) => !knownWords.contains(word))
      .toList();

  return {
    'knownWords': knownWords.toList()..sort(),
    'learningWords': learningWords..sort(),
    'contexts': contexts.map(
      (word, examples) =>
          MapEntry(word, examples.map((example) => example.toJson()).toList()),
    ),
  };
}

Set<String> _extractWordSet(dynamic value) {
  final words = <String>{};
  if (value is Map) {
    for (final key in value.keys) {
      final word = _normalizeWord(key.toString());
      if (word.isNotEmpty) words.add(word);
    }
  } else if (value is List) {
    for (final item in value) {
      if (item is String) {
        final word = _normalizeWord(item);
        if (word.isNotEmpty) words.add(word);
      } else if (item is Map) {
        final word = _normalizeWord(
          (item['word'] ?? item['text'] ?? '').toString(),
        );
        if (word.isNotEmpty) words.add(word);
      }
    }
  }
  return words;
}

Map<String, List<WordContextExample>> _parseWordHunterContexts(dynamic value) {
  final result = <String, List<WordContextExample>>{};
  if (value is! Map) return result;

  for (final entry in value.entries) {
    final fallbackWord = _normalizeWord(entry.key.toString());
    if (fallbackWord.isEmpty) continue;

    final rawExamples = entry.value is List
        ? entry.value as List<dynamic>
        : <dynamic>[entry.value];
    for (final rawExample in rawExamples) {
      final example = _parseWordHunterExample(rawExample, fallbackWord);
      if (example == null) continue;
      result.putIfAbsent(example.word, () => []).add(example);
    }
  }
  return result;
}

WordContextExample? _parseWordHunterExample(
  dynamic value,
  String fallbackWord,
) {
  if (value is String) {
    final text = _normalizeText(value);
    if (text.isEmpty) return null;
    return WordContextExample(word: fallbackWord, text: text);
  }
  if (value is! Map) return null;

  final map = _asStringKeyMapStatic(value);
  final word = _normalizeWord((map['word'] ?? fallbackWord).toString());
  final text = _normalizeText(
    (map['text'] ?? map['sentence'] ?? map['context'] ?? '').toString(),
  );
  if (word.isEmpty || text.isEmpty) return null;

  return WordContextExample(
    word: word,
    text: text,
    title: _normalizeText((map['title'] ?? '').toString()),
    url: (map['url'] ?? '').toString().trim(),
    favicon: (map['favicon'] ?? '').toString().trim(),
    createdAt: _parseWordHunterTimestamp(map['timestamp']),
  );
}

DateTime? _parseWordHunterTimestamp(dynamic value) {
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) {
      return DateTime.fromMillisecondsSinceEpoch(parsed);
    }
    return DateTime.tryParse(value);
  }
  return null;
}

Map<String, dynamic> _asStringKeyMapStatic(Map value) {
  return value.map((k, v) => MapEntry(k.toString(), v));
}

String _normalizeWord(String word) => word.toLowerCase().trim();

String _normalizeText(String text) {
  return text.replaceAll(String.fromCharCode(0x00a0), ' ').trim();
}

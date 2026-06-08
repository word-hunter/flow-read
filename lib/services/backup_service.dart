import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/book_glossary_entry.dart';
import '../models/book_metadata.dart';
import '../models/learning_item.dart';
import '../models/rss_models.dart';
import '../storage/hive_box_names.dart';
import '../storage/storage_migrations.dart';
import 'backup_archive.dart' as archive;
import 'backup_folder_access.dart';
import 'package:flow_language/flow_language.dart';
import 'settings_service.dart';
import 'wordhunter_import_service.dart';

class BackupException implements Exception {
  final String message;

  const BackupException(this.message);

  @override
  String toString() => message;
}

class BackupService extends ChangeNotifier {
  static const schemaVersion = 2;
  static const appId = 'flow_read';
  static const _defaultLang = HiveBoxNames.defaultLanguageCode;

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

  // Regenerable/reference data stays out of backups: wordLevels and dictionaryCache.
  static List<_BackupDataSegment> _globalBackupSegments() {
    return [
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
      _BackupDataSegment.box<RssFeedSubscription>(
        boxName: HiveBoxNames.rssSubscriptions,
        box: () => Hive.box<RssFeedSubscription>(HiveBoxNames.rssSubscriptions),
        encode: _rssSubscriptionToJson,
        decode: (value) => _rssSubscriptionFromJson(_asStringKeyMap(value)),
      ),
      _BackupDataSegment.box<BookGlossaryEntry>(
        boxName: HiveBoxNames.bookGlossary,
        box: () => Hive.box<BookGlossaryEntry>(HiveBoxNames.bookGlossary),
        encode: (value) => value.toJson(),
        decode: (value) => BookGlossaryEntry.fromJson(_asStringKeyMap(value)),
      ),
      _BackupDataSegment.box<String>(
        boxName: HiveBoxNames.characterRegistry,
        box: () => Hive.box<String>(HiveBoxNames.characterRegistry),
      ),
    ];
  }

  static List<_BackupDataSegment> _languageBackupSegments(String lang) {
    return [
      _BackupDataSegment.box<BookMetadata>(
        boxName: HiveBoxNames.booksFor(lang),
        box: () => Hive.box<BookMetadata>(HiveBoxNames.booksFor(lang)),
        encode: (value) => value.toJson(),
        decode: (value) => BookMetadata.fromJson(_asStringKeyMap(value)),
      ),
      _BackupDataSegment.box<String>(
        boxName: HiveBoxNames.userVocabularyFor(lang),
        box: () => Hive.box<String>(HiveBoxNames.userVocabularyFor(lang)),
      ),
      _BackupDataSegment.box<String>(
        boxName: HiveBoxNames.wordBookmarksFor(lang),
        box: () => Hive.box<String>(HiveBoxNames.wordBookmarksFor(lang)),
      ),
      _BackupDataSegment.box<String>(
        boxName: HiveBoxNames.readingBookmarksFor(lang),
        box: () => Hive.box<String>(HiveBoxNames.readingBookmarksFor(lang)),
      ),
      _BackupDataSegment.box<String>(
        boxName: HiveBoxNames.readingConfigFor(lang),
        box: () => Hive.box<String>(HiveBoxNames.readingConfigFor(lang)),
      ),
      _BackupDataSegment.box<int>(
        boxName: HiveBoxNames.readingTimeFor(lang),
        box: () => Hive.box<int>(HiveBoxNames.readingTimeFor(lang)),
        decode: _decodeInt,
      ),
      _BackupDataSegment.box<String>(
        boxName: HiveBoxNames.wordContextsFor(lang),
        box: () => Hive.box<String>(HiveBoxNames.wordContextsFor(lang)),
      ),
      _BackupDataSegment.box<LearningItem>(
        boxName: HiveBoxNames.learningItemsFor(lang),
        box: () => Hive.box<LearningItem>(HiveBoxNames.learningItemsFor(lang)),
        encode: (value) => value.toJson(),
        decode: (value) => LearningItem.fromJson(_asStringKeyMap(value)),
      ),
      _BackupDataSegment.box<int>(
        boxName: HiveBoxNames.learningAnalyticsFor(lang),
        box: () => Hive.box<int>(HiveBoxNames.learningAnalyticsFor(lang)),
        decode: _decodeInt,
      ),
    ];
  }

  static List<_BackupDataSegment> _v1BackupSegments() {
    return [
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
    ];
  }

  @visibleForTesting
  static List<String> get backupDataBoxNames {
    return List.unmodifiable(
      [
        ..._globalBackupSegments(),
        ..._languageBackupSegments(_defaultLang),
      ].map((segment) => segment.boxName),
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
      return await _exportBackupSnapshot(
        folderPath: targetFolder,
        bookmark: settings.backupFolderBookmark,
        prefix: 'flow_read_backup',
        updateLastBackup: true,
      );
    } catch (e) {
      debugPrint('[BackupService] export failed: $e');
      final message = _describeExportError(e);
      _lastError = message;
      throw BackupException(message);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<String> _exportBackupSnapshot({
    required String folderPath,
    required String prefix,
    String? bookmark,
    required bool updateLastBackup,
  }) async {
    final folderAccess = await _folderAccess.startAccessing(
      path: folderPath,
      bookmark: bookmark,
    );
    try {
      final createdAt = DateTime.now();
      final dataSegments = await _buildBackupSegments();
      final bookFiles = await _collectBookFiles(dataSegments);
      final dataPayload = _buildDataPayload(dataSegments);
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
        prefix: prefix,
      );
      if (updateLastBackup) {
        await settings.setLastBackup(createdAt, filePath);
      }
      return filePath;
    } finally {
      await folderAccess.stopAccessing();
    }
  }

  Future<String> _exportPreImportBackup() async {
    final configuredPath = settings.backupFolderPath.trim();
    Object? configuredError;

    if (configuredPath.isNotEmpty) {
      try {
        return await _exportBackupSnapshot(
          folderPath: configuredPath,
          bookmark: settings.backupFolderBookmark,
          prefix: 'flow_read_pre_import',
          updateLastBackup: false,
        );
      } catch (e) {
        debugPrint('[BackupService] pre-import backup (configured path) failed: $e');
        configuredError = e;
        // Fallback to documents directory.
      }
    }

    try {
      final documentsDir = await _documentsDirectoryProvider();
      final preImportDir = Directory(
        '${documentsDir.path}${Platform.pathSeparator}backups'
        '${Platform.pathSeparator}pre_import',
      );
      return await _exportBackupSnapshot(
        folderPath: preImportDir.path,
        prefix: 'flow_read_pre_import',
        updateLastBackup: false,
      );
    } catch (e) {
      debugPrint('[BackupService] pre-import backup (documents dir) failed: $e');
      final cause = configuredError ?? e;
      throw BackupException('导入前备份失败，当前数据未更改：${_describeExportError(cause)}');
    }
  }

  Future<void> importBackupFile(String filePath) async {
    if (_isSyncing) {
      throw const BackupException('备份正在进行');
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      await _importBackupFile(filePath);
    } catch (e) {
      debugPrint('[BackupService] import failed: $e');
      final message = e is BackupException ? e.message : e.toString();
      _lastError = message;
      if (e is BackupException) rethrow;
      throw BackupException(message);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _importBackupFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const BackupException('备份文件不存在');
    }

    final zipBytes = await file.readAsBytes();
    if (zipBytes.isEmpty) {
      throw const BackupException('备份文件为空');
    }
    if (zipBytes.length < 4 ||
        !archive.isZipFileHeader(Uint8List.sublistView(zipBytes, 0, 4))) {
      throw const BackupException('不是 Flow Read 备份文件');
    }

    await _exportPreImportBackup();

    final decoded = await compute(archive.decodeZipArchive, zipBytes);
    final manifestJson = decoded['manifestJson'] as String;
    final dataJson = decoded['dataJson'] as String;
    final entryBytes = decoded['entryBytes'] as Map<String, dynamic>;

    final manifest = jsonDecode(manifestJson) as Map<String, dynamic>;
    final data = jsonDecode(dataJson) as Map<String, dynamic>;

    archive.validateManifest(manifest, appId);
    archive.validateDataSchema(data, schemaVersion);
    final importedSchemaVersion = _dataSchemaVersion(data);

    final manifestIds = archive.manifestBookIds(manifest);
    final boxes = data['boxes'] as Map<String, dynamic>;
    final dataBookIds = _dataBookIds(boxes, importedSchemaVersion);

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

    try {
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

      if (importedSchemaVersion < 2) {
        await _clearV1BackupBoxes();
      }

      final restoreSegments = await _buildRestoreSegments(
        boxNames: boxes.keys.map((key) => key.toString()).toSet(),
        importedSchemaVersion: importedSchemaVersion,
      );
      for (final segment in restoreSegments) {
        final boxData = boxes[segment.boxName];
        if (boxData is Map) {
          await _restoreSegment(segment, _asStringKeyMap(boxData));
        }
      }

      if (importedSchemaVersion < 2) {
        await _clearLanguageBackupBoxes(_defaultLang);
        await migrateV1BoxesToLanguageBoxes();
        await Hive.box<dynamic>(
          HiveBoxNames.settings,
        ).put(StorageSchema.versionKey, StorageSchema.currentVersion);
      }

      final restoredBookBoxNames = _restoredBookBoxNames(
        boxes,
        importedSchemaVersion,
      );
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

        for (final boxName in restoredBookBoxNames) {
          if (!Hive.isBoxOpen(boxName)) {
            await Hive.openBox<BookMetadata>(boxName);
          }
          final booksBoxRef = Hive.box<BookMetadata>(boxName);
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
      }

      await _cleanupStaleImportingFiles(booksDir);
      await settings.reloadFromStorage();
    } catch (_) {
      debugPrint('[BackupService] import data restoration failed');
      await _cleanupStaleImportingFiles(booksDir);
      throw const BackupException(
        '导入失败，当前数据可能已部分更改。\n'
        '如需恢复，请使用上次导入前自动保存的备份。',
      );
    }
  }

  Future<WordHunterImportResult> importWordHunterBackupFile(
    String filePath,
  ) async {
    _isSyncing = true;
    _lastError = null;
    notifyListeners();
    try {
      final service = WordHunterImportService();
      return await service.importFile(filePath);
    } catch (e) {
      debugPrint('[BackupService] Word Hunter import failed: $e');
      _lastError = e.toString();
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<WordHunterImportResult> importWordHunterPayload(
    Map<String, dynamic> payload,
  ) async {
    _isSyncing = true;
    _lastError = null;
    notifyListeners();
    try {
      final service = WordHunterImportService();
      return await service.importPayload(payload);
    } catch (e) {
      debugPrint('[BackupService] Word Hunter import failed: $e');
      _lastError = e.toString();
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _buildDataPayload(List<_BackupDataSegment> segments) {
    return archive.buildDataPayload(
      schemaVersion: schemaVersion,
      boxes: {
        for (final segment in segments)
          segment.boxName: _snapshotSegment(segment),
      },
    );
  }

  Future<List<_BackupDataSegment>> _buildBackupSegments() async {
    final segments = <_BackupDataSegment>[];
    for (final segment in _globalBackupSegments()) {
      await segment.ensureOpen();
      segments.add(segment);
    }

    for (final languageCode in _backupLanguageCodes()) {
      for (final segment in _languageBackupSegments(languageCode)) {
        if (await _segmentBoxExistsOrOpen(segment.boxName)) {
          await segment.ensureOpen();
          segments.add(segment);
        }
      }
    }
    return segments;
  }

  Set<String> _backupLanguageCodes() {
    return {
      _defaultLang,
      settings.activeSourceLanguage.trim().toLowerCase(),
      for (final module in LanguageRegistry.instance.modules)
        module.languageCode.trim().toLowerCase(),
    }.where((code) => code.isNotEmpty).toSet();
  }

  Future<List<_BackupDataSegment>> _buildRestoreSegments({
    required Set<String> boxNames,
    required int importedSchemaVersion,
  }) async {
    final candidates = importedSchemaVersion < 2
        ? [..._globalBackupSegments(), ..._v1BackupSegments()]
        : [
            for (final boxName in boxNames)
              if (_segmentForBoxName(boxName) != null)
                _segmentForBoxName(boxName)!,
          ];
    final segments = <_BackupDataSegment>[];
    for (final segment in candidates) {
      if (!boxNames.contains(segment.boxName)) continue;
      await segment.ensureOpen();
      segments.add(segment);
    }
    return segments;
  }

  _BackupDataSegment? _segmentForBoxName(String boxName) {
    if (boxName == HiveBoxNames.settings) {
      return _globalBackupSegments().firstWhere(
        (segment) => segment.boxName == boxName,
      );
    }
    if (boxName == HiveBoxNames.rssSubscriptions) {
      return _globalBackupSegments().firstWhere(
        (segment) => segment.boxName == boxName,
      );
    }
    if (boxName == HiveBoxNames.bookGlossary) {
      return _globalBackupSegments().firstWhere(
        (segment) => segment.boxName == boxName,
      );
    }
    if (boxName == HiveBoxNames.characterRegistry) {
      return _globalBackupSegments().firstWhere(
        (segment) => segment.boxName == boxName,
      );
    }
    if (boxName.startsWith('${HiveBoxNames.books}_')) {
      return _BackupDataSegment.box<BookMetadata>(
        boxName: boxName,
        box: () => Hive.box<BookMetadata>(boxName),
        encode: (value) => value.toJson(),
        decode: (value) => BookMetadata.fromJson(_asStringKeyMap(value)),
      );
    }
    if (boxName.startsWith('${HiveBoxNames.learningItems}_')) {
      return _BackupDataSegment.box<LearningItem>(
        boxName: boxName,
        box: () => Hive.box<LearningItem>(boxName),
        encode: (value) => value.toJson(),
        decode: (value) => LearningItem.fromJson(_asStringKeyMap(value)),
      );
    }
    if (boxName.startsWith('${HiveBoxNames.readingTime}_') ||
        boxName.startsWith('${HiveBoxNames.learningAnalytics}_')) {
      return _BackupDataSegment.box<int>(
        boxName: boxName,
        box: () => Hive.box<int>(boxName),
        decode: _decodeInt,
      );
    }
    if (_isLanguageStringBoxName(boxName)) {
      return _BackupDataSegment.box<String>(
        boxName: boxName,
        box: () => Hive.box<String>(boxName),
      );
    }
    return null;
  }

  int _dataSchemaVersion(Map<String, dynamic> data) {
    final raw = data['schemaVersion'];
    return raw is int ? raw : int.parse(raw.toString());
  }

  Set<String> _dataBookIds(
    Map<String, dynamic> boxes,
    int importedSchemaVersion,
  ) {
    final bookBoxNames = importedSchemaVersion < 2
        ? [HiveBoxNames.books]
        : boxes.keys
              .map((key) => key.toString())
              .where(_isLanguageBooksBoxName)
              .toList();
    return {
      for (final boxName in bookBoxNames)
        for (final entry in _boxEntries(boxes[boxName]))
          _decodeKey(entry['key']).toString(),
    };
  }

  List<String> _restoredBookBoxNames(
    Map<String, dynamic> boxes,
    int importedSchemaVersion,
  ) {
    if (importedSchemaVersion < 2) {
      return [HiveBoxNames.booksFor(_defaultLang)];
    }
    return boxes.keys
        .map((key) => key.toString())
        .where(_isLanguageBooksBoxName)
        .toList();
  }

  Iterable<Map<dynamic, dynamic>> _boxEntries(dynamic boxData) {
    if (boxData is! Map) return const [];
    final entries = boxData['entries'];
    if (entries is! List) return const [];
    return entries.whereType<Map>();
  }

  Future<void> _clearLanguageBackupBoxes(String languageCode) async {
    for (final segment in _languageBackupSegments(languageCode)) {
      if (await _segmentBoxExistsOrOpen(segment.boxName)) {
        await segment.ensureOpen();
        await segment.clear();
      }
    }
  }

  Future<void> _clearV1BackupBoxes() async {
    for (final segment in _v1BackupSegments()) {
      await segment.ensureOpen();
      await segment.clear();
    }
  }

  Future<bool> _segmentBoxExistsOrOpen(String boxName) async {
    return Hive.isBoxOpen(boxName) || await Hive.boxExists(boxName);
  }

  bool _isLanguageBooksBoxName(String boxName) {
    return boxName.startsWith('${HiveBoxNames.books}_');
  }

  bool _isLanguageStringBoxName(String boxName) {
    return boxName.startsWith('${HiveBoxNames.userVocabulary}_') ||
        boxName.startsWith('${HiveBoxNames.wordBookmarks}_') ||
        boxName.startsWith('${HiveBoxNames.readingBookmarks}_') ||
        boxName.startsWith('${HiveBoxNames.readingConfig}_') ||
        boxName.startsWith('${HiveBoxNames.wordContexts}_');
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

  Future<_BookFilesCollection> _collectBookFiles(
    List<_BackupDataSegment> segments,
  ) async {
    final books = <String, _BookFile>{};
    final hasCover = <String, bool>{};
    var totalBytes = 0;

    for (final segment in segments.where(
      (segment) => _isLanguageBooksBoxName(segment.boxName),
    )) {
      final booksBox = Hive.box<BookMetadata>(segment.boxName);
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
      debugPrint('[BackupService] backup rename failed, retrying delete+rename');
      try {
        if (await File(finalPath).exists()) {
          await File(finalPath).delete();
        }
        await File(partPath).rename(finalPath);
      } catch (_) {
        debugPrint('[BackupService] rename retry failed, falling back to copy+delete');
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
      debugPrint('[BackupService] part file cleanup failed, continuing');
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
      debugPrint('[BackupService] stale importing file cleanup failed, continuing');
      // Best-effort cleanup.
    }
  }

  Future<void> _atomicRename(File source, File target) async {
    try {
      await source.rename(target.path);
    } catch (_) {
      debugPrint('[BackupService] staged file rename failed, retrying delete+rename');
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
    required this.ensureOpen,
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
      ensureOpen: () async {
        if (!Hive.isBoxOpen(boxName)) {
          await Hive.openBox<T>(boxName);
        }
      },
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
  final Future<void> Function() ensureOpen;
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

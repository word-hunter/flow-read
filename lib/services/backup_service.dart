import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/book_glossary_entry.dart';
import '../models/book_metadata.dart';
import '../models/learning_item.dart';
import '../models/user_vocabulary.dart' as vocabulary;
import 'package:flow_rss/flow_rss.dart';
import '../storage/database/app_database.dart' as drift;
import '../storage/database/repositories/drift_book_repository.dart';
import '../storage/database/repositories/drift_bookmark_repository.dart';
import '../storage/database/repositories/drift_learning_item_repository.dart';
import '../storage/database/repositories/drift_rss_repository.dart';
import '../storage/hive_box_names.dart';
import 'backup_archive.dart' as archive;
import 'backup_folder_access.dart';
import 'package:flow_language/flow_language.dart';
import 'settings_service.dart';
import 'wordhunter_import_service.dart';

typedef WordHunterImportServiceFactory = WordHunterImportService Function();

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
  static const _globalBackupBoxNames = <String>[
    HiveBoxNames.settings,
    HiveBoxNames.rssSubscriptions,
    HiveBoxNames.bookGlossary,
    HiveBoxNames.characterRegistry,
  ];

  static List<String> _languageBackupBoxNames(String lang) {
    return [
      HiveBoxNames.booksFor(lang),
      HiveBoxNames.userVocabularyFor(lang),
      HiveBoxNames.wordBookmarksFor(lang),
      HiveBoxNames.readingBookmarksFor(lang),
      HiveBoxNames.readingConfigFor(lang),
      HiveBoxNames.readingTimeFor(lang),
      HiveBoxNames.wordContextsFor(lang),
      HiveBoxNames.learningItemsFor(lang),
      HiveBoxNames.learningAnalyticsFor(lang),
    ];
  }

  @visibleForTesting
  static List<String> get backupDataBoxNames {
    return List.unmodifiable(
      [
        ..._globalBackupBoxNames,
        ..._languageBackupBoxNames(_defaultLang),
      ],
    );
  }

  final SettingsService settings;
  final BackupFolderAccess _folderAccess;
  final Future<Directory> Function() _documentsDirectoryProvider;
  final WordHunterImportServiceFactory? _wordHunterImportServiceFactory;
  final drift.AppDatabase _database;

  Timer? _timer;
  bool _isSyncing = false;
  String? _lastError;

  BackupService(
    this.settings, {
    BackupFolderAccess? folderAccess,
    Future<Directory> Function()? documentsDirectoryProvider,
    WordHunterImportServiceFactory? wordHunterImportServiceFactory,
    required drift.AppDatabase database,
  }) : _folderAccess = folderAccess ?? const BackupFolderAccess(),
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory,
       _wordHunterImportServiceFactory = wordHunterImportServiceFactory,
       _database = database;

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
        debugPrint(
          '[BackupService] pre-import backup (configured path) failed: $e',
        );
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
      debugPrint(
        '[BackupService] pre-import backup (documents dir) failed: $e',
      );
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

      await _restoreDriftBackup(
        database: _database,
        boxes: boxes,
        importedSchemaVersion: importedSchemaVersion,
        stagingPaths: stagingPaths,
        booksDir: booksDir,
      );

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

  Future<void> _restoreDriftBackup({
    required drift.AppDatabase database,
    required Map<String, dynamic> boxes,
    required int importedSchemaVersion,
    required Map<String, ({String source, String? cover})> stagingPaths,
    required Directory booksDir,
  }) async {
    await database.transaction(() async {
      await _restoreDriftSettings(database, boxes);
      await _restoreDriftRssSubscriptions(database, boxes);
      await _restoreDriftCharacterRegistry(database, boxes);

      for (final languageCode in _restoredLanguageCodes(
        boxes,
        importedSchemaVersion,
      )) {
        await _restoreDriftLanguageData(
          database,
          boxes,
          languageCode,
          importedSchemaVersion,
        );
      }

      await _restoreDriftBookGlossary(database, boxes);
    });

    await _commitStagedBookFiles(
      stagingPaths: stagingPaths,
      booksDir: booksDir,
      updateBook: (id, sourcePath, coverPath) async {
        final entry = await database.bookDao.getById(id);
        if (entry == null) return;
        final metadata = DriftBookRepository.metadataFromEntry(entry).copyWith(
          sourcePath: sourcePath,
          coverPath: coverPath,
        );
        await database.bookDao.upsert(
          DriftBookRepository.companionFromMetadata(
            metadata,
            languageCode: entry.language,
          ),
        );
      },
    );
  }

  Future<void> _commitStagedBookFiles({
    required Map<String, ({String source, String? cover})> stagingPaths,
    required Directory booksDir,
    required Future<void> Function(
      String id,
      String sourcePath,
      String? coverPath,
    )
    updateBook,
  }) async {
    for (final id in stagingPaths.keys) {
      final canonicalSource = _bookSourcePath(booksDir, id);
      final staging = stagingPaths[id]!;

      final sourceFile = File(staging.source);
      if (await sourceFile.exists()) {
        final target = File(canonicalSource);
        await _atomicRename(sourceFile, target);
      }

      String? canonicalCover;
      if (staging.cover != null) {
        final coverFile = File(staging.cover!);
        canonicalCover = _bookCoverPath(booksDir, id);
        if (await coverFile.exists()) {
          final target = File(canonicalCover);
          await _atomicRename(coverFile, target);
        }
      }

      await updateBook(id, canonicalSource, canonicalCover);
    }
  }

  Future<WordHunterImportResult> importWordHunterBackupFile(
    String filePath,
  ) async {
    _isSyncing = true;
    _lastError = null;
    notifyListeners();
    try {
      final service = _requireWordHunterImportService();
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
      final service = _requireWordHunterImportService();
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

  WordHunterImportService _requireWordHunterImportService() {
    final factory = _wordHunterImportServiceFactory;
    if (factory == null) {
      throw const BackupException('Word Hunter 导入服务未配置');
    }
    return factory();
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
    return _buildDriftBackupSegments(_database);
  }

  Future<List<_BackupDataSegment>> _buildDriftBackupSegments(
    drift.AppDatabase database,
  ) async {
    final globalSegments = await Future.wait([
      _driftSettingsSegment(database),
      _driftRssSegment(database),
      _driftBookGlossarySegment(database),
      _driftCharacterRegistrySegment(database),
    ]);
    final languageSegments = await Future.wait(
      _backupLanguageCodes().map(
        (languageCode) => _driftLanguageBackupSegments(
          database,
          languageCode,
        ),
      ),
    );

    return [
      ...globalSegments,
      for (final group in languageSegments) ...group,
    ];
  }

  Future<_BackupDataSegment> _driftSettingsSegment(
    drift.AppDatabase database,
  ) async {
    return _BackupDataSegment.memory<String>(
      boxName: HiveBoxNames.settings,
      entries: await database.settingsDao.allEntries(),
      skipSnapshotKey: (key, includeSecretsInBackup) {
        if (_localSettingKeys.contains(key)) return true;
        return !includeSecretsInBackup && _secretSettingKeys.contains(key);
      },
    );
  }

  Future<_BackupDataSegment> _driftRssSegment(
    drift.AppDatabase database,
  ) async {
    final rows = await database.rssDao.allSubscriptions();
    return _BackupDataSegment.memory<RssFeedSubscription>(
      boxName: HiveBoxNames.rssSubscriptions,
      entries: {
        for (var index = 0; index < rows.length; index += 1)
          index: _rssSubscriptionFromDriftEntry(rows[index]),
      },
      encode: _rssSubscriptionToJson,
    );
  }

  Future<_BackupDataSegment> _driftBookGlossarySegment(
    drift.AppDatabase database,
  ) async {
    final rows = await database.bookGlossaryDao.allEntries();
    return _BackupDataSegment.memory<BookGlossaryEntry>(
      boxName: HiveBoxNames.bookGlossary,
      entries: {
        for (final row in rows) row.id: _bookGlossaryEntryFromDrift(row),
      },
      encode: (value) => value.toJson(),
    );
  }

  Future<_BackupDataSegment> _driftCharacterRegistrySegment(
    drift.AppDatabase database,
  ) async {
    return _BackupDataSegment.memory<String>(
      boxName: HiveBoxNames.characterRegistry,
      entries: await database.characterRegistryDao.allEntries(),
    );
  }

  Future<List<_BackupDataSegment>> _driftLanguageBackupSegments(
    drift.AppDatabase database,
    String languageCode,
  ) async {
    final results = await Future.wait<Object>([
      database.bookDao.allBooks(languageCode),
      database.userVocabularyDao.allWords(languageCode),
      database.bookmarkDao.allWordBookmarksForLanguage(languageCode),
      database.bookmarkDao.allReadingBookmarksForLanguage(languageCode),
      database.readingConfigDao.allValues(languageCode),
      database.readingTimeDao.allValues(languageCode),
      database.wordContextDao.allValues(languageCode),
      database.learningItemDao.allForLanguage(languageCode),
      database.learningAnalyticsDao.allValues(languageCode),
    ]);

    final bookRows = results[0] as List<drift.BookEntry>;
    final vocabularyValues = results[1] as Map<String, String>;
    final wordBookmarkRows = results[2] as List<drift.WordBookmark>;
    final readingBookmarkRows = results[3] as List<drift.ReadingBookmarkEntry>;
    final readingConfig = results[4] as Map<String, String>;
    final readingTime = results[5] as Map<String, int>;
    final wordContexts = results[6] as Map<String, String>;
    final learningItemRows = results[7] as List<drift.LearningItemEntry>;
    final learningAnalytics = results[8] as Map<String, int>;

    return [
      _BackupDataSegment.memory<BookMetadata>(
        boxName: HiveBoxNames.booksFor(languageCode),
        entries: {
          for (final row in bookRows)
            row.id: DriftBookRepository.metadataFromEntry(row),
        },
        encode: (value) => value.toJson(),
      ),
      _BackupDataSegment.memory<String>(
        boxName: HiveBoxNames.userVocabularyFor(languageCode),
        entries: vocabularyValues,
      ),
      _BackupDataSegment.memory<String>(
        boxName: HiveBoxNames.wordBookmarksFor(languageCode),
        entries: DriftBookmarkRepository.encodedWordBookmarksByBook(
          wordBookmarkRows,
        ),
      ),
      _BackupDataSegment.memory<String>(
        boxName: HiveBoxNames.readingBookmarksFor(languageCode),
        entries: DriftBookmarkRepository.encodedReadingBookmarksByBook(
          readingBookmarkRows,
        ),
      ),
      _BackupDataSegment.memory<String>(
        boxName: HiveBoxNames.readingConfigFor(languageCode),
        entries: readingConfig,
      ),
      _BackupDataSegment.memory<int>(
        boxName: HiveBoxNames.readingTimeFor(languageCode),
        entries: readingTime,
      ),
      _BackupDataSegment.memory<String>(
        boxName: HiveBoxNames.wordContextsFor(languageCode),
        entries: wordContexts,
      ),
      _BackupDataSegment.memory<LearningItem>(
        boxName: HiveBoxNames.learningItemsFor(languageCode),
        entries: {
          for (final row in learningItemRows)
            row.id: DriftLearningItemRepository.itemFromEntry(row),
        },
        encode: (value) => value.toJson(),
      ),
      _BackupDataSegment.memory<int>(
        boxName: HiveBoxNames.learningAnalyticsFor(languageCode),
        entries: {
          for (final entry in learningAnalytics.entries)
            int.tryParse(entry.key) ?? entry.key: entry.value,
        },
      ),
    ];
  }

  Future<void> _restoreDriftSettings(
    drift.AppDatabase database,
    Map<String, dynamic> boxes,
  ) async {
    final boxData = _boxData(boxes, HiveBoxNames.settings);
    if (boxData == null) return;

    for (final entry in _boxEntries(boxData)) {
      final key = _decodeKey(entry['key']);
      if (_localSettingKeys.contains(key)) continue;
      await database.settingsDao.putValue(
        key.toString(),
        entry['value']?.toString() ?? '',
      );
    }
  }

  Future<void> _restoreDriftRssSubscriptions(
    drift.AppDatabase database,
    Map<String, dynamic> boxes,
  ) async {
    final boxData = _boxData(boxes, HiveBoxNames.rssSubscriptions);
    if (boxData == null) return;

    await database.rssDao.deleteAllArticles();
    await database.rssDao.deleteAllSubscriptions();
    for (final entry in _boxEntries(boxData)) {
      final value = entry['value'];
      if (value is! Map) continue;
      final subscription = _rssSubscriptionFromJson(_asStringKeyMap(value));
      if (subscription.url.trim().isEmpty) continue;
      await database.rssDao.insertSubscription(
        drift.RssSubscriptionsCompanion.insert(
          id: DriftRssRepository.subscriptionIdForUrl(subscription.url),
          url: subscription.url,
          title: Value(subscription.title),
          description: Value(subscription.description),
          imageUrl: Value(subscription.imageUrl),
          lastFetchedAt: Value(
            subscription.lastFetchedAt?.toUtc().toIso8601String(),
          ),
        ),
      );
    }
  }

  Future<void> _restoreDriftCharacterRegistry(
    drift.AppDatabase database,
    Map<String, dynamic> boxes,
  ) async {
    final boxData = _boxData(boxes, HiveBoxNames.characterRegistry);
    if (boxData == null) return;

    await database.characterRegistryDao.clear();
    for (final entry in _boxEntries(boxData)) {
      await database.characterRegistryDao.putValue(
        _decodeKey(entry['key']).toString(),
        entry['value']?.toString() ?? '',
      );
    }
  }

  Future<void> _restoreDriftBookGlossary(
    drift.AppDatabase database,
    Map<String, dynamic> boxes,
  ) async {
    final boxData = _boxData(boxes, HiveBoxNames.bookGlossary);
    if (boxData == null) return;

    await database.bookGlossaryDao.deleteAll();
    for (final entry in _boxEntries(boxData)) {
      final value = entry['value'];
      if (value is! Map) continue;
      final glossary = BookGlossaryEntry.fromJson(_asStringKeyMap(value));
      if (glossary.id.isEmpty || glossary.bookId.isEmpty) continue;
      await database.bookGlossaryDao.upsert(
        drift.BookGlossaryCompanion.insert(
          id: glossary.id,
          bookId: glossary.bookId,
          word: glossary.word,
          canonicalForm: Value(glossary.canonicalForm),
          explanation: Value(glossary.explanation),
          sourceContext: Value(glossary.sourceContext),
          createdAt: Value(glossary.createdAt.toUtc().toIso8601String()),
          lastAccessedAt: Value(
            glossary.lastAccessedAt?.toUtc().toIso8601String(),
          ),
        ),
      );
    }
  }

  Future<void> _restoreDriftLanguageData(
    drift.AppDatabase database,
    Map<String, dynamic> boxes,
    String languageCode,
    int importedSchemaVersion,
  ) async {
    if (importedSchemaVersion < 2) {
      await _clearDriftLanguageData(database, languageCode);
    }
    await _restoreDriftBooks(
      database,
      boxes,
      languageCode,
      importedSchemaVersion,
    );
    await _restoreDriftUserVocabulary(
      database,
      boxes,
      languageCode,
      importedSchemaVersion,
    );
    await _restoreDriftWordBookmarks(
      database,
      boxes,
      languageCode,
      importedSchemaVersion,
    );
    await _restoreDriftReadingBookmarks(
      database,
      boxes,
      languageCode,
      importedSchemaVersion,
    );
    await _restoreDriftReadingConfig(
      database,
      boxes,
      languageCode,
      importedSchemaVersion,
    );
    await _restoreDriftReadingTime(
      database,
      boxes,
      languageCode,
      importedSchemaVersion,
    );
    await _restoreDriftWordContexts(
      database,
      boxes,
      languageCode,
      importedSchemaVersion,
    );
    await _restoreDriftLearningItems(
      database,
      boxes,
      languageCode,
      importedSchemaVersion,
    );
    await _restoreDriftLearningAnalytics(
      database,
      boxes,
      languageCode,
      importedSchemaVersion,
    );
  }

  Future<void> _restoreDriftBooks(
    drift.AppDatabase database,
    Map<String, dynamic> boxes,
    String languageCode,
    int importedSchemaVersion,
  ) async {
    final boxData = _languageBoxData(
      boxes,
      HiveBoxNames.books,
      languageCode,
      importedSchemaVersion,
    );
    if (boxData == null) return;

    await database.bookDao.deleteAllForLanguage(languageCode);
    for (final entry in _boxEntries(boxData)) {
      final value = entry['value'];
      if (value is! Map) continue;
      var metadata = BookMetadata.fromJson(_asStringKeyMap(value));
      final key = _decodeKey(entry['key']).toString();
      if (metadata.id.isEmpty && key.isNotEmpty) {
        metadata = metadata.copyWith(id: key);
      }
      if (metadata.id.isEmpty) continue;
      await database.bookDao.upsert(
        DriftBookRepository.companionFromMetadata(
          metadata,
          languageCode: languageCode,
        ),
      );
    }
  }

  Future<void> _restoreDriftUserVocabulary(
    drift.AppDatabase database,
    Map<String, dynamic> boxes,
    String languageCode,
    int importedSchemaVersion,
  ) async {
    final boxData = _boxData(
      boxes,
      _languageBoxName(
        HiveBoxNames.userVocabulary,
        languageCode,
        importedSchemaVersion,
      ),
    );
    if (boxData == null) return;

    await database.userVocabularyDao.clearForLanguage(languageCode);
    for (final entry in _boxEntries(boxData)) {
      final parsed = _vocabularyBackupEntry(
        key: _decodeKey(entry['key']),
        value: entry['value'],
        languageCode: languageCode,
      );
      if (parsed == null) continue;
      await database.userVocabularyDao.upsert(
        drift.UserVocabulariesCompanion.insert(
          id: vocabulary.UserVocabularyKey(
            languageId: languageCode,
            canonical: parsed.canonical,
          ).storageKey,
          canonical: parsed.canonical,
          status: parsed.status,
          language: Value(languageCode),
        ),
      );
    }
  }

  Future<void> _restoreDriftWordBookmarks(
    drift.AppDatabase database,
    Map<String, dynamic> boxes,
    String languageCode,
    int importedSchemaVersion,
  ) async {
    final boxData = _boxData(
      boxes,
      _languageBoxName(
        HiveBoxNames.wordBookmarks,
        languageCode,
        importedSchemaVersion,
      ),
    );
    if (boxData == null) return;

    await database.bookmarkDao.deleteWordBookmarksForLanguage(languageCode);
    final repository = DriftBookmarkRepository(
      database.bookmarkDao,
      languageCode: languageCode,
    );
    for (final entry in _boxEntries(boxData)) {
      final bookId = _decodeKey(entry['key']).toString();
      final encoded = entry['value']?.toString() ?? '[]';
      await repository.putWordBookmarks(bookId, encoded);
    }
  }

  Future<void> _restoreDriftReadingBookmarks(
    drift.AppDatabase database,
    Map<String, dynamic> boxes,
    String languageCode,
    int importedSchemaVersion,
  ) async {
    final boxData = _boxData(
      boxes,
      _languageBoxName(
        HiveBoxNames.readingBookmarks,
        languageCode,
        importedSchemaVersion,
      ),
    );
    if (boxData == null) return;

    await database.bookmarkDao.deleteReadingBookmarksForLanguage(languageCode);
    final repository = DriftBookmarkRepository(
      database.bookmarkDao,
      languageCode: languageCode,
    );
    for (final entry in _boxEntries(boxData)) {
      final bookId = _decodeKey(entry['key']).toString();
      final encoded = entry['value']?.toString() ?? '[]';
      await repository.putReadingBookmarks(bookId, encoded);
    }
  }

  Future<void> _restoreDriftReadingConfig(
    drift.AppDatabase database,
    Map<String, dynamic> boxes,
    String languageCode,
    int importedSchemaVersion,
  ) async {
    final boxData = _boxData(
      boxes,
      _languageBoxName(
        HiveBoxNames.readingConfig,
        languageCode,
        importedSchemaVersion,
      ),
    );
    if (boxData == null) return;

    await database.readingConfigDao.clearForLanguage(languageCode);
    for (final entry in _boxEntries(boxData)) {
      await database.readingConfigDao.putValue(
        _decodeKey(entry['key']).toString(),
        languageCode,
        entry['value']?.toString() ?? '',
      );
    }
  }

  Future<void> _restoreDriftReadingTime(
    drift.AppDatabase database,
    Map<String, dynamic> boxes,
    String languageCode,
    int importedSchemaVersion,
  ) async {
    final boxData = _languageBoxData(
      boxes,
      HiveBoxNames.readingTime,
      languageCode,
      importedSchemaVersion,
    );
    if (boxData == null) return;

    await database.readingTimeDao.clearForLanguage(languageCode);
    for (final entry in _boxEntries(boxData)) {
      await database.readingTimeDao.putSeconds(
        _decodeKey(entry['key']).toString(),
        languageCode,
        _decodeInt(entry['value']),
      );
    }
  }

  Future<void> _restoreDriftWordContexts(
    drift.AppDatabase database,
    Map<String, dynamic> boxes,
    String languageCode,
    int importedSchemaVersion,
  ) async {
    final boxData = _languageBoxData(
      boxes,
      HiveBoxNames.wordContexts,
      languageCode,
      importedSchemaVersion,
    );
    if (boxData == null) return;

    await database.wordContextDao.clearForLanguage(languageCode);
    for (final entry in _boxEntries(boxData)) {
      await database.wordContextDao.putData(
        _decodeKey(entry['key']).toString(),
        languageCode,
        entry['value']?.toString() ?? '',
      );
    }
  }

  Future<void> _restoreDriftLearningItems(
    drift.AppDatabase database,
    Map<String, dynamic> boxes,
    String languageCode,
    int importedSchemaVersion,
  ) async {
    final boxData = _boxData(
      boxes,
      _languageBoxName(
        HiveBoxNames.learningItems,
        languageCode,
        importedSchemaVersion,
      ),
    );
    if (boxData == null) return;

    await database.learningItemDao.clearForLanguage(languageCode);
    for (final entry in _boxEntries(boxData)) {
      final value = entry['value'];
      if (value is! Map) continue;
      var item = LearningItem.fromJson(_asStringKeyMap(value));
      final key = _decodeKey(entry['key']).toString();
      if (item.id.isEmpty && key.isNotEmpty) {
        item = item.copyWith(id: key);
      }
      if (item.id.isEmpty) continue;
      await database.learningItemDao.upsert(
        DriftLearningItemRepository.companionFromItem(
          item,
          languageCode: languageCode,
        ),
      );
    }
  }

  Future<void> _restoreDriftLearningAnalytics(
    drift.AppDatabase database,
    Map<String, dynamic> boxes,
    String languageCode,
    int importedSchemaVersion,
  ) async {
    final boxData = _boxData(
      boxes,
      _languageBoxName(
        HiveBoxNames.learningAnalytics,
        languageCode,
        importedSchemaVersion,
      ),
    );
    if (boxData == null) return;

    await database.learningAnalyticsDao.clearForLanguage(languageCode);
    for (final entry in _boxEntries(boxData)) {
      await database.learningAnalyticsDao.putValue(
        _decodeKey(entry['key']).toString(),
        languageCode,
        _decodeInt(entry['value']),
      );
    }
  }

  Map<String, dynamic>? _boxData(
    Map<String, dynamic> boxes,
    String boxName,
  ) {
    final data = boxes[boxName];
    if (data is! Map) return null;
    return _asStringKeyMap(data);
  }

  Map<String, dynamic>? _languageBoxData(
    Map<String, dynamic> boxes,
    String baseBoxName,
    String languageCode,
    int importedSchemaVersion,
  ) {
    return _boxData(
      boxes,
      _languageBoxName(baseBoxName, languageCode, importedSchemaVersion),
    );
  }

  String _languageBoxName(
    String baseBoxName,
    String languageCode,
    int importedSchemaVersion,
  ) {
    if (importedSchemaVersion < 2) return baseBoxName;
    return switch (baseBoxName) {
      HiveBoxNames.books => HiveBoxNames.booksFor(languageCode),
      HiveBoxNames.userVocabulary => HiveBoxNames.userVocabularyFor(
        languageCode,
      ),
      HiveBoxNames.wordBookmarks => HiveBoxNames.wordBookmarksFor(
        languageCode,
      ),
      HiveBoxNames.readingBookmarks => HiveBoxNames.readingBookmarksFor(
        languageCode,
      ),
      HiveBoxNames.readingConfig => HiveBoxNames.readingConfigFor(
        languageCode,
      ),
      HiveBoxNames.readingTime => HiveBoxNames.readingTimeFor(languageCode),
      HiveBoxNames.wordContexts => HiveBoxNames.wordContextsFor(languageCode),
      HiveBoxNames.learningItems => HiveBoxNames.learningItemsFor(
        languageCode,
      ),
      HiveBoxNames.learningAnalytics => HiveBoxNames.learningAnalyticsFor(
        languageCode,
      ),
      _ => throw BackupException('未知的语言备份分区：$baseBoxName'),
    };
  }

  Future<void> _clearDriftLanguageData(
    drift.AppDatabase database,
    String languageCode,
  ) async {
    await database.bookDao.deleteAllForLanguage(languageCode);
    await database.userVocabularyDao.clearForLanguage(languageCode);
    await database.bookmarkDao.deleteWordBookmarksForLanguage(languageCode);
    await database.bookmarkDao.deleteReadingBookmarksForLanguage(languageCode);
    await database.readingConfigDao.clearForLanguage(languageCode);
    await database.readingTimeDao.clearForLanguage(languageCode);
    await database.wordContextDao.clearForLanguage(languageCode);
    await database.learningItemDao.clearForLanguage(languageCode);
    await database.learningAnalyticsDao.clearForLanguage(languageCode);
  }

  Set<String> _restoredLanguageCodes(
    Map<String, dynamic> boxes,
    int importedSchemaVersion,
  ) {
    if (importedSchemaVersion < 2) {
      return const {HiveBoxNames.defaultLanguageCode};
    }
    const languageBoxPrefixes = [
      HiveBoxNames.books,
      HiveBoxNames.userVocabulary,
      HiveBoxNames.wordBookmarks,
      HiveBoxNames.readingBookmarks,
      HiveBoxNames.readingConfig,
      HiveBoxNames.readingTime,
      HiveBoxNames.wordContexts,
      HiveBoxNames.learningItems,
      HiveBoxNames.learningAnalytics,
    ];
    final languageCodes = <String>{};
    for (final boxName in boxes.keys.map((key) => key.toString())) {
      for (final prefix in languageBoxPrefixes) {
        final code = _languageCodeFromBoxName(boxName, prefix);
        if (code != null) {
          languageCodes.add(code);
        }
      }
    }
    return languageCodes;
  }

  String? _languageCodeFromBoxName(String boxName, String prefix) {
    final languagePrefix = '${prefix}_';
    if (!boxName.startsWith(languagePrefix)) return null;
    final languageCode = boxName.substring(languagePrefix.length);
    return languageCode.trim().isEmpty ? null : languageCode;
  }

  ({String canonical, String status})? _vocabularyBackupEntry({
    required dynamic key,
    required dynamic value,
    required String languageCode,
  }) {
    final fallbackKey = vocabulary.UserVocabularyKey.fromStorageKey(
      key.toString(),
      fallbackLanguageId: languageCode,
    );
    if (value is Map) {
      final entry = vocabulary.UserVocabularyEntry.fromJson(
        _asStringKeyMap(value),
      );
      final canonical = entry.key.canonical.trim().toLowerCase();
      return (
        canonical: canonical.isEmpty
            ? fallbackKey.canonical.trim().toLowerCase()
            : canonical,
        status: entry.status.name,
      );
    }
    if (value is String && value.trimLeft().startsWith('{')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return _vocabularyBackupEntry(
            key: key,
            value: decoded,
            languageCode: languageCode,
          );
        }
      } catch (_) {
        // Fall back to the legacy `word -> status` string shape.
      }
    }

    final canonical = fallbackKey.canonical.trim().toLowerCase();
    if (canonical.isEmpty) return null;
    final status = value?.toString() == vocabulary.UserWordStatus.learning.name
        ? vocabulary.UserWordStatus.learning.name
        : vocabulary.UserWordStatus.known.name;
    return (canonical: canonical, status: status);
  }

  Set<String> _backupLanguageCodes() {
    return {
      _defaultLang,
      settings.activeSourceLanguage.trim().toLowerCase(),
      for (final module in LanguageRegistry.instance.modules)
        module.languageCode.trim().toLowerCase(),
    }.where((code) => code.isNotEmpty).toSet();
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

  Iterable<Map<dynamic, dynamic>> _boxEntries(dynamic boxData) {
    if (boxData is! Map) return const [];
    final entries = boxData['entries'];
    if (entries is! List) return const [];
    return entries.whereType<Map>();
  }

  bool _isLanguageBooksBoxName(String boxName) {
    return boxName.startsWith('${HiveBoxNames.books}_');
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
      for (final meta in segment.values().whereType<BookMetadata>()) {
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
      debugPrint(
        '[BackupService] backup rename failed, retrying delete+rename',
      );
      try {
        if (await File(finalPath).exists()) {
          await File(finalPath).delete();
        }
        await File(partPath).rename(finalPath);
      } catch (_) {
        debugPrint(
          '[BackupService] rename retry failed, falling back to copy+delete',
        );
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
      debugPrint(
        '[BackupService] stale importing file cleanup failed, continuing',
      );
      // Best-effort cleanup.
    }
  }

  Future<void> _atomicRename(File source, File target) async {
    try {
      await source.rename(target.path);
    } catch (_) {
      debugPrint(
        '[BackupService] staged file rename failed, retrying delete+rename',
      );
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

  static RssFeedSubscription _rssSubscriptionFromDriftEntry(
    drift.RssSubscriptionEntry entry,
  ) {
    return RssFeedSubscription(
      url: entry.url,
      title: entry.title,
      description: entry.description,
      imageUrl: entry.imageUrl,
      lastFetchedAt: entry.lastFetchedAt == null
          ? null
          : DateTime.tryParse(entry.lastFetchedAt!),
    );
  }

  static BookGlossaryEntry _bookGlossaryEntryFromDrift(
    drift.BookGlossaryEntry entry,
  ) {
    return BookGlossaryEntry(
      id: entry.id,
      bookId: entry.bookId,
      word: entry.word,
      canonicalForm: entry.canonicalForm,
      explanation: entry.explanation,
      sourceContext: entry.sourceContext,
      createdAt:
          DateTime.tryParse(entry.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      lastAccessedAt: entry.lastAccessedAt == null
          ? null
          : DateTime.tryParse(entry.lastAccessedAt!),
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

class _BackupDataSegment {
  _BackupDataSegment._({
    required this.boxName,
    required this.keys,
    required this.values,
    required this.getValue,
    required this.encodeValue,
    this.skipSnapshotKey,
  });

  static _BackupDataSegment memory<T>({
    required String boxName,
    required Map<dynamic, T> entries,
    dynamic Function(T value)? encode,
    _BackupSnapshotSkip? skipSnapshotKey,
  }) {
    final snapshot = Map<dynamic, T>.of(entries);
    return _BackupDataSegment._(
      boxName: boxName,
      keys: () => snapshot.keys,
      values: () => snapshot.values,
      getValue: (key) => snapshot[key],
      encodeValue: (value) {
        if (encode != null) return encode(value as T);
        return BackupService._encodeJsonValue(value);
      },
      skipSnapshotKey: skipSnapshotKey,
    );
  }

  final String boxName;
  final Iterable<dynamic> Function() keys;
  final Iterable<dynamic> Function() values;
  final dynamic Function(dynamic key) getValue;
  final dynamic Function(dynamic value) encodeValue;
  final _BackupSnapshotSkip? skipSnapshotKey;

  bool shouldSkipSnapshotKey(
    dynamic key, {
    required bool includeSecretsInBackup,
  }) {
    final predicate = skipSnapshotKey;
    return predicate != null && predicate(key, includeSecretsInBackup);
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

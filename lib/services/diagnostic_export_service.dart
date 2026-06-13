import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../storage/database/app_database.dart';
import '../storage/hive_box_names.dart';
import '../storage/hive_storage.dart' show appDatabase;
import 'app_logger.dart';
import 'app_version.dart';
import 'settings_service.dart';

class DiagnosticExportException implements Exception {
  final String message;

  const DiagnosticExportException(this.message);

  @override
  String toString() => message;
}

class DiagnosticExportService {
  DiagnosticExportService({
    AppLogger? logger,
    Future<Directory> Function()? tempDirectoryProvider,
    DateTime Function()? clock,
    AppDatabase? database,
  }) : _logger = logger ?? AppLogger.instance,
       _tempDirectoryProvider = tempDirectoryProvider ?? getTemporaryDirectory,
       _clock = clock ?? DateTime.now,
       _database = database ?? appDatabase;

  final AppLogger _logger;
  final Future<Directory> Function() _tempDirectoryProvider;
  final DateTime Function() _clock;
  final AppDatabase? _database;

  Future<String> export({SettingsService? settings}) async {
    final bytes = await buildArchive(settings: settings);
    final directory = await _tempDirectoryProvider();
    await directory.create(recursive: true);
    final file = File(
      '${directory.path}${Platform.pathSeparator}'
      'flow_read_diagnostic_${_timestamp(_clock())}.zip',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<Uint8List> buildArchive({SettingsService? settings}) async {
    final archive = Archive();
    final appInfoJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(await _collectAppInfo(settings));
    _validateAppInfoJson(appInfoJson);

    archive.addFile(
      ArchiveFile.bytes('app_info.json', utf8.encode(appInfoJson)),
    );

    final logsDirectory = await _logger.logsDirectory();
    if (await logsDirectory.exists()) {
      final files = await logsDirectory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();
      files.sort((a, b) => a.path.compareTo(b.path));
      for (final file in files) {
        final name = file.uri.pathSegments.last;
        archive.addFile(
          ArchiveFile.bytes('logs/$name', await file.readAsBytes()),
        );
      }
    }

    final encoded = ZipEncoder().encodeBytes(archive);
    return Uint8List.fromList(encoded);
  }

  Future<Map<String, Object?>> _collectAppInfo(
    SettingsService? settings,
  ) async {
    return {
      'exportType': 'diagnostic',
      'appName': 'Flow Read',
      'version': FlowReadVersion.name,
      'buildNumber': FlowReadVersion.buildNumber,
      'fullVersion': FlowReadVersion.full,
      'platform': Platform.operatingSystem,
      'platformVersion': Platform.operatingSystemVersion,
      'exportedAt': _clock().toUtc().toIso8601String(),
      'deviceInfo': {
        'locale': Platform.localeName,
        'numberOfProcessors': Platform.numberOfProcessors,
      },
      'appStats': await _collectAppStats(),
      'settingsSummary': settings == null
          ? null
          : _collectSettingsSummary(settings),
    };
  }

  Future<Map<String, Object?>> _collectAppStats() async {
    const lang = HiveBoxNames.defaultLanguageCode;
    final database = _database;
    if (database != null) {
      return {
        'bookCount': await _countRows(
          database,
          'books',
          language: lang,
        ),
        'vocabularyCount': await _countRows(
          database,
          'user_vocabulary',
          language: lang,
        ),
        'rssSubscriptionCount': await _countRows(
          database,
          'rss_subscriptions',
        ),
        'learningItemCount': await _countRows(
          database,
          'learning_items',
          language: lang,
        ),
        'dictionaryCacheCount': await _countRows(
          database,
          'dictionary_cache',
          language: lang,
        ),
      };
    }

    return {
      'bookCount': _boxLength(HiveBoxNames.booksFor(lang)),
      'vocabularyCount': _boxLength(HiveBoxNames.userVocabularyFor(lang)),
      'rssSubscriptionCount': _boxLength(HiveBoxNames.rssSubscriptions),
      'learningItemCount': _boxLength(HiveBoxNames.learningItemsFor(lang)),
      'dictionaryCacheCount': _boxLength(HiveBoxNames.dictionaryCacheFor(lang)),
    };
  }

  Map<String, Object?> _collectSettingsSummary(SettingsService settings) {
    return {
      'appTheme': settings.appThemeId.name,
      'themeMode': settings.themeMode.name,
      'dailyReadingGoalMinutes': settings.dailyReadingGoalMinutes,
      'dictionarySources': [
        for (final source in settings.dictionarySources)
          {
            'id': source.type.id,
            'label': source.type.label,
            'enabled': source.enabled,
            'priority': source.priority,
          },
      ],
      'aiProvider': settings.aiProvider.label,
      'aiConfigured': settings.aiFeaturesEnabled,
      'rssFeatureEnabled': settings.rssFeatureEnabled,
      'reviewFeatureEnabled': settings.reviewFeatureEnabled,
      'backupEnabled': settings.backupEnabled,
      'backupFolderConfigured': settings.backupFolderPath.trim().isNotEmpty,
      'backupIntervalMinutes': settings.backupIntervalMinutes,
    };
  }

  int? _boxLength(String boxName) {
    if (!Hive.isBoxOpen(boxName)) return null;
    return Hive.box(boxName).length;
  }

  Future<int> _countRows(
    AppDatabase database,
    String tableName, {
    String? language,
  }) async {
    final where = language == null ? '' : ' WHERE language = ?';
    final variables = language == null
        ? const <Variable>[]
        : <Variable>[Variable<String>(language)];
    final row = await database
        .customSelect(
          'SELECT COUNT(*) AS count FROM $tableName$where',
          variables: variables,
          readsFrom: const {},
        )
        .getSingle();
    return row.read<int>('count');
  }

  void _validateAppInfoJson(String json) {
    final forbidden = RegExp(
      r'(api[_ -]?key|authorization|password|token|secret|bookmark|'
      r'backupFolderPath|backupFolderBookmark|file:\/\/|\/Users\/|'
      r'[A-Za-z]:\\)',
      caseSensitive: false,
    );
    if (forbidden.hasMatch(json)) {
      throw const DiagnosticExportException('诊断元信息包含敏感字段，已取消导出');
    }
  }

  String _timestamp(DateTime value) {
    final utc = value.toUtc().toIso8601String();
    return utc.replaceAll(RegExp(r'[:.]'), '-');
  }
}

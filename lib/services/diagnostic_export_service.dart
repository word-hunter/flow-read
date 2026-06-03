import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../storage/hive_box_names.dart';
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
  }) : _logger = logger ?? AppLogger.instance,
       _tempDirectoryProvider = tempDirectoryProvider ?? getTemporaryDirectory,
       _clock = clock ?? DateTime.now;

  final AppLogger _logger;
  final Future<Directory> Function() _tempDirectoryProvider;
  final DateTime Function() _clock;

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
    ).convert(_collectAppInfo(settings));
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

  Map<String, Object?> _collectAppInfo(SettingsService? settings) {
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
      'appStats': _collectAppStats(),
      'settingsSummary': settings == null
          ? null
          : _collectSettingsSummary(settings),
    };
  }

  Map<String, Object?> _collectAppStats() {
    const lang = HiveBoxNames.defaultLanguageCode;
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

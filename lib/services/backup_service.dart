import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/book_metadata.dart';
import '../models/rss_models.dart';
import 'settings_service.dart';

class BackupException implements Exception {
  final String message;

  const BackupException(this.message);

  @override
  String toString() => message;
}

class BackupService extends ChangeNotifier {
  static const schemaVersion = 1;
  static const appId = 'flow_read';

  static const _includedBoxes = <String>[
    'books',
    'user_vocabulary',
    'settings',
    'word_bookmarks',
    'reading_bookmarks',
    'reading_config',
    'reading_time',
    'dictionary_cache',
    'rss_subscriptions',
  ];

  static const _localSettingKeys = <String>{
    'backupEnabled',
    'backupFolderPath',
    'backupIntervalMinutes',
    'includeSecretsInBackup',
    'lastBackupAt',
    'lastBackupPath',
  };
  static const _secretSettingKeys = <String>{'apiKey', 'aiApiKeys'};

  final SettingsService settings;

  Timer? _timer;
  bool _isSyncing = false;
  String? _lastError;

  BackupService(this.settings);

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
      final createdAt = DateTime.now();
      final payload = createBackupPayload(createdAt: createdAt);
      final encoded = await compute(_encodeBackupPayload, payload);
      final fileName = 'flow_read_backup_${_formatTimestamp(createdAt)}.json';
      final file = File('$targetFolder${Platform.pathSeparator}$fileName');
      await file.parent.create(recursive: true);
      await file.writeAsString(encoded, flush: true);
      await settings.setLastBackup(createdAt, file.path);
      return file.path;
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> createBackupPayload({DateTime? createdAt}) {
    final timestamp = createdAt ?? DateTime.now();
    return {
      'schemaVersion': schemaVersion,
      'app': appId,
      'createdAt': timestamp.toIso8601String(),
      'boxes': {
        for (final boxName in _includedBoxes) boxName: _snapshotBox(boxName),
      },
    };
  }

  Future<void> importBackupFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const BackupException('备份文件不存在');
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const BackupException('备份文件格式无效');
    }
    await importBackupPayload(decoded);
  }

  Future<void> importBackupPayload(Map<String, dynamic> payload) async {
    if (payload['app'] != appId) {
      throw const BackupException('不是 FlowRead 备份文件');
    }
    final version = payload['schemaVersion'];
    if (version is! int || version > schemaVersion) {
      throw const BackupException('备份版本不兼容');
    }
    final boxes = payload['boxes'];
    if (boxes is! Map<String, dynamic>) {
      throw const BackupException('备份数据缺失');
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      for (final boxName in _includedBoxes) {
        final data = boxes[boxName];
        if (data is Map<String, dynamic>) {
          await _restoreBox(boxName, data);
        }
      }
      await settings.reloadFromStorage();
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _snapshotBox(String boxName) {
    final entries = <Map<String, dynamic>>[];
    for (final key in _keysFor(boxName)) {
      if (boxName == 'settings' && _shouldSkipSettingInSnapshot(key)) {
        continue;
      }
      final value = _getValue(boxName, key);
      entries.add({
        'key': _encodeKey(key),
        'value': _encodeBoxValue(boxName, value),
      });
    }
    return {'entries': entries};
  }

  Future<void> _restoreBox(String boxName, Map<String, dynamic> data) async {
    final entries = data['entries'];
    if (entries is! List) {
      throw BackupException('$boxName 备份数据无效');
    }

    if (boxName != 'settings') {
      await _clearBox(boxName);
    }

    for (final entry in entries) {
      if (entry is! Map) continue;
      final key = _decodeKey(entry['key']);
      if (boxName == 'settings' && _localSettingKeys.contains(key)) {
        continue;
      }
      final value = _decodeBoxValue(boxName, entry['value']);
      await _putValue(boxName, key, value);
    }
  }

  bool _shouldSkipSettingInSnapshot(dynamic key) {
    if (_localSettingKeys.contains(key)) return true;
    if (!settings.includeSecretsInBackup && _secretSettingKeys.contains(key)) {
      return true;
    }
    return false;
  }

  Iterable<dynamic> _keysFor(String boxName) {
    switch (boxName) {
      case 'books':
        return Hive.box<BookMetadata>('books').keys;
      case 'user_vocabulary':
        return Hive.box<String>('user_vocabulary').keys;
      case 'settings':
        return Hive.box('settings').keys;
      case 'word_bookmarks':
        return Hive.box<String>('word_bookmarks').keys;
      case 'reading_bookmarks':
        return Hive.box<String>('reading_bookmarks').keys;
      case 'reading_config':
        return Hive.box<String>('reading_config').keys;
      case 'reading_time':
        return Hive.box<int>('reading_time').keys;
      case 'dictionary_cache':
        return Hive.box<String>('dictionary_cache').keys;
      case 'rss_subscriptions':
        return Hive.box<RssFeedSubscription>('rss_subscriptions').keys;
      default:
        return const [];
    }
  }

  dynamic _getValue(String boxName, dynamic key) {
    switch (boxName) {
      case 'books':
        return Hive.box<BookMetadata>('books').get(key);
      case 'user_vocabulary':
        return Hive.box<String>('user_vocabulary').get(key);
      case 'settings':
        return Hive.box('settings').get(key);
      case 'word_bookmarks':
        return Hive.box<String>('word_bookmarks').get(key);
      case 'reading_bookmarks':
        return Hive.box<String>('reading_bookmarks').get(key);
      case 'reading_config':
        return Hive.box<String>('reading_config').get(key);
      case 'reading_time':
        return Hive.box<int>('reading_time').get(key);
      case 'dictionary_cache':
        return Hive.box<String>('dictionary_cache').get(key);
      case 'rss_subscriptions':
        return Hive.box<RssFeedSubscription>('rss_subscriptions').get(key);
    }
  }

  Future<void> _clearBox(String boxName) async {
    switch (boxName) {
      case 'books':
        await Hive.box<BookMetadata>('books').clear();
        return;
      case 'user_vocabulary':
        await Hive.box<String>('user_vocabulary').clear();
        return;
      case 'word_bookmarks':
        await Hive.box<String>('word_bookmarks').clear();
        return;
      case 'reading_bookmarks':
        await Hive.box<String>('reading_bookmarks').clear();
        return;
      case 'reading_config':
        await Hive.box<String>('reading_config').clear();
        return;
      case 'reading_time':
        await Hive.box<int>('reading_time').clear();
        return;
      case 'dictionary_cache':
        await Hive.box<String>('dictionary_cache').clear();
        return;
      case 'rss_subscriptions':
        await Hive.box<RssFeedSubscription>('rss_subscriptions').clear();
        return;
    }
  }

  Future<void> _putValue(String boxName, dynamic key, dynamic value) async {
    switch (boxName) {
      case 'books':
        await Hive.box<BookMetadata>('books').put(key, value as BookMetadata);
        return;
      case 'user_vocabulary':
        await Hive.box<String>('user_vocabulary').put(key, value as String);
        return;
      case 'settings':
        await Hive.box('settings').put(key, value);
        return;
      case 'word_bookmarks':
        await Hive.box<String>('word_bookmarks').put(key, value as String);
        return;
      case 'reading_bookmarks':
        await Hive.box<String>('reading_bookmarks').put(key, value as String);
        return;
      case 'reading_config':
        await Hive.box<String>('reading_config').put(key, value as String);
        return;
      case 'reading_time':
        await Hive.box<int>('reading_time').put(key, value as int);
        return;
      case 'dictionary_cache':
        await Hive.box<String>('dictionary_cache').put(key, value as String);
        return;
      case 'rss_subscriptions':
        await Hive.box<RssFeedSubscription>(
          'rss_subscriptions',
        ).put(key, value as RssFeedSubscription);
        return;
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

  dynamic _encodeBoxValue(String boxName, dynamic value) {
    switch (boxName) {
      case 'books':
        return (value as BookMetadata).toJson();
      case 'rss_subscriptions':
        return _rssSubscriptionToJson(value as RssFeedSubscription);
      default:
        return _encodeJsonValue(value);
    }
  }

  dynamic _decodeBoxValue(String boxName, dynamic value) {
    switch (boxName) {
      case 'books':
        return BookMetadata.fromJson(_asStringKeyMap(value));
      case 'rss_subscriptions':
        return _rssSubscriptionFromJson(_asStringKeyMap(value));
      case 'reading_time':
        return (value as num).toInt();
      default:
        return value;
    }
  }

  Map<String, dynamic> _rssSubscriptionToJson(RssFeedSubscription value) {
    return {
      'url': value.url,
      'title': value.title,
      'description': value.description,
      'imageUrl': value.imageUrl,
      'lastFetchedAt': value.lastFetchedAt?.toIso8601String(),
    };
  }

  RssFeedSubscription _rssSubscriptionFromJson(Map<String, dynamic> json) {
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

  Map<String, dynamic> _asStringKeyMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    throw const BackupException('备份数据格式无效');
  }

  dynamic _encodeJsonValue(dynamic value) {
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

  String _formatTimestamp(DateTime value) {
    final iso = value.toIso8601String().split('.').first;
    return iso.replaceAll(':', '-');
  }

  @override
  void dispose() {
    settings.removeListener(_configureTimer);
    _timer?.cancel();
    super.dispose();
  }
}

String _encodeBackupPayload(Map<String, dynamic> payload) {
  return const JsonEncoder.withIndent('  ').convert(payload);
}

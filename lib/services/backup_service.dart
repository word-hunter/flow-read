import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../models/book_metadata.dart';
import '../models/rss_models.dart';
import '../models/word_context_example.dart';
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
    'word_contexts',
  ];

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

  final SettingsService settings;
  final BackupFolderAccess _folderAccess;

  Timer? _timer;
  bool _isSyncing = false;
  String? _lastError;

  BackupService(this.settings, {BackupFolderAccess? folderAccess})
    : _folderAccess = folderAccess ?? const BackupFolderAccess();

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
        final payload = createBackupPayload(createdAt: createdAt);
        final encoded = await compute(_encodeBackupPayload, payload);
        final fileName = 'flow_read_backup_${_formatTimestamp(createdAt)}.json';
        final file = File(
          '${folderAccess.path}${Platform.pathSeparator}$fileName',
        );
        await file.parent.create(recursive: true);
        await file.writeAsString(encoded, flush: true);
        await settings.setLastBackup(createdAt, file.path);
        return file.path;
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
      final vocabBox = Hive.box<String>('user_vocabulary');
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

      final contextBox = Hive.box<String>('word_contexts');
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
      case 'word_contexts':
        return Hive.box<String>('word_contexts').keys;
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
      case 'word_contexts':
        return Hive.box<String>('word_contexts').get(key);
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
      case 'word_contexts':
        await Hive.box<String>('word_contexts').clear();
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
      case 'word_contexts':
        await Hive.box<String>('word_contexts').put(key, value as String);
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

  String _formatTimestamp(DateTime value) {
    final iso = value.toIso8601String().split('.').first;
    return iso.replaceAll(':', '-');
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

String _encodeBackupPayload(Map<String, dynamic> payload) {
  return const JsonEncoder.withIndent('  ').convert(payload);
}

Map<String, dynamic> _parseWordHunterBackupSource(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map) {
    throw const FormatException('根节点不是对象');
  }
  return _asStringKeyMap(decoded);
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

  final map = _asStringKeyMap(value);
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

Map<String, dynamic> _asStringKeyMap(Map value) {
  return value.map((k, v) => MapEntry(k.toString(), v));
}

String _normalizeWord(String word) => word.toLowerCase().trim();

String _normalizeText(String text) {
  return text.replaceAll(String.fromCharCode(0x00a0), ' ').trim();
}

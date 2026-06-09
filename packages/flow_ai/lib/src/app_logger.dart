import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum AppLogLevel {
  debug,
  info,
  warning,
  error,
  fatal;

  String get label => name;
}

class AppLogger {
  AppLogger({
    Future<Directory> Function()? logDirectoryProvider,
    bool Function()? includeDebugProvider,
    DateTime Function()? clock,
    Duration retention = const Duration(days: 14),
  }) : _logDirectoryProvider =
           logDirectoryProvider ?? _defaultLogDirectoryProvider,
       _includeDebugProvider = includeDebugProvider ?? (() => kDebugMode),
       _clock = clock ?? DateTime.now,
       _retention = retention;

  static final AppLogger instance = AppLogger();

  final Future<Directory> Function() _logDirectoryProvider;
  final bool Function() _includeDebugProvider;
  final DateTime Function() _clock;
  final Duration _retention;

  Directory? _logDirectory;
  Future<void>? _initFuture;
  Future<void> _writeQueue = Future<void>.value();
  String? _appSupportPath;

  Future<void> init() {
    return _initFuture ??= _initialize();
  }

  Future<Directory> logsDirectory() async {
    await init();
    return _logDirectory!;
  }

  void event(
    String event, {
    AppLogLevel level = AppLogLevel.info,
    String? source,
    Map<String, Object?> metadata = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_shouldWrite(level)) return;

    final safeEntry = _buildEntry(
      event: event,
      level: level,
      source: source,
      metadata: metadata,
      error: error,
      stackTrace: stackTrace,
    );

    _writeQueue = _writeQueue
        .catchError((Object _) {})
        .then((_) => _writeEntry(safeEntry));
    unawaited(_writeQueue.catchError((_) {}));
  }

  Future<void> cleanupOldLogs({Duration? retention}) async {
    final directory = await logsDirectory();
    await _cleanupOldLogsInDirectory(directory, retention ?? _retention);
  }

  Future<void> _cleanupOldLogsInDirectory(
    Directory directory,
    Duration retention,
  ) async {
    final now = _clock();
    final cutoff = DateTime(now.year, now.month, now.day).subtract(retention);

    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      final fileDate = _dateFromLogFilename(entity.uri.pathSegments.last);
      if (fileDate == null || !fileDate.isBefore(cutoff)) continue;
      await entity.delete();
    }
  }

  @visibleForTesting
  Future<void> drain() => _writeQueue.catchError((Object _) {});

  static Future<Directory> _defaultLogDirectoryProvider() async {
    final supportDir = await getApplicationSupportDirectory();
    return Directory('${supportDir.path}${Platform.pathSeparator}logs');
  }

  Future<void> _initialize() async {
    final directory = await _logDirectoryProvider();
    await directory.create(recursive: true);
    _logDirectory = directory;
    _appSupportPath = directory.parent.path;
    await _cleanupOldLogsInDirectory(directory, _retention);
  }

  bool _shouldWrite(AppLogLevel level) {
    if (level == AppLogLevel.debug) return _includeDebugProvider();
    return true;
  }

  Map<String, Object?> _buildEntry({
    required String event,
    required AppLogLevel level,
    required String? source,
    required Map<String, Object?> metadata,
    required Object? error,
    required StackTrace? stackTrace,
  }) {
    final runtimeType = error?.runtimeType.toString();

    return {
      'time': _clock().toIso8601String(),
      'level': level.label,
      'source': _sanitizeIdentifier(source ?? 'app'),
      'event': _sanitizeIdentifier(event),
      'message': runtimeType == null
          ? null
          : 'Captured ${_sanitizeIdentifier(runtimeType)}',
      'errorType': runtimeType == null
          ? null
          : _sanitizeIdentifier(runtimeType),
      'metadata': _sanitizeMetadata(metadata),
      'stackTrace': stackTrace == null
          ? null
          : _sanitizeStackTrace(stackTrace.toString()),
      if (error != null) 'error': '<redacted_error_message>',
    };
  }

  Future<void> _writeEntry(Map<String, Object?> entry) async {
    final directory = await logsDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}'
      'flow_read-${_formatDate(_clock())}.log',
    );
    await file.writeAsString(
      '${jsonEncode(entry)}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  Map<String, Object?> _sanitizeMetadata(Map<String, Object?> metadata) {
    return metadata.map((key, value) {
      final safeKey = _sanitizeMetadataKey(key);
      if (_isSensitiveKey(key)) {
        return MapEntry(safeKey, '<redacted>');
      }
      if (_isContentKey(key)) {
        return MapEntry(safeKey, '<redacted_content>');
      }
      return MapEntry(safeKey, _sanitizeValue(value));
    });
  }

  Object? _sanitizeValue(Object? value) {
    if (value == null || value is num || value is bool) return value;
    if (value is DateTime) return value.toIso8601String();
    if (value is Uri) return _sanitizeString(value.toString());
    if (value is String) return _sanitizeString(value);
    if (value is Iterable) {
      return value.map(_sanitizeValue).toList(growable: false);
    }
    if (value is Map) {
      return value.map((key, mapValue) {
        final safeKey = _sanitizeMetadataKey(key.toString());
        if (_isSensitiveKey(key.toString())) {
          return MapEntry(safeKey, '<redacted>');
        }
        if (_isContentKey(key.toString())) {
          return MapEntry(safeKey, '<redacted_content>');
        }
        return MapEntry(safeKey, _sanitizeValue(mapValue));
      });
    }
    return '<${_sanitizeIdentifier(value.runtimeType.toString())}>';
  }

  String _sanitizeStackTrace(String value) {
    final lines = _sanitizeString(value).split('\n').take(40).toList();
    final text = lines.join('\n');
    if (text.length <= 12000) return text;
    return '${text.substring(0, 12000)}\n<truncated>';
  }

  String _sanitizeString(String value) {
    var sanitized = value;
    sanitized = _redactHttpUrlQuery(sanitized);
    sanitized = _redactLocalPaths(sanitized);
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'\bBearer\s+[A-Za-z0-9._~+/=-]+', caseSensitive: false),
      (match) => '${match.group(0)!.split(RegExp(r'\s+')).first} <redacted>',
    );
    sanitized = sanitized.replaceAllMapped(
      RegExp(
        r'\b(api[_ -]?key|authorization|password|token|secret|'
        r'access[_ -]?token|refresh[_ -]?token)\b\s*[:=]\s*'
        r"""["']?[^"'\s,;&}]+""",
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}=<redacted>',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'\b(?:sk|pk|rk)-[A-Za-z0-9_-]{12,}\b'),
      '<redacted_token>',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'\b[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b'),
      '<redacted_token>',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'\b[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}\b'),
      '<redacted_email>',
    );
    return sanitized;
  }

  String _redactHttpUrlQuery(String value) {
    return value.replaceAllMapped(RegExp(r"""https?:\/\/[^\s<>"']+"""), (
      match,
    ) {
      final uri = Uri.tryParse(match.group(0)!);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        return '<redacted_url>';
      }
      final buffer = StringBuffer('${uri.scheme}://${uri.host}');
      if (uri.hasPort) buffer.write(':${uri.port}');
      buffer.write(uri.path);
      return buffer.toString();
    });
  }

  String _redactLocalPaths(String value) {
    var sanitized = value;
    final supportPath = _appSupportPath;
    if (supportPath != null && supportPath.isNotEmpty) {
      sanitized = sanitized.replaceAll(
        RegExp("""${RegExp.escape(supportPath)}[^\\s,;\\)\\]\\}"']*"""),
        '<app_support>',
      );
    }
    sanitized = sanitized.replaceAll(
      RegExp(r"""file:\/\/\/[^\s,;)\]}"']+"""),
      '<local_path>',
    );
    sanitized = sanitized.replaceAll(
      RegExp(
        r'\/(?:Users|private|var|tmp|Volumes|Applications|Library)\/'
        r"""[^\s,;)\]}"']+""",
      ),
      '<local_path>',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r"""[A-Za-z]:\\[^\s,;)\]}"']+"""),
      '<local_path>',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r"""~\/[^\s,;)\]}"']+"""),
      '<local_path>',
    );
    return sanitized;
  }

  bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return {
      'apikey',
      'authorization',
      'password',
      'token',
      'secret',
      'accesstoken',
      'refreshtoken',
      'bearertoken',
      'bookmark',
    }.contains(normalized);
  }

  bool _isContentKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return {
      'text',
      'selectedtext',
      'chaptertext',
      'context',
      'contextbefore',
      'contextafter',
      'prompt',
      'systemprompt',
      'userprompt',
      'response',
      'content',
      'body',
      'source',
      'sentence',
      'booktitle',
      'title',
      'description',
      'filename',
      'filepath',
      'path',
    }.contains(normalized);
  }

  String _sanitizeMetadataKey(String key) {
    final sanitized = _sanitizeString(key)
        .replaceAll(RegExp(r'[^A-Za-z0-9_.:-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    if (sanitized.isEmpty) return 'metadata';
    return sanitized.length <= 64 ? sanitized : sanitized.substring(0, 64);
  }

  String _sanitizeIdentifier(String value) {
    final sanitized = _sanitizeString(value)
        .replaceAll(RegExp(r'[^A-Za-z0-9_.:-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    if (sanitized.isEmpty) return 'unknown';
    return sanitized.length <= 80 ? sanitized : sanitized.substring(0, 80);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime? _dateFromLogFilename(String filename) {
    final match = RegExp(
      r'^flow_read-(\d{4})-(\d{2})-(\d{2})\.log$',
    ).firstMatch(filename);
    if (match == null) return null;
    return DateTime.tryParse(
      '${match.group(1)}-${match.group(2)}-${match.group(3)}',
    );
  }
}

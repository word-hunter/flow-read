import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AIDebugTraceConfig {
  static const key = 'FLOW_AI_DEBUG_TRACE';
  static const enabled =
      bool.fromEnvironment(key) && !bool.fromEnvironment('dart.vm.product');

  const AIDebugTraceConfig._();
}

class AIDebugTraceRecorder {
  AIDebugTraceRecorder({
    required this.enabled,
    Future<Directory> Function()? directoryProvider,
    DateTime Function()? clock,
    this.filePrefix = 'flow_read_ai_trace',
  }) : _directoryProvider = directoryProvider ?? _defaultDirectoryProvider,
       _clock = clock ?? DateTime.now;

  static final AIDebugTraceRecorder instance = AIDebugTraceRecorder(
    enabled: AIDebugTraceConfig.enabled,
  );

  final bool enabled;
  final String filePrefix;
  final Future<Directory> Function() _directoryProvider;
  final DateTime Function() _clock;

  Future<void> _writeQueue = Future<void>.value();
  final Set<String> _announcedPaths = <String>{};

  void recordHttpInteraction({
    required String operation,
    required String method,
    required Uri url,
    required Map<String, String> requestHeaders,
    required Object? requestBody,
    Map<String, String> responseHeaders = const {},
    Object? responseBody,
    int? statusCode,
    required int durationMs,
    bool stream = false,
    Map<String, Object?> metadata = const {},
    Object? error,
  }) {
    recordEvent(
      'http_interaction',
      data: {
        'operation': operation,
        'method': method,
        'url': url.toString(),
        'stream': stream,
        'durationMs': durationMs,
        'success': error == null && statusCode != null && statusCode < 400,
        'statusCode': statusCode,
        'request': {
          'headers': _sanitizeHeaders(requestHeaders),
          'body': requestBody,
        },
        'response': {
          'headers': _sanitizeHeaders(responseHeaders),
          'body': responseBody,
        },
        if (metadata.isNotEmpty) 'metadata': metadata,
        if (error != null)
          'error': {
            'type': error.runtimeType.toString(),
            'message': error.toString(),
          },
      },
    );
  }

  void recordCacheHit({
    required String action,
    required Object? cacheKey,
    required Object? prompt,
    required String response,
    Map<String, Object?> metadata = const {},
  }) {
    recordEvent(
      'cache_hit',
      data: {
        'action': action,
        'cacheKey': cacheKey,
        'prompt': prompt,
        'response': response,
        if (metadata.isNotEmpty) 'metadata': metadata,
      },
    );
  }

  void recordEvent(String event, {Map<String, Object?> data = const {}}) {
    if (!enabled) return;

    final entry = <String, Object?>{
      'schemaVersion': 1,
      'time': _clock().toIso8601String(),
      'source': 'flow_read.ai_debug',
      'event': event,
      ..._sanitizeMap(data),
    };

    _writeQueue = _writeQueue
        .catchError((Object _) {})
        .then((_) => _writeEntry(entry));
    unawaited(_writeQueue.catchError((Object _) {}));
  }

  Future<void> drain() => _writeQueue.catchError((Object _) {});

  Future<void> _writeEntry(Map<String, Object?> entry) async {
    final directory = await _directoryProvider();
    await directory.create(recursive: true);
    final file = File(
      '${directory.path}${Platform.pathSeparator}'
      '$filePrefix-${_formatDate(_clock())}.jsonl',
    );
    if (_announcedPaths.add(file.path)) {
      stdout.writeln('[FlowRead][AI Debug] trace file: ${file.path}');
      stdout.writeln('[FlowRead][AI Debug] viewer: make ai-debug-viewer');
    }
    await file.writeAsString(
      '${jsonEncode(entry)}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  static Future<Directory> _defaultDirectoryProvider() async {
    final supportDir = await getApplicationSupportDirectory();
    return Directory('${supportDir.path}${Platform.pathSeparator}ai_debug');
  }

  Map<String, Object?> _sanitizeHeaders(Map<String, String> headers) {
    return headers.map((key, value) {
      if (_isSensitiveKey(key)) {
        return MapEntry(key, '<redacted>');
      }
      return MapEntry(key, _redactSecrets(value));
    });
  }

  Map<String, Object?> _sanitizeMap(Map<String, Object?> values) {
    return values.map((key, value) {
      if (_isSensitiveKey(key)) {
        return MapEntry(key, '<redacted>');
      }
      return MapEntry(key, _sanitizeValue(value));
    });
  }

  Object? _sanitizeValue(Object? value) {
    if (value == null || value is num || value is bool) return value;
    if (value is DateTime) return value.toIso8601String();
    if (value is Uri) return _redactSecrets(value.toString());
    if (value is String) return _redactSecrets(value);
    if (value is Iterable) {
      return value.map(_sanitizeValue).toList(growable: false);
    }
    if (value is Map) {
      return value.map((key, mapValue) {
        final safeKey = key.toString();
        if (_isSensitiveKey(safeKey)) {
          return MapEntry(safeKey, '<redacted>');
        }
        return MapEntry(safeKey, _sanitizeValue(mapValue));
      });
    }
    return _redactSecrets(value.toString());
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
      'cookie',
      'setcookie',
      'xapikey',
    }.contains(normalized);
  }

  String _redactSecrets(String value) {
    var sanitized = value;
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'\bBearer\s+[A-Za-z0-9._~+/=-]+', caseSensitive: false),
      (match) => '${match.group(0)!.split(RegExp(r'\s+')).first} <redacted>',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'\b(?:sk|pk|rk)-[A-Za-z0-9_-]{12,}\b'),
      '<redacted_token>',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'\b[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b'),
      '<redacted_token>',
    );
    return sanitized;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

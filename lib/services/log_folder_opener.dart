import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_logger.dart';

enum LogFolderOpenPlatform { macOS, windows, linux, unsupported }

class LogFolderOpener {
  LogFolderOpener({
    AppLogger? logger,
    MethodChannel? channel,
    Future<ProcessResult> Function(String executable, List<String> arguments)?
    processRunner,
    LogFolderOpenPlatform? platform,
    bool? isWeb,
  }) : _logger = logger ?? AppLogger.instance,
       _channel = channel ?? const MethodChannel('flow_read/external_url'),
       _processRunner = processRunner ?? Process.run,
       _platform = platform ?? _currentPlatform(),
       _isWeb = isWeb ?? kIsWeb;

  final AppLogger _logger;
  final MethodChannel _channel;
  final Future<ProcessResult> Function(
    String executable,
    List<String> arguments,
  )
  _processRunner;
  final LogFolderOpenPlatform _platform;
  final bool _isWeb;

  Future<String> logsFolderPath() async {
    final directory = await _logger.logsDirectory();
    return directory.path;
  }

  Future<void> openLogsFolder() async {
    if (_isWeb) {
      throw const LogFolderOpenException('当前平台不支持打开日志文件夹');
    }

    final path = await logsFolderPath();
    await Directory(path).create(recursive: true);

    if (_platform == LogFolderOpenPlatform.macOS) {
      try {
        await _channel.invokeMethod<void>('openPath', {'path': path});
        _logger.event(
          'logs_folder.opened',
          source: 'log_folder_opener',
          metadata: const {'platform': 'macos'},
        );
        return;
      } on MissingPluginException {
        await _openWithPlatformCommand('open', [path]);
        return;
      } on PlatformException catch (error, stackTrace) {
        _logger.event(
          'logs_folder.open_failed',
          level: AppLogLevel.warning,
          source: 'log_folder_opener',
          metadata: const {'platform': 'macos'},
          error: error,
          stackTrace: stackTrace,
        );
        throw LogFolderOpenException(error.message ?? '打开日志文件夹失败');
      }
    }

    if (_platform == LogFolderOpenPlatform.windows) {
      await _openWithPlatformCommand('explorer', [path]);
      return;
    }

    if (_platform == LogFolderOpenPlatform.linux) {
      await _openWithPlatformCommand('xdg-open', [path]);
      return;
    }

    throw const LogFolderOpenException('当前平台不支持打开日志文件夹');
  }

  Future<void> _openWithPlatformCommand(
    String executable,
    List<String> arguments,
  ) async {
    try {
      final result = await _processRunner(executable, arguments);
      if (result.exitCode == 0) {
        _logger.event(
          'logs_folder.opened',
          source: 'log_folder_opener',
          metadata: {'command': executable},
        );
        return;
      }
      throw LogFolderOpenException('打开日志文件夹失败：$executable');
    } on ProcessException catch (error, stackTrace) {
      _logger.event(
        'logs_folder.open_failed',
        level: AppLogLevel.warning,
        source: 'log_folder_opener',
        metadata: {'command': executable},
        error: error,
        stackTrace: stackTrace,
      );
      throw LogFolderOpenException('打开日志文件夹失败：${error.message}');
    }
  }

  static LogFolderOpenPlatform _currentPlatform() {
    if (Platform.isMacOS) return LogFolderOpenPlatform.macOS;
    if (Platform.isWindows) return LogFolderOpenPlatform.windows;
    if (Platform.isLinux) return LogFolderOpenPlatform.linux;
    return LogFolderOpenPlatform.unsupported;
  }
}

class LogFolderOpenException implements Exception {
  const LogFolderOpenException(this.message);

  final String message;

  @override
  String toString() => message;
}

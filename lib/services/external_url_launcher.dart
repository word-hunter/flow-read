import 'dart:io';

import 'package:flutter/services.dart';

class ExternalUrlLauncher {
  const ExternalUrlLauncher();

  static const MethodChannel _channel = MethodChannel('flow_read/external_url');

  Future<void> open(Uri uri) async {
    _validateUrl(uri);

    if (Platform.isMacOS) {
      try {
        await _channel.invokeMethod<void>('openExternalUrl', {
          'url': uri.toString(),
        });
      } on PlatformException catch (error) {
        throw ExternalUrlOpenException(error.message ?? '打开链接失败');
      }
      return;
    }

    await _openWithPlatformCommand(uri);
  }

  static void _validateUrl(Uri uri) {
    if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const ExternalUrlOpenException('只支持打开 http 或 https 链接');
    }
  }

  static Future<void> _openWithPlatformCommand(Uri uri) async {
    final url = uri.toString();
    final executable = Platform.isWindows
        ? 'rundll32'
        : Platform.isLinux
        ? 'xdg-open'
        : 'open';
    final arguments = Platform.isWindows
        ? ['url.dll,FileProtocolHandler', url]
        : [url];

    try {
      final process = await Process.start(executable, arguments);
      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        throw ExternalUrlOpenException('打开链接失败：$url');
      }
    } on ProcessException catch (error) {
      throw ExternalUrlOpenException('打开链接失败：${error.message}');
    }
  }
}

class ExternalUrlOpenException implements Exception {
  const ExternalUrlOpenException(this.message);

  final String message;

  @override
  String toString() => message;
}

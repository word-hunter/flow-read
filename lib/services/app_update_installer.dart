import 'dart:io';

import 'package:flutter/services.dart';

class AppUpdateInstaller {
  const AppUpdateInstaller();

  static const MethodChannel _channel = MethodChannel('flow_read/app_update');

  Future<void> installUpdate(String appPath) async {
    if (!Platform.isMacOS) {
      throw AppUpdateInstallException('当前平台不支持自动安装');
    }

    final appDir = Directory(appPath);
    if (!appDir.existsSync()) {
      throw AppUpdateInstallException('更新包未找到：$appPath');
    }

    try {
      await _channel.invokeMethod<void>('installUpdate', {
        'appPath': appPath,
      });
    } on PlatformException catch (error) {
      throw AppUpdateInstallException(error.message ?? '安装更新失败');
    }
  }
}

class AppUpdateInstallException implements Exception {
  const AppUpdateInstallException(this.message);

  final String message;

  @override
  String toString() => message;
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'backup_folder_access.dart';

enum PermissionDiagnosticStatus { ok, warning, error, unknown }

class PermissionDiagnostic {
  final String name;
  final String description;
  final PermissionDiagnosticStatus status;
  final String? detail;
  final String? fixAction;

  const PermissionDiagnostic({
    required this.name,
    required this.description,
    required this.status,
    this.detail,
    this.fixAction,
  });
}

typedef NetworkStatusProbe = Future<int> Function();
typedef BackupFolderProbe = Future<bool> Function(String path, String bookmark);

class MacPermissionDiagnostics {
  MacPermissionDiagnostics({
    BackupFolderAccess backupFolderAccess = const BackupFolderAccess(),
    NetworkStatusProbe? networkStatusProbe,
    BackupFolderProbe? backupFolderProbe,
    bool Function()? isMacOSProvider,
  }) : _backupFolderAccess = backupFolderAccess,
       _networkStatusProbe = networkStatusProbe ?? _defaultNetworkStatusProbe,
       _backupFolderProbe =
           backupFolderProbe ??
           ((path, bookmark) =>
               _defaultBackupFolderProbe(backupFolderAccess, path, bookmark)),
       _isMacOSProvider =
           isMacOSProvider ?? (() => !kIsWeb && Platform.isMacOS);

  final BackupFolderAccess _backupFolderAccess;
  final NetworkStatusProbe _networkStatusProbe;
  final BackupFolderProbe _backupFolderProbe;
  final bool Function() _isMacOSProvider;

  bool get isMacOS => _isMacOSProvider();

  Future<List<PermissionDiagnostic>> diagnose({
    required String backupFolderPath,
    required String backupFolderBookmark,
  }) async {
    if (!isMacOS) return const [];
    return [
      await _checkNetworkPermission(),
      await _checkBackupFolderPermission(
        backupFolderPath: backupFolderPath,
        backupFolderBookmark: backupFolderBookmark,
      ),
      _checkSandboxStatus(),
    ];
  }

  Future<PermissionDiagnostic> _checkNetworkPermission() async {
    try {
      final statusCode = await _networkStatusProbe();
      if (statusCode >= 200 && statusCode < 400) {
        return const PermissionDiagnostic(
          name: '网络访问',
          description: '应用可以正常访问互联网',
          status: PermissionDiagnosticStatus.ok,
        );
      }
      return PermissionDiagnostic(
        name: '网络访问',
        description: '网络请求返回异常状态',
        detail: 'HTTP $statusCode',
        status: PermissionDiagnosticStatus.warning,
      );
    } catch (error) {
      return PermissionDiagnostic(
        name: '网络访问',
        description: '无法连接互联网',
        detail: error.toString(),
        status: PermissionDiagnosticStatus.error,
        fixAction: '检查网络、代理设置和应用网络权限',
      );
    }
  }

  Future<PermissionDiagnostic> _checkBackupFolderPermission({
    required String backupFolderPath,
    required String backupFolderBookmark,
  }) async {
    final path = backupFolderPath.trim();
    if (path.isEmpty) {
      return const PermissionDiagnostic(
        name: '备份文件夹访问',
        description: '未配置备份文件夹',
        status: PermissionDiagnosticStatus.unknown,
      );
    }
    if (_backupFolderAccess.requiresPersistentAccess &&
        backupFolderBookmark.trim().isEmpty) {
      return const PermissionDiagnostic(
        name: '备份文件夹访问',
        description: '需要重新授权备份文件夹',
        status: PermissionDiagnosticStatus.error,
        fixAction: '重新授权',
      );
    }

    try {
      final accessible = await _backupFolderProbe(path, backupFolderBookmark);
      if (!accessible) {
        return const PermissionDiagnostic(
          name: '备份文件夹访问',
          description: '备份文件夹不存在或不可访问',
          status: PermissionDiagnosticStatus.error,
          fixAction: '重新授权',
        );
      }
      return const PermissionDiagnostic(
        name: '备份文件夹访问',
        description: '备份文件夹授权有效',
        status: PermissionDiagnosticStatus.ok,
      );
    } catch (error) {
      return PermissionDiagnostic(
        name: '备份文件夹访问',
        description: '备份文件夹授权不可用',
        detail: error.toString(),
        status: PermissionDiagnosticStatus.error,
        fixAction: '重新授权',
      );
    }
  }

  PermissionDiagnostic _checkSandboxStatus() {
    return const PermissionDiagnostic(
      name: '应用沙盒',
      description: 'macOS 沙盒应用',
      detail: '网络和文件访问由 entitlements 与安全作用域授权控制',
      status: PermissionDiagnosticStatus.ok,
    );
  }

  static Future<int> _defaultNetworkStatusProbe() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(Uri.parse('https://www.apple.com'));
      final response = await request.close();
      unawaited(response.drain<void>());
      return response.statusCode;
    } finally {
      client.close(force: true);
    }
  }

  static Future<bool> _defaultBackupFolderProbe(
    BackupFolderAccess access,
    String path,
    String bookmark,
  ) async {
    BackupFolderAccessHandle? handle;
    try {
      handle = await access.startAccessing(path: path, bookmark: bookmark);
      return Directory(handle.path).exists();
    } finally {
      await handle?.stopAccessing();
    }
  }
}

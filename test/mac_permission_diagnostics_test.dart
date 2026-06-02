import 'dart:io';

import 'package:flow_read/services/mac_permission_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns no diagnostics outside macOS', () async {
    final diagnostics = MacPermissionDiagnostics(
      isMacOSProvider: () => false,
      networkStatusProbe: () async => 200,
    );

    final results = await diagnostics.diagnose(
      backupFolderPath: '',
      backupFolderBookmark: '',
    );

    expect(results, isEmpty);
  });

  test('reports network and backup states on macOS', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'flow_read_mac_permission_test_',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });
    final diagnostics = MacPermissionDiagnostics(
      isMacOSProvider: () => true,
      networkStatusProbe: () async => 204,
      backupFolderProbe: (path, bookmark) async => Directory(path).exists(),
    );

    final results = await diagnostics.diagnose(
      backupFolderPath: tempDir.path,
      backupFolderBookmark: 'bookmark',
    );

    expect(results.map((item) => item.name), ['网络访问', '备份文件夹访问', '应用沙盒']);
    expect(results[0].status, PermissionDiagnosticStatus.ok);
    expect(results[1].status, PermissionDiagnosticStatus.ok);
    expect(results[2].status, PermissionDiagnosticStatus.ok);
  });

  test('reports network probe failures', () async {
    final diagnostics = MacPermissionDiagnostics(
      isMacOSProvider: () => true,
      networkStatusProbe: () async => throw StateError('offline'),
    );

    final results = await diagnostics.diagnose(
      backupFolderPath: '',
      backupFolderBookmark: '',
    );

    expect(results.first.name, '网络访问');
    expect(results.first.status, PermissionDiagnosticStatus.error);
    expect(results.first.detail, contains('offline'));
    expect(results[1].status, PermissionDiagnosticStatus.unknown);
  });
}

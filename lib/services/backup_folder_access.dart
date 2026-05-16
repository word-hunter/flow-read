import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BackupFolderSelection {
  final String path;
  final String? bookmark;

  const BackupFolderSelection({required this.path, this.bookmark});
}

class BackupFolderAccessHandle {
  final String path;
  final bool _scoped;
  final BackupFolderAccess _access;

  const BackupFolderAccessHandle._({
    required this.path,
    required bool scoped,
    required BackupFolderAccess access,
  }) : _scoped = scoped,
       _access = access;

  Future<void> stopAccessing() => _access._stopAccessing(this);
}

class BackupFolderAccess {
  static const _channel = MethodChannel('flow_read/backup_folder_access');

  const BackupFolderAccess();

  bool get requiresPersistentAccess => !kIsWeb && Platform.isMacOS;

  Future<BackupFolderSelection?> chooseDirectory({
    String? dialogTitle,
    String? initialDirectory,
  }) async {
    if (requiresPersistentAccess) {
      try {
        final result = await _channel.invokeMapMethod<String, Object?>(
          'chooseBackupFolder',
          <String, Object?>{
            'dialogTitle': dialogTitle,
            'initialDirectory': initialDirectory,
          },
        );
        final path = (result?['path'] as String?)?.trim();
        if (path == null || path.isEmpty) return null;
        return BackupFolderSelection(
          path: path,
          bookmark: result?['bookmark'] as String?,
        );
      } on MissingPluginException {
        // Unit tests and non-macOS runners do not register the native channel.
      }
    }

    final path = await FilePicker.getDirectoryPath(
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
    );
    if (path == null || path.trim().isEmpty) return null;
    return BackupFolderSelection(path: path.trim());
  }

  Future<BackupFolderAccessHandle> startAccessing({
    required String path,
    String? bookmark,
  }) async {
    if (!requiresPersistentAccess || bookmark == null || bookmark.isEmpty) {
      return BackupFolderAccessHandle._(
        path: path,
        scoped: false,
        access: this,
      );
    }

    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'startAccessingBackupFolder',
        <String, Object?>{'path': path, 'bookmark': bookmark},
      );
      final resolvedPath = (result?['path'] as String?)?.trim();
      return BackupFolderAccessHandle._(
        path: resolvedPath == null || resolvedPath.isEmpty
            ? path
            : resolvedPath,
        scoped: result?['started'] == true,
        access: this,
      );
    } on MissingPluginException {
      return BackupFolderAccessHandle._(
        path: path,
        scoped: false,
        access: this,
      );
    }
  }

  Future<void> _stopAccessing(BackupFolderAccessHandle handle) async {
    if (!requiresPersistentAccess || !handle._scoped) return;

    try {
      await _channel.invokeMethod<void>(
        'stopAccessingBackupFolder',
        <String, Object?>{'path': handle.path},
      );
    } on MissingPluginException {
      // Nothing to release when the native side is not present.
    }
  }
}

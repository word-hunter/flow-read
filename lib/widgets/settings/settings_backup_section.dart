import 'package:flutter/material.dart';

import '../../services/backup_service.dart';
import '../../services/settings_service.dart';
import '../flow/flow_components.dart';
import 'settings_shared.dart';

class SettingsBackupSection extends StatelessWidget {
  const SettingsBackupSection({
    super.key,
    required this.settings,
    required this.backup,
    required this.importingWordHunter,
    required this.onChooseFolder,
    required this.onExportBackup,
    required this.onImportBackup,
    required this.onImportWordHunter,
  });

  final SettingsService settings;
  final BackupService backup;
  final bool importingWordHunter;
  final VoidCallback onChooseFolder;
  final VoidCallback onExportBackup;
  final VoidCallback onImportBackup;
  final VoidCallback onImportWordHunter;

  static const _backupIntervals = <int>[60, 360, 1440];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFolder = settings.backupFolderPath.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveSettingsGrid(
          children: [
            SettingsCard(
              icon: Icons.sync_outlined,
              title: '自动同步',
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.sync_outlined),
                    title: const Text('自动同步'),
                    subtitle: const Text('开启后按设定间隔同步本地数据'),
                    value: settings.backupEnabled,
                    onChanged: settings.setBackupEnabled,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue:
                        _backupIntervals.contains(
                          settings.backupIntervalMinutes,
                        )
                        ? settings.backupIntervalMinutes
                        : SettingsService.defaultBackupIntervalMinutes,
                    decoration: const InputDecoration(
                      labelText: '同步间隔',
                      prefixIcon: Icon(Icons.schedule_outlined, size: 20),
                      border: OutlineInputBorder(),
                    ),
                    items: _backupIntervals
                        .map(
                          (minutes) => DropdownMenuItem(
                            value: minutes,
                            child: Text(_formatInterval(minutes)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        settings.setBackupIntervalMinutes(value);
                      }
                    },
                  ),
                ],
              ),
            ),
            SettingsCard(
              icon: Icons.inventory_2_outlined,
              title: '备份内容',
              child: Column(
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.check_circle_outline),
                    title: const Text('应用数据'),
                    subtitle: const Text('书籍文件、封面、词汇、书签、RSS 和阅读进度'),
                    value: true,
                    onChanged: null,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.key_outlined),
                    title: const Text('API Key'),
                    subtitle: const Text('关闭时备份不会保存你的 API Key'),
                    value: settings.includeSecretsInBackup,
                    onChanged: (value) {
                      settings.setIncludeSecretsInBackup(value ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SettingsCard(
          icon: Icons.folder_outlined,
          title: '备份路径',
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasFolder ? settings.backupFolderPath : '未选择备份路径',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: hasFolder
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              FlowButton.secondary(
                onPressed: onChooseFolder,
                icon: const Icon(Icons.drive_folder_upload_outlined),
                child: Text(hasFolder ? '更改位置' : '选择位置'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsCard(
          icon: Icons.flash_on_outlined,
          title: '手动操作',
          child: Align(
            alignment: Alignment.centerLeft,
            child: FlowButton.primary(
              onPressed: !hasFolder || backup.isSyncing ? null : onExportBackup,
              icon: backup.isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              child: Text(backup.isSyncing ? '同步中...' : '立即备份'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SettingsCard(
          icon: Icons.download_outlined,
          title: '导入与恢复',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FlowButton.secondary(
                onPressed: backup.isSyncing ? null : onImportBackup,
                icon: const Icon(Icons.upload_file_outlined),
                child: const Text('导入备份'),
              ),
              FlowButton.secondary(
                onPressed: backup.isSyncing || importingWordHunter
                    ? null
                    : onImportWordHunter,
                icon: importingWordHunter
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.school_outlined),
                child: Text(
                  importingWordHunter ? '导入中...' : '导入 Word Hunter 备份',
                ),
              ),
            ],
          ),
        ),
        if (settings.lastBackupAt != null || backup.lastError != null) ...[
          const SizedBox(height: 16),
          SettingsCard(
            icon: backup.lastError == null
                ? Icons.history_outlined
                : Icons.error_outline,
            title: backup.lastError == null ? '同步记录' : '同步失败',
            child: SettingsStatusLine(
              icon: backup.lastError == null
                  ? Icons.access_time_outlined
                  : Icons.error_outline,
              text:
                  backup.lastError ??
                  '上次同步：${_formatDateTime(settings.lastBackupAt!)}',
              color: backup.lastError == null
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  static String _formatInterval(int minutes) {
    if (minutes < 60) return '$minutes 分钟';
    if (minutes == 1440) return '每天';
    return '${minutes ~/ 60} 小时';
  }

  static String _formatDateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
  }
}

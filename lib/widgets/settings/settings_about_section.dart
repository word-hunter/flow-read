import 'package:flutter/material.dart';

import '../../services/app_links.dart';
import '../../services/app_update_service.dart';
import '../../services/app_version.dart';
import '../../services/mac_permission_diagnostics.dart';
import 'settings_shared.dart';

class SettingsAboutSection extends StatelessWidget {
  SettingsAboutSection({
    super.key,
    required this.onShowReleaseNotes,
    required this.onCheckForUpdates,
    required this.checkingForUpdate,
    required this.updateStatusMessage,
    required this.updateStatusIsError,
    required this.updateFallbackActionLabel,
    required this.onOpenUpdateFallback,
    required this.availableUpdate,
    required this.onDownloadUpdate,
    this.downloadingUpdate = false,
    this.downloadProgress = 0,
    this.installedAppPath,
    this.installingUpdate = false,
    this.onInstallUpdate,
    required this.onOpenUpdateReleasePage,
    required this.onOpenLogsFolder,
    required this.onExportDiagnostics,
    this.exportingDiagnostics = false,
    required this.backupFolderPath,
    required this.backupFolderBookmark,
    required this.onReauthorizeBackupFolder,
    MacPermissionDiagnostics? macPermissionDiagnostics,
    required this.onOpenRepository,
    required this.onOpenIssueFeedback,
  }) : macPermissionDiagnostics =
           macPermissionDiagnostics ?? MacPermissionDiagnostics();

  final VoidCallback onShowReleaseNotes;
  final VoidCallback onCheckForUpdates;
  final bool checkingForUpdate;
  final String? updateStatusMessage;
  final bool updateStatusIsError;
  final String? updateFallbackActionLabel;
  final VoidCallback? onOpenUpdateFallback;
  final AppUpdateInfo? availableUpdate;
  final VoidCallback? onDownloadUpdate;
  final bool downloadingUpdate;
  final double downloadProgress;
  final String? installedAppPath;
  final bool installingUpdate;
  final VoidCallback? onInstallUpdate;
  final VoidCallback? onOpenUpdateReleasePage;
  final VoidCallback onOpenLogsFolder;
  final VoidCallback onExportDiagnostics;
  final bool exportingDiagnostics;
  final String backupFolderPath;
  final String backupFolderBookmark;
  final VoidCallback onReauthorizeBackupFolder;
  final MacPermissionDiagnostics macPermissionDiagnostics;
  final VoidCallback onOpenRepository;
  final VoidCallback onOpenIssueFeedback;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AboutHeroCard(
          checkingForUpdate: checkingForUpdate,
          updateStatusMessage: updateStatusMessage,
          updateStatusIsError: updateStatusIsError,
          availableUpdate: availableUpdate,
          updateFallbackActionLabel: updateFallbackActionLabel,
          onOpenUpdateFallback: onOpenUpdateFallback,
          onCheckForUpdates: onCheckForUpdates,
          onShowReleaseNotes: onShowReleaseNotes,
        ),
        if (availableUpdate != null) ...[
          const SizedBox(height: 20),
          _AvailableUpdateCard(
            update: availableUpdate!,
            onDownloadUpdate: onDownloadUpdate,
            downloadingUpdate: downloadingUpdate,
            downloadProgress: downloadProgress,
            installedAppPath: installedAppPath,
            installingUpdate: installingUpdate,
            onInstallUpdate: onInstallUpdate,
            onOpenReleasePage: onOpenUpdateReleasePage,
          ),
        ],
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              SettingsCard(
                icon: Icons.account_tree_outlined,
                title: '项目与反馈',
                child: _ProjectFeedbackContent(
                  onOpenRepository: onOpenRepository,
                  onOpenIssueFeedback: onOpenIssueFeedback,
                ),
              ),
              SettingsCard(
                icon: Icons.plagiarism_outlined,
                title: '诊断日志',
                child: _DiagnosticsContent(
                  onOpenLogsFolder: onOpenLogsFolder,
                  onExportDiagnostics: onExportDiagnostics,
                  exportingDiagnostics: exportingDiagnostics,
                ),
              ),
            ];

            if (constraints.maxWidth < 720) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: settingsChildrenWithSpacing(
                  cards,
                  const SizedBox(height: 16),
                ),
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < cards.length; index++) ...[
                    if (index > 0) const SizedBox(width: 20),
                    Expanded(child: cards[index]),
                  ],
                ],
              ),
            );
          },
        ),
        if (macPermissionDiagnostics.isMacOS) ...[
          const SizedBox(height: 20),
          SettingsCard(
            icon: Icons.security_outlined,
            title: '系统权限状态',
            child: _MacPermissionDiagnosticsContent(
              diagnostics: macPermissionDiagnostics,
              backupFolderPath: backupFolderPath,
              backupFolderBookmark: backupFolderBookmark,
              onReauthorizeBackupFolder: onReauthorizeBackupFolder,
            ),
          ),
        ],
      ],
    );
  }
}
class _AboutHeroCard extends StatelessWidget {
  const _AboutHeroCard({
    required this.checkingForUpdate,
    required this.updateStatusMessage,
    required this.updateStatusIsError,
    required this.availableUpdate,
    required this.updateFallbackActionLabel,
    required this.onOpenUpdateFallback,
    required this.onCheckForUpdates,
    required this.onShowReleaseNotes,
  });

  final bool checkingForUpdate;
  final String? updateStatusMessage;
  final bool updateStatusIsError;
  final AppUpdateInfo? availableUpdate;
  final String? updateFallbackActionLabel;
  final VoidCallback? onOpenUpdateFallback;
  final VoidCallback onCheckForUpdates;
  final VoidCallback onShowReleaseNotes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = _statusFor(theme);

    return Material(
      color: Color.alphaBlend(
        colorScheme.primaryContainer.withValues(alpha: 0.12),
        colorScheme.surfaceContainerLowest,
      ),
      elevation: 1,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.05),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final identity = _AboutIdentity(status: status, compact: compact);
            final actions = _AboutActions(
              checkingForUpdate: checkingForUpdate,
              updateFallbackActionLabel: updateFallbackActionLabel,
              onOpenUpdateFallback: onOpenUpdateFallback,
              onCheckForUpdates: onCheckForUpdates,
              onShowReleaseNotes: onShowReleaseNotes,
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [identity, const SizedBox(height: 24), actions],
              );
            }

            return Row(
              children: [
                Expanded(child: identity),
                Container(
                  width: 1,
                  height: 128,
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  color: colorScheme.outlineVariant.withValues(alpha: 0.75),
                ),
                SizedBox(width: 240, child: actions),
              ],
            );
          },
        ),
      ),
    );
  }

  _AboutStatusData _statusFor(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    if (checkingForUpdate) {
      return _AboutStatusData(
        icon: Icons.sync,
        label: '正在检查更新...',
        color: colorScheme.primary,
      );
    }
    if (updateStatusMessage != null) {
      return _AboutStatusData(
        icon: updateStatusIsError
            ? Icons.error_outline
            : Icons.check_circle_outline,
        label: updateStatusMessage!,
        color: updateStatusIsError ? colorScheme.error : colorScheme.primary,
      );
    }
    if (availableUpdate != null) {
      return _AboutStatusData(
        icon: Icons.download_for_offline_outlined,
        label: '发现新版本 ${availableUpdate!.version}',
        color: colorScheme.tertiary,
      );
    }
    return _AboutStatusData(
      icon: Icons.info_outline,
      label: '当前安装版本',
      color: colorScheme.primary,
    );
  }
}
class _AboutIdentity extends StatelessWidget {
  const _AboutIdentity({required this.status, required this.compact});

  final _AboutStatusData status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logoSize = compact ? 76.0 : 104.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/brand/flow_read_logo.png',
          width: logoSize,
          height: logoSize,
          filterQuality: FilterQuality.high,
        ),
        SizedBox(width: compact ? 18 : 28),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Flow Read',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    (compact
                            ? theme.textTheme.headlineSmall
                            : theme.textTheme.headlineMedium)
                        ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                '辅助英语阅读与生词高亮工具',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _AboutPill(
                    icon: Icons.confirmation_number_outlined,
                    label: '版本 ${FlowReadVersion.display}',
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  _AboutPill(
                    icon: status.icon,
                    label: status.label,
                    color: status.color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
class _AboutActions extends StatelessWidget {
  const _AboutActions({
    required this.checkingForUpdate,
    required this.updateFallbackActionLabel,
    required this.onOpenUpdateFallback,
    required this.onCheckForUpdates,
    required this.onShowReleaseNotes,
  });

  final bool checkingForUpdate;
  final String? updateFallbackActionLabel;
  final VoidCallback? onOpenUpdateFallback;
  final VoidCallback onCheckForUpdates;
  final VoidCallback onShowReleaseNotes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: checkingForUpdate ? null : onCheckForUpdates,
            icon: checkingForUpdate
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(checkingForUpdate ? '检查中...' : '检查更新'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: onShowReleaseNotes,
            icon: const Icon(Icons.article_outlined),
            label: const Text('查看更新内容'),
          ),
        ),
        if (updateFallbackActionLabel != null &&
            onOpenUpdateFallback != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: onOpenUpdateFallback,
              icon: const Icon(Icons.open_in_new),
              label: Text(updateFallbackActionLabel!),
            ),
          ),
        ],
      ],
    );
  }
}
class _ProjectFeedbackContent extends StatelessWidget {
  const _ProjectFeedbackContent({
    required this.onOpenRepository,
    required this.onOpenIssueFeedback,
  });

  final VoidCallback onOpenRepository;
  final VoidCallback onOpenIssueFeedback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AboutInfoRow(
          icon: Icons.person_outline,
          label: '开发者：',
          value: AppLinks.developerName,
          strong: true,
        ),
        const SizedBox(height: 14),
        _AboutInfoRow(
          icon: Icons.link,
          label: '',
          value: AppLinks.repositoryUrl.toString(),
          valueColor: theme.colorScheme.primary,
        ),
        const Divider(height: 34),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: onOpenRepository,
              icon: const Icon(Icons.code),
              label: const Text('GitHub 仓库'),
            ),
            OutlinedButton.icon(
              onPressed: onOpenIssueFeedback,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('反馈问题'),
            ),
          ],
        ),
      ],
    );
  }
}
class _DiagnosticsContent extends StatelessWidget {
  const _DiagnosticsContent({
    required this.onOpenLogsFolder,
    required this.onExportDiagnostics,
    required this.exportingDiagnostics,
  });

  final VoidCallback onOpenLogsFolder;
  final VoidCallback onExportDiagnostics;
  final bool exportingDiagnostics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '本地日志默认脱敏，保留最近 14 天。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: exportingDiagnostics ? null : onExportDiagnostics,
              icon: exportingDiagnostics
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bug_report_outlined),
              label: Text(exportingDiagnostics ? '导出中...' : '导出诊断报告'),
            ),
            OutlinedButton.icon(
              onPressed: onOpenLogsFolder,
              icon: const Icon(Icons.folder_outlined),
              label: const Text('打开日志文件夹'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '包含最近日志和应用状态摘要，不含密钥、正文内容或本地文件路径。',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }
}
class _MacPermissionDiagnosticsContent extends StatefulWidget {
  const _MacPermissionDiagnosticsContent({
    required this.diagnostics,
    required this.backupFolderPath,
    required this.backupFolderBookmark,
    required this.onReauthorizeBackupFolder,
  });

  final MacPermissionDiagnostics diagnostics;
  final String backupFolderPath;
  final String backupFolderBookmark;
  final VoidCallback onReauthorizeBackupFolder;

  @override
  State<_MacPermissionDiagnosticsContent> createState() =>
      _MacPermissionDiagnosticsContentState();
}

class _MacPermissionDiagnosticsContentState
    extends State<_MacPermissionDiagnosticsContent> {
  List<PermissionDiagnostic>? _items;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void didUpdateWidget(covariant _MacPermissionDiagnosticsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backupFolderPath != widget.backupFolderPath ||
        oldWidget.backupFolderBookmark != widget.backupFolderBookmark) {
      _check();
    }
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    final results = await widget.diagnostics.diagnose(
      backupFolderPath: widget.backupFolderPath,
      backupFolderBookmark: widget.backupFolderBookmark,
    );
    if (!mounted) return;
    setState(() {
      _items = results;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '用于排查 RSS 网络访问和备份文件夹授权。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            IconButton(
              onPressed: _checking ? null : () => _check(),
              icon: _checking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              tooltip: '重新检查',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: LinearProgressIndicator(),
          )
        else
          for (final item in items)
            _PermissionDiagnosticRow(
              item: item,
              onReauthorizeBackupFolder: widget.onReauthorizeBackupFolder,
            ),
        const SizedBox(height: 8),
        Text(
          '若权限异常，可检查系统设置中的网络、隐私与安全性，必要时重新选择备份文件夹。',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }
}
class _PermissionDiagnosticRow extends StatelessWidget {
  const _PermissionDiagnosticRow({
    required this.item,
    required this.onReauthorizeBackupFolder,
  });

  final PermissionDiagnostic item;
  final VoidCallback onReauthorizeBackupFolder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(theme);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_statusIcon(), size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (item.detail?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.detail!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.68,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (item.fixAction != null &&
              item.name == '备份文件夹访问' &&
              item.status != PermissionDiagnosticStatus.ok) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onReauthorizeBackupFolder,
              child: Text(item.fixAction!),
            ),
          ],
        ],
      ),
    );
  }

  IconData _statusIcon() {
    return switch (item.status) {
      PermissionDiagnosticStatus.ok => Icons.check_circle_outline,
      PermissionDiagnosticStatus.warning => Icons.warning_amber_outlined,
      PermissionDiagnosticStatus.error => Icons.error_outline,
      PermissionDiagnosticStatus.unknown => Icons.info_outline,
    };
  }

  Color _statusColor(ThemeData theme) {
    return switch (item.status) {
      PermissionDiagnosticStatus.ok => theme.colorScheme.primary,
      PermissionDiagnosticStatus.warning => theme.colorScheme.tertiary,
      PermissionDiagnosticStatus.error => theme.colorScheme.error,
      PermissionDiagnosticStatus.unknown => theme.colorScheme.onSurfaceVariant,
    };
  }
}
class _AboutInfoRow extends StatelessWidget {
  const _AboutInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.strong = false,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool strong;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        if (label.isNotEmpty)
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor ?? theme.colorScheme.onSurface,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
class _AboutPill extends StatelessWidget {
  const _AboutPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _AboutStatusData {
  const _AboutStatusData({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;
}
class _AvailableUpdateCard extends StatelessWidget {
  const _AvailableUpdateCard({
    required this.update,
    required this.onDownloadUpdate,
    this.downloadingUpdate = false,
    this.downloadProgress = 0,
    this.installedAppPath,
    this.installingUpdate = false,
    this.onInstallUpdate,
    required this.onOpenReleasePage,
  });

  final AppUpdateInfo update;
  final VoidCallback? onDownloadUpdate;
  final bool downloadingUpdate;
  final double downloadProgress;
  final String? installedAppPath;
  final bool installingUpdate;
  final VoidCallback? onInstallUpdate;
  final VoidCallback? onOpenReleasePage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final notes = update.releaseNotes.trim();
    final readyToInstall = installedAppPath != null;
    final colorScheme = theme.colorScheme;

    return SettingsCard(
      icon: Icons.download_for_offline_outlined,
      title: readyToInstall ? '安装更新' : '可用更新',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!readyToInstall && !downloadingUpdate) ...[
            Text(
              'Flow Read ${update.version}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(update.isPrerelease ? '预发布版本' : '正式版本', style: mutedStyle),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                notes,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
          if (downloadingUpdate) ...[
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: downloadProgress > 0 ? downloadProgress : null,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '正在下载... ${(downloadProgress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: downloadProgress > 0 ? downloadProgress : null,
                minHeight: 6,
              ),
            ),
          ],
          if (readyToInstall) ...[
            SettingsStatusLine(
              icon: Icons.check_circle_outline,
              text: '更新已就绪，点击「安装并重启」完成更新。',
              color: colorScheme.primary,
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (!readyToInstall &&
                  !downloadingUpdate &&
                  onDownloadUpdate != null)
                FilledButton.icon(
                  onPressed: onDownloadUpdate,
                  icon: Icon(
                    update.hasDownloadAsset
                        ? Icons.download_outlined
                        : Icons.open_in_new,
                  ),
                  label: Text(update.hasDownloadAsset ? '下载更新' : '打开发布页'),
                ),
              if (onInstallUpdate != null)
                FilledButton.icon(
                  onPressed: installingUpdate ? null : onInstallUpdate,
                  icon: installingUpdate
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restart_alt),
                  label: Text(installingUpdate ? '安装中...' : '安装并重启'),
                ),
              if (!readyToInstall &&
                  !downloadingUpdate &&
                  update.hasDownloadAsset)
                OutlinedButton.icon(
                  onPressed: onOpenReleasePage,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('查看更新说明'),
                ),
            ],
          ),
          if (!downloadingUpdate && update.assetName != null) ...[
            const SizedBox(height: 12),
            SettingsStatusLine(
              icon: Icons.inventory_2_outlined,
              text: update.assetName!,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }
}

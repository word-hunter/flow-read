import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/reading_provider.dart';
import '../providers/rss_provider.dart';
import '../services/backup_service.dart';
import '../services/llm_client.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  String? _controllerProviderId;
  bool _obscureKey = true;
  bool _testingConnection = false;
  String? _connectionResult;

  static const _backupIntervals = <int>[15, 30, 60, 360, 1440];

  static const _colorOptions = [
    _ColorOption('Red', Color(0xFFE74C3C)),
    _ColorOption('Orange', Color(0xFFE67E22)),
    _ColorOption('Yellow', Color(0xFFF1C40F)),
    _ColorOption('Green', Color(0xFF27AE60)),
    _ColorOption('Blue', Color(0xFF2980B9)),
    _ColorOption('Purple', Color(0xFF8E44AD)),
    _ColorOption('Pink', Color(0xFFE91E63)),
    _ColorOption('Teal', Color(0xFF009688)),
    _ColorOption('Grey', Color(0xFF999999)),
    _ColorOption('Dark', Color(0xFF34495E)),
  ];

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final backup = context.watch<BackupService>();
    final theme = Theme.of(context);
    _syncAIControllers(settings);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(
            theme: theme,
            icon: Icons.palette_outlined,
            title: '外观',
            child: _buildAppearanceSection(theme, settings),
          ),
          const SizedBox(height: 16),
          _buildSection(
            theme: theme,
            icon: Icons.auto_awesome,
            title: 'AI',
            child: _buildAISection(theme, settings),
          ),
          const SizedBox(height: 16),
          _buildSection(
            theme: theme,
            icon: Icons.backup_outlined,
            title: '备份',
            child: _buildBackupSection(theme, settings, backup),
          ),
        ],
      ),
    );
  }

  void _syncAIControllers(SettingsService settings) {
    if (_controllerProviderId == settings.aiProviderId) return;
    _controllerProviderId = settings.aiProviderId;
    _apiKeyController.text = settings.apiKeyFor(settings.aiProviderId);
    _baseUrlController.text = settings.aiBaseUrlFor(settings.aiProviderId);
    _modelController.text = settings.aiModelFor(settings.aiProviderId);
  }

  Widget _buildSection({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(ThemeData theme, SettingsService settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.devices_outlined),
              label: Text('系统'),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode_outlined),
              label: Text('浅色'),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode_outlined),
              label: Text('深色'),
            ),
          ],
          selected: {settings.themeMode},
          onSelectionChanged: (value) => settings.setThemeMode(value.first),
        ),
        const SizedBox(height: 18),
        _buildColorRow(
          context,
          settings,
          '生词',
          settings.colors.unknownColor,
          settings.setUnknownColor,
        ),
        const SizedBox(height: 14),
        _buildColorRow(
          context,
          settings,
          '学习中',
          settings.colors.learningColor,
          settings.setLearningColor,
        ),
        const SizedBox(height: 14),
        _buildColorRow(
          context,
          settings,
          '已掌握',
          settings.colors.knownColor,
          settings.setKnownColor,
        ),
      ],
    );
  }

  Widget _buildAISection(ThemeData theme, SettingsService settings) {
    final provider = settings.aiProvider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: settings.aiProviderId,
          decoration: const InputDecoration(
            labelText: '服务商',
            prefixIcon: Icon(Icons.hub_outlined, size: 20),
            border: OutlineInputBorder(),
          ),
          items: settings.aiProviders
              .map(
                (item) =>
                    DropdownMenuItem(value: item.id, child: Text(item.label)),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            _connectionResult = null;
            settings.setAIProvider(value);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _baseUrlController,
          enabled: provider.baseUrlEditable,
          decoration: const InputDecoration(
            labelText: 'Base URL',
            prefixIcon: Icon(Icons.link_outlined, size: 20),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            settings.setAIBaseUrl(value);
            _connectionResult = null;
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _modelController,
          enabled: provider.modelEditable,
          decoration: const InputDecoration(
            labelText: '模型',
            prefixIcon: Icon(Icons.memory_outlined, size: 20),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            settings.setAIModel(value);
            _connectionResult = null;
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _apiKeyController,
          obscureText: _obscureKey,
          decoration: InputDecoration(
            labelText: 'API Key',
            hintText: 'sk-...',
            prefixIcon: const Icon(Icons.key, size: 20),
            suffixIcon: Tooltip(
              message: _obscureKey ? '显示' : '隐藏',
              child: IconButton(
                icon: Icon(
                  _obscureKey ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) {
            settings.setApiKey(value);
            _connectionResult = null;
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTestConnectionButton(settings)),
            const SizedBox(width: 12),
            Tooltip(
              message: '清除 AI 缓存',
              child: IconButton.outlined(
                onPressed: _showClearCacheDialog,
                icon: const Icon(Icons.delete_sweep_outlined),
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
        if (_connectionResult != null) ...[
          const SizedBox(height: 8),
          Text(
            _connectionResult!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _connectionResult!.contains('成功')
                  ? Colors.green
                  : theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBackupSection(
    ThemeData theme,
    SettingsService settings,
    BackupService backup,
  ) {
    final hasFolder = settings.backupFolderPath.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('定时同步'),
          secondary: const Icon(Icons.sync_outlined),
          value: settings.backupEnabled,
          onChanged: (value) => settings.setBackupEnabled(value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('包含 API Key'),
          secondary: const Icon(Icons.key_outlined),
          value: settings.includeSecretsInBackup,
          onChanged: (value) => settings.setIncludeSecretsInBackup(value),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.folder_outlined),
          title: const Text('备份文件夹'),
          subtitle: Text(
            hasFolder ? settings.backupFolderPath : '未选择',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Tooltip(
            message: '选择文件夹',
            child: IconButton(
              icon: const Icon(Icons.drive_folder_upload_outlined),
              onPressed: _chooseBackupFolder,
            ),
          ),
          onTap: _chooseBackupFolder,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue:
              _backupIntervals.contains(settings.backupIntervalMinutes)
              ? settings.backupIntervalMinutes
              : 60,
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
            if (value != null) settings.setBackupIntervalMinutes(value);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: !hasFolder || backup.isSyncing
                    ? null
                    : () => _exportBackup(backup),
                icon: backup.isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.backup_outlined),
                label: Text(backup.isSyncing ? '同步中...' : '立即备份'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: backup.isSyncing ? null : () => _importBackup(),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('导入备份'),
              ),
            ),
          ],
        ),
        if (settings.lastBackupAt != null || backup.lastError != null) ...[
          const SizedBox(height: 10),
          Text(
            backup.lastError ??
                '上次同步 ${_formatDateTime(settings.lastBackupAt!)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: backup.lastError == null
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildColorRow(
    BuildContext context,
    SettingsService settings,
    String label,
    Color currentColor,
    ValueChanged<Color> onColorChanged,
  ) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colorOptions.map((opt) {
              final selected = currentColor.toARGB32() == opt.color.toARGB32();
              return Tooltip(
                message: opt.name,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onColorChanged(opt.color),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: opt.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.outlineVariant,
                        width: selected ? 3 : 1,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTestConnectionButton(SettingsService settings) {
    return OutlinedButton.icon(
      onPressed: _testingConnection || settings.apiKey.isEmpty
          ? null
          : () => _testConnection(settings),
      icon: _testingConnection
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.wifi_find, size: 18),
      label: Text(_testingConnection ? '测试中...' : '测试连接'),
    );
  }

  Future<void> _testConnection(SettingsService settings) async {
    setState(() {
      _testingConnection = true;
      _connectionResult = null;
    });

    final client = LLMClient(settings);
    final ok = await client.testConnection();

    if (!mounted) return;
    setState(() {
      _testingConnection = false;
      _connectionResult = ok ? '连接成功' : '连接失败，请检查配置';
    });
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清除 AI 缓存'),
        content: const Text('将清除所有章节总结和练习题缓存。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await context.read<ReadingProvider>().clearAICache();
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('AI 缓存已清除')));
              }
            },
            child: const Text('确认清除'),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseBackupFolder() async {
    final path = await FilePicker.getDirectoryPath(dialogTitle: '选择备份文件夹');
    if (path == null || !mounted) return;
    await context.read<SettingsService>().setBackupFolderPath(path);
  }

  Future<void> _exportBackup(BackupService backup) async {
    try {
      final path = await backup.exportNow();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('备份已生成：$path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('备份失败：$e')));
    }
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: '选择 FlowRead 备份',
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    final confirmed = await _confirmImport();
    if (!confirmed || !mounted) return;

    final backup = context.read<BackupService>();
    final readingProvider = context.read<ReadingProvider>();
    final rssProvider = context.read<RssProvider>();

    try {
      await backup.importBackupFile(path);
      await readingProvider.init();
      await rssProvider.init();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('备份已导入')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导入失败：$e')));
    }
  }

  Future<bool> _confirmImport() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('导入备份'),
            content: const Text('导入后将替换当前书架、词汇、书签、RSS 和阅读数据。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('导入'),
              ),
            ],
          ),
        ) ??
        false;
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

class _ColorOption {
  final String name;
  final Color color;
  const _ColorOption(this.name, this.color);
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/reading_provider.dart';
import '../providers/rss_provider.dart';
import '../services/app_version.dart';
import '../services/backup_folder_access.dart';
import '../services/backup_service.dart';
import '../services/changelog_service.dart';
import '../services/dictionary/dictionary_cache_service.dart';
import '../services/llm_client.dart';
import '../services/settings_service.dart';
import '../theme/app_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/release_notes_dialog.dart';
import '../widgets/theme_transition.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

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
  bool _importingWordHunter = false;
  String? _connectionResult;
  _SettingsSection _selectedSection = _SettingsSection.appearance;
  final BackupFolderAccess _backupFolderAccess = const BackupFolderAccess();

  static const _desktopBreakpoint = 760.0;
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
      body: SafeArea(
        child: ColoredBox(
          color: theme.colorScheme.surface,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= _desktopBreakpoint) {
                return Row(
                  children: [
                    _buildSidebar(theme),
                    VerticalDivider(
                      width: 1,
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    Expanded(
                      child: _buildSectionContent(theme, settings, backup),
                    ),
                  ],
                );
              }
              return _buildCompactLayout(theme, settings, backup);
            },
          ),
        ),
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

  Widget _buildSidebar(ThemeData theme) {
    final topInset = AppConstants.immersiveTitleBarTopInset;
    return SizedBox(
      width: 240,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(18, 18 + topInset, 18, 22),
              child: Row(
                children: [
                  if (Navigator.canPop(context)) ...[
                    Tooltip(
                      message: '返回',
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Image.asset(
                    'assets/brand/flow_read_logo.png',
                    width: 26,
                    height: 26,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'FlowRead',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 16, 16),
                children: [
                  for (final section in _SettingsSection.values)
                    _SettingsSidebarItem(
                      section: section,
                      selected: _selectedSection == section,
                      onTap: () => setState(() => _selectedSection = section),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactLayout(
    ThemeData theme,
    SettingsService settings,
    BackupService backup,
  ) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            10 + AppConstants.immersiveTitleBarTopInset,
            12,
            6,
          ),
          child: Row(
            children: [
              if (Navigator.canPop(context))
                Tooltip(
                  message: '返回',
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
              Image.asset(
                'assets/brand/flow_read_logo.png',
                width: 26,
                height: 26,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(width: 10),
              Text(
                '设置',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) {
              final section = _SettingsSection.values[index];
              final selected = _selectedSection == section;
              return ChoiceChip(
                avatar: Icon(section.icon, size: 18),
                label: Text(section.title),
                selected: selected,
                onSelected: (_) => setState(() => _selectedSection = section),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemCount: _SettingsSection.values.length,
          ),
        ),
        Expanded(child: _buildSectionContent(theme, settings, backup)),
      ],
    );
  }

  Widget _buildSectionContent(
    ThemeData theme,
    SettingsService settings,
    BackupService backup, {
    double topInset = 0,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: ListView(
          key: ValueKey('settings-section-${_selectedSection.name}'),
          padding: EdgeInsets.fromLTRB(32, 28 + topInset, 36, 36),
          children: [
            _SectionHeading(section: _selectedSection),
            const SizedBox(height: 22),
            switch (_selectedSection) {
              _SettingsSection.appearance => _buildAppearanceSection(
                theme,
                settings,
              ),
              _SettingsSection.dictionary => _buildDictionarySection(
                theme,
                settings,
              ),
              _SettingsSection.ai => _buildAISection(theme, settings),
              _SettingsSection.backup => _buildBackupSection(
                theme,
                settings,
                backup,
              ),
              _SettingsSection.experiments => _buildExperimentalFeaturesSection(
                theme,
                settings,
              ),
              _SettingsSection.about => _buildAboutSection(theme),
            },
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(ThemeData theme, SettingsService settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsCard(
          icon: Icons.style_outlined,
          title: '主题',
          child: _buildResponsiveGrid(
            children: [
              DropdownButtonFormField<AppThemeId>(
                initialValue: settings.appThemeId,
                decoration: const InputDecoration(
                  labelText: '主题',
                  prefixIcon: Icon(Icons.style_outlined, size: 20),
                  border: OutlineInputBorder(),
                ),
                items: AppThemeId.values
                    .map(
                      (themeId) => DropdownMenuItem(
                        value: themeId,
                        child: Row(
                          children: [
                            Icon(themeId.icon, size: 18),
                            const SizedBox(width: 8),
                            Text(themeId.label),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  _switchTheme(() => settings.setAppThemeId(value));
                },
              ),
              _buildThemeModeControl(settings),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          icon: Icons.format_color_fill_outlined,
          title: '词汇标记',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildColorRow(
                context,
                '生词颜色',
                settings.colors.unknownColor,
                settings.setUnknownColor,
              ),
              const SizedBox(height: 18),
              _buildColorRow(
                context,
                '学习中颜色',
                settings.colors.learningColor,
                settings.setLearningColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeModeControl(SettingsService settings) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '颜色模式',
        prefixIcon: Icon(Icons.contrast_outlined, size: 20),
        border: OutlineInputBorder(),
      ),
      child: SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
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
        onSelectionChanged: (value) {
          _switchTheme(() => settings.setThemeMode(value.first));
        },
      ),
    );
  }

  Future<void> _switchTheme(ThemeMutation mutation) {
    return runThemeTransition(context, mutation);
  }

  Widget _buildAISection(ThemeData theme, SettingsService settings) {
    final provider = settings.aiProvider;
    final successColor = theme.colorScheme.tertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsCard(
          icon: Icons.auto_awesome,
          title: '模型配置',
          child: _buildResponsiveGrid(
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
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  _connectionResult = null;
                  settings.setAIProvider(value);
                },
              ),
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
                        _obscureKey
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  settings.setApiKey(value);
                  _connectionResult = null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          icon: Icons.wifi_tethering_outlined,
          title: '连接',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildTestConnectionButton(settings),
                  OutlinedButton.icon(
                    onPressed: () => _clearAIConfig(settings),
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: const Text('清除配置'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _showClearCacheDialog,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('清除 AI 缓存'),
                  ),
                ],
              ),
              if (_connectionResult != null) ...[
                const SizedBox(height: 12),
                _StatusLine(
                  icon: _connectionResult!.contains('成功')
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  text: _connectionResult!,
                  color: _connectionResult!.contains('成功')
                      ? successColor
                      : theme.colorScheme.error,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDictionarySection(ThemeData theme, SettingsService settings) {
    final enabledSources = settings.dictionarySources
        .where((config) => config.enabled)
        .map((config) => config.type.label)
        .join(' → ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsCard(
          icon: Icons.menu_book_outlined,
          title: '来源',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.language_outlined),
                title: const Text('Collins 在线词典'),
                subtitle: Text(
                  settings.collinsDictionaryEnabled ? '已启用' : '已停用',
                ),
                value: settings.collinsDictionaryEnabled,
                onChanged: settings.setCollinsDictionaryEnabled,
              ),
              if (enabledSources.isNotEmpty) ...[
                const SizedBox(height: 8),
                _StatusLine(
                  icon: Icons.low_priority_outlined,
                  text: '当前顺序：$enabledSources',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          icon: Icons.delete_sweep_outlined,
          title: '缓存',
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _clearDictionaryCache,
              icon: const Icon(Icons.cleaning_services_outlined),
              label: const Text('清理词典缓存'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExperimentalFeaturesSection(
    ThemeData theme,
    SettingsService settings,
  ) {
    final testingEnabled = settings.enabledExperimentalFeatures.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsCard(
          icon: Icons.science_outlined,
          title: '开启测试功能',
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.tune_outlined),
            title: const Text('开启测试功能'),
            subtitle: Text(testingEnabled ? '测试项列表已启用' : '关闭后隐藏测试入口'),
            value: testingEnabled,
            onChanged: (value) => _setAllExperimentalFeatures(settings, value),
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          icon: Icons.list_alt_outlined,
          title: '测试项列表',
          child: Column(
            children: [
              _buildExperimentalFeatureTile(
                icon: Icons.rss_feed_outlined,
                title: 'RSS 入口',
                subtitle: '在首页显示 RSS 订阅与最新内容入口',
                value: settings.rssFeatureEnabled,
                enabled: testingEnabled,
                onChanged: (value) => settings.setRssFeatureEnabled(value),
              ),
              const Divider(height: 1),
              _buildExperimentalFeatureTile(
                icon: Icons.language_outlined,
                title: '浏览器入口',
                subtitle: '在首页显示网页阅读、单词标记与 AI 助手入口',
                value: settings.browserFeatureEnabled,
                enabled: testingEnabled,
                onChanged: (value) => settings.setBrowserFeatureEnabled(value),
              ),
            ],
          ),
        ),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildResponsiveGrid(
          children: [
            _SettingsCard(
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
                    onChanged: (value) => settings.setBackupEnabled(value),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue:
                        _backupIntervals.contains(
                          settings.backupIntervalMinutes,
                        )
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
                      if (value != null) {
                        settings.setBackupIntervalMinutes(value);
                      }
                    },
                  ),
                ],
              ),
            ),
            _SettingsCard(
              icon: Icons.inventory_2_outlined,
              title: '备份内容',
              child: Column(
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.check_circle_outline),
                    title: const Text('应用数据'),
                    subtitle: const Text('书架、词汇、书签、RSS 和阅读进度'),
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
        _SettingsCard(
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
              OutlinedButton.icon(
                onPressed: _chooseBackupFolder,
                icon: const Icon(Icons.drive_folder_upload_outlined),
                label: Text(hasFolder ? '更改位置' : '选择位置'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          icon: Icons.flash_on_outlined,
          title: '手动操作',
          child: Align(
            alignment: Alignment.centerLeft,
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
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(backup.isSyncing ? '同步中...' : '立即备份'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          icon: Icons.download_outlined,
          title: '导入与恢复',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: backup.isSyncing ? null : () => _importBackup(),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('导入备份'),
              ),
              OutlinedButton.icon(
                onPressed: backup.isSyncing || _importingWordHunter
                    ? null
                    : _importWordHunterBackup,
                icon: _importingWordHunter
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.school_outlined),
                label: Text(
                  _importingWordHunter ? '导入中...' : '导入 Word Hunter 备份',
                ),
              ),
            ],
          ),
        ),
        if (settings.lastBackupAt != null || backup.lastError != null) ...[
          const SizedBox(height: 16),
          _SettingsCard(
            icon: backup.lastError == null
                ? Icons.history_outlined
                : Icons.error_outline,
            title: backup.lastError == null ? '同步记录' : '同步失败',
            child: _StatusLine(
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

  Widget _buildAboutSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsCard(
          icon: Icons.info_outline,
          title: '版本',
          child: Row(
            children: [
              Image.asset(
                'assets/brand/flow_read_logo.png',
                width: 42,
                height: 42,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Flow Read',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '版本 ${FlowReadVersion.display}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          icon: Icons.settings_applications_outlined,
          title: '操作',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _showCurrentReleaseNotes,
                icon: const Icon(Icons.new_releases_outlined),
                label: const Text('检查更新'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveGrid({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 680 || children.length == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _separateWithSpacing(
              children,
              const SizedBox(height: 12),
            ),
          );
        }

        final itemWidth = (constraints.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }

  List<Widget> _separateWithSpacing(List<Widget> children, Widget spacing) {
    return [
      for (var i = 0; i < children.length; i++) ...[
        if (i != 0) spacing,
        children[i],
      ],
    ];
  }

  Widget _buildColorRow(
    BuildContext context,
    String label,
    Color currentColor,
    ValueChanged<Color> onColorChanged,
  ) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
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
    return FilledButton.icon(
      onPressed: _testingConnection || !settings.aiFeaturesEnabled
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

  Widget _buildExperimentalFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: enabled ? onChanged : null,
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

  Future<void> _clearAIConfig(SettingsService settings) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('清除配置'),
            content: Text(
              '将清除 ${settings.aiProvider.label} 的 API Key，并把 Base URL 和模型恢复为默认值。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('清除配置'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    final provider = settings.aiProvider;
    await settings.setApiKey('');
    await settings.setAIBaseUrl(provider.defaultBaseUrl);
    await settings.setAIModel(provider.defaultModel);
    if (!mounted) return;

    _controllerProviderId = null;
    _syncAIControllers(settings);
    setState(() => _connectionResult = null);
    _showSnackBar('AI 配置已清除');
  }

  void _showClearCacheDialog() {
    showDialog<void>(
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
                _showSnackBar('AI 缓存已清除');
              }
            },
            child: const Text('确认清除'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearDictionaryCache() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('清理词典缓存'),
            content: const Text('将删除 Collins、Longman 等在线词典的本地缓存。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('清理'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    final cache = DictionaryCacheService();
    await cache.init();
    await cache.clear();
    if (mounted) {
      _showSnackBar('词典缓存已清理');
    }
  }

  Future<void> _setAllExperimentalFeatures(
    SettingsService settings,
    bool enabled,
  ) async {
    await settings.setRssFeatureEnabled(enabled);
    await settings.setBrowserFeatureEnabled(enabled);
  }

  Future<void> _chooseBackupFolder() async {
    final settings = context.read<SettingsService>();
    final selection = await _backupFolderAccess.chooseDirectory(
      dialogTitle: '选择备份文件夹',
      initialDirectory: settings.backupFolderPath.trim().isEmpty
          ? null
          : settings.backupFolderPath,
    );
    if (selection == null || !mounted) return;
    await settings.setBackupFolderPath(
      selection.path,
      bookmark: selection.bookmark,
    );
  }

  Future<void> _exportBackup(BackupService backup) async {
    try {
      final refreshed = await _refreshBackupFolderAccessIfNeeded();
      if (!refreshed || !mounted) return;
      final path = await backup.exportNow();
      if (!mounted) return;
      _showSnackBar('备份已生成：$path');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('备份失败：$e');
    }
  }

  Future<bool> _refreshBackupFolderAccessIfNeeded() async {
    final settings = context.read<SettingsService>();
    if (!_backupFolderAccess.requiresPersistentAccess ||
        settings.backupFolderBookmark.isNotEmpty) {
      return true;
    }

    final selection = await _backupFolderAccess.chooseDirectory(
      dialogTitle: '重新授权备份文件夹',
      initialDirectory: settings.backupFolderPath.trim().isEmpty
          ? null
          : settings.backupFolderPath,
    );
    if (selection == null || !mounted) return false;
    await settings.setBackupFolderPath(
      selection.path,
      bookmark: selection.bookmark,
    );
    return true;
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
      _showSnackBar('备份已导入');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('导入失败：$e');
    }
  }

  Future<void> _importWordHunterBackup() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: '选择 Word Hunter 备份',
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    final confirmed = await _confirmWordHunterImport();
    if (!confirmed || !mounted) return;

    final backup = context.read<BackupService>();
    final readingProvider = context.read<ReadingProvider>();

    setState(() => _importingWordHunter = true);
    try {
      final importResult = await backup.importWordHunterBackupFile(path);
      await readingProvider.init();
      if (!mounted) return;
      _showSnackBar(
        'Word Hunter 已导入：${importResult.knownCount} 个熟词、'
        '${importResult.learningCount} 个学习中、'
        '${importResult.exampleCount} 条例句',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Word Hunter 导入失败：$e');
    } finally {
      if (mounted) {
        setState(() => _importingWordHunter = false);
      }
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

  Future<bool> _confirmWordHunterImport() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('导入 Word Hunter 备份'),
            content: const Text(
              '将合并熟词、学习中单词和例句，不会清空当前 FlowRead 数据；同一个单词以熟词状态优先。',
            ),
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

  // TODO: 增加自动更新
  Future<void> _showCurrentReleaseNotes() async {
    final notes = await ChangelogService.loadCurrentReleaseNotes();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => ReleaseNotesDialog(notes: notes),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

enum _SettingsSection { appearance, dictionary, ai, backup, experiments, about }

extension _SettingsSectionMeta on _SettingsSection {
  String get title {
    switch (this) {
      case _SettingsSection.appearance:
        return '外观';
      case _SettingsSection.dictionary:
        return '词典';
      case _SettingsSection.ai:
        return 'AI 设置';
      case _SettingsSection.backup:
        return '备份与同步';
      case _SettingsSection.experiments:
        return '测试功能';
      case _SettingsSection.about:
        return '关于';
    }
  }

  String get subtitle {
    switch (this) {
      case _SettingsSection.appearance:
        return '调整主题、颜色模式与词汇标记色。';
      case _SettingsSection.dictionary:
        return '管理查词来源和本地缓存。';
      case _SettingsSection.ai:
        return '配置 AI 服务商、模型、密钥与连接状态。';
      case _SettingsSection.backup:
        return '管理本地数据备份、自动同步与恢复。';
      case _SettingsSection.experiments:
        return '管理仍在测试中的入口和功能项。';
      case _SettingsSection.about:
        return '查看版本信息并打开本地目录。';
    }
  }

  IconData get icon {
    switch (this) {
      case _SettingsSection.appearance:
        return Icons.palette_outlined;
      case _SettingsSection.dictionary:
        return Icons.menu_book_outlined;
      case _SettingsSection.ai:
        return Icons.auto_awesome;
      case _SettingsSection.backup:
        return Icons.cloud_sync_outlined;
      case _SettingsSection.experiments:
        return Icons.science_outlined;
      case _SettingsSection.about:
        return Icons.info_outline;
    }
  }
}

class _SettingsSidebarItem extends StatelessWidget {
  const _SettingsSidebarItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final _SettingsSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 4,
                  height: selected ? 36 : 0,
                  decoration: BoxDecoration(
                    color: selected ? colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 14),
                Icon(
                  section.icon,
                  size: 22,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    section.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.section});

  final _SettingsSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(section.icon, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                section.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          section.subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 21, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _ColorOption {
  final String name;
  final Color color;
  const _ColorOption(this.name, this.color);
}

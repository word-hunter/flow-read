import 'package:flutter/material.dart';

import '../../services/app_links.dart';
import '../../services/app_update_service.dart';
import '../../services/app_version.dart';
import '../../services/backup_service.dart';
import '../../services/dictionary/dictionary_source_config.dart';
import '../../services/dictionary/dictionary_source_test_service.dart';
import '../../services/language/language_registry.dart';
import '../../services/mac_permission_diagnostics.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../theme_transition.dart';

typedef ThemeMutationRunner = Future<void> Function(ThemeMutation mutation);

enum SettingsSection {
  appearance,
  reading,
  dictionary,
  ai,
  backup,
  experiments,
  about,
}

extension SettingsSectionMeta on SettingsSection {
  String get title {
    switch (this) {
      case SettingsSection.appearance:
        return '外观';
      case SettingsSection.reading:
        return '阅读';
      case SettingsSection.dictionary:
        return '词典';
      case SettingsSection.ai:
        return 'AI 设置';
      case SettingsSection.backup:
        return '备份与同步';
      case SettingsSection.experiments:
        return '测试功能';
      case SettingsSection.about:
        return '关于';
    }
  }

  String get subtitle {
    switch (this) {
      case SettingsSection.appearance:
        return '调整主题、颜色模式与词汇标记色。';
      case SettingsSection.reading:
        return '设置首页阅读目标和阅读节奏。';
      case SettingsSection.dictionary:
        return '管理查词来源和本地缓存。';
      case SettingsSection.ai:
        return '配置 AI 服务商、模型、密钥与连接状态。';
      case SettingsSection.backup:
        return '管理本地数据备份、自动同步与恢复。';
      case SettingsSection.experiments:
        return '管理仍在测试中的入口和功能项。';
      case SettingsSection.about:
        return '版本信息、更新检查、问题反馈与诊断日志。';
    }
  }

  IconData get icon {
    switch (this) {
      case SettingsSection.appearance:
        return Icons.palette_outlined;
      case SettingsSection.reading:
        return Icons.flag_outlined;
      case SettingsSection.dictionary:
        return Icons.menu_book_outlined;
      case SettingsSection.ai:
        return Icons.auto_awesome;
      case SettingsSection.backup:
        return Icons.cloud_sync_outlined;
      case SettingsSection.experiments:
        return Icons.science_outlined;
      case SettingsSection.about:
        return Icons.info_outline;
    }
  }
}

class SettingsAppearanceSection extends StatelessWidget {
  const SettingsAppearanceSection({
    super.key,
    required this.settings,
    required this.onSwitchTheme,
  });

  final SettingsService settings;
  final ThemeMutationRunner onSwitchTheme;

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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          icon: Icons.style_outlined,
          title: '主题',
          child: ResponsiveSettingsGrid(
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
                  onSwitchTheme(() => settings.setAppThemeId(value));
                },
              ),
              _ThemeModeControl(
                settings: settings,
                onSwitchTheme: onSwitchTheme,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsCard(
          icon: Icons.format_color_fill_outlined,
          title: '词汇标记',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ColorRow(
                label: '生词颜色',
                currentColor: settings.colors.unknownColor,
                onColorChanged: settings.setUnknownColor,
                colorOptions: _colorOptions,
              ),
              const SizedBox(height: 18),
              _ColorRow(
                label: '学习中颜色',
                currentColor: settings.colors.learningColor,
                onColorChanged: settings.setLearningColor,
                colorOptions: _colorOptions,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsReadingSection extends StatelessWidget {
  const SettingsReadingSection({super.key, required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentMinutes = settings.dailyReadingGoalMinutes;
    final weeklyMinutes = currentMinutes * 6;
    final languageModules = LanguageRegistry.instance.modules;
    final languageOptions = languageModules.isEmpty
        ? const [_LanguageOption(code: 'en', name: 'English')]
        : languageModules
              .map(
                (module) => _LanguageOption(
                  code: module.languageCode,
                  name: module.languageName,
                ),
              )
              .toList();
    final selectedLanguage =
        languageOptions.any(
          (option) => option.code == settings.activeSourceLanguage,
        )
        ? settings.activeSourceLanguage
        : 'en';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          icon: Icons.flag_outlined,
          title: '每日目标',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '每日 ${_formatDuration(currentMinutes)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Slider(
                value: currentMinutes.toDouble(),
                min: SettingsService.minDailyReadingGoalMinutes.toDouble(),
                max: SettingsService.maxDailyReadingGoalMinutes.toDouble(),
                divisions:
                    (SettingsService.maxDailyReadingGoalMinutes -
                        SettingsService.minDailyReadingGoalMinutes) ~/
                    SettingsService.dailyReadingGoalStepMinutes,
                label: _formatDuration(currentMinutes),
                onChanged: (value) {
                  settings.setDailyReadingGoalMinutes(value.round());
                },
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    _formatDuration(SettingsService.minDailyReadingGoalMinutes),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDuration(SettingsService.maxDailyReadingGoalMinutes),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SettingsStatusLine(
                icon: Icons.calendar_view_week_outlined,
                text: '周目标 ${_formatDuration(weeklyMinutes)}',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsCard(
          icon: Icons.translate_outlined,
          title: '内容语言',
          child: SegmentedButton<String>(
            segments: [
              for (final option in languageOptions)
                ButtonSegment<String>(
                  value: option.code,
                  label: Text(option.name),
                ),
            ],
            selected: {selectedLanguage},
            onSelectionChanged: (value) {
              if (value.isEmpty) return;
              settings.setActiveSourceLanguage(value.first);
            },
          ),
        ),
      ],
    );
  }

  static String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes 分钟';
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    if (remain == 0) return '$hours 小时';
    return '$hours 小时 $remain 分钟';
  }
}

class _LanguageOption {
  const _LanguageOption({required this.code, required this.name});

  final String code;
  final String name;
}

class SettingsAISection extends StatelessWidget {
  const SettingsAISection({
    super.key,
    required this.settings,
    required this.apiKeyController,
    required this.baseUrlController,
    required this.modelController,
    required this.obscureKey,
    required this.testingConnection,
    required this.connectionResult,
    required this.onProviderChanged,
    required this.onModelChanged,
    required this.onBaseUrlChanged,
    required this.onApiKeyChanged,
    required this.onToggleObscureKey,
    required this.onTestConnection,
    required this.onClearConfig,
    required this.onClearCache,
    required this.aiCacheEntryCount,
    required this.cacheStatsLoading,
  });

  final SettingsService settings;
  final TextEditingController apiKeyController;
  final TextEditingController baseUrlController;
  final TextEditingController modelController;
  final bool obscureKey;
  final bool testingConnection;
  final String? connectionResult;
  final ValueChanged<String> onProviderChanged;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<String> onBaseUrlChanged;
  final ValueChanged<String> onApiKeyChanged;
  final VoidCallback onToggleObscureKey;
  final VoidCallback onTestConnection;
  final VoidCallback onClearConfig;
  final VoidCallback onClearCache;
  final int? aiCacheEntryCount;
  final bool cacheStatsLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = settings.aiProvider;
    final successColor = theme.colorScheme.tertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          icon: Icons.auto_awesome,
          title: '模型配置',
          child: ResponsiveSettingsGrid(
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
                  if (value != null) onProviderChanged(value);
                },
              ),
              TextField(
                controller: modelController,
                enabled: provider.modelEditable,
                decoration: const InputDecoration(
                  labelText: '模型',
                  prefixIcon: Icon(Icons.memory_outlined, size: 20),
                  border: OutlineInputBorder(),
                ),
                onChanged: onModelChanged,
              ),
              TextField(
                controller: baseUrlController,
                enabled: provider.baseUrlEditable,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  prefixIcon: Icon(Icons.link_outlined, size: 20),
                  border: OutlineInputBorder(),
                ),
                onChanged: onBaseUrlChanged,
              ),
              TextField(
                controller: apiKeyController,
                obscureText: obscureKey,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: 'sk-...',
                  prefixIcon: const Icon(Icons.key, size: 20),
                  suffixIcon: Tooltip(
                    message: obscureKey ? '显示' : '隐藏',
                    child: IconButton(
                      icon: Icon(
                        obscureKey
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: onToggleObscureKey,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: onApiKeyChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsCard(
          icon: Icons.wifi_tethering_outlined,
          title: '连接',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: testingConnection || !settings.aiFeaturesEnabled
                        ? null
                        : onTestConnection,
                    icon: testingConnection
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find, size: 18),
                    label: Text(testingConnection ? '测试中...' : '测试连接'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onClearConfig,
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: const Text('清除配置'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
              if (connectionResult != null) ...[
                const SizedBox(height: 12),
                SettingsStatusLine(
                  icon: connectionResult!.contains('成功')
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  text: connectionResult!,
                  color: connectionResult!.contains('成功')
                      ? successColor
                      : theme.colorScheme.error,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsCard(
          icon: Icons.delete_sweep_outlined,
          title: '缓存',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsStatusLine(
                icon: Icons.auto_stories_outlined,
                text: _formatCacheCount(
                  count: aiCacheEntryCount,
                  loading: cacheStatsLoading,
                  loadedLabel: '章节总结与练习题缓存',
                  unit: '个文件',
                ),
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              SettingsStatusLine(
                icon: Icons.info_outline,
                text: '清理后只会重新生成 AI 内容，不会删除书籍、生词、书签、阅读进度或 AI 配置。',
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onClearCache,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('清除 AI 缓存'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatCacheCount({
    required int? count,
    required bool loading,
    required String loadedLabel,
    required String unit,
  }) {
    if (loading) return '正在统计缓存...';
    if (count == null) return '缓存数量暂无法统计';
    return '$loadedLabel：$count $unit';
  }
}

class SettingsDictionarySection extends StatelessWidget {
  const SettingsDictionarySection({
    super.key,
    required this.settings,
    required this.testWordController,
    required this.testingSources,
    required this.testResults,
    required this.onTestSources,
    required this.onClearCache,
    required this.cacheEntryCount,
    required this.cacheStatsLoading,
  });

  final SettingsService settings;
  final TextEditingController testWordController;
  final bool testingSources;
  final Map<DictionarySourceType, DictionarySourceTestResult> testResults;
  final VoidCallback onTestSources;
  final VoidCallback onClearCache;
  final int? cacheEntryCount;
  final bool cacheStatsLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabledSources = settings.dictionarySources
        .where((config) => config.enabled)
        .map((config) => config.type.label)
        .join(' → ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          icon: Icons.menu_book_outlined,
          title: '来源',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < settings.dictionarySources.length; i++) ...[
                if (i > 0) const Divider(height: 24),
                _DictionarySourceTile(
                  config: settings.dictionarySources[i],
                  testResult: testResults[settings.dictionarySources[i].type],
                  position: i + 1,
                  isFirst: i == 0,
                  isLast: i == settings.dictionarySources.length - 1,
                  onEnabledChanged:
                      settings.dictionarySources[i].type ==
                          DictionarySourceType.wordNet
                      ? null
                      : (enabled) {
                          settings.setDictionarySourceEnabled(
                            settings.dictionarySources[i].type,
                            enabled,
                          );
                        },
                  onMoveUp: i == 0
                      ? null
                      : () {
                          settings.moveDictionarySource(
                            settings.dictionarySources[i].type,
                            -1,
                          );
                        },
                  onMoveDown: i == settings.dictionarySources.length - 1
                      ? null
                      : () {
                          settings.moveDictionarySource(
                            settings.dictionarySources[i].type,
                            1,
                          );
                        },
                ),
              ],
              if (enabledSources.isNotEmpty) ...[
                const SizedBox(height: 16),
                SettingsStatusLine(
                  icon: Icons.low_priority_outlined,
                  text: '当前顺序：$enabledSources',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsCard(
          icon: Icons.fact_check_outlined,
          title: '测试',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveSettingsGrid(
                children: [
                  TextField(
                    controller: testWordController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: '测试单词',
                      prefixIcon: Icon(Icons.search_outlined, size: 20),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) {
                      if (!testingSources) onTestSources();
                    },
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: testingSources ? null : onTestSources,
                      icon: testingSources
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_find, size: 18),
                      label: Text(testingSources ? '测试中...' : '测试来源'),
                    ),
                  ),
                ],
              ),
              if (testResults.isNotEmpty) ...[
                const SizedBox(height: 12),
                SettingsStatusLine(
                  icon: Icons.history_outlined,
                  text: '最近测试：${_formatTestSummary(testResults.values)}',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsCard(
          icon: Icons.delete_sweep_outlined,
          title: '缓存',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsStatusLine(
                icon: Icons.storage_outlined,
                text: _formatCacheCount(
                  count: cacheEntryCount,
                  loading: cacheStatsLoading,
                ),
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              SettingsStatusLine(
                icon: Icons.info_outline,
                text: '只会删除在线词典查询结果，不会删除生词本、学习记录、书签或阅读进度。',
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onClearCache,
                  icon: const Icon(Icons.cleaning_services_outlined),
                  label: const Text('清理词典缓存'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatCacheCount({
    required int? count,
    required bool loading,
  }) {
    if (loading) return '正在统计缓存...';
    if (count == null) return '缓存数量暂无法统计';
    return '在线词典缓存：$count 条';
  }

  static String _formatTestSummary(
    Iterable<DictionarySourceTestResult> results,
  ) {
    final hits = results
        .where((result) => result.status == DictionarySourceTestStatus.hit)
        .length;
    return '$hits / ${results.length} 个来源命中';
  }
}

class _DictionarySourceTile extends StatelessWidget {
  const _DictionarySourceTile({
    required this.config,
    required this.testResult,
    required this.position,
    required this.isFirst,
    required this.isLast,
    required this.onEnabledChanged,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final DictionarySourceConfig config;
  final DictionarySourceTestResult? testResult;
  final int position;
  final bool isFirst;
  final bool isLast;
  final ValueChanged<bool>? onEnabledChanged;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = config.type == DictionarySourceType.wordNet
        ? '始终启用'
        : config.enabled
        ? '已启用'
        : '已停用';
    final sourceType = config.type.online ? '在线来源' : '本地兜底';
    final meta = '$sourceType · $status · 第 $position 位';

    return LayoutBuilder(
      builder: (context, constraints) {
        final info = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_iconForSource(config.type), color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.type.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _DictionarySourceLanguageTag(
                    label: _languageSupportLabel(config),
                  ),
                  if (testResult != null) ...[
                    const SizedBox(height: 6),
                    _DictionarySourceTestStatusLine(result: testResult!),
                  ],
                ],
              ),
            ),
          ],
        );

        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: '上移',
              child: IconButton(
                onPressed: isFirst ? null : onMoveUp,
                icon: const Icon(Icons.keyboard_arrow_up),
                visualDensity: VisualDensity.compact,
              ),
            ),
            Tooltip(
              message: '下移',
              child: IconButton(
                onPressed: isLast ? null : onMoveDown,
                icon: const Icon(Icons.keyboard_arrow_down),
                visualDensity: VisualDensity.compact,
              ),
            ),
            Switch(value: config.enabled, onChanged: onEnabledChanged),
          ],
        );

        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: info),
                  Switch(value: config.enabled, onChanged: onEnabledChanged),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: '上移',
                      child: IconButton(
                        onPressed: isFirst ? null : onMoveUp,
                        icon: const Icon(Icons.keyboard_arrow_up),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    Tooltip(
                      message: '下移',
                      child: IconButton(
                        onPressed: isLast ? null : onMoveDown,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: info),
            const SizedBox(width: 12),
            actions,
          ],
        );
      },
    );
  }

  IconData _iconForSource(DictionarySourceType type) {
    switch (type) {
      case DictionarySourceType.wordNet:
        return Icons.auto_stories_outlined;
      case DictionarySourceType.dictionaryApi:
        return Icons.public_outlined;
      case DictionarySourceType.collins:
        return Icons.language_outlined;
      case DictionarySourceType.longman:
        return Icons.school_outlined;
    }
  }

  String _languageSupportLabel(DictionarySourceConfig config) {
    final languages = config.supportedLanguages;
    if (languages == null || languages.isEmpty) return '支持语言：全部';
    final sorted = languages.toList()..sort();
    return '支持语言：${sorted.join(', ')}';
  }
}

class _DictionarySourceLanguageTag extends StatelessWidget {
  const _DictionarySourceLanguageTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _DictionarySourceTestStatusLine extends StatelessWidget {
  const _DictionarySourceTestStatusLine({required this.result});

  final DictionarySourceTestResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (result.status) {
      DictionarySourceTestStatus.hit => theme.colorScheme.tertiary,
      DictionarySourceTestStatus.noResult => theme.colorScheme.onSurfaceVariant,
      DictionarySourceTestStatus.failed => theme.colorScheme.error,
    };
    final icon = switch (result.status) {
      DictionarySourceTestStatus.hit => Icons.check_circle_outline,
      DictionarySourceTestStatus.noResult => Icons.help_outline,
      DictionarySourceTestStatus.failed => Icons.error_outline,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _formatResult(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  String _formatResult() {
    final elapsed = '${result.elapsed.inMilliseconds} ms';
    final cache = result.fromCache ? ' · 缓存' : '';
    switch (result.status) {
      case DictionarySourceTestStatus.hit:
        return '命中 ${result.word} · $elapsed$cache';
      case DictionarySourceTestStatus.noResult:
        return '未命中或不可用 · $elapsed';
      case DictionarySourceTestStatus.failed:
        final message = result.message;
        if (message == null || message.isEmpty) return '失败 · $elapsed';
        return '失败 · $elapsed · $message';
    }
  }
}

class SettingsExperimentalFeaturesSection extends StatelessWidget {
  const SettingsExperimentalFeaturesSection({
    super.key,
    required this.settings,
  });

  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          icon: Icons.list_alt_outlined,
          title: '测试项列表',
          child: Column(
            children: [
              _ExperimentalFeatureTile(
                icon: Icons.rss_feed_outlined,
                title: 'RSS 入口',
                subtitle: '在首页显示 RSS 订阅与最新内容入口',
                value: settings.rssFeatureEnabled,
                onChanged: settings.setRssFeatureEnabled,
              ),
              const Divider(height: 1),
              _ExperimentalFeatureTile(
                icon: Icons.replay_outlined,
                title: '轻量复习',
                subtitle: '显示首页今日复习和训练页复习入口',
                value: settings.reviewFeatureEnabled,
                onChanged: settings.setReviewFeatureEnabled,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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
              OutlinedButton.icon(
                onPressed: onChooseFolder,
                icon: const Icon(Icons.drive_folder_upload_outlined),
                label: Text(hasFolder ? '更改位置' : '选择位置'),
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
            child: FilledButton.icon(
              onPressed: !hasFolder || backup.isSyncing ? null : onExportBackup,
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
        SettingsCard(
          icon: Icons.download_outlined,
          title: '导入与恢复',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: backup.isSyncing ? null : onImportBackup,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('导入备份'),
              ),
              OutlinedButton.icon(
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
                label: Text(
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
                children: _settingsChildrenWithSpacing(
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

List<Widget> _settingsChildrenWithSpacing(
  List<Widget> children,
  Widget spacing,
) {
  return [
    for (var i = 0; i < children.length; i++) ...[
      if (i != 0) spacing,
      children[i],
    ],
  ];
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

class SettingsSidebarItem extends StatelessWidget {
  const SettingsSidebarItem({
    super.key,
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final SettingsSection section;
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

class SettingsSectionHeading extends StatelessWidget {
  const SettingsSectionHeading({super.key, required this.section});

  final SettingsSection section;

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

class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
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

    return Material(
      color: colorScheme.surfaceContainerLowest,
      elevation: 1,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.05),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
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

class SettingsStatusLine extends StatelessWidget {
  const SettingsStatusLine({
    super.key,
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

class ResponsiveSettingsGrid extends StatelessWidget {
  const ResponsiveSettingsGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
}

class _ThemeModeControl extends StatelessWidget {
  const _ThemeModeControl({
    required this.settings,
    required this.onSwitchTheme,
  });

  final SettingsService settings;
  final ThemeMutationRunner onSwitchTheme;

  @override
  Widget build(BuildContext context) {
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
          onSwitchTheme(() => settings.setThemeMode(value.first));
        },
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.currentColor,
    required this.onColorChanged,
    required this.colorOptions,
  });

  final String label;
  final Color currentColor;
  final ValueChanged<Color> onColorChanged;
  final List<_ColorOption> colorOptions;

  @override
  Widget build(BuildContext context) {
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
            children: colorOptions.map((option) {
              final selected =
                  currentColor.toARGB32() == option.color.toARGB32();
              return Tooltip(
                message: option.name,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onColorChanged(option.color),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: option.color,
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
}

class _ExperimentalFeatureTile extends StatelessWidget {
  const _ExperimentalFeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ColorOption {
  const _ColorOption(this.name, this.color);

  final String name;
  final Color color;
}

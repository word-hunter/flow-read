import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
import 'package:flow_ai/flow_ai.dart';
import '../flow/flow_components.dart';
import 'settings_shared.dart';

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
    required this.aiAutomationMode,
    required this.onAutomationModeChanged,
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
  final AIAutomationMode aiAutomationMode;
  final ValueChanged<AIAutomationMode> onAutomationModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = settings.aiProvider;
    final successColor = theme.colorScheme.tertiary;
    const explanationLanguageOptions = [
      LanguageOption(code: 'zh', name: '中文'),
      LanguageOption(code: 'en', name: 'English'),
      LanguageOption(code: 'ja', name: '日本語'),
    ];
    final selectedExplanationLanguage =
        explanationLanguageOptions.any(
          (option) => option.code == settings.targetExplanationLanguage,
        )
        ? settings.targetExplanationLanguage
        : 'zh';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          icon: Icons.auto_awesome,
          title: '模型配置',
          child: ResponsiveSettingsGrid(
            children: [
              SettingsSelectField<String>(
                label: '默认解释语言',
                value: selectedExplanationLanguage,
                icon: Icons.record_voice_over_outlined,
                options: explanationLanguageOptions
                    .map(
                      (option) => SettingsSelectOption(
                        value: option.code,
                        label: option.name,
                      ),
                    )
                    .toList(),
                onChanged: settings.setTargetExplanationLanguage,
              ),
              SettingsSelectField<String>(
                label: '服务商',
                value: settings.aiProviderId,
                icon: Icons.hub_outlined,
                options: settings.aiProviders
                    .map(
                      (item) => SettingsSelectOption(
                        value: item.id,
                        label: item.label,
                      ),
                    )
                    .toList(),
                onChanged: onProviderChanged,
              ),
              FlowTextField(
                controller: modelController,
                enabled: provider.modelEditable,
                decoration: const InputDecoration(
                  labelText: '模型',
                  prefixIcon: Icon(Icons.memory_outlined, size: 20),
                  border: OutlineInputBorder(),
                ),
                onChanged: onModelChanged,
              ),
              FlowTextField(
                controller: baseUrlController,
                enabled: provider.baseUrlEditable,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  prefixIcon: Icon(Icons.link_outlined, size: 20),
                  border: OutlineInputBorder(),
                ),
                onChanged: onBaseUrlChanged,
              ),
              FlowTextField(
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
                  FlowButton.primary(
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
                    child: Text(testingConnection ? '测试中...' : '测试连接'),
                  ),
                  FlowButton.destructive(
                    onPressed: onClearConfig,
                    icon: const Icon(Icons.cleaning_services_outlined),
                    child: const Text('清除配置'),
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
                child: FlowButton.secondary(
                  onPressed: onClearCache,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  child: const Text('清除 AI 缓存'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsCard(
          icon: Icons.smart_toy_outlined,
          title: '自动化',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsStatusLine(
                icon: Icons.info_outline,
                text: _automationDescription(aiAutomationMode),
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              SegmentedButton<AIAutomationMode>(
                segments: const [
                  ButtonSegment(
                    value: AIAutomationMode.saving,
                    label: Text('节省'),
                  ),
                  ButtonSegment(
                    value: AIAutomationMode.assisted,
                    label: Text('辅助'),
                  ),
                  ButtonSegment(
                    value: AIAutomationMode.automatic,
                    label: Text('自动'),
                  ),
                ],
                selected: {aiAutomationMode},
                onSelectionChanged: (selected) {
                  if (selected.isNotEmpty) {
                    onAutomationModeChanged(selected.first);
                  }
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStatePropertyAll(theme.textTheme.labelSmall),
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

  static String _automationDescription(AIAutomationMode mode) {
    switch (mode) {
      case AIAutomationMode.saving:
        return '所有 AI 调用均需手动触发，不会自动消耗 token';
      case AIAutomationMode.assisted:
        return '读完后提示可生成总结，但需手动确认后才调用 AI';
      case AIAutomationMode.automatic:
        return '章节读完后自动生成总结（需额外配置条件限制）';
    }
  }
}

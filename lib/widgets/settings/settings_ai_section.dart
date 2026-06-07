import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
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
              DropdownButtonFormField<String>(
                initialValue: selectedExplanationLanguage,
                decoration: const InputDecoration(
                  labelText: '默认解释语言',
                  prefixIcon: Icon(Icons.record_voice_over_outlined, size: 20),
                  border: OutlineInputBorder(),
                ),
                items: explanationLanguageOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option.code,
                        child: Text(option.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    settings.setTargetExplanationLanguage(value);
                  }
                },
              ),
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

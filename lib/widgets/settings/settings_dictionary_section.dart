import 'package:flutter/material.dart';

import 'package:flow_dictionary/flow_dictionary.dart';
import '../../services/settings_service.dart';
import '../flow/flow_components.dart';
import 'settings_shared.dart';

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
                  FlowTextField(
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
                    child: FlowButton.primary(
                      onPressed: testingSources ? null : onTestSources,
                      icon: testingSources
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_find, size: 18),
                      child: Text(testingSources ? '测试中...' : '测试来源'),
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
                child: FlowButton.secondary(
                  onPressed: onClearCache,
                  icon: const Icon(Icons.cleaning_services_outlined),
                  child: const Text('清理词典缓存'),
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

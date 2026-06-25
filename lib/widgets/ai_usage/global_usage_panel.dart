import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../storage/repositories/ai_usage_repository.dart';
import '../flow/flow_components.dart';
import '../settings/settings_shared.dart';

class GlobalAIUsagePanel extends StatelessWidget {
  const GlobalAIUsagePanel({
    super.key,
    required this.summary,
    required this.onClearAll,
  });

  final AsyncValue<AIUsageSummary> summary;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      icon: Icons.query_stats_outlined,
      title: 'AI Token 消耗',
      child: summary.when(
        loading: () => const _UsageLoadingState(),
        error: (error, _) => _UsageErrorState(error: error),
        data: (data) {
          if (data.isEmpty) return const _UsageEmptyState();
          return _UsageSummaryContent(
            summary: data,
            onClearAll: onClearAll,
          );
        },
      ),
    );
  }
}

class _UsageSummaryContent extends StatelessWidget {
  const _UsageSummaryContent({
    required this.summary,
    required this.onClearAll,
  });

  final AIUsageSummary summary;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 28,
          runSpacing: 16,
          children: [
            _UsageMetric(
              label: 'Token 总计',
              value: _formatCount(summary.totalTokens),
              icon: Icons.token_outlined,
            ),
            _UsageMetric(
              label: 'API 请求',
              value: _formatCount(summary.totalCalls),
              icon: Icons.call_made_outlined,
            ),
            _UsageMetric(
              label: '输入 / 输出',
              value:
                  '${_formatCount(summary.totalPromptTokens)} / '
                  '${_formatCount(summary.totalCompletionTokens)}',
              icon: Icons.swap_horiz_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _UsageBreakdownList(
          title: '按操作类型',
          items: summary.byOperation,
          labelFor: _operationLabel,
        ),
        if (summary.byBook.isNotEmpty) ...[
          const SizedBox(height: 18),
          _UsageBreakdownList(
            title: '按书籍',
            items: summary.byBook,
          ),
        ],
        const SizedBox(height: 18),
        Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.7)),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FlowButton.destructive(
            onPressed: onClearAll,
            icon: const Icon(Icons.delete_outline),
            child: const Text('清空全部历史记录'),
          ),
        ),
      ],
    );
  }
}

class _UsageMetric extends StatelessWidget {
  const _UsageMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 260),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: colorScheme.primary),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageBreakdownList extends StatelessWidget {
  const _UsageBreakdownList({
    required this.title,
    required this.items,
    this.labelFor,
  });

  final String title;
  final List<AIUsageBreakdown> items;
  final String Function(String value)? labelFor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    labelFor?.call(item.key) ?? item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_formatCount(item.totalTokens)} tokens',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 74,
                  child: Text(
                    '${_formatCount(item.calls)} 次',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _UsageLoadingState extends StatelessWidget {
  const _UsageLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 12),
        Text('正在统计 Token 消耗...'),
      ],
    );
  }
}

class _UsageErrorState extends StatelessWidget {
  const _UsageErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return SettingsStatusLine(
      icon: Icons.error_outline,
      text: 'Token 用量暂无法读取：$error',
      color: Theme.of(context).colorScheme.error,
    );
  }
}

class _UsageEmptyState extends StatelessWidget {
  const _UsageEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.power_outlined,
          size: 30,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 10),
        Text(
          '暂无 API 调用记录',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '在阅读器中生成章节摘要、分析文本或翻译选段后，这里将展示 Token 消耗。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

String _operationLabel(String value) {
  switch (value) {
    case 'summary':
      return '章节摘要';
    case 'practice':
      return '章节练习';
    case 'chapter_preview':
      return '读前预览';
    case 'text_analysis':
      return '文本分析';
    case 'word_analysis':
      return '单词分析';
    case 'translation':
      return '翻译';
    case 'book_synthesis':
      return '全书洞察';
    case 'rss_summary':
      return 'RSS 摘要';
    case 'browser_explain':
      return '浏览器解释';
    case 'global_assistant':
      return 'AI 助手';
  }
  return value;
}

String _formatCount(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

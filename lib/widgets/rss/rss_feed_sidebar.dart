import 'package:flutter/material.dart';

import 'package:flow_rss/flow_rss.dart';
import '../flow/flow_components.dart';

class RssFeedSidebar extends StatelessWidget {
  final List<RssFeedSubscription> subscriptions;
  final String? selectedUrl;
  final RssLoadStatus subscriptionStatus;
  final RssError? subscriptionError;
  final RssArticleFilter articleFilter;
  final Map<RssArticleFilter, int> filterCounts;
  final bool isLatestSelected;
  final VoidCallback onSelectLatest;
  final void Function(String url) onSelectFeed;
  final ValueChanged<RssArticleFilter> onSelectArticleFilter;
  final VoidCallback onAddFeed;
  final void Function(RssFeedSubscription subscription) onEditFeed;
  final void Function(String url) onRemoveFeed;
  final VoidCallback onRetry;

  const RssFeedSidebar({
    super.key,
    required this.subscriptions,
    required this.selectedUrl,
    required this.subscriptionStatus,
    this.subscriptionError,
    required this.articleFilter,
    required this.filterCounts,
    required this.isLatestSelected,
    required this.onSelectLatest,
    required this.onSelectFeed,
    required this.onSelectArticleFilter,
    required this.onAddFeed,
    required this.onEditFeed,
    required this.onRemoveFeed,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.rss_feed, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '订阅源',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                tooltip: '添加订阅',
                onPressed: subscriptionStatus == RssLoadStatus.loading
                    ? null
                    : onAddFeed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
        if (subscriptionStatus == RssLoadStatus.loading &&
            subscriptions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (subscriptionStatus == RssLoadStatus.error &&
            subscriptions.isEmpty)
          _buildErrorState(context, theme)
        else if (subscriptions.isEmpty)
          _buildEmptyState(context, theme)
        else
          Expanded(
            child: Column(
              children: [
                if (subscriptionStatus == RssLoadStatus.loading)
                  const LinearProgressIndicator(minHeight: 2),
                if (subscriptionStatus == RssLoadStatus.error)
                  _buildInlineError(theme),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    children: [
                      _buildLatestItem(context, theme),
                      _buildArticleFilterItem(
                        context,
                        theme,
                        filter: RssArticleFilter.unread,
                        icon: Icons.chat_bubble_outline,
                        label: '未读文章',
                      ),
                      _buildArticleFilterItem(
                        context,
                        theme,
                        filter: RssArticleFilter.favorite,
                        icon: Icons.star_border_outlined,
                        label: '收藏',
                      ),
                      _buildArticleFilterItem(
                        context,
                        theme,
                        filter: RssArticleFilter.readLater,
                        icon: Icons.schedule_outlined,
                        label: '稍后读',
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 6, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '订阅源',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.settings_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.72),
                            ),
                          ],
                        ),
                      ),
                      ...subscriptions.map((sub) {
                        final isSelected = sub.url == selectedUrl;
                        return _buildFeedItem(context, sub, isSelected, theme);
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (subscriptionStatus != RssLoadStatus.loading &&
            subscriptions.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.2,
                  ),
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAddFeed,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '添加订阅源',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.rss_feed,
                size: 36,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.35,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '暂无 RSS 订阅',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '点击下方 + 添加 RSS 源',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.65,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(height: 10),
              Text(
                subscriptionError?.message ?? 'RSS 加载失败',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              FlowButton.secondary(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineError(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subscriptionError?.message ?? '订阅操作失败',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          FlowButton.text(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildLatestItem(BuildContext context, ThemeData theme) {
    final isSelected =
        isLatestSelected && articleFilter == RssArticleFilter.all;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onSelectLatest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '最新内容',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                _buildCountBadge(
                  theme,
                  filterCounts[RssArticleFilter.all] ?? 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArticleFilterItem(
    BuildContext context,
    ThemeData theme, {
    required RssArticleFilter filter,
    required IconData icon,
    required String label,
  }) {
    final isSelected = isLatestSelected && articleFilter == filter;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (!isLatestSelected) onSelectLatest();
            onSelectArticleFilter(filter);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                _buildCountBadge(theme, filterCounts[filter] ?? 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedItem(
    BuildContext context,
    RssFeedSubscription sub,
    bool isSelected,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onSelectFeed(sub.url),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                if (sub.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      sub.imageUrl!,
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.rss_feed,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (sub.lastFetchedAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(sub.lastFetchedAt!),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') onEditFeed(sub);
                    if (value == 'delete') onRemoveFeed(sub.url);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('编辑'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text('取消订阅', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${time.month}/${time.day}';
  }

  Widget _buildCountBadge(ThemeData theme, int count) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count.toString(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

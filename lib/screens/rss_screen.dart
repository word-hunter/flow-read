import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/rss_provider.dart';
import '../theme/app_constants.dart';
import '../widgets/rss/rss_article_list.dart';
import '../widgets/rss/rss_feed_sidebar.dart';

class RssScreen extends StatelessWidget {
  const RssScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RssProvider>();
    final theme = Theme.of(context);

    if (provider.subscriptions.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConstants.wideBreakpoint) {
          return _buildWideLayout(context, provider, theme);
        }
        return _buildNarrowLayout(context, provider, theme);
      },
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    RssProvider provider,
    ThemeData theme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 220,
          child: RssFeedSidebar(
            subscriptions: provider.subscriptions,
            selectedUrl: provider.selectedFeedUrl,
            isLoading: provider.isLoading,
            onSelectFeed: provider.selectFeed,
            onAddFeed: () => _showAddFeedDialog(context),
            onRemoveFeed: (url) => provider.removeFeed(url),
          ),
        ),
        VerticalDivider(
          width: 1,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        Expanded(child: _buildArticlePanel(context, provider, theme)),
      ],
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    RssProvider provider,
    ThemeData theme,
  ) {
    final hasSelection = provider.selectedFeedUrl != null;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(child: _buildFeedSelector(context, provider, theme)),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 22),
                tooltip: '添加订阅',
                onPressed: () => _showAddFeedDialog(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              if (provider.selectedFeedUrl != null)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: '刷新',
                  onPressed: provider.isFetchingArticles
                      ? null
                      : () => provider.refreshAll(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
            ],
          ),
        ),
        if (hasSelection)
          Expanded(child: _buildArticlePanel(context, provider, theme))
        else
          Expanded(
            child: Center(
              child: Text(
                '选择一个订阅源',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeedSelector(
    BuildContext context,
    RssProvider provider,
    ThemeData theme,
  ) {
    return DropdownButton<String?>(
      value: provider.selectedFeedUrl,
      hint: const Text('选择订阅源'),
      isExpanded: true,
      underline: const SizedBox(),
      items: provider.subscriptions.map((sub) {
        return DropdownMenuItem(
          value: sub.url,
          child: Text(
            sub.title,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        );
      }).toList(),
      onChanged: (url) {
        if (url != null) provider.selectFeed(url);
      },
    );
  }

  Widget _buildArticlePanel(
    BuildContext context,
    RssProvider provider,
    ThemeData theme,
  ) {
    if (provider.selectedFeedUrl == null) {
      return Center(
        child: Text(
          '选择一个订阅源',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    if (provider.isFetchingArticles && provider.articles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (provider.errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: theme.colorScheme.errorContainer,
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  onPressed: provider.clearError,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RssArticleList(
            articles: provider.articles,
            feedTitle: provider.selectedFeed?.title ?? '',
            unreadCount: provider.unreadCount,
            onRefresh: provider.refreshAll,
            onMarkRead: provider.markAsRead,
            onMarkUnread: provider.markAsUnread,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.rss_feed,
            size: 72,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无 RSS 订阅',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '添加你感兴趣的 RSS 源，开始阅读',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddFeedDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('添加订阅'),
          ),
        ],
      ),
    );
  }

  void _showAddFeedDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加 RSS 订阅'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入 RSS 源地址',
            prefixIcon: Icon(Icons.link),
          ),
          onSubmitted: (url) {
            if (url.trim().isNotEmpty) {
              context.read<RssProvider>().addFeed(url.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                context.read<RssProvider>().addFeed(url);
                Navigator.pop(ctx);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

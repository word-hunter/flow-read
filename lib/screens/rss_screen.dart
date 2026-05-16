import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rss_models.dart';
import '../providers/rss_provider.dart';
import '../theme/app_constants.dart';
import '../widgets/rss/rss_article_list.dart';
import '../widgets/rss/rss_feed_sidebar.dart';
import 'browser_screen.dart';

class RssScreen extends StatelessWidget {
  const RssScreen({super.key});

  static const _latestFeedValue = '__flow_read_latest__';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RssProvider>();
    final theme = Theme.of(context);

    if (provider.subscriptions.isEmpty) {
      return _buildEmptyState(context, provider, theme);
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
            isLatestSelected: provider.isLatestSelected,
            onSelectLatest: provider.selectLatest,
            onSelectFeed: provider.selectFeed,
            onAddFeed: () => _showAddFeedDialog(context),
            onEditFeed: (subscription) =>
                _showEditFeedDialog(context, subscription),
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
    final hasSelection = provider.subscriptions.isNotEmpty;

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
    return DropdownButton<String>(
      value: provider.selectedFeedUrl ?? _latestFeedValue,
      isExpanded: true,
      underline: const SizedBox(),
      items: [
        DropdownMenuItem(
          value: _latestFeedValue,
          child: Text(
            '最新内容',
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        ...provider.subscriptions.map((sub) {
          return DropdownMenuItem(
            value: sub.url,
            child: Text(
              sub.title,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          );
        }),
      ],
      onChanged: (url) {
        if (url == _latestFeedValue) {
          provider.selectLatest();
        } else if (url != null) {
          provider.selectFeed(url);
        }
      },
    );
  }

  Widget _buildArticlePanel(
    BuildContext context,
    RssProvider provider,
    ThemeData theme,
  ) {
    if (provider.subscriptions.isEmpty) {
      return Center(
        child: Text(
          '暂无 RSS 订阅',
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
            articles: provider.visibleArticles,
            feedTitle: provider.currentTitle,
            unreadCount: provider.unreadCount,
            query: provider.articleQuery,
            showFeedName: provider.isLatestSelected,
            onRefresh: provider.refreshAll,
            onSearchChanged: provider.updateArticleQuery,
            onMarkRead: provider.markAsRead,
            onMarkUnread: provider.markAsUnread,
            onOpenOriginal: (article) =>
                _openOriginalArticle(context, provider, article),
          ),
        ),
      ],
    );
  }

  void _openOriginalArticle(
    BuildContext context,
    RssProvider provider,
    RssArticle article,
  ) {
    final link = article.link?.trim();
    if (link == null || link.isEmpty) return;
    provider.markAsRead(article.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            BrowserScreen(initialUrl: link, initialTitle: article.title),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    RssProvider provider,
    ThemeData theme,
  ) {
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
          if (provider.errorMessage != null) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
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
                      tooltip: '关闭',
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
            ),
          ],
          FilledButton.icon(
            onPressed: provider.isLoading
                ? null
                : () => _showAddFeedDialog(context),
            icon: provider.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(provider.isLoading ? '正在添加' : '添加订阅'),
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

  void _showEditFeedDialog(
    BuildContext context,
    RssFeedSubscription subscription,
  ) {
    final titleController = TextEditingController(text: subscription.title);
    final urlController = TextEditingController(text: subscription.url);
    final descriptionController = TextEditingController(
      text: subscription.description ?? '',
    );
    var refreshMetadata = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('编辑 RSS 订阅'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: '名称',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'RSS 地址',
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '备注',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('重新获取源信息'),
                  value: refreshMetadata,
                  onChanged: (value) => setState(() => refreshMetadata = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final url = urlController.text.trim();
                if (url.isNotEmpty) {
                  context.read<RssProvider>().updateFeed(
                    originalUrl: subscription.url,
                    url: url,
                    title: titleController.text,
                    description: descriptionController.text,
                    refreshMetadata: refreshMetadata,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

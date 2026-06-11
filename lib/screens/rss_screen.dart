import 'package:flow_rss/flow_rss.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../providers/rss_riverpod_provider.dart';
import '../theme/app_constants.dart';
import '../widgets/flow/flow_components.dart';
import '../widgets/rss/rss_article_list.dart';
import '../widgets/rss/rss_feed_sidebar.dart';
import 'browser_screen.dart';
import 'rss_article_detail_screen.dart';

class RssScreen extends riverpod.ConsumerWidget {
  const RssScreen({super.key});

  static const _latestFeedValue = '__flow_read_latest__';

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final state = ref.watch(rssNotifierProvider);
    final theme = Theme.of(context);

    if (state.subscriptionStatus == RssLoadStatus.idle &&
        state.articlesStatus == RssLoadStatus.idle &&
        state.subscriptions.isEmpty &&
        state.articles.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(rssNotifierProvider.notifier).init();
      });
    }

    if (state.subscriptions.isEmpty) {
      return _buildEmptyState(context, ref, state, theme);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConstants.wideBreakpoint) {
          return _buildWideLayout(context, ref, state, theme);
        }
        return _buildNarrowLayout(context, ref, state, theme);
      },
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    riverpod.WidgetRef ref,
    RssState state,
    ThemeData theme,
  ) {
    final notifier = ref.read(rssNotifierProvider.notifier);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 220,
          child: RssFeedSidebar(
            subscriptions: state.subscriptions,
            selectedUrl: state.selectedFeedUrl,
            subscriptionStatus: state.subscriptionStatus,
            subscriptionError: state.subscriptionError,
            articleFilter: state.articleFilter,
            filterCounts: {
              for (final filter in RssArticleFilter.values)
                filter: state.articleCountForFilter(filter),
            },
            isLatestSelected: state.isLatestSelected,
            onSelectLatest: notifier.selectLatest,
            onSelectFeed: notifier.selectFeed,
            onSelectArticleFilter: notifier.updateArticleFilter,
            onAddFeed: () => _showAddFeedDialog(context, ref),
            onEditFeed: (subscription) =>
                _showEditFeedDialog(context, ref, subscription),
            onRemoveFeed: (url) => notifier.removeFeed(url),
            onRetry: () => notifier.retry(),
          ),
        ),
        VerticalDivider(
          width: 1,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        Expanded(child: _buildArticlePanel(context, ref, state, theme)),
      ],
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    riverpod.WidgetRef ref,
    RssState state,
    ThemeData theme,
  ) {
    final hasSelection = state.subscriptions.isNotEmpty;
    final notifier = ref.read(rssNotifierProvider.notifier);

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
              Expanded(child: _buildFeedSelector(context, ref, state, theme)),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 22),
                tooltip: '添加订阅',
                onPressed: () => _showAddFeedDialog(context, ref),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              if (state.selectedFeedUrl != null)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: '刷新',
                  onPressed: state.isFetchingArticles
                      ? null
                      : () => notifier.refreshAll(),
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
          Expanded(child: _buildArticlePanel(context, ref, state, theme))
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
    riverpod.WidgetRef ref,
    RssState state,
    ThemeData theme,
  ) {
    final notifier = ref.read(rssNotifierProvider.notifier);
    return DropdownButton<String>(
      value: state.selectedFeedUrl ?? _latestFeedValue,
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
        ...state.subscriptions.map((sub) {
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
          notifier.selectLatest();
        } else if (url != null) {
          notifier.selectFeed(url);
        }
      },
    );
  }

  Widget _buildArticlePanel(
    BuildContext context,
    riverpod.WidgetRef ref,
    RssState state,
    ThemeData theme,
  ) {
    final notifier = ref.read(rssNotifierProvider.notifier);
    if (state.subscriptions.isEmpty) {
      return Center(
        child: Text(
          '暂无 RSS 订阅',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (state.errorMessage != null &&
            (state.subscriptionError != null ||
                (state.articlesError != null &&
                    state.articlesStatus != RssLoadStatus.error)))
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
                    state.errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                FlowButton.text(
                  onPressed: notifier.retry,
                  child: const Text('重试'),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  onPressed: notifier.clearError,
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
            articles: state.visibleArticles,
            feedTitle: state.currentTitle,
            unreadCount: state.unreadCount,
            query: state.articleQuery,
            filter: state.articleFilter,
            filterCounts: {
              for (final filter in RssArticleFilter.values)
                filter: state.articleCountForFilter(filter),
            },
            articlesStatus: state.articlesStatus,
            articlesError: state.articlesError,
            hasCachedArticles: state.articles.isNotEmpty,
            showFeedName: state.isLatestSelected,
            onRefresh: notifier.refreshAll,
            onRetry: notifier.retry,
            onSearchChanged: notifier.updateArticleQuery,
            onFilterChanged: notifier.updateArticleFilter,
            onMarkRead: notifier.markAsRead,
            onMarkUnread: notifier.markAsUnread,
            onSetFavorite: notifier.setArticleFavorite,
            onSetReadLater: notifier.setArticleReadLater,
            onOpenArticle: (article) =>
                _openArticleDetail(context, state, article),
            onOpenOriginal: (article) =>
                _openOriginalArticle(context, ref, state, article),
          ),
        ),
      ],
    );
  }

  void _openOriginalArticle(
    BuildContext context,
    riverpod.WidgetRef ref,
    RssState state,
    RssArticle article,
  ) {
    final link = article.link?.trim();
    if (link == null || link.isEmpty) return;
    ref.read(rssNotifierProvider.notifier).markAsRead(article.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            BrowserScreen(initialUrl: link, initialTitle: article.title),
      ),
    );
  }

  void _openArticleDetail(
    BuildContext context,
    RssState state,
    RssArticle article,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RssArticleDetailScreen(
          articles: List<RssArticle>.of(state.visibleArticles),
          initialArticleId: article.id,
          showFeedName: state.isLatestSelected,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    riverpod.WidgetRef ref,
    RssState state,
    ThemeData theme,
  ) {
    final notifier = ref.read(rssNotifierProvider.notifier);
    if (state.subscriptionStatus == RssLoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.subscriptionStatus == RssLoadStatus.error) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 52,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 14),
                Text(
                  state.subscriptionError?.message ?? 'RSS 加载失败',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 18),
                FlowButton.secondary(
                  onPressed: notifier.retry,
                  icon: const Icon(Icons.refresh),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
          if (state.errorMessage != null) ...[
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
                        state.errorMessage!,
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
                      onPressed: notifier.clearError,
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
          FlowButton.primary(
            onPressed: state.isLoading
                ? null
                : () => _showAddFeedDialog(context, ref),
            icon: state.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            child: Text(state.isLoading ? '正在添加' : '添加订阅'),
          ),
        ],
      ),
    );
  }

  void _showAddFeedDialog(
    BuildContext context,
    riverpod.WidgetRef ref,
  ) {
    final controller = TextEditingController();
    final notifier = ref.read(rssNotifierProvider.notifier);
    showDialog(
      context: context,
      builder: (ctx) => FlowDialog(
        title: const Text('添加 RSS 订阅'),
        content: FlowTextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入 RSS 源地址',
            prefixIcon: Icon(Icons.link),
          ),
          onSubmitted: (url) {
            if (url.trim().isNotEmpty) {
              notifier.addFeed(url.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          FlowButton.text(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FlowButton.primary(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                notifier.addFeed(url);
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
    riverpod.WidgetRef ref,
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
        builder: (context, setState) => FlowDialog(
          title: const Text('编辑 RSS 订阅'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FlowTextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: '名称',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                FlowTextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'RSS 地址',
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 12),
                FlowTextField(
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
            FlowButton.text(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FlowButton.primary(
              onPressed: () {
                final url = urlController.text.trim();
                if (url.isNotEmpty) {
                  ref
                      .read(rssNotifierProvider.notifier)
                      .updateFeed(
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

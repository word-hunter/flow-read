import 'package:flow_rss/flow_rss.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../providers/rss_riverpod_provider.dart';
import '../providers/reading/word_lookup_notifier.dart';
import '../theme/app_constants.dart';
import '../widgets/flow/flow_components.dart';
import '../widgets/reader/reader_word_sidebar.dart';
import '../widgets/rss/rss_article_list.dart';
import '../widgets/rss/rss_interaction_styles.dart';
import 'rss_article_detail_screen.dart';

class RssScreen extends riverpod.ConsumerStatefulWidget {
  const RssScreen({super.key});

  @override
  riverpod.ConsumerState<RssScreen> createState() => _RssScreenState();
}

class _RssScreenState extends riverpod.ConsumerState<RssScreen> {
  static const _latestFeedValue = '__flow_read_latest__';
  String? _selectedArticleId;
  bool _isArticleListCollapsed = false;

  @override
  Widget build(BuildContext context) {
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
          return _buildWideLayout(context, ref, state, theme, constraints);
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
    BoxConstraints constraints,
  ) {
    final lookupState = ref.watch(wordLookupNotifierProvider);
    final listWidth = constraints.maxWidth >= 1120 ? 340.0 : 304.0;
    final effectiveSelectedArticleId = _effectiveSelectedArticleId(state);
    final articleListWidth = _isArticleListCollapsed ? 48.0 : listWidth;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: articleListWidth,
          child: _isArticleListCollapsed
              ? _buildCollapsedArticleListRail(theme, state)
              : _buildWideArticleListPanel(
                  context,
                  ref,
                  state,
                  theme,
                  selectedArticleId: effectiveSelectedArticleId,
                ),
        ),
        VerticalDivider(
          width: 1,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        Expanded(
          child: _buildArticleDetailPanel(
            state,
            theme,
            selectedArticleId: effectiveSelectedArticleId,
          ),
        ),
        if (lookupState.selectedWord != null) ...[
          VerticalDivider(
            width: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          ReaderWordSidebar(
            onClose: () =>
                ref.read(wordLookupNotifierProvider.notifier).clearWordLookup(),
          ),
        ],
      ],
    );
  }

  Widget _buildWideArticleListPanel(
    BuildContext context,
    riverpod.WidgetRef ref,
    RssState state,
    ThemeData theme, {
    required String? selectedArticleId,
  }) {
    return Column(
      children: [
        _buildWideFeedControlBar(context, ref, state, theme),
        Expanded(
          child: _buildArticlePanel(
            context,
            ref,
            state,
            theme,
            selectedArticleId: selectedArticleId,
            onOpenArticle: _selectInlineArticle,
          ),
        ),
      ],
    );
  }

  Widget _buildWideFeedControlBar(
    BuildContext context,
    riverpod.WidgetRef ref,
    RssState state,
    ThemeData theme,
  ) {
    final notifier = ref.read(rssNotifierProvider.notifier);
    final selectedFeed = state.selectedFeed;
    final selectedValue =
        state.selectedFeedUrl != null &&
            state.subscriptions.any((sub) => sub.url == state.selectedFeedUrl)
        ? state.selectedFeedUrl!
        : _latestFeedValue;

    return Container(
      height: 56,
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedValue,
                isExpanded: true,
                borderRadius: BorderRadius.circular(8),
                icon: const Icon(Icons.expand_more, size: 18),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                items: [
                  const DropdownMenuItem(
                    value: _latestFeedValue,
                    child: Text(
                      '最新内容',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...state.subscriptions.map((sub) {
                    final title = sub.title.trim().isEmpty
                        ? sub.url
                        : sub.title.trim();
                    return DropdownMenuItem(
                      value: sub.url,
                      child: Text(title, overflow: TextOverflow.ellipsis),
                    );
                  }),
                ],
                onChanged: (url) {
                  if (url == null) return;
                  setState(() => _selectedArticleId = null);
                  if (url == _latestFeedValue) {
                    notifier.selectLatest();
                  } else {
                    notifier.selectFeed(url);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.keyboard_double_arrow_left, size: 20),
            tooltip: '折叠列表',
            onPressed: () => setState(() => _isArticleListCollapsed = true),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            style: rssIconButtonStyle(theme),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            tooltip: '添加订阅',
            onPressed: state.subscriptionStatus == RssLoadStatus.loading
                ? null
                : () => _showAddFeedDialog(context, ref),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            style: rssIconButtonStyle(theme),
          ),
          IconButton(
            icon: state.isFetchingArticles
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 20),
            tooltip: state.isFetchingArticles ? '刷新中' : '刷新',
            onPressed: state.isFetchingArticles ? null : notifier.refreshAll,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            style: rssIconButtonStyle(theme),
          ),
          if (selectedFeed != null)
            FlowMenuButton<String>(
              entries: const [
                FlowMenuItem(
                  value: 'edit',
                  label: '编辑',
                  icon: Icons.edit_outlined,
                ),
                FlowMenuDivider(),
                FlowMenuItem(
                  value: 'delete',
                  label: '取消订阅',
                  icon: Icons.delete_outline,
                  destructive: true,
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditFeedDialog(context, ref, selectedFeed);
                } else if (value == 'delete') {
                  setState(() => _selectedArticleId = null);
                  notifier.removeFeed(selectedFeed.url);
                }
              },
              builder: (context, isOpen, toggle) => IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                tooltip: '订阅设置',
                onPressed: toggle,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                style: rssIconButtonStyle(theme, selected: isOpen),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsedArticleListRail(ThemeData theme, RssState state) {
    final unreadCount = state.unreadCount;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.keyboard_double_arrow_right, size: 20),
                tooltip: '展开列表',
                onPressed: () =>
                    setState(() => _isArticleListCollapsed = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                style: rssIconButtonStyle(theme),
              ),
            ),
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 10),
          Tooltip(
            message: unreadCount > 0 ? '$unreadCount 篇未读' : '暂无未读',
            child: Icon(
              unreadCount > 0
                  ? Icons.mark_email_unread_outlined
                  : Icons.inbox_outlined,
              size: 18,
              color: unreadCount > 0
                  ? rssAccentColor(theme)
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.62),
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              unreadCount > 99 ? '99+' : '$unreadCount',
              style: theme.textTheme.labelSmall?.copyWith(
                color: rssAccentColor(theme),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArticleDetailPanel(
    RssState state,
    ThemeData theme, {
    required String? selectedArticleId,
  }) {
    final detailArticles = _detailArticlesFor(state, selectedArticleId);
    if (detailArticles.isEmpty || selectedArticleId == null) {
      return _buildDetailPlaceholder(theme);
    }

    return RssArticleDetailPane(
      articles: detailArticles,
      initialArticleId: selectedArticleId,
      showFeedName: state.isLatestSelected,
      markInitialArticleAsRead: false,
      showLookupSheet: false,
      onArticleSelected: (article) {
        if (_selectedArticleId == article.id) return;
        setState(() => _selectedArticleId = article.id);
      },
    );
  }

  Widget _buildDetailPlaceholder(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.article_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 12),
          Text(
            '选择一篇文章',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String? _effectiveSelectedArticleId(RssState state) {
    final selectedArticleId = _selectedArticleId;
    if (selectedArticleId != null &&
        state.articles.any((article) => article.id == selectedArticleId)) {
      return selectedArticleId;
    }

    final visibleArticles = state.visibleArticles;
    if (visibleArticles.isEmpty) return null;
    return visibleArticles.first.id;
  }

  List<RssArticle> _detailArticlesFor(
    RssState state,
    String? selectedArticleId,
  ) {
    final visibleArticles = state.visibleArticles;
    if (selectedArticleId == null) return visibleArticles;
    if (visibleArticles.any((article) => article.id == selectedArticleId)) {
      return List<RssArticle>.of(visibleArticles);
    }

    final selectedArticle = state.articles
        .where((article) => article.id == selectedArticleId)
        .firstOrNull;
    if (selectedArticle == null) return List<RssArticle>.of(visibleArticles);
    return [
      selectedArticle,
      ...visibleArticles.where((article) => article.id != selectedArticleId),
    ];
  }

  void _selectInlineArticle(RssArticle article) {
    if (_selectedArticleId != article.id) {
      setState(() => _selectedArticleId = article.id);
    }
    if (!article.isRead) {
      ref.read(rssNotifierProvider.notifier).markAsRead(article.id);
    }
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
                style: rssIconButtonStyle(theme),
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
                  style: rssIconButtonStyle(theme),
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
        if (_selectedArticleId != null) {
          setState(() => _selectedArticleId = null);
        }
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
    ThemeData theme, {
    String? selectedArticleId,
    ValueChanged<RssArticle>? onOpenArticle,
  }) {
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
                  style: rssIconButtonStyle(theme, destructive: true),
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
            selectedArticleId: selectedArticleId,
            showTitleRow: onOpenArticle == null,
            onRefresh: notifier.refreshAll,
            onRetry: notifier.retry,
            onSearchChanged: (query) {
              if (_selectedArticleId != null) {
                setState(() => _selectedArticleId = null);
              }
              notifier.updateArticleQuery(query);
            },
            onFilterChanged: (filter) {
              if (_selectedArticleId != null) {
                setState(() => _selectedArticleId = null);
              }
              notifier.updateArticleFilter(filter);
            },
            onMarkRead: notifier.markAsRead,
            onOpenArticle:
                onOpenArticle ??
                (article) => _openArticleDetail(context, state, article),
          ),
        ),
      ],
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
                      style: rssIconButtonStyle(theme, destructive: true),
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

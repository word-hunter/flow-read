import 'package:flutter/material.dart';

import 'package:flow_rss/flow_rss.dart';
import '../flow/flow_components.dart';
import 'rss_interaction_styles.dart';

class RssArticleList extends StatefulWidget {
  final List<RssArticle> articles;
  final String feedTitle;
  final int unreadCount;
  final String query;
  final RssArticleFilter filter;
  final Map<RssArticleFilter, int> filterCounts;
  final RssLoadStatus articlesStatus;
  final RssError? articlesError;
  final bool hasCachedArticles;
  final bool showFeedName;
  final String? selectedArticleId;
  final bool showTitleRow;
  final List<RssArticleFilter> filters;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<RssArticleFilter> onFilterChanged;
  final Future<void> Function(String id) onMarkRead;
  final ValueChanged<RssArticle>? onOpenArticle;

  const RssArticleList({
    super.key,
    required this.articles,
    required this.feedTitle,
    required this.unreadCount,
    required this.query,
    required this.filter,
    required this.filterCounts,
    required this.articlesStatus,
    this.articlesError,
    required this.hasCachedArticles,
    required this.showFeedName,
    this.selectedArticleId,
    this.showTitleRow = true,
    this.filters = const [RssArticleFilter.all, RssArticleFilter.unread],
    required this.onRefresh,
    required this.onRetry,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onMarkRead,
    this.onOpenArticle,
  });

  @override
  State<RssArticleList> createState() => _RssArticleListState();
}

class _RssArticleListState extends State<RssArticleList> {
  late final TextEditingController _searchController;
  String? _hoveredArticleId;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant RssArticleList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _searchController.text) {
      _searchController
        ..text = widget.query
        ..selection = TextSelection.collapsed(offset: widget.query.length);
    }
    if (_hoveredArticleId != null &&
        !widget.articles.any((article) => article.id == _hoveredArticleId)) {
      _hoveredArticleId = null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = widget.articlesStatus == RssLoadStatus.loading;
    final isError = widget.articlesStatus == RssLoadStatus.error;

    if (isLoading && widget.articles.isEmpty) {
      return Column(
        children: [
          _buildHeader(context, theme),
          Expanded(child: _buildLoadingState(theme)),
        ],
      );
    }

    if (isError && widget.articles.isEmpty && !widget.hasCachedArticles) {
      return Column(
        children: [
          _buildHeader(context, theme),
          Expanded(child: _buildErrorState(theme)),
        ],
      );
    }

    if (widget.articles.isEmpty) {
      return Column(
        children: [
          _buildHeader(context, theme),
          Expanded(child: _buildEmptyState(theme)),
        ],
      );
    }

    return Column(
      children: [
        _buildHeader(context, theme),
        if (isLoading) const LinearProgressIndicator(minHeight: 2),
        if (isError) _buildCachedErrorBanner(theme),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: widget.articles.length,
              itemBuilder: (context, index) {
                final article = widget.articles[index];
                return _buildArticleCard(
                  context,
                  article,
                  theme,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final filters = widget.filters.isEmpty
        ? const [RssArticleFilter.all, RssArticleFilter.unread]
        : widget.filters;
    final selectedFilter = filters.contains(widget.filter)
        ? widget.filter
        : filters.first;
    return Container(
      padding: EdgeInsets.fromLTRB(14, widget.showTitleRow ? 10 : 12, 14, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showTitleRow) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.feedTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.unreadCount} 未读',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: widget.articlesStatus == RssLoadStatus.loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 20),
                  tooltip: widget.articlesStatus == RssLoadStatus.loading
                      ? '刷新中'
                      : '刷新',
                  onPressed: widget.articlesStatus == RssLoadStatus.loading
                      ? null
                      : () => widget.onRefresh(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  style: rssIconButtonStyle(theme),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            height: 36,
            child: _RssFilterSegmentedControl(
              filters: filters,
              selectedFilter: selectedFilter,
              labelFor: _filterLabel,
              iconFor: _filterIcon,
              onChanged: widget.onFilterChanged,
              theme: theme,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: FlowTextField(
              controller: _searchController,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                isDense: true,
                hintText: '搜索文章',
                prefixIcon: const Icon(Icons.search, size: 16),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 34,
                  minHeight: 34,
                ),
                suffixIcon: widget.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        tooltip: '清空搜索',
                        onPressed: () => widget.onSearchChanged(''),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                        style: rssIconButtonStyle(theme),
                      ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: widget.onSearchChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 14),
          Text(
            '正在加载文章…',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 44, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              widget.articlesError?.message ?? '文章加载失败',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FlowButton.secondary(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final isFiltered =
        widget.query.trim().isNotEmpty || widget.filter != RssArticleFilter.all;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.article_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            _emptyMessage(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (isFiltered) ...[
            const SizedBox(height: 6),
            Text(
              '尝试其他筛选条件',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.68,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCachedErrorBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.72),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            size: 18,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '正在显示缓存内容，上次刷新失败。${widget.articlesError?.message ?? ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          FlowButton.text(
            onPressed: widget.onRetry,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(
    BuildContext context,
    RssArticle article,
    ThemeData theme,
  ) {
    final isSelected = article.id == widget.selectedArticleId;
    final isHovered = _hoveredArticleId == article.id;
    final accentColor = rssAccentColor(theme);
    final borderColor = isSelected
        ? accentColor.withValues(alpha: 0.46)
        : isHovered
        ? accentColor.withValues(alpha: 0.28)
        : article.isRead
        ? Colors.transparent
        : accentColor.withValues(alpha: 0.14);
    final backgroundColor = isSelected
        ? accentColor.withValues(alpha: 0.12)
        : isHovered
        ? rssAccentHoverColor(theme).withValues(alpha: 0.07)
        : article.isRead
        ? theme.colorScheme.surface
        : accentColor.withValues(alpha: 0.05);
    final radius = BorderRadius.circular(10);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: radius,
          hoverColor: Colors.transparent,
          focusColor: rssHoverColor(theme, selected: isSelected),
          highlightColor: rssPressedColor(theme),
          onHover: (hovering) {
            if (hovering) {
              if (_hoveredArticleId != article.id) {
                setState(() => _hoveredArticleId = article.id);
              }
              return;
            }
            if (_hoveredArticleId == article.id) {
              setState(() => _hoveredArticleId = null);
            }
          },
          onTap: () {
            final onOpenArticle = widget.onOpenArticle;
            if (onOpenArticle != null) {
              onOpenArticle(article);
              return;
            }
            if (!article.isRead) {
              widget.onMarkRead(article.id);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        article.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: article.isRead
                              ? FontWeight.normal
                              : FontWeight.w600,
                          color: article.isRead
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                          height: 1.22,
                        ),
                      ),
                    ),
                    if (!article.isRead)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(top: 6, left: 8),
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (_hasArticleMetadata(article)) ...[
                  const SizedBox(height: 7),
                  _buildArticleMetadata(article, theme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _hasArticleMetadata(RssArticle article) {
    return (widget.showFeedName && article.feedTitle.trim().isNotEmpty) ||
        article.pubDate != null;
  }

  Widget _buildArticleMetadata(RssArticle article, ThemeData theme) {
    final source = widget.showFeedName ? article.feedTitle.trim() : '';
    return Row(
      children: [
        if (source.isNotEmpty) ...[
          Flexible(
            child: _buildMetadataItem(
              theme,
              icon: Icons.rss_feed,
              label: source,
              flexibleLabel: true,
            ),
          ),
          if (article.pubDate != null) const SizedBox(width: 10),
        ],
        if (article.pubDate != null)
          _buildMetadataItem(
            theme,
            icon: Icons.schedule,
            label: _formatDate(article.pubDate!),
          ),
      ],
    );
  }

  Widget _buildMetadataItem(
    ThemeData theme, {
    required IconData icon,
    required String label,
    bool flexibleLabel = false,
  }) {
    final foreground = theme.colorScheme.onSurfaceVariant.withValues(
      alpha: 0.64,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: foreground),
        const SizedBox(width: 4),
        if (flexibleLabel)
          Flexible(child: _metadataLabel(theme, label, foreground))
        else
          _metadataLabel(theme, label, foreground),
      ],
    );
  }

  Widget _metadataLabel(ThemeData theme, String label, Color foreground) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelSmall?.copyWith(
        color: foreground,
        fontWeight: FontWeight.w600,
        height: 1.1,
      ),
    );
  }

  String _emptyMessage() {
    if (widget.query.trim().isNotEmpty) return '没有匹配的文章';
    return switch (widget.filter) {
      RssArticleFilter.all => '暂无文章',
      RssArticleFilter.unread => '暂无未读文章',
      RssArticleFilter.favorite => '暂无收藏文章',
      RssArticleFilter.readLater => '暂无稍后读文章',
    };
  }

  String _filterLabel(RssArticleFilter filter) {
    final count = widget.filterCounts[filter] ?? 0;
    final label = switch (filter) {
      RssArticleFilter.all => '全部',
      RssArticleFilter.unread => '未读',
      RssArticleFilter.favorite => '收藏',
      RssArticleFilter.readLater => '稍后读',
    };
    return count > 0 ? '$label $count' : label;
  }

  IconData _filterIcon(RssArticleFilter filter) {
    return switch (filter) {
      RssArticleFilter.all => Icons.inbox_outlined,
      RssArticleFilter.unread => Icons.mark_email_unread_outlined,
      RssArticleFilter.favorite => Icons.star_border_outlined,
      RssArticleFilter.readLater => Icons.watch_later_outlined,
    };
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.month}/${date.day}';
  }
}

class _RssFilterSegmentedControl extends StatelessWidget {
  const _RssFilterSegmentedControl({
    required this.filters,
    required this.selectedFilter,
    required this.labelFor,
    required this.iconFor,
    required this.onChanged,
    required this.theme,
  });

  final List<RssArticleFilter> filters;
  final RssArticleFilter selectedFilter;
  final String Function(RssArticleFilter filter) labelFor;
  final IconData Function(RssArticleFilter filter) iconFor;
  final ValueChanged<RssArticleFilter> onChanged;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final radius = BorderRadius.circular(18);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: radius,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < filters.length; index++) ...[
            if (index > 0)
              ColoredBox(
                color: colorScheme.outlineVariant.withValues(alpha: 0.72),
                child: const SizedBox(width: 1),
              ),
            Expanded(
              child: _RssFilterSegment(
                label: labelFor(filters[index]),
                icon: iconFor(filters[index]),
                selected: filters[index] == selectedFilter,
                onTap: () => onChanged(filters[index]),
                theme: theme,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RssFilterSegment extends StatelessWidget {
  const _RssFilterSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final accentColor = rssAccentColor(theme);
    final foreground = selected
        ? rssOnAccentColor(theme)
        : colorScheme.onSurfaceVariant;
    final background = selected ? accentColor : Colors.transparent;

    return Material(
      color: background,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        hoverColor: rssHoverColor(theme, selected: selected),
        focusColor: rssHoverColor(theme, selected: selected),
        highlightColor: rssPressedColor(theme),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

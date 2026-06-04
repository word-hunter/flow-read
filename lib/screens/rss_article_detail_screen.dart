import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../models/rss_models.dart';
import '../providers/rss_provider.dart';
import '../providers/rss_riverpod_provider.dart';
import '../theme/app_constants.dart';
import '../widgets/font_settings_sheet.dart';
import '../widgets/rss/rss_article_body_view.dart';
import 'browser_screen.dart';

class RssArticleDetailScreen extends riverpod.ConsumerStatefulWidget {
  final List<RssArticle> articles;
  final String initialArticleId;
  final bool showFeedName;

  const RssArticleDetailScreen({
    super.key,
    required this.articles,
    required this.initialArticleId,
    required this.showFeedName,
  });

  @override
  riverpod.ConsumerState<RssArticleDetailScreen> createState() =>
      _RssArticleDetailScreenState();
}

class _RssArticleDetailScreenState
    extends riverpod.ConsumerState<RssArticleDetailScreen> {
  late String _currentArticleId;
  bool _isIntensiveReading = false;

  @override
  void initState() {
    super.initState();
    _currentArticleId = widget.initialArticleId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _markCurrentAsRead());
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(rssProvider);
    final theme = Theme.of(context);
    final currentIndex = _currentIndex;
    final article = currentIndex == -1 ? null : widget.articles[currentIndex];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回列表',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('RSS 阅读'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            tooltip: '阅读设置',
            onPressed: () => _showReadingSettings(context),
          ),
        ],
      ),
      body: article == null
          ? _buildMissingArticle(theme)
          : Column(
              children: [
                _buildActionBar(
                  context,
                  provider,
                  article,
                  currentIndex,
                  theme,
                ),
                Expanded(child: _buildArticleBody(context, article, theme)),
              ],
            ),
    );
  }

  int get _currentIndex {
    return widget.articles.indexWhere(
      (article) => article.id == _currentArticleId,
    );
  }

  Widget _buildMissingArticle(ThemeData theme) {
    return Center(
      child: Text(
        '文章不可用',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildActionBar(
    BuildContext context,
    RssProvider provider,
    RssArticle article,
    int currentIndex,
    ThemeData theme,
  ) {
    final canGoPrevious = currentIndex > 0;
    final canGoNext = currentIndex < widget.articles.length - 1;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: '上一篇',
                onPressed: canGoPrevious
                    ? () => _selectArticle(widget.articles[currentIndex - 1])
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: '下一篇',
                onPressed: canGoNext
                    ? () => _selectArticle(widget.articles[currentIndex + 1])
                    : null,
              ),
              const SizedBox(width: 8),
              VerticalDivider(
                width: 1,
                indent: 14,
                endIndent: 14,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  article.isRead
                      ? Icons.mark_email_unread
                      : Icons.mark_email_read,
                ),
                tooltip: article.isRead ? '标记未读' : '标记已读',
                onPressed: () => _toggleRead(article),
              ),
              IconButton(
                icon: Icon(
                  article.isFavorite ? Icons.star : Icons.star_border_outlined,
                ),
                tooltip: article.isFavorite ? '取消收藏' : '收藏',
                color: article.isFavorite ? theme.colorScheme.primary : null,
                onPressed: () => provider.setArticleFavorite(
                  article.id,
                  !article.isFavorite,
                ),
              ),
              IconButton(
                icon: Icon(
                  article.isReadLater
                      ? Icons.watch_later
                      : Icons.watch_later_outlined,
                ),
                tooltip: article.isReadLater ? '移出稍后读' : '稍后读',
                color: article.isReadLater ? theme.colorScheme.primary : null,
                onPressed: () => provider.setArticleReadLater(
                  article.id,
                  !article.isReadLater,
                ),
              ),
              if (article.link?.trim().isNotEmpty == true)
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  tooltip: '查看原文',
                  onPressed: () => _openOriginalArticle(context, article),
                ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: _toggleIntensiveReading,
                icon: Icon(
                  _isIntensiveReading
                      ? Icons.chrome_reader_mode_outlined
                      : Icons.local_library_outlined,
                  size: 18,
                ),
                label: Text(_isIntensiveReading ? '退出精读' : '进入精读'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticleBody(
    BuildContext context,
    RssArticle article,
    ThemeData theme,
  ) {
    final horizontalPadding =
        MediaQuery.sizeOf(context).width >= AppConstants.wideBreakpoint
        ? 32.0
        : 16.0;

    return ColoredBox(
      color: _isIntensiveReading
          ? Color.alphaBlend(
              theme.colorScheme.primaryContainer.withValues(alpha: 0.08),
              theme.colorScheme.surface,
            )
          : theme.colorScheme.surface,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetadata(article, theme),
                const SizedBox(height: 12),
                Text(
                  article.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 18),
                _buildModeSwitch(theme),
                const SizedBox(height: 24),
                if (_hasBody(article))
                  RssArticleBodyView(
                    article: article,
                    mode: _isIntensiveReading
                        ? RssArticleBodyMode.intensive
                        : RssArticleBodyMode.detail,
                    maxImageHeight: 460,
                    maxImageWidth: 720,
                  )
                else
                  _buildNoBodyState(article, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSwitch(ThemeData theme) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: false,
          icon: Icon(Icons.chrome_reader_mode_outlined, size: 16),
          label: Text('阅读模式'),
        ),
        ButtonSegment(
          value: true,
          icon: Icon(Icons.school_outlined, size: 16),
          label: Text('学习模式'),
        ),
      ],
      selected: {_isIntensiveReading},
      showSelectedIcon: false,
      onSelectionChanged: (selection) {
        final next = selection.firstOrNull;
        if (next == null || next == _isIntensiveReading) return;
        setState(() => _isIntensiveReading = next);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(theme.textTheme.labelMedium),
      ),
    );
  }

  Widget _buildMetadata(RssArticle article, ThemeData theme) {
    final chips = <Widget>[
      if (widget.showFeedName && article.feedTitle.isNotEmpty)
        _metadataChip(theme, icon: Icons.rss_feed, label: article.feedTitle),
      if (article.author?.trim().isNotEmpty == true)
        _metadataChip(
          theme,
          icon: Icons.person_outline,
          label: article.author!.trim(),
        ),
      if (article.pubDate != null)
        _metadataChip(
          theme,
          icon: Icons.schedule,
          label: _formatDate(article.pubDate!),
        ),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 12, runSpacing: 8, children: chips);
  }

  Widget _metadataChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.62),
        ),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoBodyState(RssArticle article, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        article.link?.trim().isNotEmpty == true ? '暂无可阅读正文，可查看原文。' : '暂无可阅读正文。',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  bool _hasBody(RssArticle article) {
    return article.bodyBlocks.isNotEmpty ||
        article.images.isNotEmpty ||
        article.content?.trim().isNotEmpty == true ||
        article.description?.trim().isNotEmpty == true;
  }

  void _selectArticle(RssArticle article) {
    setState(() => _currentArticleId = article.id);
    _markAsRead(article);
  }

  void _toggleIntensiveReading() {
    setState(() => _isIntensiveReading = !_isIntensiveReading);
  }

  void _markCurrentAsRead() {
    if (!mounted) return;
    final index = _currentIndex;
    if (index == -1) return;
    _markAsRead(widget.articles[index]);
  }

  void _markAsRead(RssArticle article) {
    if (article.isRead) return;
    ref.read(rssProvider).markAsRead(article.id);
  }

  void _toggleRead(RssArticle article) {
    final provider = ref.read(rssProvider);
    if (article.isRead) {
      provider.markAsUnread(article.id);
    } else {
      provider.markAsRead(article.id);
    }
  }

  void _openOriginalArticle(BuildContext context, RssArticle article) {
    final link = article.link?.trim();
    if (link == null || link.isEmpty) return;
    ref.read(rssProvider).markAsRead(article.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            BrowserScreen(initialUrl: link, initialTitle: article.title),
      ),
    );
  }

  void _showReadingSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FontSettingsSheet(),
    );
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/rss_models.dart';
import '../../providers/reading_provider.dart';
import '../../services/analysis_service.dart';
import '../reader_text_view.dart';
import '../word_bottom_sheet.dart';

class RssArticleList extends StatefulWidget {
  final List<RssArticle> articles;
  final String feedTitle;
  final int unreadCount;
  final String query;
  final bool showFeedName;
  final VoidCallback onRefresh;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function(String id) onMarkRead;
  final Future<void> Function(String id) onMarkUnread;

  const RssArticleList({
    super.key,
    required this.articles,
    required this.feedTitle,
    required this.unreadCount,
    required this.query,
    required this.showFeedName,
    required this.onRefresh,
    required this.onSearchChanged,
    required this.onMarkRead,
    required this.onMarkUnread,
  });

  @override
  State<RssArticleList> createState() => _RssArticleListState();
}

class _RssArticleListState extends State<RssArticleList> {
  String? _expandedArticleId;
  late final TextEditingController _searchController;

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.articles.isEmpty) {
      return Column(
        children: [
          _buildHeader(context, theme),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.query.isEmpty ? '暂无文章' : '没有匹配的文章',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final effectiveExpandedId =
        widget.articles.any((article) => article.id == _expandedArticleId)
        ? _expandedArticleId
        : widget.articles.first.id;

    return Column(
      children: [
        _buildHeader(context, theme),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => widget.onRefresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: widget.articles.length,
              itemBuilder: (context, index) {
                final article = widget.articles[index];
                return _buildArticleCard(
                  context,
                  article,
                  theme,
                  isExpanded: article.id == effectiveExpandedId,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
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
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: '刷新',
                onPressed: widget.onRefresh,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索文章',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: widget.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        tooltip: '清空搜索',
                        onPressed: () => widget.onSearchChanged(''),
                      ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
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

  Widget _buildArticleCard(
    BuildContext context,
    RssArticle article,
    ThemeData theme, {
    required bool isExpanded,
  }) {
    return Card(
      elevation: 0,
      color: article.isRead
          ? null
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: article.isRead
            ? BorderSide.none
            : BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() => _expandedArticleId = article.id);
          if (!article.isRead) {
            widget.onMarkRead(article.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      article.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: article.isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                        color: article.isRead
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (!article.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6, left: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              if (article.description != null &&
                  article.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  article.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.8,
                    ),
                    height: 1.4,
                  ),
                ),
              ],
              if (isExpanded &&
                  (article.content?.isNotEmpty == true ||
                      article.description?.isNotEmpty == true)) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildHighlightedContent(context, article, theme),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (widget.showFeedName && article.feedTitle.isNotEmpty) ...[
                    Icon(
                      Icons.rss_feed,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        article.feedTitle,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (article.author != null) ...[
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      article.author!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (article.pubDate != null) ...[
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(article.pubDate!),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      if (article.isRead) {
                        widget.onMarkUnread(article.id);
                      } else {
                        widget.onMarkRead(article.id);
                      }
                    },
                    child: Icon(
                      article.isRead
                          ? Icons.mark_email_unread
                          : Icons.mark_email_read,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedContent(
    BuildContext context,
    RssArticle article,
    ThemeData theme,
  ) {
    final text =
        (article.content?.isNotEmpty == true
                ? article.content
                : article.description)
            ?.trim();
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    final readingProvider = context.watch<ReadingProvider>();
    final result = AnalysisService.analyzeChapter(
      article.title,
      text,
      readingProvider.userVocabulary,
      readingProvider.wordLevelService,
    );

    return Text.rich(
      buildHighlightedParagraph(
            text,
            result,
            theme,
            onWordTapped: (word, _) => _showWordSheet(context, word),
            fontSize: 14,
            lineHeight: 1.7,
            fontFamily: 'Serif',
          )
          as TextSpan,
      style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
    );
  }

  void _showWordSheet(BuildContext context, String word) {
    context.read<ReadingProvider>().lookupWord(word);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => WordBottomSheet(word: word),
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

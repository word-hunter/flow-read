import 'package:flutter/material.dart';
import 'package:flow_read_image_viewer/flow_read_image_viewer.dart';
import 'package:provider/provider.dart';

import '../../models/analysis_result.dart';
import '../../models/rss_models.dart';
import '../../providers/reading_provider.dart';
import '../../services/analysis_service.dart';
import '../../services/settings_service.dart';
import '../reader_text_view.dart';
import '../word_bottom_sheet.dart';

class RssArticleList extends StatefulWidget {
  final List<RssArticle> articles;
  final String feedTitle;
  final int unreadCount;
  final String query;
  final RssArticleFilter filter;
  final Map<RssArticleFilter, int> filterCounts;
  final bool showFeedName;
  final VoidCallback onRefresh;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<RssArticleFilter> onFilterChanged;
  final Future<void> Function(String id) onMarkRead;
  final Future<void> Function(String id) onMarkUnread;
  final Future<void> Function(String id, bool isFavorite) onSetFavorite;
  final Future<void> Function(String id, bool isReadLater) onSetReadLater;
  final ValueChanged<RssArticle> onOpenOriginal;

  const RssArticleList({
    super.key,
    required this.articles,
    required this.feedTitle,
    required this.unreadCount,
    required this.query,
    required this.filter,
    required this.filterCounts,
    required this.showFeedName,
    required this.onRefresh,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onMarkRead,
    required this.onMarkUnread,
    required this.onSetFavorite,
    required this.onSetReadLater,
    required this.onOpenOriginal,
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
                    _emptyMessage(),
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
            height: 36,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<RssArticleFilter>(
                segments: RssArticleFilter.values
                    .map(
                      (filter) => ButtonSegment(
                        value: filter,
                        icon: Icon(_filterIcon(filter), size: 16),
                        label: Text(_filterLabel(filter)),
                      ),
                    )
                    .toList(growable: false),
                selected: {widget.filter},
                onSelectionChanged: (selection) {
                  final next = selection.firstOrNull;
                  if (next != null) widget.onFilterChanged(next);
                },
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStatePropertyAll(
                    theme.textTheme.labelMedium,
                  ),
                ),
              ),
            ),
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
                      article.description?.isNotEmpty == true ||
                      article.images.isNotEmpty)) ...[
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
                  IconButton(
                    icon: Icon(
                      article.isFavorite
                          ? Icons.star
                          : Icons.star_border_outlined,
                      size: 18,
                    ),
                    tooltip: article.isFavorite ? '取消收藏' : '收藏',
                    onPressed: () =>
                        widget.onSetFavorite(article.id, !article.isFavorite),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    visualDensity: VisualDensity.compact,
                    color: article.isFavorite
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.45,
                          ),
                  ),
                  IconButton(
                    icon: Icon(
                      article.isReadLater
                          ? Icons.watch_later
                          : Icons.watch_later_outlined,
                      size: 18,
                    ),
                    tooltip: article.isReadLater ? '移出稍后读' : '稍后读',
                    onPressed: () =>
                        widget.onSetReadLater(article.id, !article.isReadLater),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    visualDensity: VisualDensity.compact,
                    color: article.isReadLater
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.45,
                          ),
                  ),
                  if (article.link?.trim().isNotEmpty == true)
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 18),
                      tooltip: '查看原文',
                      onPressed: () => widget.onOpenOriginal(article),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  IconButton(
                    icon: Icon(
                      article.isRead
                          ? Icons.mark_email_unread
                          : Icons.mark_email_read,
                      size: 18,
                    ),
                    tooltip: article.isRead ? '标记未读' : '标记已读',
                    onPressed: () {
                      if (article.isRead) {
                        widget.onMarkUnread(article.id);
                      } else {
                        widget.onMarkRead(article.id);
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    visualDensity: VisualDensity.compact,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.45,
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

  Widget _buildHighlightedContent(
    BuildContext context,
    RssArticle article,
    ThemeData theme,
  ) {
    final bodyBlocks = article.bodyBlocks;
    final text =
        (article.content?.isNotEmpty == true
                ? article.content
                : article.description)
            ?.trim();
    final hasBodyBlocks = bodyBlocks.isNotEmpty;
    if (!hasBodyBlocks &&
        (text == null || text.isEmpty) &&
        article.images.isEmpty) {
      return const SizedBox.shrink();
    }

    if ((text == null || text.isEmpty) &&
        bodyBlocks.whereType<RssArticleTextBlock>().isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildImageOnlyBody(article, bodyBlocks),
      );
    }

    final bodyText = text ?? _textFromBodyBlocks(bodyBlocks) ?? '';
    final readingProvider = context.watch<ReadingProvider>();
    final settings = context.watch<SettingsService>();
    final result = AnalysisService.analyzeChapter(
      article.title,
      bodyText,
      readingProvider.userVocabulary,
      readingProvider.wordLevelService,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasBodyBlocks)
          ..._buildBodyBlockWidgets(
            bodyBlocks,
            result,
            theme,
            readingProvider,
            settings,
          )
        else
          _buildTextBlock(
            RssArticleTextBlock(
              type: RssArticleTextBlockType.paragraph,
              text: bodyText,
            ),
            result,
            theme,
            readingProvider,
            settings,
          ),
        ..._buildTrailingImages(article, bodyBlocks),
      ],
    );
  }

  List<Widget> _buildBodyBlockWidgets(
    List<RssArticleBodyBlock> bodyBlocks,
    AnalysisResult result,
    ThemeData theme,
    ReadingProvider readingProvider,
    SettingsService settings,
  ) {
    return bodyBlocks
        .map((block) {
          return switch (block) {
            RssArticleTextBlock() => _buildTextBlock(
              block,
              result,
              theme,
              readingProvider,
              settings,
            ),
            RssArticleImageBlock() => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildArticleImage(block.image),
            ),
          };
        })
        .toList(growable: false);
  }

  String? _textFromBodyBlocks(List<RssArticleBodyBlock> bodyBlocks) {
    final parts = bodyBlocks
        .whereType<RssArticleTextBlock>()
        .map((block) => block.text.trim())
        .where((text) => text.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return null;
    return parts.join('\n\n');
  }

  Widget _buildTextBlock(
    RssArticleTextBlock block,
    AnalysisResult result,
    ThemeData theme,
    ReadingProvider readingProvider,
    SettingsService settings,
  ) {
    final style = _rssTextStyle(block, theme);
    final richText = Text.rich(
      buildHighlightedParagraph(
            block.text,
            result,
            theme,
            onWordTapped: _showWordSheet,
            fontSize: style.fontSize ?? 14,
            lineHeight: _rssLineHeight(block),
            fontFamily: style.fontFamily ?? 'Serif',
            baseTextColor: style.color,
            colorSettings: settings.colors,
            searchQuery: widget.query,
            lookupHighlightWord: readingProvider.selectedWord,
            wordLevelService: readingProvider.wordLevelService,
          )
          as TextSpan,
      style: style,
    );

    final content = switch (block.type) {
      RssArticleTextBlockType.listItem => Padding(
        padding: EdgeInsets.only(left: (block.indent - 1).clamp(0, 4) * 18.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1, right: 8),
              child: Text(
                '•',
                style: style.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: richText),
          ],
        ),
      ),
      RssArticleTextBlockType.blockquote => Container(
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: theme.colorScheme.outlineVariant, width: 3),
          ),
        ),
        child: richText,
      ),
      _ => richText,
    };

    return Padding(padding: _rssBlockPadding(block), child: content);
  }

  TextStyle _rssTextStyle(RssArticleTextBlock block, ThemeData theme) {
    final color = block.type == RssArticleTextBlockType.blockquote
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurface;
    final base = theme.textTheme.bodyMedium ?? const TextStyle();
    final fontSize = switch (block.type) {
      RssArticleTextBlockType.heading => switch (block.headingLevel) {
        1 => 17.0,
        2 => 16.0,
        3 => 15.0,
        _ => 14.5,
      },
      _ => 14.0,
    };
    return base.copyWith(
      height: _rssLineHeight(block),
      fontFamily: 'Serif',
      fontSize: fontSize,
      fontWeight: block.type == RssArticleTextBlockType.heading
          ? FontWeight.w700
          : null,
      fontStyle: block.type == RssArticleTextBlockType.blockquote
          ? FontStyle.italic
          : null,
      color: color,
    );
  }

  double _rssLineHeight(RssArticleTextBlock block) {
    return block.type == RssArticleTextBlockType.heading ? 1.35 : 1.7;
  }

  EdgeInsets _rssBlockPadding(RssArticleTextBlock block) {
    return switch (block.type) {
      RssArticleTextBlockType.heading => const EdgeInsets.only(
        top: 4,
        bottom: 8,
      ),
      RssArticleTextBlockType.listItem => const EdgeInsets.only(bottom: 6),
      _ => const EdgeInsets.only(bottom: 10),
    };
  }

  List<Widget> _buildImageOnlyBody(
    RssArticle article,
    List<RssArticleBodyBlock> bodyBlocks,
  ) {
    return [
      ...bodyBlocks.whereType<RssArticleImageBlock>().map(
        (block) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildArticleImage(block.image),
        ),
      ),
      ..._buildTrailingImages(article, bodyBlocks),
    ];
  }

  List<Widget> _buildTrailingImages(
    RssArticle article,
    List<RssArticleBodyBlock> bodyBlocks,
  ) {
    final inlineUrls = bodyBlocks
        .whereType<RssArticleImageBlock>()
        .map((block) => block.image.url)
        .toSet();
    return article.images
        .where((image) => !inlineUrls.contains(image.url))
        .map(
          (image) => Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 10),
            child: _buildArticleImage(image),
          ),
        )
        .toList(growable: false);
  }

  Widget _buildArticleImage(RssArticleImage image) {
    final uri = Uri.tryParse(image.url);
    if (uri == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: ReadableImagePreview(
        resource: ReadableImageResource.network(
          uri,
          alt: image.alt,
          suggestedFileName: uri.pathSegments
              .where((segment) => segment.trim().isNotEmpty)
              .lastOrNull,
          width: image.width?.toDouble(),
          height: image.height?.toDouble(),
        ),
        maxHeight: 320,
        maxWidth: 520,
      ),
    );
  }

  void _showWordSheet(
    String word,
    String contextText, {
    int? contextWordStart,
    int? contextWordEnd,
  }) {
    final provider = context.read<ReadingProvider>();
    provider.lookupWord(
      word,
      contextText: contextText,
      contextWordStart: contextWordStart,
      contextWordEnd: contextWordEnd,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => WordBottomSheet(word: word),
    ).whenComplete(provider.clearWordLookup);
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

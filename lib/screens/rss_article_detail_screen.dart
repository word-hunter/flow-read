import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import 'package:flow_rss/flow_rss.dart';
import '../providers/rss_riverpod_provider.dart';
import '../providers/rss_reading_config_provider.dart';
import '../providers/reading/reading_config_notifier.dart';
import '../providers/web_content_provider.dart';
import '../services/app_logger.dart';
import '../services/web_content_service.dart';
import '../theme/app_constants.dart';
import '../theme/app_surface_tokens.dart';
import '../widgets/flow/flow_components.dart';
import '../widgets/font_settings_sheet.dart';
import '../widgets/reader/reader_content_view.dart';
import '../widgets/rss/rss_article_body_view.dart';
import '../widgets/rss/rss_interaction_styles.dart';

class RssArticleDetailScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FlowToolbar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回列表',
          onPressed: () => Navigator.of(context).maybePop(),
          style: rssIconButtonStyle(Theme.of(context)),
        ),
        title: const Text('RSS 阅读'),
      ),
      body: RssArticleDetailPane(
        articles: articles,
        initialArticleId: initialArticleId,
        showFeedName: showFeedName,
      ),
    );
  }
}

class RssArticleDetailPane extends riverpod.ConsumerStatefulWidget {
  final List<RssArticle> articles;
  final String initialArticleId;
  final bool showFeedName;
  final ValueChanged<RssArticle>? onArticleSelected;
  final bool showReadingSettingsAction;
  final bool markInitialArticleAsRead;
  final bool showLookupSheet;

  const RssArticleDetailPane({
    super.key,
    required this.articles,
    required this.initialArticleId,
    required this.showFeedName,
    this.onArticleSelected,
    this.showReadingSettingsAction = true,
    this.markInitialArticleAsRead = true,
    this.showLookupSheet = true,
  });

  @override
  riverpod.ConsumerState<RssArticleDetailPane> createState() =>
      _RssArticleDetailPaneState();
}

class _RssArticleDetailPaneState
    extends riverpod.ConsumerState<RssArticleDetailPane> {
  late String _currentArticleId;
  final MenuController _readingSettingsMenuController = MenuController();
  final Map<String, RssArticle> _readableArticlesById = {};
  final Map<String, String> _readableArticleErrors = {};
  final Set<String> _loadingReadableArticleIds = {};

  @override
  void initState() {
    super.initState();
    _currentArticleId = widget.initialArticleId;
    if (widget.markInitialArticleAsRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _markCurrentAsRead());
    }
  }

  @override
  void didUpdateWidget(covariant RssArticleDetailPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    final requestedChanged =
        widget.initialArticleId != oldWidget.initialArticleId;
    final currentExists = widget.articles.any(
      (article) => article.id == _currentArticleId,
    );
    if (!requestedChanged && currentExists) return;

    final nextArticle =
        widget.articles
            .where((article) => article.id == widget.initialArticleId)
            .firstOrNull ??
        widget.articles.firstOrNull;
    if (nextArticle == null || nextArticle.id == _currentArticleId) return;

    _currentArticleId = nextArticle.id;
    if (widget.markInitialArticleAsRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _markCurrentAsRead());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(rssNotifierProvider);
    final theme = Theme.of(context);
    final readingConfig = ref.watch(rssReadingConfigNotifierProvider);
    final currentIndex = _currentIndex;
    final article = currentIndex == -1 ? null : widget.articles[currentIndex];
    if (article != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_loadReadableArticleIfNeeded(article));
      });
    }
    final readableArticle = article == null
        ? null
        : _readableArticlesById[article.id];
    final displayArticle = article == null
        ? null
        : readableArticle?.copyWith(
                isRead: article.isRead,
                isFavorite: article.isFavorite,
                isReadLater: article.isReadLater,
              ) ??
              article;
    final articleId = article?.id;

    return displayArticle == null
        ? _buildMissingArticle(theme)
        : Column(
            children: [
              _buildActionBar(
                context,
                displayArticle,
                currentIndex,
                theme,
                readingConfig,
              ),
              Expanded(
                child: _buildArticleBody(
                  context,
                  displayArticle,
                  theme,
                  readingConfig: readingConfig,
                  isLoadingReadableArticle:
                      articleId != null &&
                      _loadingReadableArticleIds.contains(articleId),
                  readableArticleError: articleId == null
                      ? null
                      : _readableArticleErrors[articleId],
                ),
              ),
            ],
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
    RssArticle article,
    int currentIndex,
    ThemeData theme,
    ReadingConfigState readingConfig,
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
              style: rssIconButtonStyle(theme),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: '下一篇',
              onPressed: canGoNext
                  ? () => _selectArticle(widget.articles[currentIndex + 1])
                  : null,
              style: rssIconButtonStyle(theme),
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
              style: rssIconButtonStyle(theme),
            ),
            if (widget.showReadingSettingsAction) ...[
              const Spacer(),
              _buildReadingSettingsAction(context, theme, readingConfig),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReadingSettingsAction(
    BuildContext context,
    ThemeData theme,
    ReadingConfigState readingConfig,
  ) {
    final useDropdown =
        MediaQuery.sizeOf(context).width >= AppConstants.wideBreakpoint;
    if (!useDropdown) {
      return IconButton(
        icon: const Icon(Icons.tune_outlined),
        tooltip: '阅读设置',
        onPressed: () => _showReadingSettings(context),
        style: rssIconButtonStyle(theme),
      );
    }

    final panelWidth = FontSettingsDropdownPanel.preferredWidthFor(
      MediaQuery.sizeOf(context),
    );
    return MenuAnchor(
      controller: _readingSettingsMenuController,
      alignmentOffset: Offset(-(panelWidth - 32), 6),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        FontSettingsDropdownPanel(
          width: panelWidth,
          onClose: _readingSettingsMenuController.close,
          controller: _rssReadingSettingsController(ref, readingConfig),
        ),
      ],
      builder: (context, controller, _) {
        return IconButton(
          icon: const Icon(Icons.tune_outlined),
          tooltip: '阅读设置',
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          style: rssIconButtonStyle(theme, selected: controller.isOpen),
        );
      },
    );
  }

  ReadingSettingsPanelController _rssReadingSettingsController(
    riverpod.WidgetRef ref,
    ReadingConfigState state,
  ) {
    final notifier = ref.read(rssReadingConfigNotifierProvider.notifier);
    return ReadingSettingsPanelController(
      state: state,
      onFontSizeChanged: notifier.setFontSize,
      onLineHeightChanged: notifier.setLineHeight,
      onFontFamilyChanged: notifier.setFontFamily,
      onReadingThemeChanged: notifier.setReadingTheme,
      onRestoreDefaults: notifier.restoreDefaults,
    );
  }

  Widget _buildArticleBody(
    BuildContext context,
    RssArticle article,
    ThemeData theme, {
    required ReadingConfigState readingConfig,
    required bool isLoadingReadableArticle,
    required String? readableArticleError,
  }) {
    final horizontalPadding =
        MediaQuery.sizeOf(context).width >= AppConstants.wideBreakpoint
        ? 32.0
        : 16.0;
    final readerTextColor = resolveReaderTextColor(
      readingConfig,
      null,
      appBrightness: theme.brightness,
    );
    final readerMutedTextColor = resolveReaderMutedTextColor(
      readingConfig,
      null,
      appBrightness: theme.brightness,
    );

    return ColoredBox(
      color: _rssReaderBackgroundColor(context, theme, readingConfig),
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
                _buildMetadata(
                  article,
                  theme,
                  foreground: readerMutedTextColor,
                ),
                const SizedBox(height: 12),
                Text(
                  article.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: readerTextColor,
                  ),
                ),
                const SizedBox(height: 18),
                if (isLoadingReadableArticle) ...[
                  _buildReadableArticleStatus(
                    theme,
                    icon: Icons.sync,
                    message: '正在加载全文…',
                    isLoading: true,
                  ),
                  const SizedBox(height: 18),
                ] else if (readableArticleError != null) ...[
                  _buildReadableArticleStatus(
                    theme,
                    icon: Icons.warning_amber_outlined,
                    message: '全文加载失败，正在显示 RSS 摘要。$readableArticleError',
                    isError: true,
                  ),
                  const SizedBox(height: 18),
                ],
                if (_hasBody(article))
                  RssArticleBodyView(
                    article: article,
                    mode: RssArticleBodyMode.intensive,
                    readingConfig: readingConfig,
                    showLookupSheet: widget.showLookupSheet,
                    maxImageHeight: 460,
                    maxImageWidth: 720,
                  )
                else
                  _buildNoBodyState(theme, foreground: readerMutedTextColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadableArticleStatus(
    ThemeData theme, {
    required IconData icon,
    required String message,
    bool isLoading = false,
    bool isError = false,
  }) {
    final colorScheme = theme.colorScheme;
    final background = isError
        ? colorScheme.errorContainer.withValues(alpha: 0.58)
        : colorScheme.primaryContainer.withValues(alpha: 0.28);
    final foreground = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            )
          else
            Icon(
              icon,
              size: 18,
              color: isError ? colorScheme.error : colorScheme.primary,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(
    RssArticle article,
    ThemeData theme, {
    required Color foreground,
  }) {
    final chips = <Widget>[
      if (widget.showFeedName && article.feedTitle.isNotEmpty)
        _metadataChip(
          theme,
          icon: Icons.rss_feed,
          label: article.feedTitle,
          foreground: foreground,
        ),
      if (article.author?.trim().isNotEmpty == true)
        _metadataChip(
          theme,
          icon: Icons.person_outline,
          label: article.author!.trim(),
          foreground: foreground,
        ),
      if (article.pubDate != null)
        _metadataChip(
          theme,
          icon: Icons.schedule,
          label: _formatDate(article.pubDate!),
          foreground: foreground,
        ),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 12, runSpacing: 8, children: chips);
  }

  Widget _metadataChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color foreground,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: foreground.withValues(alpha: 0.72),
        ),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: foreground,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoBodyState(
    ThemeData theme, {
    required Color foreground,
  }) {
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
        '暂无可阅读正文。',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: foreground,
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
    widget.onArticleSelected?.call(article);
    _markAsRead(article);
  }

  Future<void> _loadReadableArticleIfNeeded(RssArticle article) async {
    final link = article.link?.trim();
    if (link == null || link.isEmpty) return;
    if (!_needsReadableArticleFetch(article)) return;
    if (_readableArticlesById.containsKey(article.id) ||
        _loadingReadableArticleIds.contains(article.id)) {
      return;
    }

    setState(() {
      _loadingReadableArticleIds.add(article.id);
      _readableArticleErrors.remove(article.id);
    });

    try {
      final page = await ref.read(webContentServiceProvider).fetch(link);
      if (!mounted) return;
      setState(() {
        _readableArticlesById[article.id] = _articleWithReadableContent(
          article,
          page,
        );
        _loadingReadableArticleIds.remove(article.id);
      });
    } catch (error, stackTrace) {
      AppLogger.instance.event(
        'rss.article_readable_fetch_failed',
        level: AppLogLevel.warning,
        source: 'rss_article_detail_screen',
        metadata: {'articleId': article.id, 'url': link},
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _loadingReadableArticleIds.remove(article.id);
        _readableArticleErrors[article.id] = error.toString();
      });
    }
  }

  bool _needsReadableArticleFetch(RssArticle article) {
    final content = article.content?.trim() ?? '';
    final description = article.description?.trim() ?? '';
    final textBlockCount = article.bodyBlocks
        .whereType<RssArticleTextBlock>()
        .length;

    if (content.length >= 900 || textBlockCount >= 3) return false;
    if (content.isEmpty) return true;
    if (description.isNotEmpty && content == description) return true;
    return content.length < 500;
  }

  RssArticle _articleWithReadableContent(
    RssArticle article,
    WebPageContent page,
  ) {
    final paragraphs = page.paragraphs
        .map((paragraph) => paragraph.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList(growable: false);
    if (paragraphs.isEmpty) return article;

    return article.copyWith(
      content: paragraphs.join('\n\n'),
      bodyBlocks: paragraphs
          .map(
            (paragraph) => RssArticleTextBlock(
              type: RssArticleTextBlockType.paragraph,
              text: paragraph,
            ),
          )
          .toList(growable: false),
    );
  }

  void _markCurrentAsRead() {
    if (!mounted) return;
    final index = _currentIndex;
    if (index == -1) return;
    _markAsRead(widget.articles[index]);
  }

  void _markAsRead(RssArticle article) {
    if (article.isRead) return;
    ref.read(rssNotifierProvider.notifier).markAsRead(article.id);
  }

  void _toggleRead(RssArticle article) {
    final notifier = ref.read(rssNotifierProvider.notifier);
    if (article.isRead) {
      notifier.markAsUnread(article.id);
    } else {
      notifier.markAsRead(article.id);
    }
  }

  void _showReadingSettings(BuildContext context) {
    showFlowSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => riverpod.Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(rssReadingConfigNotifierProvider);
          final notifier = ref.read(rssReadingConfigNotifierProvider.notifier);
          return FontSettingsSheet(
            controller: ReadingSettingsPanelController(
              state: state,
              onFontSizeChanged: notifier.setFontSize,
              onLineHeightChanged: notifier.setLineHeight,
              onFontFamilyChanged: notifier.setFontFamily,
              onReadingThemeChanged: notifier.setReadingTheme,
              onRestoreDefaults: notifier.restoreDefaults,
            ),
          );
        },
      ),
    );
  }

  Color _rssReaderBackgroundColor(
    BuildContext context,
    ThemeData theme,
    ReadingConfigState readingConfig,
  ) {
    return switch (readingConfig.readingTheme) {
      'sepia' => const Color(0xFFF5ECD7),
      'dark' => AppSurfaceTokens.of(context).readerWorkspaceBackground,
      _ => Color.alphaBlend(
        theme.colorScheme.primaryContainer.withValues(alpha: 0.08),
        theme.colorScheme.surface,
      ),
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

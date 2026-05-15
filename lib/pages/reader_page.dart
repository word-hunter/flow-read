import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/analysis_result.dart';
import '../models/content_block.dart';
import '../providers/reading_provider.dart';
import '../theme/app_constants.dart';
import '../widgets/ai_summary_view.dart';
import '../widgets/bookmark_sheet.dart';
import '../widgets/font_settings_sheet.dart';
import '../widgets/reader/reader_word_sidebar.dart';
import '../widgets/reader_text_view.dart';
import '../widgets/selected_text_sheet.dart';
import '../widgets/toc_bottom_sheet.dart';
import '../widgets/word_bottom_sheet.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final ScrollController _scrollController = ScrollController();
  double _viewportHeight = 0;
  String _selectedText = '';
  bool _sidebarOpen = false;
  double _layoutWidth = 0;
  double _displayProgress = 0.0;

  bool get _isWideScreen => _layoutWidth >= AppConstants.wideBreakpoint;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    final progress = (_scrollController.offset / maxScroll).clamp(0.0, 1.0);
    _displayProgress = progress;
    context.read<ReadingProvider>().updateReadingProgress(progress);
    setState(() {});
  }

  void _scrollPage(bool forward) {
    if (!_scrollController.hasClients) return;
    final viewport = _viewportHeight > 0 ? _viewportHeight : 600;
    final offset = _scrollController.offset;
    var target = forward ? offset + viewport * 0.85 : offset - viewport * 0.85;
    target = target.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onWordTapped(String word, String contextText) {
    context.read<ReadingProvider>().lookupWord(word);
    if (_isWideScreen) {
      setState(() => _sidebarOpen = true);
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => WordBottomSheet(word: word),
      );
    }
  }

  void _onTranslateSelected(String text) {
    if (text.trim().isEmpty) return;
    final provider = context.read<ReadingProvider>();
    provider.translateSelectedTextAI(text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SelectedTextSheet(
        selectedText: '',
        analysis: null,
        tab: SelectedTextTab.translate,
        analyzerName: 'DeepSeek AI',
      ),
    );
  }

  void _onAnalyzeSelected(String text) {
    if (text.trim().isEmpty) return;
    final provider = context.read<ReadingProvider>();
    // Get surrounding context
    final result = provider.result;
    String before = '';
    String after = '';
    if (result != null) {
      final fullText = result.passageText;
      final idx = fullText.indexOf(text);
      if (idx >= 0) {
        final start = (idx - 200).clamp(0, idx);
        before = fullText.substring(start, idx);
        final end = (idx + text.length + 200).clamp(0, fullText.length);
        after = fullText.substring(idx + text.length, end);
      }
    }
    provider.analyzeSelectedTextAI(text, before, after);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SelectedTextSheet(
        selectedText: '',
        analysis: null,
        tab: SelectedTextTab.analysis,
        analyzerName: 'DeepSeek AI',
      ),
    );
  }

  void _showTocSheet() {
    final provider = context.read<ReadingProvider>();
    if (!provider.hasBook) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TocBottomSheet(),
    );
  }

  void _showFontSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FontSettingsSheet(),
    );
  }

  void _onBookmarkTap() {
    final provider = context.read<ReadingProvider>();
    if (provider.isCurrentPositionBookmarked()) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const BookmarkSheet(),
      );
    } else {
      provider.addReadingBookmark();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已添加书签'), duration: Duration(seconds: 1)),
      );
    }
  }

  Color _readerBackgroundColor(ReadingProvider provider) {
    switch (provider.readingTheme) {
      case 'sepia':
        return const Color(0xFFF5ECD7);
      case 'dark':
        return const Color(0xFF1E1E1E);
      default:
        return Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white;
    }
  }

  TextStyle _buildBaseTextStyle(ThemeData theme, ReadingProvider provider) {
    final isDark =
        provider.readingTheme == 'dark' ||
        (theme.brightness == Brightness.dark &&
            provider.readingTheme == 'light');
    final color = isDark
        ? const Color(0xFFE0E0E0)
        : theme.colorScheme.onSurface;
    return (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
      fontSize: provider.fontSize,
      height: provider.lineHeight,
      letterSpacing: 0.3,
      fontFamily: provider.fontFamily,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingProvider>();
    final result = provider.result;
    if (result == null) {
      return _buildPageScaffold(
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final paragraphs = splitIntoParagraphs(result.passageText);
    final blocks = provider.hasBook && provider.chapterCount > 0
        ? provider.book!.chapters[provider.currentChapter].blocks
        : const <ContentBlock>[];
    final theme = Theme.of(context);
    final progressPercent = (_displayProgress * 100).toInt();
    final chapterTitle = provider.hasBook && provider.chapterCount > 0
        ? provider.book!.chapters[provider.currentChapter].title
        : result.title;

    return LayoutBuilder(
      builder: (context, constraints) {
        _layoutWidth = constraints.maxWidth;
        final isWide = _isWideScreen;

        return _buildPageScaffold(
          child: Column(
            children: [
              _buildNavBar(
                provider,
                theme,
                chapterTitle,
                showSidebarToggle: isWide,
              ),
              Expanded(
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildReadingContent(
                              paragraphs,
                              blocks,
                              result,
                              theme,
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: _sidebarOpen
                                ? ReaderWordSidebar(
                                    onClose: () =>
                                        setState(() => _sidebarOpen = false),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      )
                    : _buildReadingContent(paragraphs, blocks, result, theme),
              ),
              _buildBottomBar(
                context,
                _displayProgress,
                theme,
                chapterTitle,
                progressPercent,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageScaffold({required Widget child}) {
    final provider = context.watch<ReadingProvider>();
    return Container(
      decoration: BoxDecoration(
        color: _readerBackgroundColor(provider),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: child),
    );
  }

  Widget _buildReadingContent(
    List<String> paragraphs,
    List<ContentBlock> blocks,
    AnalysisResult result,
    ThemeData theme,
  ) {
    return SelectionArea(
      onSelectionChanged: (selection) {
        if (selection != null) {
          setState(() => _selectedText = selection.plainText);
        }
      },
      contextMenuBuilder: (context, selectableRegionState) {
        final defaultItems = selectableRegionState.contextMenuButtonItems;
        final customItems = <ContextMenuButtonItem>[
          ContextMenuButtonItem(
            onPressed: () {
              _onTranslateSelected(_selectedText);
            },
            label: '翻译',
          ),
          ContextMenuButtonItem(
            onPressed: () {
              _onAnalyzeSelected(_selectedText);
            },
            label: 'AI 解析',
          ),
        ];
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: selectableRegionState.contextMenuAnchors,
          buttonItems: [...defaultItems, ...customItems],
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          _viewportHeight = constraints.maxHeight;
          final provider = context.read<ReadingProvider>();
          final showTitleBlock = !provider.hasBook;
          final topPadding = showTitleBlock ? 14.0 : 10.0;
          final horizontalPadding = _isWideScreen ? 32.0 : 18.0;
          final maxTextWidth = _isWideScreen ? 920.0 : double.infinity;
          final useBlocks = blocks.isNotEmpty;
          final contentCount = useBlocks ? blocks.length : paragraphs.length;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxTextWidth),
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  topPadding,
                  horizontalPadding,
                  24,
                ),
                itemCount: contentCount + (showTitleBlock ? 1 : 0),
                itemBuilder: (context, index) {
                  if (showTitleBlock && index == 0) {
                    return _buildTitleBlock(result, theme);
                  }
                  final contentIndex = showTitleBlock ? index - 1 : index;
                  if (contentIndex >= contentCount) {
                    return const SizedBox.shrink();
                  }

                  if (useBlocks) {
                    return _buildContentBlock(
                      blocks[contentIndex],
                      result,
                      theme,
                      isFirstBlock: contentIndex == 0 && provider.hasBook,
                    );
                  }

                  return _buildParagraph(
                    paragraphs[contentIndex],
                    result,
                    theme,
                    isFirstParagraph: contentIndex == 0 && provider.hasBook,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentBlock(
    ContentBlock block,
    AnalysisResult result,
    ThemeData theme, {
    bool isFirstBlock = false,
  }) {
    final provider = context.read<ReadingProvider>();

    if (isFirstBlock &&
        block is TextBlock &&
        block.type == BlockType.paragraph &&
        block.plainText.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildDropCapParagraph(
          block.plainText,
          result,
          theme,
          _buildBaseTextStyle(theme, provider),
        ),
      );
    }

    return buildBlockWidget(
      block,
      result,
      theme,
      onWordTapped: _onWordTapped,
      fontSize: provider.fontSize,
      lineHeight: provider.lineHeight,
      fontFamily: provider.fontFamily,
    );
  }

  Widget _buildTitleBlock(AnalysisResult result, ThemeData theme) {
    final provider = context.read<ReadingProvider>();
    final isDark =
        provider.readingTheme == 'dark' ||
        (theme.brightness == Brightness.dark &&
            provider.readingTheme == 'light');
    final titleColor = isDark
        ? const Color(0xFFE0E0E0)
        : theme.colorScheme.onSurface;
    final dividerColor = isDark
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFEEEEEE);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: titleColor,
              fontFamily: provider.fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: dividerColor),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildParagraph(
    String paragraph,
    AnalysisResult result,
    ThemeData theme, {
    bool isFirstParagraph = false,
  }) {
    final provider = context.read<ReadingProvider>();
    final baseStyle = _buildBaseTextStyle(theme, provider);

    if (isFirstParagraph && paragraph.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildDropCapParagraph(paragraph, result, theme, baseStyle),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text.rich(
        buildHighlightedParagraph(
          paragraph,
          result,
          theme,
          onWordTapped: _onWordTapped,
          fontSize: provider.fontSize,
          lineHeight: provider.lineHeight,
          fontFamily: provider.fontFamily,
        ),
        style: baseStyle,
      ),
    );
  }

  Widget _buildDropCapParagraph(
    String paragraph,
    AnalysisResult result,
    ThemeData theme,
    TextStyle baseStyle,
  ) {
    final provider = context.read<ReadingProvider>();
    final firstLetter = paragraph.substring(0, 1).toUpperCase();
    final restText = paragraph.substring(1).trimLeft();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 10, top: 5),
          child: Text(
            firstLetter,
            style: baseStyle.copyWith(
              fontSize: provider.fontSize * 3.05,
              height: 0.84,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(
          child: Text.rich(
            buildHighlightedParagraph(
              restText,
              result,
              theme,
              onWordTapped: _onWordTapped,
              fontSize: provider.fontSize,
              lineHeight: provider.lineHeight,
              fontFamily: provider.fontFamily,
            ),
            style: baseStyle,
          ),
        ),
      ],
    );
  }

  Widget _compactIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    double size = 20,
  }) {
    return IconButton(
      icon: Icon(icon, size: size),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _chapterStepButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 30),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 30, height: 38),
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildNavBar(
    ReadingProvider provider,
    ThemeData theme,
    String chapterTitle, {
    bool showSidebarToggle = false,
  }) {
    final isDark =
        provider.readingTheme == 'dark' ||
        (theme.brightness == Brightness.dark &&
            provider.readingTheme == 'light');
    final borderColor = isDark
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFEEEEEE);
    final showSearch = _layoutWidth >= 520;
    final showChapterStep = _layoutWidth >= 680 && provider.chapterCount > 1;
    final contentTitle = chapterTitle.trim().isNotEmpty
        ? chapterTitle.trim()
        : '当前位置';
    final locationLabel = provider.hasBook
        ? '位置 ${provider.currentChapter + 1} / ${provider.chapterCount}'
        : 'Reader';
    final canGoPreviousChapter =
        provider.hasBook && provider.currentChapter > 0;
    final canGoNextChapter =
        provider.hasBook && provider.currentChapter < provider.chapterCount - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          _compactIconButton(
            icon: Icons.arrow_back,
            tooltip: '返回',
            onPressed: () => context.read<ReadingProvider>().exitReader(),
          ),
          if (provider.hasBook && provider.chapterCount > 1)
            _compactIconButton(
              icon: Icons.menu,
              tooltip: '目录',
              onPressed: _showTocSheet,
            ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showChapterStep)
                  _chapterStepButton(
                    icon: Icons.chevron_left,
                    tooltip: '上一个目录项',
                    onPressed: canGoPreviousChapter
                        ? () =>
                              provider.goToChapter(provider.currentChapter - 1)
                        : null,
                  ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          contentTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                            height: 1.05,
                          ),
                        ),
                        Text(
                          locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showChapterStep)
                  _chapterStepButton(
                    icon: Icons.chevron_right,
                    tooltip: '下一个目录项',
                    onPressed: canGoNextChapter
                        ? () =>
                              provider.goToChapter(provider.currentChapter + 1)
                        : null,
                  ),
              ],
            ),
          ),
          Text(
            '${(_displayProgress * 100).toInt()}%',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          if (showSidebarToggle)
            _compactIconButton(
              icon: _sidebarOpen
                  ? Icons.vertical_split
                  : Icons.vertical_split_outlined,
              tooltip: _sidebarOpen ? '收起侧栏' : '展开侧栏',
              onPressed: () => setState(() => _sidebarOpen = !_sidebarOpen),
            ),
          if (showSearch)
            _compactIconButton(
              icon: Icons.search,
              tooltip: '搜索',
              onPressed: () {},
            ),
          _compactIconButton(
            icon: Icons.text_fields,
            tooltip: '字体',
            onPressed: _showFontSettingsSheet,
          ),
          _compactIconButton(
            icon: provider.isCurrentPositionBookmarked()
                ? Icons.bookmark
                : Icons.bookmark_outline,
            tooltip: '书签',
            onPressed: _onBookmarkTap,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            tooltip: '更多',
            onSelected: (value) {
              switch (value) {
                case 'prevChapter':
                  if (canGoPreviousChapter) {
                    provider.goToChapter(provider.currentChapter - 1);
                  }
                  break;
                case 'nextChapter':
                  if (canGoNextChapter) {
                    provider.goToChapter(provider.currentChapter + 1);
                  }
                  break;
                case 'summary':
                  provider.generateSummary();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AISummaryView(),
                  );
                  break;
                case 'practice':
                  provider.generatePractice();
                  break;
                case 'bookmarks':
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const BookmarkSheet(),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              if (provider.hasBook && provider.chapterCount > 1) ...[
                PopupMenuItem(
                  value: 'prevChapter',
                  enabled: canGoPreviousChapter,
                  child: const Text('上一个目录项'),
                ),
                PopupMenuItem(
                  value: 'nextChapter',
                  enabled: canGoNextChapter,
                  child: const Text('下一个目录项'),
                ),
                const PopupMenuDivider(),
              ],
              const PopupMenuItem(value: 'summary', child: Text('AI 总结当前内容')),
              const PopupMenuItem(value: 'practice', child: Text('生成练习题')),
              const PopupMenuItem(value: 'bookmarks', child: Text('历史书签')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    double progress,
    ThemeData theme,
    String chapterTitle,
    int progressPercent,
  ) {
    final provider = context.read<ReadingProvider>();
    final isDark =
        provider.readingTheme == 'dark' ||
        (theme.brightness == Brightness.dark &&
            provider.readingTheme == 'light');
    final bgColor = _readerBackgroundColor(provider);
    final borderColor = isDark
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFEEEEEE);
    final textColor = isDark
        ? const Color(0xFFB0B0B0)
        : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, size: 28),
                tooltip: '上一页',
                onPressed: () => _scrollPage(false),
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chapterTitle,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Text(
                          '$progressPercent%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 28),
                tooltip: '下一页',
                onPressed: () => _scrollPage(true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

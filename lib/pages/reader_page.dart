import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/analysis_result.dart';
import '../models/content_block.dart';
import '../models/reading_search_result.dart';
import '../providers/reading_provider.dart';
import '../services/settings_service.dart';
import '../theme/app_constants.dart';
import '../widgets/ai_summary_view.dart';
import '../widgets/bookmark_sheet.dart';
import '../widgets/font_settings_sheet.dart';
import '../widgets/reader/reader_word_sidebar.dart';
import '../widgets/reader_text_view.dart';
import '../widgets/selected_text_action_toolbar.dart';
import '../widgets/selected_text_sheet.dart';
import '../widgets/toc_bottom_sheet.dart';
import '../widgets/word_bottom_sheet.dart';

enum _ReaderSidebarMode { word, textAnalysis }

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Map<int, GlobalKey> _contentKeys = {};
  ReadingProvider? _readingProvider;
  String? _lastReaderLocationKey;
  bool _scrollResetQueued = false;
  String _sidebarSelectedText = '';
  String _sidebarAnalyzerName = 'AI';
  _ReaderSidebarMode _sidebarMode = _ReaderSidebarMode.word;
  bool _sidebarOpen = false;
  bool _searchSheetOpen = false;
  bool _searchShowingAll = false;
  bool _dailyGoalPromptShown = false;
  bool _wasDailyGoalReached = false;
  Timer? _dailyGoalCheckTimer;
  double _layoutWidth = 0;
  double _displayProgress = 0.0;
  int _visibleContentCount = 0;

  bool get _isWideScreen => _layoutWidth >= AppConstants.wideBreakpoint;
  bool get _isSearchPanelVisible => _searchSheetOpen;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<ReadingProvider>();
    if (identical(_readingProvider, provider)) return;

    _readingProvider?.removeListener(_onReadingProviderChanged);
    _readingProvider = provider;
    _lastReaderLocationKey = _readerLocationKey(provider);
    provider.addListener(_onReadingProviderChanged);
    _syncDailyGoalWatcher(provider);
  }

  @override
  void dispose() {
    _dailyGoalCheckTimer?.cancel();
    _readingProvider?.removeListener(_onReadingProviderChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _readerLocationKey(ReadingProvider provider) {
    final book = provider.book;
    final bookKey =
        provider.activeBookId ??
        (book == null
            ? 'standalone'
            : '${identityHashCode(book)}:${book.title}');
    return '$bookKey:${provider.currentChapter}';
  }

  void _onReadingProviderChanged() {
    final provider = _readingProvider;
    if (provider == null) return;
    _syncDailyGoalWatcher(provider);

    final nextLocationKey = _readerLocationKey(provider);
    if (_lastReaderLocationKey == null) {
      _lastReaderLocationKey = nextLocationKey;
      return;
    }
    if (_lastReaderLocationKey == nextLocationKey) return;

    _lastReaderLocationKey = nextLocationKey;
    _queueScrollToTopForNewLocation();
  }

  void _queueScrollToTopForNewLocation() {
    if (mounted) {
      setState(() {
        _displayProgress = 0.0;
        _contentKeys.clear();
      });
    }

    if (_scrollResetQueued) return;
    _scrollResetQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollResetQueued = false;
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    final progress = (_scrollController.offset / maxScroll).clamp(0.0, 1.0);
    _displayProgress = progress;
    context.read<ReadingProvider>().updateReadingProgress(progress);
    _checkDailyReadingGoal();
    setState(() {});
  }

  void _syncDailyGoalWatcher(ReadingProvider provider) {
    if (!provider.isReading) {
      _dailyGoalCheckTimer?.cancel();
      _dailyGoalCheckTimer = null;
      _dailyGoalPromptShown = false;
      _wasDailyGoalReached = provider.dailyReadingGoalReached;
      return;
    }

    if (_dailyGoalCheckTimer != null) return;
    _wasDailyGoalReached = provider.dailyReadingGoalReached;
    _dailyGoalCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkDailyReadingGoal(),
    );
  }

  void _checkDailyReadingGoal() {
    if (!mounted) return;
    final provider = context.read<ReadingProvider>();
    final reached = provider.dailyReadingGoalReached;
    if (!reached) {
      _wasDailyGoalReached = false;
      _dailyGoalPromptShown = false;
      return;
    }
    if (_wasDailyGoalReached || _dailyGoalPromptShown) return;

    _wasDailyGoalReached = true;
    _dailyGoalPromptShown = true;
    final goalText = _formatGoalDuration(provider.dailyReadingGoalSeconds);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('今日阅读目标已达成：$goalText'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  String _formatGoalDuration(int seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes 分钟';
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    if (remain == 0) return '$hours 小时';
    return '$hours 小时 $remain 分钟';
  }

  void _onWordTapped(String word, String contextText) {
    context.read<ReadingProvider>().lookupWord(word, contextText: contextText);
    if (_isWideScreen) {
      setState(() {
        _sidebarMode = _ReaderSidebarMode.word;
        _sidebarOpen = true;
      });
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => WordBottomSheet(word: word),
      );
    }
  }

  void _onAnalyzeSelected(String text) {
    final settings = context.read<SettingsService>();
    if (!settings.aiFeaturesEnabled) return;
    final selectedText = text.trim();
    if (selectedText.isEmpty) return;
    final provider = context.read<ReadingProvider>();
    final analyzerName = '${settings.aiProvider.label} AI';
    // Get surrounding context
    final result = provider.result;
    String before = '';
    String after = '';
    if (result != null) {
      final fullText = result.passageText;
      final idx = fullText.indexOf(selectedText);
      if (idx >= 0) {
        final start = (idx - 200).clamp(0, idx);
        before = fullText.substring(start, idx);
        final end = (idx + selectedText.length + 200).clamp(0, fullText.length);
        after = fullText.substring(idx + selectedText.length, end);
      }
    }
    provider.analyzeSelectedTextAI(selectedText, before, after);
    if (_isWideScreen) {
      setState(() {
        _sidebarMode = _ReaderSidebarMode.textAnalysis;
        _sidebarSelectedText = selectedText;
        _sidebarAnalyzerName = analyzerName;
        _sidebarOpen = true;
      });
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectedTextSheet(
        selectedText: selectedText,
        analysis: null,
        analyzerName: analyzerName,
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

  Future<void> _showSearchSheet() async {
    if (_searchSheetOpen) return;

    setState(() {
      _searchSheetOpen = true;
      _searchShowingAll = false;
    });
    if (_searchController.text.trim().isNotEmpty) {
      unawaited(
        context.read<ReadingProvider>().searchInBook(_searchController.text),
      );
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReaderSearchSheet(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        onMore: _showAllSearchResults,
        onResultTap: _onSearchResultTap,
      ),
    );
    if (!mounted) return;
    setState(() => _searchSheetOpen = false);
  }

  void _onSearchChanged(String value) {
    unawaited(
      context.read<ReadingProvider>().searchInBook(
        value,
        includeAll: _searchShowingAll,
      ),
    );
  }

  void _showAllSearchResults() {
    setState(() => _searchShowingAll = true);
    unawaited(context.read<ReadingProvider>().searchAllInBook());
  }

  Future<void> _onSearchResultTap(ReadingSearchResult result) async {
    final provider = context.read<ReadingProvider>();
    await provider.goToSearchResult(result);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToSearchResult(result);
    });
  }

  void _scrollToSearchResult(ReadingSearchResult result) {
    final contextForItem = _contentKeys[result.itemIndex]?.currentContext;
    if (contextForItem != null) {
      Scrollable.ensureVisible(
        contextForItem,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0.22,
      );
      return;
    }

    if (!_scrollController.hasClients || _visibleContentCount <= 1) return;
    final position = _scrollController.position;
    final ratio = (result.itemIndex / (_visibleContentCount - 1)).clamp(
      0.0,
      1.0,
    );
    final target = position.maxScrollExtent * ratio;
    unawaited(
      _scrollController
          .animateTo(
            target,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          )
          .then((_) {
            if (!mounted) return;
            final contextForItem =
                _contentKeys[result.itemIndex]?.currentContext;
            if (contextForItem == null) return;
            if (!contextForItem.mounted) return;
            Scrollable.ensureVisible(
              contextForItem,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: 0.22,
            );
          }),
    );
  }

  GlobalKey _contentKeyFor(int index) {
    return _contentKeys.putIfAbsent(index, GlobalKey.new);
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
    final settings = context.watch<SettingsService>();
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
    final progressPercent = (_displayProgress * 100).round();
    final chapterTitle = provider.hasBook && provider.chapterCount > 0
        ? provider.book!.chapters[provider.currentChapter].title
        : result.title;
    final colorSettings = settings.colors;

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
                progressPercent: progressPercent,
                showSidebarToggle: isWide,
                aiFeaturesEnabled: settings.aiFeaturesEnabled,
              ),
              _buildReadingProgressLine(theme, _displayProgress),
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
                              colorSettings,
                              settings.aiFeaturesEnabled,
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: _sidebarOpen
                                ? _buildReaderSidebar()
                                : const SizedBox.shrink(),
                          ),
                        ],
                      )
                    : _buildReadingContent(
                        paragraphs,
                        blocks,
                        result,
                        theme,
                        colorSettings,
                        settings.aiFeaturesEnabled,
                      ),
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

  Widget _buildReadingProgressLine(ThemeData theme, double progress) {
    return LinearProgressIndicator(
      value: progress,
      minHeight: 2,
      backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
    );
  }

  Widget _buildReadingContent(
    List<String> paragraphs,
    List<ContentBlock> blocks,
    AnalysisResult result,
    ThemeData theme,
    VocabularyColorSettings colorSettings,
    bool aiFeaturesEnabled,
  ) {
    return SelectedTextActionRegion(
      actionsBuilder: (context, selectedText, closeToolbar) =>
          _buildSelectedTextActions(
            context,
            selectedText,
            closeToolbar,
            aiFeaturesEnabled: aiFeaturesEnabled,
          ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final provider = context.read<ReadingProvider>();
          final showTitleBlock = !provider.hasBook;
          final topPadding = showTitleBlock ? 14.0 : 10.0;
          final wide = _isWideScreen;
          final compactWide = wide && constraints.maxWidth < 760;
          final leftPadding = wide ? (compactWide ? 48.0 : 80.0) : 18.0;
          final rightPadding = wide
              ? (_sidebarOpen ? (compactWide ? 24.0 : 40.0) : leftPadding)
              : 18.0;
          final maxTextWidth = wide ? 720.0 : double.infinity;
          final maxFrameWidth = wide
              ? maxTextWidth + leftPadding + rightPadding
              : double.infinity;
          final useBlocks = blocks.isNotEmpty;
          final contentCount = useBlocks ? blocks.length : paragraphs.length;
          _visibleContentCount = contentCount;

          return Align(
            alignment: wide && _sidebarOpen
                ? Alignment.topLeft
                : Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxFrameWidth),
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  leftPadding,
                  topPadding,
                  rightPadding,
                  40,
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
                    return KeyedSubtree(
                      key: _contentKeyFor(contentIndex),
                      child: _buildContentBlock(
                        blocks[contentIndex],
                        result,
                        theme,
                        colorSettings: colorSettings,
                        isFirstBlock: contentIndex == 0 && provider.hasBook,
                      ),
                    );
                  }

                  return KeyedSubtree(
                    key: _contentKeyFor(contentIndex),
                    child: _buildParagraph(
                      paragraphs[contentIndex],
                      result,
                      theme,
                      colorSettings: colorSettings,
                      isFirstParagraph: contentIndex == 0 && provider.hasBook,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  List<SelectedTextAction> _buildSelectedTextActions(
    BuildContext context,
    String selectedText,
    VoidCallback closeToolbar, {
    required bool aiFeaturesEnabled,
  }) {
    return [
      SelectedTextAction.copy(
        context: context,
        selectedText: selectedText,
        closeToolbar: closeToolbar,
      ),
      SelectedTextAction(
        icon: Icons.auto_awesome_rounded,
        tooltip: 'AI 解析',
        enabled: aiFeaturesEnabled && selectedText.trim().isNotEmpty,
        onPressed: () {
          closeToolbar();
          _onAnalyzeSelected(selectedText);
        },
      ),
    ];
  }

  Widget _buildContentBlock(
    ContentBlock block,
    AnalysisResult result,
    ThemeData theme, {
    required VocabularyColorSettings colorSettings,
    bool isFirstBlock = false,
  }) {
    final provider = context.read<ReadingProvider>();
    final searchQuery = _isSearchPanelVisible ? provider.searchQuery : '';

    if (isFirstBlock &&
        searchQuery.isEmpty &&
        block is TextBlock &&
        block.type == BlockType.paragraph &&
        block.plainText.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildDropCapParagraph(
          block.plainText,
          result,
          theme,
          colorSettings,
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
      colorSettings: colorSettings,
      searchQuery: searchQuery,
      wordLevelService: provider.wordLevelService,
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
    required VocabularyColorSettings colorSettings,
    bool isFirstParagraph = false,
  }) {
    final provider = context.read<ReadingProvider>();
    final baseStyle = _buildBaseTextStyle(theme, provider);
    final searchQuery = _isSearchPanelVisible ? provider.searchQuery : '';

    if (isFirstParagraph && paragraph.isNotEmpty && searchQuery.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildDropCapParagraph(
          paragraph,
          result,
          theme,
          colorSettings,
          baseStyle,
        ),
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
          colorSettings: colorSettings,
          searchQuery: searchQuery,
          wordLevelService: provider.wordLevelService,
        ),
        style: baseStyle,
      ),
    );
  }

  Widget _buildDropCapParagraph(
    String paragraph,
    AnalysisResult result,
    ThemeData theme,
    VocabularyColorSettings colorSettings,
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
              colorSettings: colorSettings,
              wordLevelService: provider.wordLevelService,
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
    required int progressPercent,
    bool showSidebarToggle = false,
    required bool aiFeaturesEnabled,
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
    final difficultyLabel = provider.currentBookDifficulty?.level.shortLabel;
    final locationLabel = provider.hasBook
        ? [
            '位置 ${provider.currentChapter + 1} / ${provider.chapterCount}',
            '$progressPercent%',
            ?difficultyLabel,
          ].join(' · ')
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
          if (showSidebarToggle)
            _compactIconButton(
              icon: _sidebarOpen
                  ? Icons.vertical_split
                  : Icons.vertical_split_outlined,
              tooltip: _sidebarOpen ? '收起侧栏' : '展开侧栏',
              onPressed: () => setState(() {
                if (!_sidebarOpen && _sidebarSelectedText.isEmpty) {
                  _sidebarMode = _ReaderSidebarMode.word;
                }
                _sidebarOpen = !_sidebarOpen;
              }),
            ),
          if (showSearch)
            _compactIconButton(
              icon: Icons.search,
              tooltip: '搜索',
              onPressed: () => unawaited(_showSearchSheet()),
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
            position: PopupMenuPosition.under,
            tooltip: '更多',
            onSelected: (value) {
              switch (value) {
                case 'search':
                  unawaited(_showSearchSheet());
                  break;
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
              if (!showSearch)
                const PopupMenuItem(value: 'search', child: Text('搜索')),
              if (!showSearch) const PopupMenuDivider(),
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
              PopupMenuItem(
                value: 'summary',
                enabled: aiFeaturesEnabled,
                child: const Text('AI 总结当前内容'),
              ),
              PopupMenuItem(
                value: 'practice',
                enabled: aiFeaturesEnabled,
                child: const Text('生成练习题'),
              ),
              const PopupMenuItem(value: 'bookmarks', child: Text('历史书签')),
            ],
            child: const SizedBox.square(
              dimension: 34,
              child: Icon(Icons.more_horiz, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReaderSidebar() {
    return switch (_sidebarMode) {
      _ReaderSidebarMode.word => ReaderWordSidebar(
        onClose: () => setState(() => _sidebarOpen = false),
      ),
      _ReaderSidebarMode.textAnalysis => SelectedTextSheet(
        selectedText: _sidebarSelectedText,
        analysis: null,
        analyzerName: _sidebarAnalyzerName,
        embedded: true,
        onClose: () => setState(() => _sidebarOpen = false),
      ),
    };
  }
}

class _ReaderSearchSheet extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onMore;
  final ValueChanged<ReadingSearchResult> onResultTap;

  const _ReaderSearchSheet({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onMore,
    required this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      minChildSize: 0.44,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: _ReaderSearchPanel(
              controller: controller,
              focusNode: focusNode,
              expanded: false,
              resultsScrollController: scrollController,
              onChanged: onChanged,
              onClose: () => Navigator.of(context).pop(),
              onMore: onMore,
              onResultTap: onResultTap,
            ),
          ),
        );
      },
    );
  }
}

class _ReaderSearchPanel extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool expanded;
  final ScrollController? resultsScrollController;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;
  final VoidCallback onMore;
  final ValueChanged<ReadingSearchResult> onResultTap;

  const _ReaderSearchPanel({
    required this.controller,
    required this.focusNode,
    required this.expanded,
    required this.onChanged,
    required this.onClose,
    required this.onMore,
    required this.onResultTap,
    this.resultsScrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ReadingProvider>(
      builder: (context, provider, _) {
        final results = provider.searchResults;
        final query = provider.searchQuery;
        return Padding(
          padding: expanded
              ? const EdgeInsets.fromLTRB(18, 12, 18, 14)
              : const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              _SearchField(
                controller: controller,
                focusNode: focusNode,
                expanded: expanded,
                onChanged: onChanged,
                onClose: onClose,
              ),
              const SizedBox(height: 8),
              _SearchStatus(provider: provider, expanded: expanded),
              const SizedBox(height: 6),
              Expanded(
                child: _SearchResultsList(
                  query: query,
                  results: results,
                  isSearching: provider.isSearching,
                  activeResult: provider.activeSearchResult,
                  scrollController: resultsScrollController,
                  onResultTap: onResultTap,
                ),
              ),
              if (!expanded && provider.searchStoppedAtLimit) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onMore,
                    icon: const Icon(Icons.open_in_full, size: 18),
                    label: const Text('显示更多'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool expanded;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.expanded,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: onChanged,
            decoration: InputDecoration(
              isDense: true,
              hintText: '搜索书中内容',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: '清除',
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(expanded ? Icons.keyboard_arrow_down : Icons.close),
          tooltip: expanded ? '收起' : '关闭',
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _SearchStatus extends StatelessWidget {
  final ReadingProvider provider;
  final bool expanded;

  const _SearchStatus({required this.provider, required this.expanded});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resultCount = provider.searchResults.length;
    final query = provider.searchQuery;
    final text = query.isEmpty
        ? '输入关键词'
        : provider.isSearching
        ? '正在搜索... $resultCount'
        : provider.searchStoppedAtLimit && !expanded
        ? '已显示前 $resultCount 条'
        : '共 $resultCount 条结果';

    return Row(
      children: [
        if (provider.isSearching) ...[
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  final String query;
  final List<ReadingSearchResult> results;
  final bool isSearching;
  final ReadingSearchResult? activeResult;
  final ScrollController? scrollController;
  final ValueChanged<ReadingSearchResult> onResultTap;

  const _SearchResultsList({
    required this.query,
    required this.results,
    required this.isSearching,
    required this.activeResult,
    required this.onResultTap,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (query.isEmpty) {
      return _SearchEmptyState(text: '输入关键词进行全文搜索');
    }
    if (results.isEmpty) {
      if (isSearching) {
        return _SearchEmptyState(text: '正在搜索...');
      }
      return _SearchEmptyState(text: '未找到匹配内容');
    }

    return ListView.separated(
      controller: scrollController,
      itemCount: results.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
      ),
      itemBuilder: (context, index) {
        final result = results[index];
        return _SearchResultTile(
          result: result,
          selected: activeResult == result,
          onTap: () => onResultTap(result),
        );
      },
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  final String text;

  const _SearchEmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final ReadingSearchResult result;
  final bool selected;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.result,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = result.chapterTitle.trim().isEmpty
        ? result.locationLabel
        : '${result.locationLabel} · ${result.chapterTitle.trim()}';

    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                text: _buildResultSnippetSpan(result, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

TextSpan _buildResultSnippetSpan(ReadingSearchResult result, ThemeData theme) {
  final baseStyle = theme.textTheme.bodySmall?.copyWith(
    height: 1.35,
    color: theme.colorScheme.onSurfaceVariant,
  );
  final highlightStyle = baseStyle?.copyWith(
    color: searchHighlightForegroundFor(theme),
    backgroundColor: searchHighlightBackgroundFor(theme),
    fontWeight: FontWeight.w700,
  );
  final text = result.snippet;
  final start = result.snippetMatchStart.clamp(0, text.length).toInt();
  final end = result.snippetMatchEnd.clamp(start, text.length).toInt();

  return TextSpan(
    style: baseStyle,
    children: [
      if (start > 0) TextSpan(text: text.substring(0, start)),
      TextSpan(text: text.substring(start, end), style: highlightStyle),
      if (end < text.length) TextSpan(text: text.substring(end)),
    ],
  );
}

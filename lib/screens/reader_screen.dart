import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/analysis_result.dart';
import '../models/content_block.dart';
import '../providers/reading_provider.dart';
import '../services/settings_service.dart';
import '../theme/app_constants.dart';
import '../widgets/reader/reader_book_sidebar.dart';
import '../widgets/reader_text_view.dart';
import '../widgets/selected_text_sheet.dart';
import '../widgets/toc_bottom_sheet.dart';

class ReaderScreen extends StatelessWidget {
  const ReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConstants.layoutBreakpoint) {
          return const _WideReader();
        }
        return const _NarrowReader();
      },
    );
  }
}

class _NarrowReader extends StatefulWidget {
  const _NarrowReader();

  @override
  State<_NarrowReader> createState() => _NarrowReaderState();
}

class _NarrowReaderState extends State<_NarrowReader> {
  final ScrollController _scrollController = ScrollController();
  double _viewportHeight = 0;
  int? _selectedParagraphIndex;

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
    context.read<ReadingProvider>().updateReadingProgress(
      _scrollController.offset / maxScroll,
    );
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
    setState(() => _selectedParagraphIndex = null);
    context.read<ReadingProvider>().lookupWord(word);
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

  void _onParagraphLongPress(int paraIndex, String text, Offset globalPos) {
    setState(() => _selectedParagraphIndex = paraIndex);
    _showSelectionMenu(text, globalPos);
  }

  void _showSelectionMenu(String selectedText, Offset position) {
    final theme = Theme.of(context);
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: [
        PopupMenuItem(
          value: 'analyze',
          child: Row(
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text('分析句子结构', style: theme.textTheme.labelLarge),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'translate',
          child: Row(
            children: [
              Icon(
                Icons.translate,
                size: 20,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 12),
              Text('翻译', style: theme.textTheme.labelLarge),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(
                Icons.copy,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text('复制', style: theme.textTheme.labelLarge),
            ],
          ),
        ),
      ],
    ).then((value) {
      setState(() => _selectedParagraphIndex = null);
      switch (value) {
        case 'analyze':
          _analyzeSelectedText(selectedText);
          break;
        case 'translate':
          _translateSelectedText(selectedText);
          break;
        case 'copy':
          Clipboard.setData(ClipboardData(text: selectedText));
          _showCopiedSnackBar();
          break;
      }
    });
  }

  void _analyzeSelectedText(String text) {
    context.read<ReadingProvider>().analyzeSelectedText(text);
    final provider = context.read<ReadingProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectedTextSheet(
        selectedText: text,
        analysis: provider.selectedAnalysis,
        breakdowns: provider.selectedBreakdowns,
        analyzerName: provider.sentenceAnalyzer.analyzerName,
        tab: SelectedTextTab.analysis,
      ),
    );
  }

  void _translateSelectedText(String text) {
    context.read<ReadingProvider>().analyzeSelectedText(text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectedTextSheet(
        selectedText: text,
        analysis: null,
        breakdowns: null,
        tab: SelectedTextTab.translate,
      ),
    );
  }

  void _showCopiedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已复制到剪贴板'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 200,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingProvider>();
    final settings = context.watch<SettingsService>();
    final result = provider.result;
    final theme = Theme.of(context);

    if (result == null) return const Center(child: CircularProgressIndicator());

    final chapter = provider.hasBook && provider.chapterCount > 0
        ? provider.book!.chapters[provider.currentChapter]
        : null;
    final blocks = chapter?.blocks ?? const [];
    final useBlocks = blocks.isNotEmpty;
    final paragraphs = useBlocks
        ? <String>[]
        : splitIntoParagraphs(result.passageText);
    final itemCount = useBlocks ? blocks.length + 1 : paragraphs.length + 1;
    final progressPercent = (provider.readingProgress * 100).toInt();
    final chapterTitle = chapter?.title ?? result.title;
    final colorSettings = settings.colors;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: provider.exitReader,
        ),
        title: Text(
          result.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (provider.hasBook && provider.chapterCount > 1)
            IconButton(
              icon: const Icon(Icons.list_alt),
              tooltip: 'Table of Contents',
              onPressed: _showTocSheet,
            ),
        ],
      ),
      body: Column(
        children: [
          if (provider.hasBook && provider.chapterCount > 1)
            buildChapterNav(context, provider, theme),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _viewportHeight = constraints.maxHeight;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                                fontFamily: 'Serif',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Divider(color: theme.colorScheme.outlineVariant),
                            const SizedBox(height: 12),
                          ],
                        ),
                      );
                    }
                    final itemIndex = index - 1;

                    if (useBlocks) {
                      if (itemIndex >= blocks.length) {
                        return const SizedBox.shrink();
                      }
                      return buildBlockWidget(
                        blocks[itemIndex],
                        result,
                        theme,
                        onWordTapped: _onWordTapped,
                        onParagraphLongPress: (text) =>
                            _onParagraphLongPress(itemIndex, text, Offset.zero),
                        colorSettings: colorSettings,
                        wordLevelService: provider.wordLevelService,
                      );
                    }

                    if (itemIndex >= paragraphs.length) {
                      return const SizedBox.shrink();
                    }

                    final isSelected = _selectedParagraphIndex == itemIndex;
                    return GestureDetector(
                      onLongPressStart: (details) => _onParagraphLongPress(
                        itemIndex,
                        paragraphs[itemIndex],
                        details.globalPosition,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primaryContainer.withValues(
                                  alpha: 0.25,
                                )
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text.rich(
                            buildHighlightedParagraph(
                              paragraphs[itemIndex],
                              result,
                              theme,
                              onWordTapped: _onWordTapped,
                              colorSettings: colorSettings,
                              wordLevelService: provider.wordLevelService,
                            ),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 2.0,
                              letterSpacing: 0.3,
                              fontFamily: 'Serif',
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (provider.selectedWord != null)
            buildInlineDictionaryPopup(context, provider, theme),
          _buildBottomBar(
            context,
            provider.readingProgress,
            theme,
            chapterTitle,
            progressPercent,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, size: 28),
                tooltip: 'Previous page',
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
                              color: theme.colorScheme.onSurfaceVariant,
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
                tooltip: 'Next page',
                onPressed: () => _scrollPage(true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WideReader extends StatefulWidget {
  const _WideReader();

  @override
  State<_WideReader> createState() => _WideReaderState();
}

class _WideReaderState extends State<_WideReader> {
  final ScrollController _scrollController = ScrollController();
  int? _selectedParagraphIndex;

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
    context.read<ReadingProvider>().updateReadingProgress(
      _scrollController.offset / maxScroll,
    );
  }

  void _onWordTapped(String word, String contextText) {
    setState(() => _selectedParagraphIndex = null);
    context.read<ReadingProvider>().lookupWord(word);
  }

  void _onParagraphLongPress(int paraIndex, String text, Offset globalPos) {
    setState(() => _selectedParagraphIndex = paraIndex);
    _showSelectionMenu(text, globalPos);
  }

  void _showSelectionMenu(String selectedText, Offset position) {
    final theme = Theme.of(context);
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: [
        PopupMenuItem(
          value: 'analyze',
          child: Row(
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text('分析句子结构', style: theme.textTheme.labelLarge),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'translate',
          child: Row(
            children: [
              Icon(
                Icons.translate,
                size: 20,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 12),
              Text('翻译', style: theme.textTheme.labelLarge),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(
                Icons.copy,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text('复制', style: theme.textTheme.labelLarge),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (!mounted) return;
      setState(() => _selectedParagraphIndex = null);
      switch (value) {
        case 'analyze':
          _analyzeSelectedText(selectedText);
          break;
        case 'translate':
          _translateSelectedText(selectedText);
          break;
        case 'copy':
          Clipboard.setData(ClipboardData(text: selectedText));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('已复制到剪贴板'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              width: 200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          break;
      }
    });
  }

  void _analyzeSelectedText(String text) {
    context.read<ReadingProvider>().analyzeSelectedText(text);
    final provider = context.read<ReadingProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectedTextSheet(
        selectedText: text,
        analysis: provider.selectedAnalysis,
        breakdowns: provider.selectedBreakdowns,
        analyzerName: provider.sentenceAnalyzer.analyzerName,
        tab: SelectedTextTab.analysis,
      ),
    );
  }

  void _translateSelectedText(String text) {
    context.read<ReadingProvider>().analyzeSelectedText(text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectedTextSheet(
        selectedText: text,
        analysis: null,
        breakdowns: null,
        tab: SelectedTextTab.translate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingProvider>();
    final settings = context.watch<SettingsService>();
    final result = provider.result;
    final theme = Theme.of(context);

    if (result == null) return const Center(child: CircularProgressIndicator());

    final chapter = provider.hasBook && provider.chapterCount > 0
        ? provider.book!.chapters[provider.currentChapter]
        : null;
    final wideBlocks = chapter?.blocks ?? const [];
    final wideUseBlocks = wideBlocks.isNotEmpty;
    final paragraphs = wideUseBlocks
        ? <String>[]
        : splitIntoParagraphs(result.passageText);
    final progressPercent = (provider.readingProgress * 100).toInt();
    final chapterTitle = chapter?.title ?? result.title;
    final colorSettings = settings.colors;

    return Scaffold(
      body: Column(
        children: [
          _buildTopBar(theme, provider, chapterTitle, progressPercent),
          Expanded(
            child: Row(
              children: [
                const ReaderBookSidebar(),
                VerticalDivider(
                  width: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppConstants.readerMaxWidth,
                            ),
                            child: _buildReadingContent(
                              paragraphs,
                              result,
                              theme,
                              colorSettings,
                              blocks: wideBlocks,
                              useBlocks: wideUseBlocks,
                            ),
                          ),
                        ),
                      ),
                      if (provider.selectedWord != null)
                        buildInlineDictionaryPopup(context, provider, theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildBottomSlider(theme, provider, progressPercent),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    ThemeData theme,
    ReadingProvider provider,
    String chapterTitle,
    int progressPercent,
  ) {
    final contentTitle = chapterTitle.trim().isNotEmpty
        ? chapterTitle.trim()
        : '当前位置';
    final locationLabel =
        '位置 ${provider.currentChapter + 1} / ${provider.chapterCount}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: provider.exitReader,
            tooltip: '返回',
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _showToc(context),
            tooltip: '目录',
          ),
          const Spacer(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                contentTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                locationLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '$progressPercent%',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
            tooltip: '搜索',
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () {},
            tooltip: '字体',
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () {},
            tooltip: '书签',
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {},
            tooltip: '更多',
          ),
        ],
      ),
    );
  }

  Widget _buildReadingContent(
    List<String> paragraphs,
    AnalysisResult result,
    ThemeData theme,
    VocabularyColorSettings colorSettings, {
    List<ContentBlock> blocks = const [],
    bool useBlocks = false,
  }) {
    if (useBlocks) {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(32),
        itemCount: blocks.length,
        itemBuilder: (context, index) {
          return buildBlockWidget(
            blocks[index],
            result,
            theme,
            onWordTapped: _onWordTapped,
            onParagraphLongPress: (text) =>
                _onParagraphLongPress(index, text, Offset.zero),
            fontSize: 18,
            colorSettings: colorSettings,
            wordLevelService: context.read<ReadingProvider>().wordLevelService,
          );
        },
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(32),
      itemCount: paragraphs.length,
      itemBuilder: (context, index) {
        final isSelected = _selectedParagraphIndex == index;

        Widget paragraphWidget;
        if (index == 0 && paragraphs[index].isNotEmpty) {
          paragraphWidget = _buildDropCapParagraph(
            paragraphs[index],
            result,
            theme,
            colorSettings,
          );
        } else {
          paragraphWidget = Text.rich(
            buildHighlightedParagraph(
              paragraphs[index],
              result,
              theme,
              onWordTapped: _onWordTapped,
              colorSettings: colorSettings,
              wordLevelService: context
                  .read<ReadingProvider>()
                  .wordLevelService,
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 2.0,
              letterSpacing: 0.3,
              fontFamily: 'Serif',
              fontSize: 18,
              color: theme.colorScheme.onSurface,
            ),
          );
        }

        return GestureDetector(
          onLongPressStart: (details) => _onParagraphLongPress(
            index,
            paragraphs[index],
            details.globalPosition,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(6),
            margin: const EdgeInsets.only(bottom: 8),
            child: paragraphWidget,
          ),
        );
      },
    );
  }

  Widget _buildDropCapParagraph(
    String paragraph,
    AnalysisResult result,
    ThemeData theme,
    VocabularyColorSettings colorSettings,
  ) {
    final firstLetter = paragraph[0].toUpperCase();
    final restText = paragraph.substring(1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 4),
          child: Text(
            firstLetter,
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              height: 0.8,
              fontFamily: 'Serif',
              color: theme.colorScheme.onSurface,
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
              colorSettings: colorSettings,
              wordLevelService: context
                  .read<ReadingProvider>()
                  .wordLevelService,
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 2.0,
              letterSpacing: 0.3,
              fontFamily: 'Serif',
              fontSize: 18,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSlider(
    ThemeData theme,
    ReadingProvider provider,
    int progressPercent,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '0%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                activeTrackColor: theme.colorScheme.primary,
                inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
                thumbColor: theme.colorScheme.onSurface,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: provider.readingProgress.clamp(0.0, 1.0),
                onChanged: (value) {},
              ),
            ),
          ),
          Text(
            '100%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: provider.currentChapter < provider.chapterCount - 1
                ? () => provider.goToChapter(provider.currentChapter + 1)
                : null,
            icon: const Text('下一项'),
            label: const Icon(Icons.chevron_right, size: 18),
          ),
        ],
      ),
    );
  }

  void _showToc(BuildContext context) {
    final provider = context.read<ReadingProvider>();
    if (!provider.hasBook || provider.chapterCount <= 1) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TocBottomSheet(),
    );
  }
}

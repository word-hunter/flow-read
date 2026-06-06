import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../models/analysis_result.dart';
import '../models/content_block.dart';
import '../models/reading_search_result.dart';
import '../providers/reading/bookmark_provider.dart';
import '../providers/reading/current_book_provider.dart';
import '../providers/reading/reading_config_provider.dart';
import '../providers/reading/reading_search_provider.dart';
import '../providers/reading/reading_time_provider.dart';
import '../providers/reading/text_selection_provider.dart';
import '../providers/reading/word_lookup_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_constants.dart';
import '../widgets/bookmark_sheet.dart';
import '../widgets/font_settings_sheet.dart';
import '../widgets/reader/reader_content_view.dart';
import '../widgets/reader/reader_nav_bar.dart';
import '../widgets/reader/reader_search_panel.dart';
import '../widgets/reader/reader_word_sidebar.dart';
import '../widgets/reader_text_view.dart';
import '../widgets/selected_text_sheet.dart';
import '../widgets/toc_bottom_sheet.dart';
import '../widgets/word_bottom_sheet.dart';

part 'reader_daily_goal_mixin.dart';
part 'reader_keyboard_mixin.dart';
part 'reader_viewport_mixin.dart';

enum _ReaderSidebarMode { word, textAnalysis }

class ReaderPage extends riverpod.ConsumerStatefulWidget {
  const ReaderPage({super.key});

  @override
  riverpod.ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends riverpod.ConsumerState<ReaderPage>
    with ReaderDailyGoalMixin, ReaderViewportMixin, ReaderKeyboardMixin {
  @override
  final ScrollController _scrollController = ScrollController();
  final MenuController _tocMenuController = MenuController();
  final MenuController _fontSettingsMenuController = MenuController();
  @override
  final FocusNode _readerFocusNode = FocusNode(
    debugLabel: 'ReaderPageKeyboard',
  );
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  @override
  final Map<int, GlobalKey> _contentKeys = {};
  @override
  final ValueNotifier<double> _displayProgressNotifier = ValueNotifier<double>(
    0.0,
  );

  String _sidebarSelectedText = '';
  String _sidebarAnalyzerName = 'AI';
  _ReaderSidebarMode _sidebarMode = _ReaderSidebarMode.word;
  bool _sidebarOpen = false;
  @override
  bool _searchSheetOpen = false;
  bool _tocMenuOpen = false;
  bool _fontSettingsMenuOpen = false;
  bool _searchShowingAll = false;
  double _layoutWidth = 0;

  bool get _isWideScreen => _layoutWidth >= AppConstants.wideBreakpoint;
  bool get _isSearchPanelVisible => _searchSheetOpen;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _disposeDailyGoalWatcher();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _displayProgressNotifier.dispose();
    _readerFocusNode.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onWordTapped(
    String word,
    String contextText, {
    int? contextWordStart,
    int? contextWordEnd,
  }) {
    _hideReadingReminder();
    final lookup = ref.read(wordLookupProvider);
    lookup.lookupWord(
      word,
      contextText: contextText,
      contextWordStart: contextWordStart,
      contextWordEnd: contextWordEnd,
      trackReadingLookup: true,
    );
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
      ).whenComplete(lookup.clearWordLookup);
    }
  }

  void _onAnalyzeSelected(String text) {
    final settings = ref.read(settingsProvider);
    if (!settings.aiFeaturesEnabled) return;
    final selectedText = text.trim();
    if (selectedText.isEmpty) return;
    final analyzerName = '${settings.aiProvider.label} AI';
    ref.read(textSelectionProvider).analyzeSelectedTextAI(selectedText);
    if (_isWideScreen) {
      ref.read(wordLookupProvider).clearWordLookup();
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
    final currentBook = ref.read(currentBookProvider);
    if (!currentBook.hasBook) return;
    _hideReadingReminder();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TocBottomSheet(),
    );
  }

  void _toggleTocMenu(MenuController controller) {
    _hideReadingReminder();
    if (controller.isOpen) {
      controller.close();
    } else {
      if (_fontSettingsMenuOpen) {
        _fontSettingsMenuController.close();
      }
      controller.open();
    }
  }

  void _setTocMenuOpen(bool isOpen) {
    if (!mounted || _tocMenuOpen == isOpen) return;
    setState(() => _tocMenuOpen = isOpen);
  }

  void _toggleFontSettingsMenu(MenuController controller) {
    _hideReadingReminder();
    if (controller.isOpen) {
      controller.close();
    } else {
      if (_tocMenuOpen) {
        _tocMenuController.close();
      }
      controller.open();
    }
  }

  void _setFontSettingsMenuOpen(bool isOpen) {
    if (!mounted || _fontSettingsMenuOpen == isOpen) return;
    setState(() => _fontSettingsMenuOpen = isOpen);
  }

  void _showFontSettingsSheet() {
    _hideReadingReminder();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FontSettingsSheet(),
    );
  }

  Future<void> _showSearchSheet() async {
    if (_searchSheetOpen) return;

    _hideReadingReminder();
    final search = riverpod.ProviderScope.containerOf(
      context,
      listen: false,
    ).read(readingSearchProvider);
    search.clearSourceHighlight();
    setState(() {
      _searchSheetOpen = true;
      _searchShowingAll = false;
    });
    if (_searchController.text.trim().isNotEmpty) {
      unawaited(search.searchInBook(_searchController.text));
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReaderSearchSheet(
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
    final search = riverpod.ProviderScope.containerOf(
      context,
      listen: false,
    ).read(readingSearchProvider);
    unawaited(search.searchInBook(value, includeAll: _searchShowingAll));
  }

  void _showAllSearchResults() {
    setState(() => _searchShowingAll = true);
    final search = riverpod.ProviderScope.containerOf(
      context,
      listen: false,
    ).read(readingSearchProvider);
    unawaited(search.searchAllInBook());
  }

  Future<void> _onSearchResultTap(ReadingSearchResult result) async {
    final search = riverpod.ProviderScope.containerOf(
      context,
      listen: false,
    ).read(readingSearchProvider);
    await search.goToSearchResult(result);
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

  void _onBookmarkTap() {
    final bookmarks = riverpod.ProviderScope.containerOf(
      context,
      listen: false,
    ).read(bookmarkProvider);
    if (bookmarks.isCurrentPositionBookmarked()) {
      _hideReadingReminder();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const BookmarkSheet(),
      );
    } else {
      bookmarks.addReadingBookmark();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已添加书签'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _showBookmarkHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BookmarkSheet(),
    );
  }

  void _toggleSidebar() {
    final closingWordSidebar =
        _sidebarOpen && _sidebarMode == _ReaderSidebarMode.word;
    if (closingWordSidebar) {
      ref.read(wordLookupProvider).clearWordLookup();
    }
    setState(() {
      if (!_sidebarOpen && _sidebarSelectedText.isEmpty) {
        _sidebarMode = _ReaderSidebarMode.word;
      }
      _sidebarOpen = !_sidebarOpen;
    });
  }

  Color _readerBackgroundColor(ReadingConfigController config) {
    switch (config.readingTheme) {
      case 'sepia':
        return const Color(0xFFF5ECD7);
      case 'dark':
        return const Color(0xFF1E1E1E);
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CurrentBookController>(currentBookProvider, (_, currentBook) {
      _onReaderStateChanged(currentBook, ref.read(readingTimeProvider));
    });
    final currentBook = ref.watch(currentBookProvider);
    final config = ref.watch(readingConfigProvider);
    final readingTime = ref.watch(readingTimeProvider);
    final settings = ref.watch(settingsProvider);
    if (_lastReaderLocationKey == null) {
      _primeReaderState(currentBook, readingTime);
    }
    final result = currentBook.result;
    if (result == null) {
      return _buildKeyboardScope(
        _buildPageScaffold(
          config: config,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final blocks = currentBook.hasBook && currentBook.chapterCount > 0
        ? currentBook.book!.chapters[currentBook.currentChapter].blocks
        : const <ContentBlock>[];
    final paragraphs = blocks.isEmpty
        ? _paragraphsFor(result, currentBook)
        : const <String>[];
    final theme = Theme.of(context);
    final chapterTitle = currentBook.hasBook && currentBook.chapterCount > 0
        ? currentBook.book!.chapters[currentBook.currentChapter].title
        : result.title;
    final colorSettings = settings.colors;
    final search = ref.watch(readingSearchProvider);
    final lookup = ref.watch(wordLookupProvider);
    final bookmarks = ref.watch(bookmarkProvider);

    return _buildKeyboardScope(
      LayoutBuilder(
        builder: (context, constraints) {
          _layoutWidth = constraints.maxWidth;
          final isWide = _isWideScreen;

          Widget buildContent() {
            return ReaderContentView(
              paragraphs: paragraphs,
              blocks: blocks,
              result: result,
              theme: theme,
              colorSettings: colorSettings,
              aiFeaturesEnabled: settings.aiFeaturesEnabled,
              currentBook: currentBook,
              config: config,
              search: search,
              lookup: lookup,
              scrollController: _scrollController,
              isWideScreen: isWide,
              sidebarOpen: _sidebarOpen,
              isSearchPanelVisible: _isSearchPanelVisible,
              contentKeyFor: _contentKeyFor,
              onVisibleContentCountChanged: _setVisibleContentCount,
              onWordTapped: _onWordTapped,
              onAnalyzeSelected: _onAnalyzeSelected,
            );
          }

          return _buildPageScaffold(
            config: config,
            child: Column(
              children: [
                ReaderNavBar(
                  currentBook: currentBook,
                  config: config,
                  bookmarks: bookmarks,
                  chapterTitle: chapterTitle,
                  layoutWidth: _layoutWidth,
                  displayProgressListenable: _displayProgressNotifier,
                  showSidebarToggle: isWide,
                  sidebarOpen: _sidebarOpen,
                  tocMenuOpen: _tocMenuOpen,
                  tocMenuController: _tocMenuController,
                  fontSettingsMenuController: _fontSettingsMenuController,
                  onSidebarToggle: _toggleSidebar,
                  onShowTocSheet: _showTocSheet,
                  onTocMenuToggle: _toggleTocMenu,
                  onTocMenuOpenChanged: _setTocMenuOpen,
                  onShowFontSettingsSheet: _showFontSettingsSheet,
                  onFontSettingsMenuToggle: _toggleFontSettingsMenu,
                  onFontSettingsMenuOpenChanged: _setFontSettingsMenuOpen,
                  onSearchTap: () => unawaited(_showSearchSheet()),
                  onBookmarkTap: _onBookmarkTap,
                  onBookmarkHistoryTap: _showBookmarkHistory,
                ),
                _buildReadingProgressLine(theme, _displayProgressNotifier),
                _buildReadingReminder(theme),
                Expanded(
                  child: _buildReadingBodyOverlay(
                    theme: theme,
                    showOverlay:
                        isWide && (_tocMenuOpen || _fontSettingsMenuOpen),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: buildContent()),
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
                        : buildContent(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageScaffold({
    required ReadingConfigController config,
    required Widget child,
  }) {
    return ColoredBox(color: _readerBackgroundColor(config), child: child);
  }

  Widget _buildReadingProgressLine(
    ThemeData theme,
    ValueListenable<double> progressListenable,
  ) {
    return ValueListenableBuilder<double>(
      valueListenable: progressListenable,
      builder: (context, progress, _) {
        return LinearProgressIndicator(
          value: progress,
          minHeight: 2,
          backgroundColor: theme.colorScheme.outlineVariant.withValues(
            alpha: 0.2,
          ),
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        );
      },
    );
  }

  Widget _buildReadingBodyOverlay({
    required ThemeData theme,
    required bool showOverlay,
    required Widget child,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !showOverlay,
            child: AnimatedOpacity(
              opacity: showOverlay ? 1 : 0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_tocMenuOpen) {
                    _tocMenuController.close();
                  }
                  if (_fontSettingsMenuOpen) {
                    _fontSettingsMenuController.close();
                  }
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReaderSidebar() {
    return switch (_sidebarMode) {
      _ReaderSidebarMode.word => ReaderWordSidebar(
        onClose: () {
          ref.read(wordLookupProvider).clearWordLookup();
          setState(() => _sidebarOpen = false);
        },
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

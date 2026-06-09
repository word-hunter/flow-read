import 'dart:async';

import 'package:flow_read_atmosphere/flow_read_atmosphere.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import 'package:flow_ai/flow_ai.dart';
import '../models/analysis_result.dart';
import '../models/content_block.dart';
import '../models/reading_position.dart';
import '../models/reading_search_result.dart';
import '../providers/reading/bookmark_notifier.dart';
import '../providers/reading/bookshelf_notifier.dart';
import '../providers/reading/current_book_notifier.dart';
import '../providers/reading/reading_config_notifier.dart';
import '../providers/reading/reading_search_notifier.dart';
import '../providers/reading/reading_time_notifier.dart';
import '../providers/reading/services_provider.dart';
import '../providers/reading/vocabulary_notifier.dart';
import '../providers/reading/word_lookup_notifier.dart';
import '../providers/settings_provider.dart';
import '../layout/app_platform_class.dart';
import '../layout/reader_layout_policy.dart';
import '../services/reader_layout_engine.dart';
import '../theme/app_constants.dart';
import '../widgets/ai_assistant_panel.dart';
import '../widgets/bookmark_sheet.dart';
import '../widgets/font_settings_sheet.dart';
import '../widgets/reader/reader_nav_bar.dart';
import '../widgets/reader/reader_search_panel.dart';
import '../widgets/reader/reader_word_sidebar.dart';
import '../widgets/reader_shell/desktop_reader_workspace_shell.dart';
import '../widgets/reader_shell/reader_core_view.dart';
import '../widgets/reader_shell/reader_workspace_controller.dart';
import '../widgets/reader_text_view.dart';
import '../widgets/selected_text_action_toolbar.dart'
    show SelectedTextActionRegionState;
import '../widgets/selected_text_sheet.dart';
import '../widgets/toc_bottom_sheet.dart';
import '../widgets/word_bottom_sheet.dart';

part 'reader_daily_goal_mixin.dart';
part 'reader_keyboard_mixin.dart';
part 'reader_viewport_mixin.dart';

enum _ReaderSidebarMode { word, textAnalysis, assistant }

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
  final GlobalKey<SelectionAreaState> _readerSelectionAreaKey =
      GlobalKey<SelectionAreaState>();
  final GlobalKey<SelectedTextActionRegionState> _actionRegionKey =
      GlobalKey<SelectedTextActionRegionState>();
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

  late final ReaderWorkspaceController _workspaceController =
      ReaderWorkspaceController();

  String _sidebarSelectedText = '';
  final String _sidebarAnalyzerName = 'AI';
  _ReaderSidebarMode _sidebarMode = _ReaderSidebarMode.word;
  bool _sidebarOpen = false;
  @override
  bool _searchSheetOpen = false;
  bool _tocMenuOpen = false;
  bool _fontSettingsMenuOpen = false;
  bool _searchShowingAll = false;
  double _layoutWidth = 0;

  bool get _isWideScreen => _layoutWidth >= AppConstants.wideBreakpoint;
  bool get _isWorkspaceEnabled {
    final settings = ref.read(settingsProvider);
    return settings.desktopReaderWorkspaceEnabled;
  }
  bool get _isSearchPanelVisible => _searchSheetOpen;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _disposeViewportTracking();
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
    String surface,
    String canonical,
    String languageId,
    String contextText, {
    int? contextWordStart,
    int? contextWordEnd,
  }) {
    _flushPendingScrollProgress();
    _hideReadingReminder();
    final lookupNotifier = ref.read(wordLookupNotifierProvider.notifier);
    lookupNotifier.lookupWord(
      surface,
      canonicalForm: canonical,
      languageCode: languageId,
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
    } else if (_isWorkspaceEnabled) {
      _workspaceController.openRightPanel(ReaderRightPanelTab.dictionary);
      setState(() {
        _sidebarMode = _ReaderSidebarMode.word;
      });
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => WordBottomSheet(word: surface),
      ).whenComplete(() {
        lookupNotifier.clearWordLookup();
        final assistant = ref.read(aiAssistantControllerProvider);
        if (!assistant.isEmpty) {
          _openAssistantPanel(assistant);
        }
      });
    }
  }

  void _onAnalyzeSelected(String text) {
    final settings = ref.read(settingsProvider);
    if (!settings.aiFeaturesEnabled) return;
    final selectedText = text.trim();
    if (selectedText.isEmpty) return;

    final assistant = ref.read(aiAssistantControllerProvider);
    final currentBookNotifier = ref.read(currentBookNotifierProvider);
    final bookshelfNotifier = ref.read(bookshelfNotifierProvider);
    final book = bookshelfNotifier.book;

    assistant.setContext(
      AIContextSnapshot(
        source: AIContextSource.readerSelectedText,
        selectedText: selectedText,
        surroundingPassage: _extractPassage(selectedText),
        bookId: bookshelfNotifier.activeBookId,
        chapterIndex: currentBookNotifier.currentChapter,
        chapterTitle: book?.chapters.isNotEmpty == true
            ? book!.chapters[currentBookNotifier.currentChapter].title
            : null,
      ),
    );

    if (_isWideScreen) {
      ref.read(wordLookupNotifierProvider.notifier).clearWordLookup();
      setState(() {
        _sidebarMode = _ReaderSidebarMode.assistant;
        _sidebarSelectedText = selectedText;
        _sidebarOpen = true;
      });
      return;
    }

    if (_isWorkspaceEnabled) {
      ref.read(wordLookupNotifierProvider.notifier).clearWordLookup();
      _workspaceController.openRightPanel(ReaderRightPanelTab.ai);
      setState(() {
        _sidebarMode = _ReaderSidebarMode.assistant;
        _sidebarSelectedText = selectedText;
      });
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => AIAssistantPanel(
          controller: assistant,
        ),
      ),
    );
  }

  void _openAssistantPanel(AIAssistantController assistant) {
    if (_isWideScreen) {
      setState(() {
        _sidebarMode = _ReaderSidebarMode.assistant;
        _sidebarOpen = true;
      });
      return;
    }
    if (_isWorkspaceEnabled) {
      _workspaceController.openRightPanel(ReaderRightPanelTab.ai);
      setState(() {
        _sidebarMode = _ReaderSidebarMode.assistant;
      });
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => AIAssistantPanel(
          controller: assistant,
        ),
      ),
    );
  }

  void _exitReader() {
    _flushPendingScrollProgress();
    ref.read(currentBookNotifierProvider.notifier).exitReader();
  }

  @override
  void _goToChapter(int index) {
    _flushPendingScrollProgress();
    unawaited(
      ref.read(currentBookNotifierProvider.notifier).goToChapter(index),
    );
  }

  String _extractPassage(String selectedText) {
    final book = ref.read(bookshelfNotifierProvider).book;
    if (book == null) return selectedText;
    final current = ref.read(currentBookNotifierProvider);
    final chapter = current.currentChapter < book.chapters.length
        ? book.chapters[current.currentChapter]
        : null;
    final passage = chapter?.plainText ?? '';
    if (passage.isEmpty) return selectedText;
    final index = passage.indexOf(selectedText);
    if (index < 0) return selectedText;
    final start = index - 120 > 0 ? index - 120 : 0;
    final end = index + selectedText.length + 120 < passage.length
        ? index + selectedText.length + 120
        : passage.length;
    return passage.substring(start, end);
  }

  void _showTocSheet() {
    final currentBookNotifier = ref.read(currentBookNotifierProvider.notifier);
    if (!currentBookNotifier.hasBook) return;
    _hideReadingReminder();

    final settings = ref.read(settingsProvider);
    final platform = AppPlatformClassPolicy.current;
    final widthClass = _layoutWidth;
    final layout = ReaderLayoutPolicy.resolveLayout(
      platform: platform,
      width: widthClass,
      workspaceFeatureEnabled: settings.desktopReaderWorkspaceEnabled,
      userRequestedImmersive: false,
    );

    if (layout.isWorkspace) {
      _workspaceController.openToc();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TocBottomSheet(onGoToChapter: _goToChapter),
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
    final search = ref.read(readingSearchNotifierProvider.notifier);
    search.clearSearch();
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
    final search = ref.read(readingSearchNotifierProvider.notifier);
    unawaited(search.searchInBook(value, includeAll: _searchShowingAll));
  }

  void _showAllSearchResults() {
    setState(() => _searchShowingAll = true);
    final search = ref.read(readingSearchNotifierProvider.notifier);
    unawaited(search.searchAllInBook());
  }

  Future<void> _onSearchResultTap(ReadingSearchResult result) async {
    _flushPendingScrollProgress();
    final search = ref.read(readingSearchNotifierProvider.notifier);
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
    _flushPendingScrollProgress();
    final bookmarks = ref.read(bookmarkNotifierProvider.notifier);
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
      ref.read(wordLookupNotifierProvider.notifier).clearWordLookup();
    }
    setState(() {
      if (!_sidebarOpen && _sidebarSelectedText.isEmpty) {
        _sidebarMode = _ReaderSidebarMode.word;
      }
      _sidebarOpen = !_sidebarOpen;
    });
  }

  Color _readerBackgroundColor(
    BuildContext context,
    ReadingConfigState config,
  ) {
    final cityPreset = CityThemeScope.maybeOf(context)?.preset;
    if (cityPreset != null) {
      return cityPreset.pageBackground.withValues(alpha: 0.92);
    }

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
    ref.listen(currentBookNotifierProvider, (_, currentBookState) {
      _onReaderStateChanged(
        currentBookState,
        ref.read(readingTimeNotifierProvider),
      );
    });
    final currentBookState = ref.watch(currentBookNotifierProvider);
    final currentBookNotifier = ref.read(currentBookNotifierProvider.notifier);

    final config = ref.watch(readingConfigNotifierProvider);
    final readingTime = ref.watch(readingTimeNotifierProvider);
    final settings = ref.watch(settingsProvider);

    final layoutConfig = PageLayoutConfig(
      fontSize: config.fontSize,
      fontFamily: config.fontFamily,
      lineHeight: config.lineHeight,
      viewportWidth: _layoutWidth > 0
          ? _layoutWidth
          : MediaQuery.sizeOf(context).width,
      viewportHeight: MediaQuery.sizeOf(context).height,
    );
    final didReflow = _needsReflow(layoutConfig);
    if (didReflow && _scrollController.hasClients) {
      final activeBookId = ref.read(bookshelfNotifierProvider).activeBookId;
      final book = ref.read(bookshelfNotifierProvider).book;
      if (book != null && activeBookId != null) {
        _captureAnchorForReflow(
          chapterIndex: currentBookState.currentChapter,
          blocks: book.chapters[currentBookState.currentChapter].blocks,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) return;
          final currentChapters = ref
              .read(bookshelfNotifierProvider)
              .book
              ?.chapters;
          if (currentChapters == null) return;
          final chapter = currentBookState.currentChapter;
          if (chapter >= currentChapters.length) return;
          _applyReflowAnchor(
            chapterIndex: chapter,
            blocks: currentChapters[chapter].blocks,
          );
          if (_pendingScrollOffset != null) {
            _isRestoringViewport = true;
            _scheduleViewportSyncPass();
          }
        });
      }
    }

    if (_lastReaderLocationKey == null) {
      _primeReaderState(currentBookState, currentBookNotifier, readingTime);
    }
    final result = currentBookNotifier.result;
    if (result == null) {
      return _buildKeyboardScope(
        _buildPageScaffold(
          config: config,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final blocks =
        currentBookNotifier.hasBook && currentBookNotifier.chapterCount > 0
        ? currentBookNotifier
              .book!
              .chapters[currentBookState.currentChapter]
              .blocks
        : const <ContentBlock>[];
    final paragraphs = blocks.isEmpty
        ? _paragraphsFor(result, currentBookState, currentBookNotifier)
        : const <String>[];
    final theme = Theme.of(context);
    final chapterTitle =
        currentBookNotifier.hasBook && currentBookNotifier.chapterCount > 0
        ? currentBookNotifier
              .book!
              .chapters[currentBookState.currentChapter]
              .title
        : result.title;
    final colorSettings = settings.colors;
    final search = ref.watch(readingSearchNotifierProvider);
    final lookupState = ref.watch(wordLookupNotifierProvider);
    ref.watch(bookmarkNotifierProvider);
    final bookmarkNotifier = ref.read(bookmarkNotifierProvider.notifier);

    return _buildKeyboardScope(
      LayoutBuilder(
        builder: (context, constraints) {
          _layoutWidth = constraints.maxWidth;
          final isWide = _isWideScreen;

          final platform = AppPlatformClassPolicy.current;
          final layoutSpec = ReaderLayoutPolicy.resolveLayout(
            platform: platform,
            width: constraints.maxWidth,
            workspaceFeatureEnabled:
                settings.desktopReaderWorkspaceEnabled,
            userRequestedImmersive: false,
          );
          final useWorkspace = layoutSpec.isWorkspace;

          Widget buildContent() {
            return ReaderCoreView(
              paragraphs: paragraphs,
              blocks: blocks,
              result: result,
              theme: theme,
              colorSettings: colorSettings,
              aiFeaturesEnabled: settings.aiFeaturesEnabled,
              currentBook: currentBookNotifier,
              config: config,
              search: search,
              lookupState: lookupState,
              wordLevelService: ref.read(wordLevelServiceProvider),
              activeLanguageModule: ref
                  .read(vocabularyNotifierProvider.notifier)
                  .activeLanguageModule,
              readerSelectionAreaKey: _readerSelectionAreaKey,
              actionRegionKey: _actionRegionKey,
              scrollController: _scrollController,
              isWideScreen: isWide || useWorkspace,
              sidebarOpen:
                  useWorkspace ? _workspaceController.isRightPanelOpen : _sidebarOpen,
              isSearchPanelVisible: _isSearchPanelVisible,
              progressListenable: _displayProgressNotifier,
              contentKeyFor: _contentKeyFor,
              onVisibleContentCountChanged: _setVisibleContentCount,
              onWordTapped: _onWordTapped,
              onAnalyzeSelected: _onAnalyzeSelected,
            );
          }

          Widget buildToolbar() {
            return ReaderNavBar(
              currentBook: currentBookNotifier,
              currentBookState: currentBookState,
              config: config,
              bookmarks: bookmarkNotifier,
              chapterTitle: chapterTitle,
              layoutWidth: _layoutWidth,
              displayProgressListenable: _displayProgressNotifier,
              showSidebarToggle: useWorkspace || isWide,
              sidebarOpen: useWorkspace
                  ? _workspaceController.isLeftPanelOpen
                  : _sidebarOpen,
              tocMenuOpen: _tocMenuOpen,
              tocMenuController: _tocMenuController,
              fontSettingsMenuController: _fontSettingsMenuController,
              onSidebarToggle: useWorkspace
                  ? _workspaceController.toggleLeftPanel
                  : _toggleSidebar,
              onShowTocSheet: _showTocSheet,
              onTocMenuToggle: _toggleTocMenu,
              onTocMenuOpenChanged: _setTocMenuOpen,
              onShowFontSettingsSheet: _showFontSettingsSheet,
              onFontSettingsMenuToggle: _toggleFontSettingsMenu,
              onFontSettingsMenuOpenChanged: _setFontSettingsMenuOpen,
              onExitReader: _exitReader,
              onGoToChapter: _goToChapter,
              onSearchTap: () => unawaited(_showSearchSheet()),
              onBookmarkTap: _onBookmarkTap,
              onBookmarkHistoryTap: _showBookmarkHistory,
            );
          }

          if (useWorkspace) {
            return _buildPageScaffold(
              config: config,
              child: DesktopReaderWorkspaceShell(
                workspaceController: _workspaceController,
                toolbar: buildToolbar(),
                centerContent: buildContent(),
                rightPanel: _workspaceController.isRightPanelOpen
                    ? _buildReaderSidebar()
                    : const SizedBox.shrink(),
                readingProgressLine: _buildReadingProgressLine(
                    theme, _displayProgressNotifier),
                readingReminder: _buildReadingReminder(theme),
                onGoToChapter: _goToChapter,
              ),
            );
          }

          return _buildPageScaffold(
            config: config,
            child: Column(
              children: [
                buildToolbar(),
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
    required ReadingConfigState config,
    required Widget child,
  }) {
    return ColoredBox(
      color: _readerBackgroundColor(context, config),
      child: child,
    );
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
          ref.read(wordLookupNotifierProvider.notifier).clearWordLookup();
          setState(() => _sidebarOpen = false);
        },
        onOpenAssistant: () {
          setState(() => _sidebarMode = _ReaderSidebarMode.assistant);
        },
      ),
      _ReaderSidebarMode.textAnalysis => SelectedTextSheet(
        selectedText: _sidebarSelectedText,
        analysis: null,
        analyzerName: _sidebarAnalyzerName,
        embedded: true,
        onClose: () => setState(() => _sidebarOpen = false),
      ),
      _ReaderSidebarMode.assistant => AIAssistantPanel(
        controller: ref.read(aiAssistantControllerProvider),
        embedded: true,
        onClose: () => setState(() => _sidebarOpen = false),
      ),
    };
  }
}

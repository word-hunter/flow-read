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
import '../layout/reader_layout_spec.dart';
import '../services/reader_layout_engine.dart';
import '../theme/app_constants.dart';
import '../theme/app_motion_tokens.dart';
import '../theme/app_surface_tokens.dart';
import '../widgets/ai_assistant_panel.dart';
import '../widgets/bookmark_sheet.dart';
import '../widgets/flow/flow_components.dart';
import '../widgets/font_settings_sheet.dart';
import '../widgets/reader/reader_nav_bar.dart';
import '../widgets/reader/reader_learning_stats_panel.dart';
import '../widgets/reader/reader_search_panel.dart';
import '../widgets/reader/reader_vocabulary_panel.dart';
import '../widgets/reader/reader_word_sidebar.dart';
import '../widgets/reader_shell/desktop_reader_workspace_shell.dart';
import '../widgets/reader_shell/reader_core_view.dart';
import '../widgets/reader_shell/reader_right_assistant_panel.dart';
import '../widgets/reader_shell/reader_workspace_controller.dart';
import '../widgets/reader_text_view.dart';
import '../widgets/surfaces/app_surface.dart';
import '../widgets/selected_text_action_toolbar.dart'
    show SelectedTextActionRegionState;
import '../widgets/toc_bottom_sheet.dart';
import '../widgets/word_bottom_sheet.dart';

part 'reader_daily_goal_mixin.dart';
part 'reader_keyboard_mixin.dart';
part 'reader_viewport_mixin.dart';

enum _ReaderSidebarMode { word, assistant }

class ReaderPage extends riverpod.ConsumerStatefulWidget {
  const ReaderPage({super.key});

  @override
  riverpod.ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends riverpod.ConsumerState<ReaderPage>
    with ReaderDailyGoalMixin, ReaderViewportMixin, ReaderKeyboardMixin {
  static const bool _workspaceFeatureEnabled = true;
  static const List<Duration> _selectedTextVisibilityCheckDelays = [
    Duration.zero,
    Duration(milliseconds: 80),
    ReaderMotionTokens.panelOpenDuration,
    Duration(milliseconds: 320),
  ];
  static const double _selectedTextVisibilityTopMargin = 72;
  static const double _selectedTextVisibilityBottomMargin = 96;

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
  final Set<Timer> _selectedTextVisibilityTimers = {};
  @override
  final Map<int, GlobalKey> _contentKeys = {};
  @override
  final ValueNotifier<double> _displayProgressNotifier = ValueNotifier<double>(
    0.0,
  );

  @override
  late final ReaderWorkspaceController _workspaceController =
      ReaderWorkspaceController();

  _ReaderSidebarMode _sidebarMode = _ReaderSidebarMode.word;
  bool _sidebarOpen = false;
  @override
  bool _searchSheetOpen = false;
  bool _tocMenuOpen = false;
  bool _fontSettingsMenuOpen = false;
  bool _searchShowingAll = false;
  double _layoutWidth = 0;

  bool get _isWideScreen => _layoutWidth >= AppConstants.wideBreakpoint;
  @override
  bool get _isWorkspaceEnabled => _currentLayoutSpec.isWorkspace;
  ReaderLayoutSpec get _currentLayoutSpec => _resolveLayout(_layoutWidth);
  ReaderActionPanelHost get _actionPanelHost => ReaderActionPanelPolicy.resolve(
    layoutSpec: _currentLayoutSpec,
    isWideScreen: _isWideScreen,
  );
  bool get _isSearchPanelVisible => _searchSheetOpen;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _workspaceController.addListener(_onWorkspaceControllerChanged);
  }

  @override
  void dispose() {
    _clearSelectedTextVisibilityTimers();
    _disposeViewportTracking();
    _disposeDailyGoalWatcher();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _workspaceController.removeListener(_onWorkspaceControllerChanged);
    _workspaceController.dispose();
    _displayProgressNotifier.dispose();
    _readerFocusNode.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  ReaderLayoutSpec _resolveLayout(double width) {
    return ReaderLayoutPolicy.resolveLayout(
      platform: AppPlatformClassPolicy.current,
      width: width,
      workspaceFeatureEnabled: _workspaceFeatureEnabled,
      userRequestedImmersive: false,
    );
  }

  void _onWorkspaceControllerChanged() {
    if (!mounted) return;
    setState(() {});
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
    switch (_actionPanelHost) {
      case ReaderActionPanelHost.workspaceRightPanel:
        _workspaceController.openRightPanel(ReaderRightPanelTab.dictionary);
        setState(() {
          _sidebarMode = _ReaderSidebarMode.word;
        });
      case ReaderActionPanelHost.wideSidebar:
        setState(() {
          _sidebarMode = _ReaderSidebarMode.word;
          _sidebarOpen = true;
        });
      case ReaderActionPanelHost.bottomSheet:
        showFlowSheet(
          context: context,
          isScrollControlled: true,
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

    ref.read(wordLookupNotifierProvider.notifier).clearWordLookup();
    switch (_actionPanelHost) {
      case ReaderActionPanelHost.workspaceRightPanel:
        _workspaceController.openRightPanel(ReaderRightPanelTab.ai);
        setState(() {
          _sidebarMode = _ReaderSidebarMode.assistant;
        });
      case ReaderActionPanelHost.wideSidebar:
        setState(() {
          _sidebarMode = _ReaderSidebarMode.assistant;
          _sidebarOpen = true;
        });
      case ReaderActionPanelHost.bottomSheet:
        showFlowSheet(
          context: context,
          isScrollControlled: true,
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

    if (_actionPanelHost != ReaderActionPanelHost.bottomSheet) {
      _ensureSelectedTextVisibleAfterPanelOpen(selectedText);
    }
    _executeDefaultAssistantAction(
      assistant,
      preferred: AIAssistantActionType.explain,
    );
  }

  void _ensureSelectedTextVisibleAfterPanelOpen(String selectedText) {
    _clearSelectedTextVisibilityTimers();
    for (final delay in _selectedTextVisibilityCheckDelays) {
      _scheduleSelectedTextVisibilityCheck(selectedText, delay);
    }
  }

  void _scheduleSelectedTextVisibilityCheck(
    String selectedText,
    Duration delay,
  ) {
    void checkAfterLayout() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _ensureSelectedTextVisible(selectedText);
      });
    }

    if (delay == Duration.zero) {
      checkAfterLayout();
      return;
    }

    late final Timer timer;
    timer = Timer(delay, () {
      _selectedTextVisibilityTimers.remove(timer);
      if (!mounted) return;
      checkAfterLayout();
    });
    _selectedTextVisibilityTimers.add(timer);
  }

  void _clearSelectedTextVisibilityTimers() {
    for (final timer in _selectedTextVisibilityTimers) {
      timer.cancel();
    }
    _selectedTextVisibilityTimers.clear();
  }

  void _ensureSelectedTextVisible(String selectedText) {
    if (!_scrollController.hasClients) return;
    if (_ensureCurrentSelectionAnchorVisible()) return;
    _ensureSelectedTextContentVisible(selectedText);
  }

  bool _ensureCurrentSelectionAnchorVisible() {
    final anchors = _actionRegionKey.currentState?.currentSelectionAnchors;
    if (anchors == null) return false;
    final viewport = _scrollableViewportRect();
    if (viewport == null) return false;

    final primaryY = anchors.primaryAnchor.dy;
    final secondaryY = anchors.secondaryAnchor?.dy ?? primaryY;
    if (!primaryY.isFinite || !secondaryY.isFinite) return false;

    final selectionTop = primaryY < secondaryY ? primaryY : secondaryY;
    final selectionBottom = primaryY > secondaryY ? primaryY : secondaryY;
    final topLimit = viewport.top + _selectedTextVisibilityTopMargin;
    final bottomLimit = viewport.bottom - _selectedTextVisibilityBottomMargin;

    final delta = selectionTop < topLimit
        ? selectionTop - topLimit
        : selectionBottom > bottomLimit
        ? selectionBottom - bottomLimit
        : 0.0;
    if (delta.abs() < 1) return true;

    _animateReaderScrollBy(
      delta,
      duration: const Duration(milliseconds: 180),
    );
    return true;
  }

  Rect? _scrollableViewportRect() {
    if (!_scrollController.hasClients) return null;
    final viewportContext =
        _scrollController.position.context.notificationContext;
    final renderObject = viewportContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  void _animateReaderScrollBy(double delta, {required Duration duration}) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = (position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if ((target - position.pixels).abs() < 1) return;

    unawaited(
      _scrollController.animateTo(
        target,
        duration: duration,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  bool _ensureSelectedTextContentVisible(String selectedText) {
    final index = _selectedTextContentIndex(selectedText);
    if (index == null) return false;
    final contextForItem = _contentKeys[index]?.currentContext;
    if (contextForItem == null || !contextForItem.mounted) return false;

    Scrollable.ensureVisible(
      contextForItem,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: 0.35,
    );
    return true;
  }

  int? _selectedTextContentIndex(String selectedText) {
    final query = selectedText.trim();
    if (query.isEmpty) return null;

    final currentBookState = ref.read(currentBookNotifierProvider);
    final currentBookNotifier = ref.read(currentBookNotifierProvider.notifier);
    final book = ref.read(bookshelfNotifierProvider).book;
    final currentChapter = currentBookState.currentChapter;
    if (book != null && currentChapter < book.chapters.length) {
      final blocks = book.chapters[currentChapter].blocks;
      for (var i = 0; i < blocks.length; i += 1) {
        final block = blocks[i];
        if (block is TextBlock &&
            _containsSelectedText(block.plainText, query)) {
          return i;
        }
      }
    }

    final result = currentBookNotifier.result;
    if (result == null) return null;
    final paragraphs = _paragraphsFor(
      result,
      currentBookState,
      currentBookNotifier,
    );
    for (var i = 0; i < paragraphs.length; i += 1) {
      if (_containsSelectedText(paragraphs[i], query)) return i;
    }
    return null;
  }

  bool _containsSelectedText(String source, String selectedText) {
    if (source.contains(selectedText)) return true;
    final normalizedSource = source.replaceAll(RegExp(r'\s+'), ' ').trim();
    final normalizedSelection = selectedText
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return normalizedSelection.isNotEmpty &&
        normalizedSource.contains(normalizedSelection);
  }

  void _openAssistantPanel(
    AIAssistantController assistant, {
    bool executeDefaultAction = false,
  }) {
    switch (_actionPanelHost) {
      case ReaderActionPanelHost.workspaceRightPanel:
        _workspaceController.openRightPanel(ReaderRightPanelTab.ai);
        setState(() {
          _sidebarMode = _ReaderSidebarMode.assistant;
        });
      case ReaderActionPanelHost.wideSidebar:
        setState(() {
          _sidebarMode = _ReaderSidebarMode.assistant;
          _sidebarOpen = true;
        });
      case ReaderActionPanelHost.bottomSheet:
        showFlowSheet(
          context: context,
          isScrollControlled: true,
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
    if (executeDefaultAction) {
      _executeDefaultAssistantAction(assistant);
    }
  }

  @override
  void _openAssistantFromCurrentContext() {
    if (_openAssistantFromCurrentWord()) return;
    _openAssistantPanel(ref.read(aiAssistantControllerProvider));
  }

  void _openChapterAIPanel() {
    final settings = ref.read(settingsProvider);
    if (!settings.aiFeaturesEnabled) return;

    final currentBookNotifier = ref.read(currentBookNotifierProvider);
    final bookshelfNotifier = ref.read(bookshelfNotifierProvider);
    final book = bookshelfNotifier.book;
    final chapterIndex = currentBookNotifier.currentChapter;
    final currentResult = currentBookNotifier.result;
    final chapterContent = currentResult?.passageText ?? '';
    if (chapterContent.isEmpty) return;

    final chapterTitle = book != null && chapterIndex < book.chapters.length
        ? book.chapters[chapterIndex].title
        : 'Chapter ${chapterIndex + 1}';

    final assistant = ref.read(aiAssistantControllerProvider);
    assistant.setContext(
      AIContextSnapshot(
        source: AIContextSource.readerChapter,
        bookId: bookshelfNotifier.activeBookId,
        chapterIndex: chapterIndex,
        chapterTitle: chapterTitle,
        chapterContent: chapterContent,
      ),
    );

    _openAssistantPanel(assistant);
  }

  bool _openAssistantFromCurrentWord() {
    final settings = ref.read(settingsProvider);
    if (!settings.aiFeaturesEnabled) return false;
    final lookupState = ref.read(wordLookupNotifierProvider);
    final word = lookupState.selectedWord?.trim();
    if (word == null || word.isEmpty) return false;

    final assistant = ref.read(aiAssistantControllerProvider);
    assistant.setContext(_wordAssistantContext(lookupState, word));
    _openAssistantPanel(
      assistant,
      executeDefaultAction: false,
    );
    _executeDefaultAssistantAction(
      assistant,
      preferred: AIAssistantActionType.wordAnalysis,
    );
    return true;
  }

  AIContextSnapshot _wordAssistantContext(
    WordLookupState lookupState,
    String word,
  ) {
    final currentBookState = ref.read(currentBookNotifierProvider);
    final bookshelf = ref.read(bookshelfNotifierProvider);
    final book = bookshelf.book;
    final chapterIndex = currentBookState.currentChapter;
    final chapterTitle = book != null && chapterIndex < book.chapters.length
        ? book.chapters[chapterIndex].title
        : null;

    return AIContextSnapshot(
      source: AIContextSource.readerWord,
      word: word,
      wordSentence: _wordAnalysisContext(lookupState, word),
      bookId: bookshelf.activeBookId,
      chapterIndex: chapterIndex,
      chapterTitle: chapterTitle,
    );
  }

  String _wordAnalysisContext(WordLookupState lookupState, String word) {
    final contextText = lookupState.selectedWordContext?.trim();
    if (contextText != null && contextText.isNotEmpty) return contextText;
    final definitions = lookupState.selectedWordEntry?.meanings
        .expand((meaning) => meaning.definitions)
        .map((definition) => definition.trim())
        .where((definition) => definition.isNotEmpty);
    if (definitions != null && definitions.isNotEmpty) {
      return definitions.first;
    }
    return lookupState.selectedWordTranslation?.trim().isNotEmpty == true
        ? lookupState.selectedWordTranslation!.trim()
        : word;
  }

  void _executeDefaultAssistantAction(
    AIAssistantController assistant, {
    AIAssistantActionType? preferred,
  }) {
    final actions = assistant.availableActions;
    if (actions.isEmpty) return;

    final action = preferred != null && actions.contains(preferred)
        ? preferred
        : actions.contains(AIAssistantActionType.explain)
        ? AIAssistantActionType.explain
        : actions.first;
    unawaited(assistant.executeAction(action));
  }

  void _exitReader() {
    _flushPendingScrollProgress();
    unawaited(ref.read(currentBookNotifierProvider.notifier).exitReader());
  }

  void _openVocabularyPanel() {
    _hideReadingReminder();
    ref.read(wordLookupNotifierProvider.notifier).clearWordLookup();
    switch (_actionPanelHost) {
      case ReaderActionPanelHost.workspaceRightPanel:
        _workspaceController.openRightPanel(ReaderRightPanelTab.dictionary);
        setState(() {
          _sidebarMode = _ReaderSidebarMode.word;
        });
      case ReaderActionPanelHost.wideSidebar:
        setState(() {
          _sidebarMode = _ReaderSidebarMode.word;
          _sidebarOpen = true;
        });
      case ReaderActionPanelHost.bottomSheet:
        showFlowSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => DraggableScrollableSheet(
            initialChildSize: 0.78,
            minChildSize: 0.4,
            maxChildSize: 0.94,
            expand: false,
            builder: (_, _) => ReaderVocabularyPanel(
              onVocabularySelected: _openVocabularyLookup,
            ),
          ),
        );
    }
  }

  void _openVocabularyLookup(Vocabulary vocabulary) {
    _hideReadingReminder();
    unawaited(
      ref
          .read(wordLookupNotifierProvider.notifier)
          .lookupWord(
            vocabulary.word,
            contextText: vocabulary.context,
            trackReadingLookup: true,
          ),
    );
    switch (_actionPanelHost) {
      case ReaderActionPanelHost.workspaceRightPanel:
        _workspaceController.openRightPanel(ReaderRightPanelTab.dictionary);
        setState(() {
          _sidebarMode = _ReaderSidebarMode.word;
        });
      case ReaderActionPanelHost.wideSidebar:
        setState(() {
          _sidebarMode = _ReaderSidebarMode.word;
          _sidebarOpen = true;
        });
      case ReaderActionPanelHost.bottomSheet:
        break;
    }
  }

  void _openStatsPanel() {
    _hideReadingReminder();
    switch (_actionPanelHost) {
      case ReaderActionPanelHost.workspaceRightPanel:
        _workspaceController.openRightPanel(ReaderRightPanelTab.chapter);
      case ReaderActionPanelHost.wideSidebar:
      case ReaderActionPanelHost.bottomSheet:
        showFlowSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => DraggableScrollableSheet(
            initialChildSize: 0.72,
            minChildSize: 0.36,
            maxChildSize: 0.92,
            expand: false,
            builder: (_, _) => ReaderLearningStatsPanel(
              onStartTraining: _startChapterTraining,
            ),
          ),
        );
    }
  }

  void _startChapterTraining() {
    _hideReadingReminder();
    Navigator.of(context).pushNamed('/practice');
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

    final layout = _currentLayoutSpec;

    if (layout.isWorkspace) {
      _workspaceController.openToc();
      return;
    }

    showFlowSheet(
      context: context,
      isScrollControlled: true,
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
    showFlowSheet(
      context: context,
      isScrollControlled: true,
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
    await showFlowSheet<void>(
      context: context,
      isScrollControlled: true,
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
      showFlowSheet(
        context: context,
        isScrollControlled: true,
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
    showFlowSheet(
      context: context,
      isScrollControlled: true,
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
      if (!_sidebarOpen && ref.read(aiAssistantControllerProvider).isEmpty) {
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
        return AppSurfaceTokens.of(context).readerWorkspaceBackground;
      default:
        return AppSurfaceTokens.of(context).readerOpaqueSurface;
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

    final blocks =
        currentBookNotifier.hasBook && currentBookNotifier.chapterCount > 0
        ? currentBookNotifier
              .book!
              .chapters[currentBookState.currentChapter]
              .blocks
        : const <ContentBlock>[];
    final paragraphs = result != null && blocks.isEmpty
        ? _paragraphsFor(result, currentBookState, currentBookNotifier)
        : const <String>[];
    final theme = Theme.of(context);
    final chapterTitle =
        currentBookNotifier.hasBook && currentBookNotifier.chapterCount > 0
        ? currentBookNotifier
              .book!
              .chapters[currentBookState.currentChapter]
              .title
        : (result?.title ?? '当前位置');
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

          final layoutSpec = _resolveLayout(constraints.maxWidth);
          final useWorkspace = layoutSpec.isWorkspace;

          Widget buildContent() {
            if (result == null) {
              return const Center(child: CircularProgressIndicator());
            }

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
              sidebarOpen: useWorkspace ? false : _sidebarOpen,
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
                  ? _workspaceController.isRightPanelOpen
                  : _sidebarOpen,
              useWorkspaceTocPanel: useWorkspace,
              tocMenuOpen: _tocMenuOpen,
              tocMenuController: _tocMenuController,
              fontSettingsMenuController: _fontSettingsMenuController,
              onSidebarToggle: useWorkspace
                  ? _workspaceController.toggleRightPanel
                  : _toggleSidebar,
              onShowWorkspaceToc: _workspaceController.openToc,
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
              onOpenVocabularyPanel: _openVocabularyPanel,
              onStartChapterTraining: _startChapterTraining,
              onOpenStatsPanel: _openStatsPanel,
              onOpenChapterAI: _openChapterAIPanel,
            );
          }

          if (useWorkspace) {
            return _buildPageScaffold(
              config: config,
              child: DesktopReaderWorkspaceShell(
                workspaceController: _workspaceController,
                toolbar: buildToolbar(),
                centerContent: buildContent(),
                rightPanel: _buildWorkspaceRightPanel(),
                readingProgressLine: _buildReadingProgressLine(
                  theme,
                  _displayProgressNotifier,
                ),
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
                _buildReadingProgressLine(theme, _displayProgressNotifier),
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
    return AppSurface(
      role: AppSurfaceRole.readerCanvas,
      child: ColoredBox(
        color: _readerBackgroundColor(context, config),
        child: child,
      ),
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
      ),
      _ReaderSidebarMode.assistant => AIAssistantPanel(
        controller: ref.read(aiAssistantControllerProvider),
        embedded: true,
        onClose: () => setState(() => _sidebarOpen = false),
      ),
    };
  }

  Widget _buildWorkspaceRightPanel() {
    if (!_workspaceController.isRightPanelOpen) {
      return const SizedBox.shrink();
    }

    Widget? aiContent;

    switch (_sidebarMode) {
      case _ReaderSidebarMode.word:
        break;
      case _ReaderSidebarMode.assistant:
        aiContent = AIAssistantPanel(
          controller: ref.read(aiAssistantControllerProvider),
          embedded: true,
          onClose: () => _workspaceController.closeRightPanel(),
        );
        break;
    }

    return ReaderRightAssistantPanel(
      workspaceController: _workspaceController,
      onTabSelected: _onWorkspaceRightTabSelected,
      dictionaryContent: ReaderVocabularyPanel(
        onVocabularySelected: _openVocabularyLookup,
        onClose: () {
          ref.read(wordLookupNotifierProvider.notifier).clearWordLookup();
          _workspaceController.closeRightPanel();
        },
      ),
      aiContent: aiContent ?? const SizedBox.shrink(),
      chapterContent: ReaderLearningStatsPanel(
        onStartTraining: _startChapterTraining,
      ),
    );
  }

  void _onWorkspaceRightTabSelected(ReaderRightPanelTab tab) {
    switch (tab) {
      case ReaderRightPanelTab.ai:
        _openAssistantFromCurrentContext();
      case ReaderRightPanelTab.dictionary:
        _workspaceController.setRightTab(tab);
        setState(() => _sidebarMode = _ReaderSidebarMode.word);
      case ReaderRightPanelTab.chapter:
        _workspaceController.setRightTab(tab);
    }
  }
}

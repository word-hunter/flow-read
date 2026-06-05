import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter/services.dart';
import '../models/analysis_result.dart';
import '../models/book_difficulty.dart';
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
import '../services/settings_service.dart' show VocabularyColorSettings;
import '../theme/app_constants.dart';
import '../widgets/book_difficulty_chip.dart';
import '../widgets/bookmark_sheet.dart';
import '../widgets/font_settings_sheet.dart';
import '../widgets/reader/reader_word_sidebar.dart';
import '../widgets/reader_text_view.dart';
import '../widgets/selected_text_action_toolbar.dart';
import '../widgets/selected_text_sheet.dart';
import '../widgets/toc_bottom_sheet.dart';
import '../widgets/word_bottom_sheet.dart';

enum _ReaderSidebarMode { word, textAnalysis }

class ReaderPage extends riverpod.ConsumerStatefulWidget {
  const ReaderPage({super.key});

  @override
  riverpod.ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends riverpod.ConsumerState<ReaderPage> {
  static const double _keyboardLineScrollDelta = 92;
  static const int _maxViewportRestorePasses = 10;
  static const double _viewportRestorePixelTolerance = 0.5;
  static const double _toolbarIconGap = 8;
  static const double _toolbarButtonWidth = 40;
  static const double _toolbarButtonHeight = 32;
  static const double _toolbarInfoWidth = 540;

  final ScrollController _scrollController = ScrollController();
  final MenuController _tocMenuController = MenuController();
  final MenuController _fontSettingsMenuController = MenuController();
  final FocusNode _readerFocusNode = FocusNode(
    debugLabel: 'ReaderPageKeyboard',
  );
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Map<int, GlobalKey> _contentKeys = {};
  final ValueNotifier<double> _displayProgressNotifier = ValueNotifier<double>(
    0.0,
  );
  String? _lastReaderLocationKey;
  String? _lastReaderViewportKey;
  String? _cachedParagraphLocationKey;
  String? _cachedParagraphSourceText;
  List<String>? _cachedParagraphs;
  bool _hadReaderResult = false;
  bool _scrollViewportSyncQueued = false;
  bool _isRestoringViewport = false;
  String _sidebarSelectedText = '';
  String _sidebarAnalyzerName = 'AI';
  _ReaderSidebarMode _sidebarMode = _ReaderSidebarMode.word;
  bool _sidebarOpen = false;
  bool _searchSheetOpen = false;
  bool _tocMenuOpen = false;
  bool _fontSettingsMenuOpen = false;
  bool _searchShowingAll = false;
  bool _dailyGoalPromptShown = false;
  bool _wasDailyGoalReached = false;
  Timer? _dailyGoalCheckTimer;
  Timer? _readingReminderHideTimer;
  String? _readingReminderMessage;
  double _pendingScrollProgress = 0.0;
  double? _pendingScrollOffset;
  int _viewportRestorePass = 0;
  double _layoutWidth = 0;
  int _visibleContentCount = 0;

  bool get _isWideScreen => _layoutWidth >= AppConstants.wideBreakpoint;
  bool get _isSearchPanelVisible => _searchSheetOpen;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _dailyGoalCheckTimer?.cancel();
    _readingReminderHideTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _displayProgressNotifier.dispose();
    _readerFocusNode.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _primeReaderState(
    CurrentBookController currentBook,
    ReadingTimeController readingTime,
  ) {
    _lastReaderLocationKey = _readerLocationKey(currentBook);
    _lastReaderViewportKey = _readerViewportKey(currentBook);
    _hadReaderResult = currentBook.result != null;
    _syncDailyGoalWatcher(currentBook, readingTime);
    if (_hadReaderResult) {
      _queueViewportSync(
        progress: currentBook.readingProgress,
        scrollOffset: currentBook.readingScrollOffset,
        locationChanged: false,
      );
    }
  }

  String _readerLocationKey(CurrentBookController currentBook) {
    final book = currentBook.book;
    final bookKey =
        currentBook.activeBookId ??
        (book == null
            ? 'standalone'
            : '${identityHashCode(book)}:${book.title}');
    return '$bookKey:${currentBook.currentChapter}';
  }

  String _readerViewportKey(CurrentBookController currentBook) {
    final progress = currentBook.readingProgress.clamp(0.0, 1.0);
    final scrollOffset = currentBook.readingScrollOffset;
    final offsetKey = scrollOffset == null
        ? 'ratio'
        : scrollOffset.toStringAsFixed(1);
    return '${_readerLocationKey(currentBook)}:${progress.toStringAsFixed(4)}:$offsetKey';
  }

  void _onReaderStateChanged(
    CurrentBookController currentBook,
    ReadingTimeController readingTime,
  ) {
    _syncDailyGoalWatcher(currentBook, readingTime);

    final hasResult = currentBook.result != null;
    final resultBecameReady = !_hadReaderResult && hasResult;
    _hadReaderResult = hasResult;

    final nextLocationKey = _readerLocationKey(currentBook);
    final nextViewportKey = _readerViewportKey(currentBook);
    if (_lastReaderLocationKey == null || _lastReaderViewportKey == null) {
      _lastReaderLocationKey = nextLocationKey;
      _lastReaderViewportKey = nextViewportKey;
      if (hasResult) {
        _queueViewportSync(
          progress: currentBook.readingProgress,
          scrollOffset: currentBook.readingScrollOffset,
          locationChanged: false,
        );
      }
      return;
    }
    final locationChanged = _lastReaderLocationKey != nextLocationKey;
    final viewportChanged = _lastReaderViewportKey != nextViewportKey;
    if (!locationChanged && !viewportChanged && !resultBecameReady) return;

    _lastReaderLocationKey = nextLocationKey;
    _lastReaderViewportKey = nextViewportKey;
    if (hasResult) {
      _queueViewportSync(
        progress: currentBook.readingProgress,
        scrollOffset: currentBook.readingScrollOffset,
        locationChanged: locationChanged,
      );
    }
  }

  void _queueViewportSync({
    required double progress,
    required double? scrollOffset,
    required bool locationChanged,
  }) {
    _pendingScrollProgress = progress.clamp(0.0, 1.0);
    _pendingScrollOffset = scrollOffset;
    _setDisplayProgress(_pendingScrollProgress);
    _viewportRestorePass = 0;
    if (locationChanged) {
      _contentKeys.clear();
      _clearParagraphCache();
    }

    _isRestoringViewport = true;
    _scheduleViewportSyncPass();
  }

  void _scheduleViewportSyncPass() {
    if (_scrollViewportSyncQueued) return;
    _scrollViewportSyncQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollViewportSyncQueued = false;
      if (!mounted) return;
      if (!_scrollController.hasClients) {
        _isRestoringViewport = false;
        return;
      }

      final position = _scrollController.position;
      final savedOffset = _pendingScrollOffset;
      final target = savedOffset == null
          ? (position.maxScrollExtent <= position.minScrollExtent
                ? position.minScrollExtent
                : (position.maxScrollExtent * _pendingScrollProgress)
                      .clamp(position.minScrollExtent, position.maxScrollExtent)
                      .toDouble())
          : (savedOffset < position.minScrollExtent
                ? position.minScrollExtent
                : savedOffset);
      final needsJump =
          (position.pixels - target).abs() > _viewportRestorePixelTolerance;

      if (needsJump) {
        _scrollController.jumpTo(target);
      }

      if (needsJump && _viewportRestorePass < _maxViewportRestorePasses) {
        _viewportRestorePass += 1;
        _scheduleViewportSyncPass();
        return;
      }

      _isRestoringViewport = false;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    if (_isRestoringViewport) {
      _setDisplayProgress(_pendingScrollProgress);
      return;
    }
    final progress = (_scrollController.offset / maxScroll).clamp(0.0, 1.0);
    _setDisplayProgress(progress);
    final currentBook = ref.read(currentBookProvider);
    currentBook.updateReadingProgress(
      progress,
      scrollOffset: _scrollController.offset,
    );
    _lastReaderViewportKey = _readerViewportKey(currentBook);
    _checkDailyReadingGoal();
  }

  void _setDisplayProgress(double progress) {
    final next = progress.clamp(0.0, 1.0).toDouble();
    if ((_displayProgressNotifier.value - next).abs() < 0.0001) return;
    _displayProgressNotifier.value = next;
  }

  List<String> _paragraphsFor(
    AnalysisResult result,
    CurrentBookController currentBook,
  ) {
    final locationKey = _readerLocationKey(currentBook);
    final sourceText = result.passageText;
    final cached = _cachedParagraphs;
    if (cached != null &&
        _cachedParagraphLocationKey == locationKey &&
        _cachedParagraphSourceText == sourceText) {
      return cached;
    }

    final paragraphs = splitIntoParagraphs(sourceText);
    _cachedParagraphLocationKey = locationKey;
    _cachedParagraphSourceText = sourceText;
    _cachedParagraphs = paragraphs;
    return paragraphs;
  }

  void _clearParagraphCache() {
    _cachedParagraphLocationKey = null;
    _cachedParagraphSourceText = null;
    _cachedParagraphs = null;
  }

  void _syncDailyGoalWatcher(
    CurrentBookController currentBook,
    ReadingTimeController readingTime,
  ) {
    if (!currentBook.isReading) {
      _dailyGoalCheckTimer?.cancel();
      _dailyGoalCheckTimer = null;
      _dailyGoalPromptShown = false;
      _wasDailyGoalReached = readingTime.dailyReadingGoalReached;
      return;
    }

    if (_dailyGoalCheckTimer != null) return;
    _wasDailyGoalReached = readingTime.dailyReadingGoalReached;
    _dailyGoalCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkDailyReadingGoal(),
    );
  }

  void _checkDailyReadingGoal() {
    if (!mounted) return;
    final readingTime = ref.read(readingTimeProvider);
    final reached = readingTime.dailyReadingGoalReached;
    if (!reached) {
      _wasDailyGoalReached = false;
      _dailyGoalPromptShown = false;
      return;
    }
    if (_wasDailyGoalReached || _dailyGoalPromptShown) return;

    _wasDailyGoalReached = true;
    _dailyGoalPromptShown = true;
    final goalText = _formatGoalDuration(readingTime.dailyReadingGoalSeconds);
    _showReadingReminder('今日阅读目标已达成：$goalText');
  }

  void _showReadingReminder(String message) {
    _readingReminderHideTimer?.cancel();
    if (!mounted) return;
    setState(() => _readingReminderMessage = message);
    _readingReminderHideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _readingReminderMessage = null);
    });
  }

  void _hideReadingReminder() {
    _readingReminderHideTimer?.cancel();
    _readingReminderHideTimer = null;
    if (_readingReminderMessage == null || !mounted) return;
    setState(() => _readingReminderMessage = null);
  }

  String _formatGoalDuration(int seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes 分钟';
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    if (remain == 0) return '$hours 小时';
    return '$hours 小时 $remain 分钟';
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

  GlobalKey _contentKeyFor(int index) {
    return _contentKeys.putIfAbsent(index, GlobalKey.new);
  }

  Widget _buildKeyboardScope(Widget child) {
    return Focus(
      focusNode: _readerFocusNode,
      autofocus: true,
      skipTraversal: true,
      onKeyEvent: _handleReaderKeyEvent,
      child: child,
    );
  }

  KeyEventResult _handleReaderKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final route = ModalRoute.of(context);
    if ((route != null && !route.isCurrent) ||
        _searchSheetOpen ||
        !_scrollController.hasClients) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      _scrollReaderBy(-_keyboardLineScrollDelta);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _scrollReaderBy(_keyboardLineScrollDelta);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _turnChapter(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _turnChapter(1);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _scrollReaderBy(double delta) {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final current = position.pixels;
    final target = (current + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();

    if ((target - current).abs() < 1) return;

    unawaited(
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _turnChapter(int direction) {
    if (direction == 0) return;

    final currentBook = ref.read(currentBookProvider);
    if (!currentBook.hasBook || currentBook.chapterCount <= 1) return;

    final nextChapter = currentBook.currentChapter + direction;
    if (nextChapter < 0 || nextChapter >= currentBook.chapterCount) return;

    unawaited(currentBook.goToChapter(nextChapter));
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

  Color _readerTextColor(ReadingConfigController config) {
    switch (config.readingTheme) {
      case 'dark':
        return const Color(0xFFE8E2D6);
      case 'sepia':
        return const Color(0xFF30281F);
      default:
        return const Color(0xFF20231F);
    }
  }

  Color _readerMutedTextColor(ReadingConfigController config) {
    switch (config.readingTheme) {
      case 'dark':
        return const Color(0xFFC8C1B7);
      case 'sepia':
        return const Color(0xFF6F6251);
      default:
        return const Color(0xFF626960);
    }
  }

  bool _isDarkReadingTheme(ReadingConfigController config) {
    return config.readingTheme == 'dark';
  }

  TextStyle _buildBaseTextStyle(
    ThemeData theme,
    ReadingConfigController config,
  ) {
    return (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
      fontSize: config.fontSize,
      height: config.lineHeight,
      letterSpacing: 0.3,
      fontFamily: config.fontFamily,
      color: _readerTextColor(config),
    );
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

          return _buildPageScaffold(
            config: config,
            child: Column(
              children: [
                _buildNavBar(
                  currentBook,
                  config,
                  bookmarks,
                  theme,
                  chapterTitle,
                  showSidebarToggle: isWide,
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
                              Expanded(
                                child: _buildReadingContent(
                                  paragraphs,
                                  blocks,
                                  result,
                                  theme,
                                  colorSettings,
                                  settings.aiFeaturesEnabled,
                                  currentBook,
                                  config,
                                  search,
                                  lookup,
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
                            currentBook,
                            config,
                            search,
                            lookup,
                          ),
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

  Widget _buildReadingReminder(ThemeData theme) {
    final message = _readingReminderMessage;
    final visible = message != null && !_searchSheetOpen;
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: visible
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 15,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
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

  Widget _buildReadingContent(
    List<String> paragraphs,
    List<ContentBlock> blocks,
    AnalysisResult result,
    ThemeData theme,
    VocabularyColorSettings colorSettings,
    bool aiFeaturesEnabled,
    CurrentBookController currentBook,
    ReadingConfigController config,
    ReadingSearchFacade search,
    WordLookupController lookup,
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
          final showTitleBlock = !currentBook.hasBook;
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
              child: SingleChildScrollView(
                key: const ValueKey('reader-scroll-view'),
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  leftPadding,
                  topPadding,
                  rightPadding,
                  40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showTitleBlock) _buildTitleBlock(result, theme, config),
                    for (
                      var contentIndex = 0;
                      contentIndex < contentCount;
                      contentIndex += 1
                    )
                      KeyedSubtree(
                        key: _contentKeyFor(contentIndex),
                        child: useBlocks
                            ? _buildContentBlock(
                                blocks[contentIndex],
                                result,
                                theme,
                                colorSettings: colorSettings,
                                config: config,
                                search: search,
                                lookup: lookup,
                                isFirstBlock:
                                    contentIndex == 0 && currentBook.hasBook,
                              )
                            : _buildParagraph(
                                paragraphs[contentIndex],
                                result,
                                theme,
                                colorSettings: colorSettings,
                                config: config,
                                search: search,
                                lookup: lookup,
                                isFirstParagraph:
                                    contentIndex == 0 && currentBook.hasBook,
                              ),
                      ),
                  ],
                ),
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
    required ReadingConfigController config,
    required ReadingSearchFacade search,
    required WordLookupController lookup,
    bool isFirstBlock = false,
  }) {
    final searchQuery = _effectiveHighlightQuery(search);
    final lookupHighlightWord = lookup.selectedWord;
    final hasLookupHighlight =
        lookupHighlightWord != null && lookupHighlightWord.trim().isNotEmpty;

    if (isFirstBlock &&
        searchQuery.isEmpty &&
        !hasLookupHighlight &&
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
          _buildBaseTextStyle(theme, config),
          config,
          lookup,
        ),
      );
    }

    return buildBlockWidget(
      block,
      result,
      theme,
      onWordTapped: _onWordTapped,
      fontSize: config.fontSize,
      lineHeight: config.lineHeight,
      fontFamily: config.fontFamily,
      baseTextColor: _readerTextColor(config),
      mutedTextColor: _readerMutedTextColor(config),
      colorSettings: colorSettings,
      searchQuery: searchQuery,
      lookupHighlightWord: lookupHighlightWord,
      wordLevelService: lookup.wordLevelService,
      languageModule: lookup.activeLanguageModule,
    );
  }

  String _effectiveHighlightQuery(ReadingSearchFacade search) {
    return _isSearchPanelVisible ? search.query : search.sourceHighlightQuery;
  }

  Widget _buildTitleBlock(
    AnalysisResult result,
    ThemeData theme,
    ReadingConfigController config,
  ) {
    final titleColor = _readerTextColor(config);
    final dividerColor = _isDarkReadingTheme(config)
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
              fontFamily: config.fontFamily,
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
    required ReadingConfigController config,
    required ReadingSearchFacade search,
    required WordLookupController lookup,
    bool isFirstParagraph = false,
  }) {
    final baseStyle = _buildBaseTextStyle(theme, config);
    final searchQuery = _effectiveHighlightQuery(search);
    final lookupHighlightWord = lookup.selectedWord;
    final hasLookupHighlight =
        lookupHighlightWord != null && lookupHighlightWord.trim().isNotEmpty;

    if (isFirstParagraph &&
        paragraph.isNotEmpty &&
        searchQuery.isEmpty &&
        !hasLookupHighlight) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildDropCapParagraph(
          paragraph,
          result,
          theme,
          colorSettings,
          baseStyle,
          config,
          lookup,
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
          fontSize: config.fontSize,
          lineHeight: config.lineHeight,
          fontFamily: config.fontFamily,
          baseTextColor: _readerTextColor(config),
          colorSettings: colorSettings,
          searchQuery: searchQuery,
          lookupHighlightWord: lookupHighlightWord,
          wordLevelService: lookup.wordLevelService,
          languageModule: lookup.activeLanguageModule,
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
    ReadingConfigController config,
    WordLookupController lookup,
  ) {
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
              fontSize: config.fontSize * 3.05,
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
              fontSize: config.fontSize,
              lineHeight: config.lineHeight,
              fontFamily: config.fontFamily,
              baseTextColor: _readerTextColor(config),
              colorSettings: colorSettings,
              lookupHighlightWord: lookup.selectedWord,
              wordLevelService: lookup.wordLevelService,
              languageModule: lookup.activeLanguageModule,
            ),
            style: baseStyle,
          ),
        ),
      ],
    );
  }

  Widget _compactIconButton({
    Key? key,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    double size = 19,
    bool selected = false,
  }) {
    final theme = Theme.of(context);
    final isDarkReader = _isDarkReadingTheme(ref.read(readingConfigProvider));
    return IconButton(
      key: key,
      icon: Icon(icon, size: size),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: _toolbarButtonWidth,
        height: _toolbarButtonHeight,
      ),
      visualDensity: VisualDensity.compact,
      style: _toolbarIconButtonStyle(
        theme,
        selected: selected,
        darkReader: isDarkReader,
      ),
    );
  }

  Widget _chapterStepButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);
    final isDarkReader = _isDarkReadingTheme(ref.read(readingConfigProvider));
    return IconButton(
      icon: Icon(icon, size: 22),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: _toolbarButtonWidth,
        height: _toolbarButtonHeight,
      ),
      visualDensity: VisualDensity.compact,
      style: _toolbarIconButtonStyle(theme, darkReader: isDarkReader).copyWith(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  ButtonStyle _toolbarIconButtonStyle(
    ThemeData theme, {
    bool selected = false,
    bool darkReader = false,
  }) {
    final colorScheme = theme.colorScheme;
    final inactiveForeground = darkReader
        ? const Color(0xFFC8C1B7)
        : colorScheme.onSurfaceVariant;
    return ButtonStyle(
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      mouseCursor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return SystemMouseCursors.basic;
        }
        return SystemMouseCursors.click;
      }),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.transparent;
        }
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.primary.withValues(alpha: 0.14);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return colorScheme.primary.withValues(alpha: selected ? 0.16 : 0.08);
        }
        return selected
            ? colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return inactiveForeground.withValues(alpha: 0.38);
        }
        if (selected ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return colorScheme.primary;
        }
        return inactiveForeground;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.primary.withValues(alpha: 0.10);
        }
        return Colors.transparent;
      }),
    );
  }

  Widget _buildNavBar(
    CurrentBookController currentBook,
    ReadingConfigController config,
    BookmarkController bookmarks,
    ThemeData theme,
    String chapterTitle, {
    bool showSidebarToggle = false,
  }) {
    final isDark = _isDarkReadingTheme(config);
    final borderColor = isDark
        ? const Color(0xFF3A3A3A).withValues(alpha: 0.72)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.48);
    final toolbarTextColor = isDark
        ? const Color(0xFFC8C1B7)
        : theme.colorScheme.onSurfaceVariant;
    final showSearch = _layoutWidth >= 520;
    final showChapterStep = _layoutWidth >= 680 && currentBook.chapterCount > 1;
    final compactToolbar = _layoutWidth < 760;
    final contentTitle = chapterTitle.trim().isNotEmpty
        ? chapterTitle.trim()
        : '当前位置';
    final chapterMetaPrefix = currentBook.hasBook
        ? '${currentBook.currentChapter + 1} / ${currentBook.chapterCount} · '
        : null;
    final canGoPreviousChapter =
        currentBook.hasBook && currentBook.currentChapter > 0;
    final canGoNextChapter =
        currentBook.hasBook &&
        currentBook.currentChapter < currentBook.chapterCount - 1;

    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F1F1F).withValues(alpha: 0.42)
            : theme.colorScheme.surface.withValues(alpha: 0.86),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          _buildToolbarGroup(
            children: [
              _compactIconButton(
                key: const ValueKey('reader-toolbar-back'),
                icon: Icons.arrow_back,
                tooltip: '返回',
                onPressed: currentBook.exitReader,
              ),
              _buildTocButton(currentBook, useDropdown: showSidebarToggle),
            ],
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: compactToolbar ? 320 : _toolbarInfoWidth,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (showChapterStep) ...[
                      _chapterStepButton(
                        icon: Icons.chevron_left,
                        tooltip: '上一个目录项',
                        onPressed: canGoPreviousChapter
                            ? () => currentBook.goToChapter(
                                currentBook.currentChapter - 1,
                              )
                            : null,
                      ),
                      const SizedBox(width: _toolbarIconGap),
                    ],
                    Expanded(
                      child: chapterMetaPrefix == null
                          ? _ReaderLocationSummary(
                              title: contentTitle,
                              metaLabel: null,
                              difficulty: currentBook.currentBookDifficulty,
                              textColor: toolbarTextColor,
                            )
                          : ValueListenableBuilder<double>(
                              valueListenable: _displayProgressNotifier,
                              builder: (context, progress, _) {
                                final progressPercent = (progress * 100)
                                    .round();
                                return _ReaderLocationSummary(
                                  title: contentTitle,
                                  metaLabel:
                                      '$chapterMetaPrefix$progressPercent%',
                                  difficulty: currentBook.currentBookDifficulty,
                                  textColor: toolbarTextColor,
                                );
                              },
                            ),
                    ),
                    if (showChapterStep) ...[
                      const SizedBox(width: _toolbarIconGap),
                      _chapterStepButton(
                        icon: Icons.chevron_right,
                        tooltip: '下一个目录项',
                        onPressed: canGoNextChapter
                            ? () => currentBook.goToChapter(
                                currentBook.currentChapter + 1,
                              )
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _buildToolbarGroup(
            children: [
              if (showSidebarToggle)
                _compactIconButton(
                  icon: _sidebarOpen
                      ? Icons.vertical_split
                      : Icons.vertical_split_outlined,
                  tooltip: _sidebarOpen ? '收起侧栏' : '展开侧栏',
                  onPressed: () {
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
                  },
                ),
              if (showSearch)
                _compactIconButton(
                  icon: Icons.search,
                  tooltip: '搜索',
                  onPressed: () => unawaited(_showSearchSheet()),
                ),
              _buildFontSettingsButton(useDropdown: showSidebarToggle),
              _compactIconButton(
                icon: bookmarks.isCurrentPositionBookmarked()
                    ? Icons.bookmark
                    : Icons.bookmark_outline,
                tooltip: '书签',
                onPressed: _onBookmarkTap,
              ),
              PopupMenuButton<String>(
                position: PopupMenuPosition.under,
                tooltip: '更多',
                icon: const Icon(Icons.more_vert, size: 20),
                padding: EdgeInsets.zero,
                style: _toolbarIconButtonStyle(theme, darkReader: isDark)
                    .copyWith(
                      fixedSize: const WidgetStatePropertyAll(
                        Size(_toolbarButtonWidth, _toolbarButtonHeight),
                      ),
                      minimumSize: const WidgetStatePropertyAll(
                        Size(_toolbarButtonWidth, _toolbarButtonHeight),
                      ),
                      maximumSize: const WidgetStatePropertyAll(
                        Size(_toolbarButtonWidth, _toolbarButtonHeight),
                      ),
                    ),
                onSelected: (value) {
                  switch (value) {
                    case 'search':
                      unawaited(_showSearchSheet());
                      break;
                    case 'prevChapter':
                      if (canGoPreviousChapter) {
                        currentBook.goToChapter(
                          currentBook.currentChapter - 1,
                        );
                      }
                      break;
                    case 'nextChapter':
                      if (canGoNextChapter) {
                        currentBook.goToChapter(
                          currentBook.currentChapter + 1,
                        );
                      }
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
                  if (currentBook.hasBook && currentBook.chapterCount > 1) ...[
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
                  const PopupMenuItem(value: 'bookmarks', child: Text('历史书签')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarGroup({required List<Widget> children}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, child) in children.indexed)
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: index > 0 ? _toolbarIconGap : 0,
            ),
            child: child,
          ),
      ],
    );
  }

  Widget _buildTocButton(
    CurrentBookController currentBook, {
    required bool useDropdown,
  }) {
    if (!currentBook.hasBook || currentBook.chapterCount <= 1) {
      return const SizedBox.shrink();
    }

    if (!useDropdown) {
      return _compactIconButton(
        key: const ValueKey('reader-toolbar-toc'),
        icon: Icons.menu,
        tooltip: '目录',
        onPressed: _showTocSheet,
      );
    }

    return MenuAnchor(
      controller: _tocMenuController,
      onOpen: () => _setTocMenuOpen(true),
      onClose: () => _setTocMenuOpen(false),
      alignmentOffset: const Offset(0, 6),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        TocDropdownPanel(
          onClose: _tocMenuController.close,
          onChapterSelected: (_) => _tocMenuController.close(),
        ),
      ],
      child: _compactIconButton(
        key: const ValueKey('reader-toolbar-toc'),
        icon: Icons.menu,
        tooltip: '目录',
        selected: _tocMenuOpen,
        onPressed: () => _toggleTocMenu(_tocMenuController),
      ),
    );
  }

  Widget _buildFontSettingsButton({required bool useDropdown}) {
    if (!useDropdown) {
      return _compactIconButton(
        icon: Icons.text_fields,
        tooltip: '字体',
        onPressed: _showFontSettingsSheet,
      );
    }

    final panelWidth = FontSettingsDropdownPanel.preferredWidthFor(
      MediaQuery.sizeOf(context),
    );

    return MenuAnchor(
      controller: _fontSettingsMenuController,
      onOpen: () => _setFontSettingsMenuOpen(true),
      onClose: () => _setFontSettingsMenuOpen(false),
      alignmentOffset: Offset(-(panelWidth - 32), 6),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        FontSettingsDropdownPanel(
          width: panelWidth,
          onClose: _fontSettingsMenuController.close,
        ),
      ],
      builder: (context, controller, _) {
        return _compactIconButton(
          icon: Icons.text_fields,
          tooltip: '字体',
          selected: controller.isOpen,
          onPressed: () => _toggleFontSettingsMenu(controller),
        );
      },
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

class _ReaderLocationSummary extends StatelessWidget {
  final String title;
  final String? metaLabel;
  final BookDifficultyRating? difficulty;
  final Color textColor;

  const _ReaderLocationSummary({
    required this.title,
    required this.metaLabel,
    required this.difficulty,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = metaLabel;

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Text(
            key: const ValueKey('reader-toolbar-title'),
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ),
        if (meta != null) ...[
          const SizedBox(width: 8),
          Text(
            key: const ValueKey('reader-toolbar-meta'),
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
        if (difficulty != null) ...[
          const SizedBox(width: 8),
          BookDifficultyChip(
            rating: difficulty,
            isLoading: false,
            labelOnly: true,
          ),
        ],
      ],
    );
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

class _ReaderSearchPanel extends riverpod.ConsumerWidget {
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
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final search = ref.watch(readingSearchProvider);
    final results = search.results;
    final query = search.query;
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
          _SearchStatus(search: search, expanded: expanded),
          const SizedBox(height: 6),
          Expanded(
            child: _SearchResultsList(
              query: query,
              results: results,
              isSearching: search.isSearching,
              activeResult: search.activeResult,
              scrollController: resultsScrollController,
              onResultTap: onResultTap,
            ),
          ),
          if (!expanded && search.stoppedAtLimit) ...[
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
  final ReadingSearchFacade search;
  final bool expanded;

  const _SearchStatus({required this.search, required this.expanded});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resultCount = search.results.length;
    final query = search.query;
    final text = query.isEmpty
        ? '输入关键词'
        : search.isSearching
        ? '正在搜索... $resultCount'
        : search.stoppedAtLimit && !expanded
        ? '已显示前 $resultCount 条'
        : '共 $resultCount 条结果';

    return Row(
      children: [
        if (search.isSearching) ...[
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

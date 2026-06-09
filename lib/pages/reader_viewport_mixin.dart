part of 'reader_page.dart';

const int _maxViewportRestorePasses = 10;
const double _viewportRestorePixelTolerance = 0.5;

mixin ReaderViewportMixin on riverpod.ConsumerState<ReaderPage> {
  ScrollController get _scrollController;
  ValueNotifier<double> get _displayProgressNotifier;
  Map<int, GlobalKey> get _contentKeys;

  final ReaderLayoutEngine _layoutEngine = const ReaderLayoutEngine();

  void _syncDailyGoalWatcher(
    CurrentBookState currentBookState,
    ReadingTimeState readingTime,
  );

  void _checkDailyReadingGoal();

  String? _lastReaderLocationKey;
  String? _lastReaderViewportKey;
  String? _cachedParagraphLocationKey;
  String? _cachedParagraphSourceText;
  List<String>? _cachedParagraphs;
  bool _hadReaderResult = false;
  bool _scrollViewportSyncQueued = false;
  bool _isRestoringViewport = false;
  double _pendingScrollProgress = 0.0;
  double? _pendingScrollOffset;
  int _viewportRestorePass = 0;
  int _visibleContentCount = 0;
  PageLayoutConfig? _lastPageLayoutConfig;
  ReadingPositionAnchor? _pendingReflowAnchor;

  void _captureAnchorForReflow({
    required int chapterIndex,
    List<ContentBlock> blocks = const [],
  }) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;
    _pendingReflowAnchor = _layoutEngine.anchorFor(
      blocks,
      position.pixels,
      position.maxScrollExtent,
      chapterIndex: chapterIndex,
    );
  }

  bool _needsReflow(PageLayoutConfig currentConfig) {
    final changed = _lastPageLayoutConfig != currentConfig;
    if (changed) {
      _lastPageLayoutConfig = currentConfig;
    }
    return changed;
  }

  void _applyReflowAnchor({
    required int chapterIndex,
    List<ContentBlock> blocks = const [],
  }) {
    final anchor = _pendingReflowAnchor;
    if (anchor == null || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final estimatedOffset = _layoutEngine.estimatedScrollOffset(
      blocks,
      position.maxScrollExtent,
      anchor,
    );
    _pendingScrollOffset = estimatedOffset;
    _pendingReflowAnchor = null;
  }

  void _primeReaderState(
    CurrentBookState currentBookState,
    CurrentBookNotifier currentBookNotifier,
    ReadingTimeState readingTime,
  ) {
    _lastReaderLocationKey = _readerLocationKey(currentBookState, currentBookNotifier);
    _lastReaderViewportKey = _readerViewportKey(currentBookState, currentBookNotifier);
    _hadReaderResult = currentBookNotifier.result != null;
    _syncDailyGoalWatcher(currentBookState, readingTime);
    if (_hadReaderResult) {
      _queueViewportSync(
        progress: currentBookState.readingProgress,
        scrollOffset: currentBookState.readingScrollOffset,
        locationChanged: false,
      );
    }
  }

  String _readerLocationKey(CurrentBookState currentBookState, CurrentBookNotifier currentBookNotifier) {
    final book = currentBookNotifier.book;
    final bookKey =
        currentBookNotifier.activeBookId ??
        (book == null
            ? 'standalone'
            : '${identityHashCode(book)}:${book.title}');
    return '$bookKey:${currentBookState.currentChapter}';
  }

  String _readerViewportKey(CurrentBookState currentBookState, CurrentBookNotifier currentBookNotifier) {
    final progress = currentBookState.readingProgress.clamp(0.0, 1.0);
    final scrollOffset = currentBookState.readingScrollOffset;
    final offsetKey = scrollOffset == null
        ? 'ratio'
        : scrollOffset.toStringAsFixed(1);
    return '${_readerLocationKey(currentBookState, currentBookNotifier)}:${progress.toStringAsFixed(4)}:$offsetKey';
  }

  void _onReaderStateChanged(
    CurrentBookState currentBookState,
    ReadingTimeState readingTime,
  ) {
    _syncDailyGoalWatcher(currentBookState, readingTime);

    final currentBookNotifier = ref.read(currentBookNotifierProvider.notifier);
    final hasResult = currentBookNotifier.result != null;
    final resultBecameReady = !_hadReaderResult && hasResult;
    _hadReaderResult = hasResult;

    final nextLocationKey = _readerLocationKey(currentBookState, currentBookNotifier);
    final nextViewportKey = _readerViewportKey(currentBookState, currentBookNotifier);
    if (_lastReaderLocationKey == null || _lastReaderViewportKey == null) {
      _lastReaderLocationKey = nextLocationKey;
      _lastReaderViewportKey = nextViewportKey;
      if (hasResult) {
        _queueViewportSync(
          progress: currentBookState.readingProgress,
          scrollOffset: currentBookState.readingScrollOffset,
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
        progress: currentBookState.readingProgress,
        scrollOffset: currentBookState.readingScrollOffset,
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
    final currentBookNotifier = ref.read(currentBookNotifierProvider.notifier);
    final currentBookState = ref.read(currentBookNotifierProvider);
    currentBookNotifier.updateReadingProgress(
      progress,
      scrollOffset: _scrollController.offset,
    );
    _lastReaderViewportKey = _readerViewportKey(currentBookState, currentBookNotifier);
    _checkDailyReadingGoal();
  }

  void _setDisplayProgress(double progress) {
    final next = progress.clamp(0.0, 1.0).toDouble();
    if ((_displayProgressNotifier.value - next).abs() < 0.0001) return;
    _displayProgressNotifier.value = next;
  }

  List<String> _paragraphsFor(
    AnalysisResult result,
    CurrentBookState currentBookState,
    CurrentBookNotifier currentBookNotifier,
  ) {
    final locationKey = _readerLocationKey(currentBookState, currentBookNotifier);
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

  GlobalKey _contentKeyFor(int index) {
    return _contentKeys.putIfAbsent(index, GlobalKey.new);
  }

  void _setVisibleContentCount(int count) {
    _visibleContentCount = count;
  }
}

part of 'reader_page.dart';

const int _maxViewportRestorePasses = 10;
const double _viewportRestorePixelTolerance = 0.5;

mixin ReaderViewportMixin on riverpod.ConsumerState<ReaderPage> {
  ScrollController get _scrollController;
  ValueNotifier<double> get _displayProgressNotifier;
  Map<int, GlobalKey> get _contentKeys;

  void _syncDailyGoalWatcher(
    CurrentBookController currentBook,
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

  void _primeReaderState(
    CurrentBookController currentBook,
    ReadingTimeState readingTime,
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
    ReadingTimeState readingTime,
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

  GlobalKey _contentKeyFor(int index) {
    return _contentKeys.putIfAbsent(index, GlobalKey.new);
  }

  void _setVisibleContentCount(int count) {
    _visibleContentCount = count;
  }
}

part of 'reader_page.dart';

const double _keyboardLineScrollDelta = 92;

mixin ReaderKeyboardMixin on riverpod.ConsumerState<ReaderPage> {
  ScrollController get _scrollController;
  FocusNode get _readerFocusNode;
  bool get _searchSheetOpen;

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
}

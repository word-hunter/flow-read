part of 'reader_page.dart';

const double _keyboardLineScrollDelta = 92;

mixin ReaderKeyboardMixin on riverpod.ConsumerState<ReaderPage> {
  ScrollController get _scrollController;
  FocusNode get _readerFocusNode;
  bool get _searchSheetOpen;
  void _goToChapter(int index);
  ReaderWorkspaceController get _workspaceController;
  bool get _isWorkspaceEnabled;
  void _openAssistantFromCurrentContext();

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
    final isMetaPressed = HardwareKeyboard.instance.isMetaPressed;
    final isAltPressed = HardwareKeyboard.instance.isAltPressed;
    final isMetaAlt = isMetaPressed && isAltPressed;

    if (isMetaAlt && _isWorkspaceEnabled) {
      if (key == LogicalKeyboardKey.keyL) {
        _workspaceController.toggleLeftPanel();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyT) {
        _workspaceController.openToc();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyR) {
        _workspaceController.toggleRightPanel();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyD) {
        _workspaceController.openRightPanel(ReaderRightPanelTab.dictionary);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyA) {
        _openAssistantFromCurrentContext();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyI) {
        _workspaceController.enterImmersive();
        return KeyEventResult.handled;
      }
    }

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

    final currentBookNotifier = ref.read(currentBookNotifierProvider.notifier);
    if (!currentBookNotifier.hasBook || currentBookNotifier.chapterCount <= 1) {
      return;
    }

    final currentChapter = ref.read(currentBookNotifierProvider).currentChapter;
    final nextChapter = currentChapter + direction;
    if (nextChapter < 0 || nextChapter >= currentBookNotifier.chapterCount) {
      return;
    }

    _goToChapter(nextChapter);
  }
}

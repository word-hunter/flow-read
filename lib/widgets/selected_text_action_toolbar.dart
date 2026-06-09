import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter/services.dart';

typedef SelectedTextActionBuilder =
    List<SelectedTextAction> Function(
      BuildContext context,
      String selectedText,
      VoidCallback closeToolbar,
    );

class SelectedTextAction {
  final IconData icon;
  final String tooltip;
  final FutureOr<void> Function()? onPressed;
  final bool enabled;

  const SelectedTextAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.enabled = true,
  });

  factory SelectedTextAction.copy({
    required BuildContext context,
    required String selectedText,
    required VoidCallback closeToolbar,
  }) {
    final hasText = selectedText.trim().isNotEmpty;
    return SelectedTextAction(
      icon: Icons.copy_rounded,
      tooltip: '复制',
      enabled: hasText,
      onPressed: () async {
        final messenger = ScaffoldMessenger.maybeOf(context);
        closeToolbar();
        await Clipboard.setData(ClipboardData(text: selectedText));
        messenger
          ?..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('已复制到剪贴板'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
      },
    );
  }
}

class SelectedTextActionRegion extends StatefulWidget {
  final Widget child;
  final SelectedTextActionBuilder actionsBuilder;
  final ValueChanged<String>? onSelectionTextChanged;
  final bool autoShowOnSelection;
  final Duration autoShowDelay;
  final GlobalKey<SelectionAreaState>? selectionAreaKey;

  const SelectedTextActionRegion({
    super.key,
    required this.child,
    required this.actionsBuilder,
    this.selectionAreaKey,
    this.onSelectionTextChanged,
    this.autoShowOnSelection = true,
    this.autoShowDelay = const Duration(milliseconds: 220),
  });

  @override
  State<SelectedTextActionRegion> createState() =>
      SelectedTextActionRegionState();
}

class SelectedTextActionRegionState extends State<SelectedTextActionRegion> {
  GlobalKey<SelectionAreaState>? _internalSelectionAreaKey;
  Timer? _showToolbarTimer;
  OverlayEntry? _toolbarEntry;
  String _selectedText = '';

  GlobalKey<SelectionAreaState> get _effectiveKey =>
      widget.selectionAreaKey ?? (_internalSelectionAreaKey ??= GlobalKey<SelectionAreaState>());

  @override
  void dispose() {
    _showToolbarTimer?.cancel();
    hideToolbar();
    super.dispose();
  }

  void hideToolbar() {
    _showToolbarTimer?.cancel();
    _showToolbarTimer = null;
    _toolbarEntry?.remove();
    _toolbarEntry = null;
  }

  bool _shouldAutoShowToolbar() {
    if (!widget.autoShowOnSelection) return false;
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.macOS ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux;
  }

  void onSelectionChanged(SelectedContent? selection) {
    final text = selection?.plainText ?? '';
    _selectedText = text;
    widget.onSelectionTextChanged?.call(text);

    hideToolbar();
    if (text.trim().isEmpty || !_shouldAutoShowToolbar()) return;

    _showToolbarTimer = Timer(widget.autoShowDelay, _showAutomaticToolbar);
  }

  void _showAutomaticToolbar() {
    if (!mounted || _selectedText.trim().isEmpty) return;
    final selectionArea = _effectiveKey.currentState;
    final overlay = Overlay.maybeOf(context);
    if (selectionArea == null || overlay == null) return;

    final anchors = selectionArea.selectableRegion.contextMenuAnchors;
    final entry = OverlayEntry(
      builder: (context) => SelectedTextActionToolbar(
        anchors: anchors,
        actions: widget.actionsBuilder(context, _selectedText, hideToolbar),
      ),
    );
    _toolbarEntry = entry;
    overlay.insert(entry);
  }

  Widget buildContextMenu(
    BuildContext context,
    SelectableRegionState selectableRegionState,
  ) {
    hideToolbar();
    void closeToolbar() {
      selectableRegionState.hideToolbar();
      ContextMenuController.removeAny();
    }

    return SelectedTextActionToolbar(
      anchors: selectableRegionState.contextMenuAnchors,
      actions: widget.actionsBuilder(context, _selectedText, closeToolbar),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.selectionAreaKey != null
        ? widget.child
        : SelectionArea(
            key: _effectiveKey,
            onSelectionChanged: onSelectionChanged,
            contextMenuBuilder: buildContextMenu,
            child: widget.child,
          );

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification ||
            notification is ScrollUpdateNotification) {
          hideToolbar();
        }
        return false;
      },
      child: child,
    );
  }
}

class SelectedTextActionToolbar extends StatelessWidget {
  final TextSelectionToolbarAnchors anchors;
  final List<SelectedTextAction> actions;

  const SelectedTextActionToolbar({
    super.key,
    required this.anchors,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final visibleActions = actions
        .where((action) => action.onPressed != null)
        .toList(growable: false);
    if (visibleActions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final padding = MediaQuery.paddingOf(context) + const EdgeInsets.all(8);
    final anchorBelow = anchors.secondaryAnchor ?? anchors.primaryAnchor;

    return CustomSingleChildLayout(
      delegate: _SelectedTextActionToolbarLayoutDelegate(
        anchorAbove: anchors.primaryAnchor,
        anchorBelow: anchorBelow,
        padding: padding,
      ),
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.75),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final action in visibleActions)
                  _SelectedTextActionButton(action: action),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedTextActionButton extends StatelessWidget {
  final SelectedTextAction action;

  const _SelectedTextActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = action.enabled;
    final foreground = enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);

    return Tooltip(
      message: action.tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: SizedBox.square(
        dimension: 40,
        child: IconButton(
          icon: Icon(action.icon, size: 20, color: foreground),
          tooltip: null,
          onPressed: enabled ? () => action.onPressed?.call() : null,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            foregroundColor: foreground,
          ),
        ),
      ),
    );
  }
}

class _SelectedTextActionToolbarLayoutDelegate
    extends SingleChildLayoutDelegate {
  final Offset anchorAbove;
  final Offset anchorBelow;
  final EdgeInsets padding;

  const _SelectedTextActionToolbarLayoutDelegate({
    required this.anchorAbove,
    required this.anchorBelow,
    required this.padding,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const gapAbove = 10.0;
    const gapBelow = 18.0;

    final minX = padding.left;
    final maxX = math.max(minX, size.width - childSize.width - padding.right);
    final minY = padding.top;
    final maxY = math.max(
      minY,
      size.height - childSize.height - padding.bottom,
    );

    final fitsAbove = anchorAbove.dy - childSize.height - gapAbove >= minY;
    final fitsBelow = anchorBelow.dy + gapBelow <= maxY;
    final useAbove = fitsAbove || !fitsBelow;
    final anchor = useAbove ? anchorAbove : anchorBelow;

    final x = (anchor.dx - childSize.width / 2).clamp(minX, maxX);
    final preferredY = useAbove
        ? anchor.dy - childSize.height - gapAbove
        : anchor.dy + gapBelow;
    final y = preferredY.clamp(minY, maxY);

    return Offset(x.toDouble(), y.toDouble());
  }

  @override
  bool shouldRelayout(_SelectedTextActionToolbarLayoutDelegate oldDelegate) {
    return oldDelegate.anchorAbove != anchorAbove ||
        oldDelegate.anchorBelow != anchorBelow ||
        oldDelegate.padding != padding;
  }
}

import 'package:flutter/material.dart';
import 'flow_menu_entry.dart';

Widget buildMacOsMenuButton<T>({
  required List<FlowMenuEntry<T>> entries,
  required ValueChanged<T> onSelected,
  Widget? child,
  Widget Function(BuildContext, bool, VoidCallback)? builder,
  String? tooltip,
  Offset alignmentOffset = const Offset(0, 4),
  double? minWidth,
}) {
  return _MacOsFlowMenuButton<T>(
    entries: entries,
    onSelected: onSelected,
    builder: builder,
    tooltip: tooltip,
    alignmentOffset: alignmentOffset,
    minWidth: minWidth,
    child: child,
  );
}

class _MacOsFlowMenuButton<T> extends StatefulWidget {
  const _MacOsFlowMenuButton({
    required this.entries,
    required this.onSelected,
    this.builder,
    this.tooltip,
    this.alignmentOffset = const Offset(0, 4),
    this.minWidth,
    this.child,
  });

  final List<FlowMenuEntry<T>> entries;
  final ValueChanged<T> onSelected;
  final Widget? child;
  final Widget Function(BuildContext, bool, VoidCallback)? builder;
  final String? tooltip;
  final Offset alignmentOffset;
  final double? minWidth;

  @override
  State<_MacOsFlowMenuButton<T>> createState() =>
      _MacOsFlowMenuButtonState<T>();
}

class _MacOsFlowMenuButtonState<T> extends State<_MacOsFlowMenuButton<T>> {
  final GlobalKey _triggerKey = GlobalKey();
  bool _isOpen = false;

  void _toggle() {
    if (_isOpen) return;
    _open();
  }

  void _open() async {
    setState(() => _isOpen = true);

    final renderBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset =
        renderBox?.localToGlobal(Offset.zero, ancestor: overlay) ?? Offset.zero;
    final size = renderBox?.size ?? Size.zero;

    final menuWidth = widget.minWidth ?? _MacOsPopoverSurface.defaultMinWidth;
    final estimatedHeight = _MacOsPopoverSurface.estimatedHeight(
      widget.entries,
    );
    final left = (offset.dx + widget.alignmentOffset.dx).clamp(
      8.0,
      (overlay.size.width - menuWidth - 8).clamp(8.0, double.infinity),
    );
    final top = (offset.dy + size.height + widget.alignmentOffset.dy).clamp(
      8.0,
      (overlay.size.height - estimatedHeight - 8).clamp(8.0, double.infinity),
    );

    final selected = await showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 80),
      pageBuilder: (dialogContext, _, _) {
        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: _MacOsPopoverSurface<T>(
                entries: widget.entries,
                minWidth: widget.minWidth,
                onSelected: (value) => Navigator.of(dialogContext).pop(value),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    setState(() => _isOpen = false);
    if (selected != null) widget.onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    final trigger =
        widget.builder?.call(context, _isOpen, _toggle) ??
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggle,
          child: widget.child!,
        );
    final anchoredTrigger = KeyedSubtree(key: _triggerKey, child: trigger);

    if (widget.tooltip == null) return anchoredTrigger;
    return Tooltip(message: widget.tooltip!, child: anchoredTrigger);
  }
}

class _MacOsPopoverSurface<T> extends StatelessWidget {
  const _MacOsPopoverSurface({
    required this.entries,
    required this.onSelected,
    this.minWidth,
  });

  static const double defaultMinWidth = 180;
  static const double _itemHeight = 28;
  static const double _dividerInset = 10;
  static const double _dividerSpacing = 3;

  final List<FlowMenuEntry<T>> entries;
  final ValueChanged<T> onSelected;
  final double? minWidth;

  static double estimatedHeight<T>(List<FlowMenuEntry<T>> entries) {
    return entries.fold<double>(
      0,
      (height, entry) =>
          height +
          (entry is FlowMenuDivider<T> ? _dividerSpacing * 2 + 1 : _itemHeight),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.96)
        : colorScheme.surface.withValues(alpha: 0.98);

    return Container(
      key: const ValueKey('flow-menu-surface'),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.65 : 0.85,
          ),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.14),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: minWidth ?? defaultMinWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in entries)
              if (entry is FlowMenuDivider<T>)
                _MacOsMenuDivider(inset: _dividerInset)
              else if (entry is FlowMenuItem<T>)
                _MacOsMenuItem<T>(
                  entry: entry,
                  height: _itemHeight,
                  onSelected: onSelected,
                ),
          ],
        ),
      ),
    );
  }
}

class _MacOsMenuItem<T> extends StatefulWidget {
  const _MacOsMenuItem({
    required this.entry,
    required this.height,
    required this.onSelected,
  });

  final FlowMenuItem<T> entry;
  final double height;
  final ValueChanged<T> onSelected;

  @override
  State<_MacOsMenuItem<T>> createState() => _MacOsMenuItemState<T>();
}

class _MacOsMenuItemState<T> extends State<_MacOsMenuItem<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final foreground = entry.destructive
        ? colorScheme.error
        : entry.enabled
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.38);

    final iconColor = entry.destructive
        ? colorScheme.error
        : entry.enabled
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurface.withValues(alpha: 0.32);

    final bgColor = entry.enabled && _hovered
        ? colorScheme.primary.withValues(alpha: 0.10)
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: entry.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: entry.enabled ? () => widget.onSelected(entry.value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          color: bgColor,
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: entry.icon == null
                    ? const SizedBox.shrink()
                    : Icon(entry.icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (entry.selected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check, size: 14, color: colorScheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MacOsMenuDivider extends StatelessWidget {
  const _MacOsMenuDivider({required this.inset});

  final double inset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset, vertical: 3),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: colorScheme.outlineVariant.withValues(alpha: 0.45),
      ),
    );
  }
}

Future<T?> showMacOsMenuAt<T>({
  required BuildContext context,
  required Offset position,
  required List<FlowMenuEntry<T>> entries,
  double? minWidth,
}) {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final localPosition = overlay.globalToLocal(position);
  final width = minWidth ?? _MacOsPopoverSurface.defaultMinWidth;
  final estimatedHeight = _MacOsPopoverSurface.estimatedHeight(entries);
  final left = (localPosition.dx).clamp(
    8.0,
    (overlay.size.width - width - 8).clamp(8.0, double.infinity),
  );
  final top = (localPosition.dy).clamp(
    8.0,
    (overlay.size.height - estimatedHeight - 8).clamp(8.0, double.infinity),
  );

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 80),
    pageBuilder: (dialogContext, _, _) {
      return Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            child: _MacOsPopoverSurface<T>(
              entries: entries,
              minWidth: minWidth,
              onSelected: (value) => Navigator.of(dialogContext).pop(value),
            ),
          ),
        ],
      );
    },
  );
}

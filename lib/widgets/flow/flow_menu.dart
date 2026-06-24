import 'dart:math' as math;

import 'package:flow_design_system/flow_design_system.dart';
import 'package:flutter/material.dart';
import 'flow_menu_entry.dart';
import 'flow_menu_macos.dart';

export 'flow_menu_entry.dart';

class FlowMenuButton<T> extends StatefulWidget {
  const FlowMenuButton({
    super.key,
    required this.entries,
    required this.onSelected,
    this.child,
    this.builder,
    this.tooltip,
    this.alignmentOffset = const Offset(0, 8),
    this.minWidth,
  }) : assert(child != null || builder != null);

  final List<FlowMenuEntry<T>> entries;
  final ValueChanged<T> onSelected;
  final Widget? child;
  final Widget Function(
    BuildContext context,
    bool isOpen,
    VoidCallback toggle,
  )?
  builder;
  final String? tooltip;
  final Offset alignmentOffset;
  final double? minWidth;

  @override
  State<FlowMenuButton<T>> createState() => _FlowMenuButtonState<T>();
}

class _FlowMenuButtonState<T> extends State<FlowMenuButton<T>> {
  final MenuController _controller = MenuController();

  bool get _isMacOs {
    final shellId = FlowThemeData.of(context)?.shellId;
    return shellId == ShellId.macosStandard ||
        shellId == ShellId.macosLiquidGlass;
  }

  @override
  Widget build(BuildContext context) {
    if (_isMacOs) {
      return buildMacOsMenuButton<T>(
        entries: widget.entries,
        onSelected: widget.onSelected,
        child: widget.child,
        builder: widget.builder,
        tooltip: widget.tooltip,
        alignmentOffset: widget.alignmentOffset,
        minWidth: widget.minWidth,
      );
    }

    final shellId = FlowThemeData.of(context)?.shellId;
    if (shellId == ShellId.android && widget.child != null) {
      return PopupMenuButton<T>(
        tooltip: widget.tooltip,
        onSelected: widget.onSelected,
        itemBuilder: (context) => _popupEntries(context),
        child: widget.child,
      );
    }

    return MenuAnchor(
      controller: _controller,
      alignmentOffset: widget.alignmentOffset,
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        _FlowMenuSurface<T>(
          entries: widget.entries,
          minWidth: widget.minWidth,
          onSelected: (value) {
            _controller.close();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) widget.onSelected(value);
            });
          },
        ),
      ],
      builder: (context, controller, _) {
        void toggle() {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        }

        final built =
            widget.builder?.call(context, controller.isOpen, toggle) ??
            _FlowMenuTrigger(onTap: toggle, child: widget.child!);
        if (widget.tooltip == null) return built;
        return Tooltip(message: widget.tooltip!, child: built);
      },
    );
  }

  List<PopupMenuEntry<T>> _popupEntries(BuildContext context) {
    return [
      for (final entry in widget.entries)
        if (entry is FlowMenuDivider<T>)
          const PopupMenuDivider()
        else if (entry is FlowMenuItem<T>)
          PopupMenuItem<T>(
            value: entry.value,
            enabled: entry.enabled,
            child: _FlowPopupMenuItem(entry: entry),
          ),
    ];
  }
}

Future<T?> showFlowMenuAt<T>({
  required BuildContext context,
  required Offset position,
  required List<FlowMenuEntry<T>> entries,
  double? minWidth,
}) {
  final shellId = FlowThemeData.of(context)?.shellId;
  final isMacOs =
      shellId == ShellId.macosStandard || shellId == ShellId.macosLiquidGlass;

  if (isMacOs) {
    return showMacOsMenuAt<T>(
      context: context,
      position: position,
      entries: entries,
      minWidth: minWidth,
    );
  }

  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final localPosition = overlay.globalToLocal(position);
  final theme = Theme.of(context);
  final flowTheme = FlowThemeData.of(context);
  final width = minWidth ?? _FlowMenuSurface.defaultMinWidth;
  final estimatedHeight = _FlowMenuSurface.estimatedHeight(entries);
  final left = math.min(
    math.max(8.0, localPosition.dx),
    math.max(8.0, overlay.size.width - width - 8),
  );
  final top = math.min(
    math.max(8.0, localPosition.dy),
    math.max(8.0, overlay.size.height - estimatedHeight - 8),
  );

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 80),
    pageBuilder: (dialogContext, _, _) {
      return Theme(
        data: theme.copyWith(
          extensions: [
            ...theme.extensions.values.where(
              (extension) => extension is! FlowThemeData,
            ),
            ?flowTheme,
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: _FlowMenuSurface<T>(
                entries: entries,
                minWidth: minWidth,
                onSelected: (value) => Navigator.of(dialogContext).pop(value),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _FlowMenuTrigger extends StatelessWidget {
  const _FlowMenuTrigger({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}

class _FlowMenuSurface<T> extends StatelessWidget {
  const _FlowMenuSurface({
    required this.entries,
    required this.onSelected,
    this.minWidth,
  });

  static const double defaultMinWidth = 180;
  static const double _itemHeight = 44;
  static const double _dividerHeight = 9;

  final List<FlowMenuEntry<T>> entries;
  final ValueChanged<T> onSelected;
  final double? minWidth;

  static double estimatedHeight<T>(List<FlowMenuEntry<T>> entries) {
    return entries.fold<double>(
      0,
      (height, entry) =>
          height + (entry is FlowMenuDivider<T> ? _dividerHeight : _itemHeight),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shellId = FlowThemeData.of(context)?.shellId;
    final isMac =
        shellId == ShellId.macosStandard || shellId == ShellId.macosLiquidGlass;
    final radius = BorderRadius.circular(isMac ? 8 : 10);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.96)
        : colorScheme.surface.withValues(alpha: 0.98);

    return Material(
      key: const ValueKey('flow-menu-surface'),
      color: background,
      elevation: isMac ? 12 : 8,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.42 : 0.22),
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.72 : 0.95,
          ),
          width: 1,
        ),
      ),
      child: SizedBox(
        width: minWidth ?? defaultMinWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in entries)
              if (entry is FlowMenuDivider<T>)
                const _FlowMenuDivider()
              else if (entry is FlowMenuItem<T>)
                _FlowMenuItemTile<T>(
                  entry: entry,
                  onSelected: onSelected,
                ),
          ],
        ),
      ),
    );
  }
}

class _FlowMenuItemTile<T> extends StatelessWidget {
  const _FlowMenuItemTile({required this.entry, required this.onSelected});

  final FlowMenuItem<T> entry;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
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

    return InkWell(
      onTap: entry.enabled ? () => onSelected(entry.value) : null,
      splashFactory: NoSplash.splashFactory,
      hoverColor: colorScheme.primary.withValues(alpha: 0.12),
      focusColor: colorScheme.primary.withValues(alpha: 0.12),
      highlightColor: colorScheme.primary.withValues(alpha: 0.14),
      child: SizedBox(
        height: _FlowMenuSurface._itemHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: entry.icon == null
                    ? const SizedBox.shrink()
                    : Icon(entry.icon, size: 19, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (entry.selected) ...[
                const SizedBox(width: 16),
                Icon(Icons.check, size: 18, color: colorScheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowMenuDivider extends StatelessWidget {
  const _FlowMenuDivider();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(
        height: 1,
        thickness: 0.6,
        color: colorScheme.outlineVariant.withValues(alpha: 0.55),
      ),
    );
  }
}

class _FlowPopupMenuItem<T> extends StatelessWidget {
  const _FlowPopupMenuItem({required this.entry});

  final FlowMenuItem<T> entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = entry.destructive
        ? colorScheme.error
        : entry.enabled
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.38);

    return Row(
      children: [
        if (entry.icon != null) ...[
          Icon(entry.icon, size: 18, color: foreground),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            entry.label,
            style: TextStyle(color: foreground),
          ),
        ),
        if (entry.selected) ...[
          const SizedBox(width: 12),
          Icon(Icons.check, size: 18, color: colorScheme.primary),
        ],
      ],
    );
  }
}

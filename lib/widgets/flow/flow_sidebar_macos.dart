import 'package:flutter/material.dart';
import 'flow_sidebar.dart';

Widget buildMacOsBottomBar({
  required List<FlowSidebarDestination> destinations,
  required int selectedIndex,
  required ValueChanged<int> onDestinationSelected,
  Color? backgroundColor,
}) {
  return _MacOsBottomBar(
    destinations: destinations,
    selectedIndex: selectedIndex,
    onDestinationSelected: onDestinationSelected,
    backgroundColor: backgroundColor,
  );
}

class _MacOsBottomBar extends StatelessWidget {
  const _MacOsBottomBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.backgroundColor,
  });

  final List<FlowSidebarDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 48 + bottomPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.42),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < destinations.length; i++)
              _MacOsTabItem(
                destination: destinations[i],
                selected: i == selectedIndex,
                onTap: () => onDestinationSelected(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _MacOsTabItem extends StatelessWidget {
  const _MacOsTabItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final FlowSidebarDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fg = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;
    final iconWidget =
        selected && destination.selectedIcon != null
            ? destination.selectedIcon!
            : destination.icon;

    Widget item = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme.merge(
                data: IconThemeData(color: fg, size: 20),
                child: iconWidget,
              ),
              const SizedBox(height: 2),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (destination.tooltip != null) {
      item = Tooltip(message: destination.tooltip!, child: item);
    }

    return item;
  }
}

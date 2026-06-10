import 'package:flow_design_system/flow_design_system.dart';
import 'package:flutter/material.dart';

enum FlowSidebarVariant { auto, vertical, bottom }

class FlowSidebarDestination {
  const FlowSidebarDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.tooltip,
  });

  final Widget icon;
  final Widget? selectedIcon;
  final String label;
  final String? tooltip;
}

class FlowSidebar extends StatelessWidget {
  const FlowSidebar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.variant = FlowSidebarVariant.auto,
    this.backgroundColor,
    this.width,
  });

  const FlowSidebar.bottom({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.backgroundColor,
  }) : variant = FlowSidebarVariant.bottom,
       width = null;

  const FlowSidebar.vertical({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.backgroundColor,
    this.width,
  }) : variant = FlowSidebarVariant.vertical;

  final List<FlowSidebarDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final FlowSidebarVariant variant;
  final Color? backgroundColor;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final effectiveVariant = switch (variant) {
      FlowSidebarVariant.auto =>
        MediaQuery.sizeOf(context).width >= 720
            ? FlowSidebarVariant.vertical
            : FlowSidebarVariant.bottom,
      FlowSidebarVariant.vertical => FlowSidebarVariant.vertical,
      FlowSidebarVariant.bottom => FlowSidebarVariant.bottom,
    };

    return switch (effectiveVariant) {
      FlowSidebarVariant.vertical => _VerticalFlowSidebar(
        destinations: destinations,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        backgroundColor: backgroundColor,
        width: width,
      ),
      FlowSidebarVariant.bottom => _BottomFlowSidebar(
        destinations: destinations,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        backgroundColor: backgroundColor,
      ),
      FlowSidebarVariant.auto => const SizedBox.shrink(),
    };
  }
}

class _BottomFlowSidebar extends StatelessWidget {
  const _BottomFlowSidebar({
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
    return NavigationBar(
      backgroundColor: backgroundColor,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        for (final destination in destinations)
          NavigationDestination(
            icon: destination.icon,
            selectedIcon: destination.selectedIcon,
            label: destination.label,
            tooltip: destination.tooltip,
          ),
      ],
    );
  }
}

class _VerticalFlowSidebar extends StatelessWidget {
  const _VerticalFlowSidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.backgroundColor,
    this.width,
  });

  final List<FlowSidebarDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Color? backgroundColor;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flowTheme = FlowThemeData.of(context);
    final navigationTokens = flowTheme?.navigationTokens;
    final sidebarWidth = width ?? navigationTokens?.sidebarWidth ?? 240;
    final itemRadius = navigationTokens?.itemRadius ?? BorderRadius.circular(8);
    final iconSize = navigationTokens?.iconSize ?? 22;
    final selectedColor = theme.colorScheme.primary.withValues(alpha: 0.12);
    final labelStyle = theme.textTheme.labelLarge;

    return Material(
      color: backgroundColor ?? theme.colorScheme.surface,
      child: SizedBox(
        width: sidebarWidth,
        child: SafeArea(
          bottom: false,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            itemCount: destinations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final destination = destinations[index];
              final selected = index == selectedIndex;
              final icon = selected && destination.selectedIcon != null
                  ? destination.selectedIcon!
                  : destination.icon;
              final item = InkWell(
                borderRadius: itemRadius,
                onTap: () => onDestinationSelected(index),
                child: AnimatedContainer(
                  duration:
                      flowTheme?.buttonTokens.animationDuration ??
                      const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  constraints: const BoxConstraints(minHeight: 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? selectedColor : Colors.transparent,
                    borderRadius: itemRadius,
                  ),
                  child: Row(
                    children: [
                      IconTheme.merge(
                        data: IconThemeData(
                          size: iconSize,
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        child: icon,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          destination.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: labelStyle?.copyWith(
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );

              if (destination.tooltip == null) {
                return item;
              }
              return Tooltip(message: destination.tooltip!, child: item);
            },
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flow_read_atmosphere/flow_read_atmosphere.dart';
import 'package:flutter/material.dart';

import '../../theme/app_constants.dart';
import '../../theme/app_surface_tokens.dart';
import '../theme_mode_cycle_button.dart';
import 'reading_stats_ring.dart';

class HomeSidebar extends StatefulWidget {
  final int currentTab;
  final ValueChanged<int> onTabChanged;
  final int readingTimeSeconds;
  final int monthReadingTimeSeconds;
  final List<int> weekDailyReadingSeconds;
  final List<int> monthDailyReadingSeconds;
  final DateTime? goalDate;
  final int dailyReadingGoalSeconds;
  final VoidCallback onSettingsTap;
  final VoidCallback onThemeToggle;
  final ThemeMode nextThemeMode;
  final bool showRss;

  const HomeSidebar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
    required this.readingTimeSeconds,
    this.monthReadingTimeSeconds = 0,
    this.weekDailyReadingSeconds = const [0, 0, 0, 0, 0, 0, 0],
    this.monthDailyReadingSeconds = const [],
    this.goalDate,
    required this.dailyReadingGoalSeconds,
    required this.onSettingsTap,
    required this.onThemeToggle,
    required this.nextThemeMode,
    required this.showRss,
  });

  @override
  State<HomeSidebar> createState() => _HomeSidebarState();
}

class _HomeSidebarState extends State<HomeSidebar> {
  static const _logoAsset = 'assets/brand/flow_read_logo.png';

  final _readingGoalKey = GlobalKey();
  OverlayEntry? _readingGoalOverlay;

  @override
  void dispose() {
    _readingGoalOverlay?.remove();
    _readingGoalOverlay = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _readingGoalOverlay?.markNeedsBuild();
  }

  void _toggleReadingGoalPanel() {
    if (_readingGoalOverlay == null) {
      _showReadingGoalPanel();
    } else {
      _hideReadingGoalPanel();
    }
  }

  void _showReadingGoalPanel() {
    final overlay = Overlay.of(context);
    final box =
        _readingGoalKey.currentContext?.findRenderObject() as RenderBox?;
    final cardOffset = box?.localToGlobal(Offset.zero) ?? Offset.zero;

    _readingGoalOverlay = OverlayEntry(
      builder: (context) {
        final mediaSize = MediaQuery.sizeOf(context);
        final panelWidth = (mediaSize.width - AppConstants.sidebarWidth - 28)
            .clamp(400.0, 480.0)
            .toDouble();
        const preferredPanelHeight = 700.0;
        final maxTop = math.max(
          16.0,
          mediaSize.height - preferredPanelHeight - 16,
        );
        final top = math.min(math.max(cardOffset.dy, 16.0), maxTop);

        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _hideReadingGoalPanel,
                ),
              ),
              Positioned(
                left: AppConstants.sidebarWidth + 12,
                top: top,
                width: panelWidth,
                child: ReadingGoalDetailsPanel(
                  weekTotalSeconds: widget.readingTimeSeconds,
                  monthTotalSeconds: widget.monthReadingTimeSeconds,
                  weekDailySeconds: widget.weekDailyReadingSeconds,
                  monthDailySeconds: widget.monthDailyReadingSeconds,
                  dailyGoalSeconds: widget.dailyReadingGoalSeconds,
                  goalDate: widget.goalDate ?? DateTime.now(),
                  onClose: _hideReadingGoalPanel,
                ),
              ),
            ],
          ),
        );
      },
    );
    overlay.insert(_readingGoalOverlay!);
    setState(() {});
  }

  void _hideReadingGoalPanel() {
    _readingGoalOverlay?.remove();
    _readingGoalOverlay = null;
    if (mounted) setState(() {});
  }

  static const _navItems = [
    (
      tabIndex: 0,
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      label: '书架',
    ),
    (
      tabIndex: 1,
      icon: Icons.rss_feed_outlined,
      selectedIcon: Icons.rss_feed,
      label: 'RSS',
    ),
    (
      tabIndex: 3,
      icon: Icons.text_fields_outlined,
      selectedIcon: Icons.text_fields,
      label: '词汇',
    ),
    (
      tabIndex: 4,
      icon: Icons.person_outlined,
      selectedIcon: Icons.person,
      label: '我的',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppSurfaceTokens.of(context);
    final cityPreset = CityThemeScope.maybeOf(context)?.preset;
    final topSpacing = 12 + AppConstants.immersiveTitleBarTopInset;

    return Container(
      width: AppConstants.sidebarWidth,
      color:
          cityPreset?.surface.withValues(alpha: 0.72) ??
          tokens.leftWorkspaceColor,
      child: Column(
        children: [
          SizedBox(height: topSpacing),
          _buildBrandHeader(theme),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  _buildSectionLabel(theme, '导航'),
                  _buildNavItems(theme, cityPreset),
                  const SizedBox(height: 28),
                  _buildSectionLabel(theme, '阅读目标'),
                  const SizedBox(height: 10),
                  ReadingStatsRing(
                    key: _readingGoalKey,
                    totalSeconds: widget.readingTimeSeconds,
                    dailyGoalSeconds: widget.dailyReadingGoalSeconds,
                    isExpanded: _readingGoalOverlay != null,
                    onTap: _toggleReadingGoalPanel,
                  ),
                ],
              ),
            ),
          ),
          _buildBottomActions(theme),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItems(ThemeData theme, CityThemePreset? cityPreset) {
    final navItems = _navItems
        .where((item) => widget.showRss || item.tabIndex != 1)
        .toList(growable: false);

    return Column(
      children: List.generate(navItems.length, (index) {
        final item = navItems[index];
        final isSelected = widget.currentTab == item.tabIndex;
        return _buildNavItem(
          theme: theme,
          cityPreset: cityPreset,
          icon: isSelected ? item.selectedIcon : item.icon,
          label: item.label,
          isSelected: isSelected,
          onTap: () {
            _hideReadingGoalPanel();
            widget.onTabChanged(item.tabIndex);
          },
        );
      }),
    );
  }

  Widget _buildBrandHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: Image.asset(_logoAsset, filterQuality: FilterQuality.high),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Flow Read',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required ThemeData theme,
    required CityThemePreset? cityPreset,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected
            ? (cityPreset?.surfaceSoft.withValues(alpha: 0.72) ??
                  theme.colorScheme.primaryContainer)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: theme.colorScheme.onSurfaceVariant,
            onPressed: () {
              _hideReadingGoalPanel();
              widget.onSettingsTap();
            },
            tooltip: '设置',
          ),
          ThemeModeCycleButton(
            nextMode: widget.nextThemeMode,
            color: theme.colorScheme.onSurfaceVariant,
            onPressed: widget.onThemeToggle,
          ),
        ],
      ),
    );
  }
}

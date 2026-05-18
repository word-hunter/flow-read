import 'package:flutter/material.dart';
import '../../theme/app_constants.dart';
import 'reading_stats_ring.dart';

class HomeSidebar extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTabChanged;
  final int readingTimeSeconds;
  final VoidCallback onSettingsTap;
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  final bool showRss;
  final bool showBrowser;

  const HomeSidebar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
    required this.readingTimeSeconds,
    required this.onSettingsTap,
    required this.onThemeToggle,
    required this.isDarkMode,
    required this.showRss,
    required this.showBrowser,
  });

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
      tabIndex: 2,
      icon: Icons.language_outlined,
      selectedIcon: Icons.language,
      label: '浏览器',
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
    final topSpacing = 16 + AppConstants.immersiveTitleBarTopInset;

    return Container(
      width: AppConstants.sidebarWidth,
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          SizedBox(height: topSpacing),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  _buildSectionLabel(theme, '导航'),
                  _buildNavItems(theme),
                  const SizedBox(height: 28),
                  _buildSectionLabel(theme, '阅读目标'),
                  const SizedBox(height: 10),
                  ReadingStatsRing(totalSeconds: readingTimeSeconds),
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

  Widget _buildNavItems(ThemeData theme) {
    final navItems = _navItems
        .where(
          (item) =>
              (showRss || item.tabIndex != 1) &&
              (showBrowser || item.tabIndex != 2),
        )
        .toList(growable: false);

    return Column(
      children: List.generate(navItems.length, (index) {
        final item = navItems[index];
        final isSelected = currentTab == item.tabIndex;
        return _buildNavItem(
          theme: theme,
          icon: isSelected ? item.selectedIcon : item.icon,
          label: item.label,
          isSelected: isSelected,
          onTap: () => onTabChanged(item.tabIndex),
        );
      }),
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
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
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
            onPressed: onSettingsTap,
            tooltip: '设置',
          ),
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            color: theme.colorScheme.onSurfaceVariant,
            onPressed: onThemeToggle,
            tooltip: isDarkMode ? '浅色模式' : '深色模式',
          ),
        ],
      ),
    );
  }
}

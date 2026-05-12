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

  const HomeSidebar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
    required this.readingTimeSeconds,
    required this.onSettingsTap,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  static const _navItems = [
    (icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book, label: '书架'),
    (icon: Icons.rss_feed_outlined, selectedIcon: Icons.rss_feed, label: 'RSS'),
    (icon: Icons.text_fields_outlined, selectedIcon: Icons.text_fields, label: '词汇'),
    (icon: Icons.person_outlined, selectedIcon: Icons.person, label: '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: AppConstants.sidebarWidth,
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildLogo(theme),
          const SizedBox(height: 32),
          _buildNavItems(theme),
          const Spacer(),
          ReadingStatsRing(totalSeconds: readingTimeSeconds),
          const Spacer(),
          _buildBottomActions(theme),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  Widget _buildLogo(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(Icons.auto_stories, color: theme.colorScheme.primary, size: 32),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FlowRead',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '阅读·探索·成长',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItems(ThemeData theme) {
    return Column(
      children: List.generate(_navItems.length, (index) {
        final item = _navItems[index];
        final isSelected = currentTab == index;
        return _buildNavItem(
          theme: theme,
          icon: isSelected ? item.selectedIcon : item.icon,
          label: item.label,
          isSelected: isSelected,
          onTap: () => onTabChanged(index),
        );
      }),
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
        color: isSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
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
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
            icon: Icon(isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            color: theme.colorScheme.onSurfaceVariant,
            onPressed: onThemeToggle,
            tooltip: isDarkMode ? '浅色模式' : '深色模式',
          ),
        ],
      ),
    );
  }
}

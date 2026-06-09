import 'package:flutter/material.dart';

import '../theme_transition.dart';

typedef ThemeMutationRunner = Future<void> Function(ThemeMutation mutation);

enum SettingsSection {
  appearance,
  reading,
  dictionary,
  ai,
  backup,
  experiments,
  about,
}

extension SettingsSectionMeta on SettingsSection {
  String get title {
    switch (this) {
      case SettingsSection.appearance:
        return '外观';
      case SettingsSection.reading:
        return '阅读';
      case SettingsSection.dictionary:
        return '词典';
      case SettingsSection.ai:
        return 'AI 设置';
      case SettingsSection.backup:
        return '备份与同步';
      case SettingsSection.experiments:
        return '测试功能';
      case SettingsSection.about:
        return '关于';
    }
  }

  String get subtitle {
    switch (this) {
      case SettingsSection.appearance:
        return '调整主题、颜色模式与词汇标记色。';
      case SettingsSection.reading:
        return '设置首页阅读目标和阅读节奏。';
      case SettingsSection.dictionary:
        return '管理查词来源和本地缓存。';
      case SettingsSection.ai:
        return '配置 AI 服务商、模型、密钥与连接状态。';
      case SettingsSection.backup:
        return '管理本地数据备份、自动同步与恢复。';
      case SettingsSection.experiments:
        return '管理仍在测试中的入口和功能项。';
      case SettingsSection.about:
        return '版本信息、更新检查、问题反馈与诊断日志。';
    }
  }

  IconData get icon {
    switch (this) {
      case SettingsSection.appearance:
        return Icons.palette_outlined;
      case SettingsSection.reading:
        return Icons.flag_outlined;
      case SettingsSection.dictionary:
        return Icons.menu_book_outlined;
      case SettingsSection.ai:
        return Icons.auto_awesome;
      case SettingsSection.backup:
        return Icons.cloud_sync_outlined;
      case SettingsSection.experiments:
        return Icons.science_outlined;
      case SettingsSection.about:
        return Icons.info_outline;
    }
  }
}

class LanguageOption {
  const LanguageOption({required this.code, required this.name});

  final String code;
  final String name;
}

class SettingsSidebarItem extends StatelessWidget {
  const SettingsSidebarItem({
    super.key,
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final SettingsSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          mouseCursor: SystemMouseCursors.click,
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 4,
                  height: selected ? 36 : 0,
                  decoration: BoxDecoration(
                    color: selected ? colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 14),
                Icon(
                  section.icon,
                  size: 22,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    section.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsSectionHeading extends StatelessWidget {
  const SettingsSectionHeading({super.key, required this.section});

  final SettingsSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(section.icon, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                section.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          section.subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      elevation: 1,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.05),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 21, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class SettingsStatusLine extends StatelessWidget {
  const SettingsStatusLine({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class ResponsiveSettingsGrid extends StatelessWidget {
  const ResponsiveSettingsGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 680 || children.length == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _separateWithSpacing(
              children,
              const SizedBox(height: 12),
            ),
          );
        }

        final itemWidth = (constraints.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }

  List<Widget> _separateWithSpacing(List<Widget> children, Widget spacing) {
    return [
      for (var i = 0; i < children.length; i++) ...[
        if (i != 0) spacing,
        children[i],
      ],
    ];
  }
}

List<Widget> settingsChildrenWithSpacing(
  List<Widget> children,
  Widget spacing,
) {
  return [
    for (var i = 0; i < children.length; i++) ...[
      if (i != 0) spacing,
      children[i],
    ],
  ];
}

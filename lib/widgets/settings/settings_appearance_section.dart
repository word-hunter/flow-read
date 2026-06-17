import 'package:flutter/material.dart';
import 'package:flow_design_system/flow_design_system.dart';

import '../../services/settings_service.dart';
import 'settings_shared.dart';

class SettingsAppearanceSection extends StatelessWidget {
  const SettingsAppearanceSection({
    super.key,
    required this.settings,
    required this.onSwitchTheme,
  });

  final SettingsService settings;
  final ThemeMutationRunner onSwitchTheme;

  static const _colorOptions = [
    _ColorOption('红色', Color(0xFFE74C3C)),
    _ColorOption('橙色', Color(0xFFE67E22)),
    _ColorOption('黄色', Color(0xFFF1C40F)),
    _ColorOption('绿色', Color(0xFF27AE60)),
    _ColorOption('蓝色', Color(0xFF2980B9)),
    _ColorOption('紫色', Color(0xFF8E44AD)),
    _ColorOption('粉色', Color(0xFFE91E63)),
    _ColorOption('青色', Color(0xFF009688)),
    _ColorOption('灰色', Color(0xFF999999)),
    _ColorOption('深色', Color(0xFF34495E)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          icon: Icons.style_outlined,
          title: '主题',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsOptionRow(
                title: '主题风格',
                subtitle: '选择 FlowRead 的整体视觉风格。',
                trailingWidth: 390,
                trailing: SettingsSelectField<PaletteId>(
                  label: '主题风格',
                  value: settings.appThemeId,
                  icon: Icons.style_outlined,
                  options: PaletteId.values
                      .map(
                        (themeId) => SettingsSelectOption(
                          value: themeId,
                          label: themeId.label,
                          icon: themeId.icon,
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    onSwitchTheme(() => settings.setAppThemeId(value));
                  },
                ),
              ),
              const SettingsCardDivider(),
              SettingsOptionRow(
                title: '颜色模式',
                subtitle: '控制应用在浅色、深色或跟随系统之间的显示方式。',
                trailingWidth: 430,
                trailing: _ThemeModeControl(
                  settings: settings,
                  onSwitchTheme: onSwitchTheme,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsCard(
          icon: Icons.format_color_fill_outlined,
          title: '词汇标记',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ColorRow(
                label: '生词颜色',
                subtitle: '用于标记尚未掌握的单词。',
                currentColor: settings.colors.unknownColor,
                onColorChanged: settings.setUnknownColor,
                colorOptions: _colorOptions,
              ),
              const SettingsCardDivider(),
              _ColorRow(
                label: '学习中颜色',
                subtitle: '用于标记正在学习和复习中的单词。',
                currentColor: settings.colors.learningColor,
                onColorChanged: settings.setLearningColor,
                colorOptions: _colorOptions,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _VocabularyPreviewCard(
          unknownColor: settings.colors.unknownColor,
          learningColor: settings.colors.learningColor,
          colorOptions: _colorOptions,
        ),
      ],
    );
  }
}

class _ThemeModeControl extends StatelessWidget {
  const _ThemeModeControl({
    required this.settings,
    required this.onSwitchTheme,
  });

  final SettingsService settings;
  final ThemeMutationRunner onSwitchTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = colorScheme.outlineVariant.withValues(alpha: 0.76);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: SizedBox(
          height: 46,
          child: Row(
            children: [
              _ThemeModeSegment(
                mode: ThemeMode.system,
                label: '系统',
                icon: Icons.desktop_windows_outlined,
                selected: settings.themeMode == ThemeMode.system,
                onSelected: () {
                  onSwitchTheme(() => settings.setThemeMode(ThemeMode.system));
                },
              ),
              _ThemeModeDivider(color: borderColor),
              _ThemeModeSegment(
                mode: ThemeMode.light,
                label: '浅色',
                icon: Icons.light_mode_outlined,
                selected: settings.themeMode == ThemeMode.light,
                onSelected: () {
                  onSwitchTheme(() => settings.setThemeMode(ThemeMode.light));
                },
              ),
              _ThemeModeDivider(color: borderColor),
              _ThemeModeSegment(
                mode: ThemeMode.dark,
                label: '深色',
                icon: Icons.dark_mode_outlined,
                selected: settings.themeMode == ThemeMode.dark,
                onSelected: () {
                  onSwitchTheme(() => settings.setThemeMode(ThemeMode.dark));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeModeDivider extends StatelessWidget {
  const _ThemeModeDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1,
      height: double.infinity,
      child: ColoredBox(color: color),
    );
  }
}

class _ThemeModeSegment extends StatelessWidget {
  const _ThemeModeSegment({
    required this.mode,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  final ThemeMode mode;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedBackground = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: 0.10),
      colorScheme.surfaceContainerHighest,
    );
    final foreground = selected
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.88);

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Tooltip(
          message: label,
          child: Material(
            color: selected ? selectedBackground : Colors.transparent,
            child: InkWell(
              onTap: selected ? null : onSelected,
              mouseCursor: selected
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.click,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: foreground),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        maxLines: 1,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.subtitle,
    required this.currentColor,
    required this.onColorChanged,
    required this.colorOptions,
  });

  final String label;
  final String subtitle;
  final Color currentColor;
  final ValueChanged<Color> onColorChanged;
  final List<_ColorOption> colorOptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
            letterSpacing: 0,
          ),
        ),
      ],
    );

    final swatches = Wrap(
      spacing: 14,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: colorOptions.map((option) {
        final selected = currentColor.toARGB32() == option.color.toARGB32();
        return Tooltip(
          message: option.name,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkResponse(
              customBorder: const CircleBorder(),
              onTap: () => onColorChanged(option.color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                width: 44,
                height: 44,
                padding: EdgeInsets.all(selected ? 3 : 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? colorScheme.primary : Colors.transparent,
                    width: selected ? 2 : 0,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: option.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: option.color.withValues(alpha: 0.24),
                        blurRadius: 9,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: selected
                      ? Icon(
                          Icons.check,
                          color: _foregroundFor(option.color),
                          size: 20,
                        )
                      : null,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 680) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              labelBlock,
              const SizedBox(height: 14),
              Align(alignment: Alignment.centerLeft, child: swatches),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: labelBlock),
            const SizedBox(width: 28),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: swatches,
              ),
            ),
          ],
        );
      },
    );
  }

  static Color _foregroundFor(Color color) {
    return color.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;
  }
}

class _VocabularyPreviewCard extends StatelessWidget {
  const _VocabularyPreviewCard({
    required this.unknownColor,
    required this.learningColor,
    required this.colorOptions,
  });

  final Color unknownColor;
  final Color learningColor;
  final List<_ColorOption> colorOptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SettingsCard(
      icon: Icons.visibility_outlined,
      title: '实时预览',
      subtitle: '在阅读内容中查看词汇标记的实际效果。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.34 : 0.74,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(
                  alpha: 0.65,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text.rich(
                TextSpan(
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.55,
                    letterSpacing: 0,
                  ),
                  children: [
                    const TextSpan(text: 'FlowRead 帮助你更高效地阅读与学习。生词会以 '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: _PreviewColorChip(
                        label: _labelFor(unknownColor),
                        color: unknownColor,
                      ),
                    ),
                    const TextSpan(text: ' 标记，学习中的词以 '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: _PreviewColorChip(
                        label: _labelFor(learningColor),
                        color: learningColor,
                      ),
                    ),
                    const TextSpan(text: ' 标记，轻松掌握每一个新词。'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SettingsStatusLine(
            icon: Icons.lightbulb_outline,
            text: '预览基于当前主题与颜色设置。',
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  String _labelFor(Color color) {
    for (final option in colorOptions) {
      if (option.color.toARGB32() == color.toARGB32()) return option.name;
    }
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}

class _PreviewColorChip extends StatelessWidget {
  const _PreviewColorChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = Color.alphaBlend(
      color.withValues(alpha: 0.86),
      theme.colorScheme.onSurface,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.24 : 0.15,
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorOption {
  const _ColorOption(this.name, this.color);

  final String name;
  final Color color;
}

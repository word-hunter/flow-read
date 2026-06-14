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
    _ColorOption('Red', Color(0xFFE74C3C)),
    _ColorOption('Orange', Color(0xFFE67E22)),
    _ColorOption('Yellow', Color(0xFFF1C40F)),
    _ColorOption('Green', Color(0xFF27AE60)),
    _ColorOption('Blue', Color(0xFF2980B9)),
    _ColorOption('Purple', Color(0xFF8E44AD)),
    _ColorOption('Pink', Color(0xFFE91E63)),
    _ColorOption('Teal', Color(0xFF009688)),
    _ColorOption('Grey', Color(0xFF999999)),
    _ColorOption('Dark', Color(0xFF34495E)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          icon: Icons.style_outlined,
          title: '主题',
          child: ResponsiveSettingsGrid(
            children: [
              SettingsSelectField<PaletteId>(
                label: '主题',
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
              _ThemeModeControl(
                settings: settings,
                onSwitchTheme: onSwitchTheme,
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
                currentColor: settings.colors.unknownColor,
                onColorChanged: settings.setUnknownColor,
                colorOptions: _colorOptions,
              ),
              const SizedBox(height: 18),
              _ColorRow(
                label: '学习中颜色',
                currentColor: settings.colors.learningColor,
                onColorChanged: settings.setLearningColor,
                colorOptions: _colorOptions,
              ),
            ],
          ),
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
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '颜色模式',
        prefixIcon: Icon(Icons.contrast_outlined, size: 20),
        border: OutlineInputBorder(),
      ),
      child: SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(Icons.devices_outlined),
            label: Text('系统'),
          ),
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.light_mode_outlined),
            label: Text('浅色'),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.dark_mode_outlined),
            label: Text('深色'),
          ),
        ],
        selected: {settings.themeMode},
        onSelectionChanged: (value) {
          onSwitchTheme(() => settings.setThemeMode(value.first));
        },
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.currentColor,
    required this.onColorChanged,
    required this.colorOptions,
  });

  final String label;
  final Color currentColor;
  final ValueChanged<Color> onColorChanged;
  final List<_ColorOption> colorOptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colorOptions.map((option) {
              final selected =
                  currentColor.toARGB32() == option.color.toARGB32();
              return Tooltip(
                message: option.name,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onColorChanged(option.color),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: option.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.outlineVariant,
                        width: selected ? 3 : 1,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ColorOption {
  const _ColorOption(this.name, this.color);

  final String name;
  final Color color;
}

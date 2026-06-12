import 'package:flow_read_atmosphere/flow_read_atmosphere.dart';
import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
import 'settings_shared.dart';

class SettingsCityAtmosphereSection extends StatelessWidget {
  const SettingsCityAtmosphereSection({super.key, required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    final citySettings = settings.cityAtmosphereSettings;
    final enabled = citySettings.enabled;
    final preset = CityThemeResolver.resolve(
      now: DateTime.now(),
      settings: citySettings,
    );
    final scene = AtmosphereSceneResolver.resolve(
      preset: preset,
      settings: citySettings,
    );

    return SettingsCard(
      icon: Icons.location_city_outlined,
      title: 'City 阅读氛围',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('开启 City 阅读氛围'),
            subtitle: Text(
              enabled ? '${preset.label} · ${scene.label}' : '保持当前阅读主题',
            ),
            value: enabled,
            onChanged: settings.setCityAtmosphereEnabled,
          ),
          const SizedBox(height: 12),
          _CityAtmospherePreview(preset: preset, scene: scene),
          const SizedBox(height: 16),
          _SectionLabel(text: '主题模式', enabled: enabled),
          const SizedBox(height: 8),
          SegmentedButton<CityThemeMode>(
            segments: [
              for (final mode in CityThemeMode.values)
                ButtonSegment(value: mode, label: Text(mode.label)),
            ],
            selected: {citySettings.themeMode},
            onSelectionChanged: enabled
                ? (value) {
                    if (value.isEmpty) return;
                    settings.setCityThemeMode(value.first);
                  }
                : null,
          ),
          if (enabled && citySettings.themeMode == CityThemeMode.manual) ...[
            const SizedBox(height: 14),
            SettingsSelectField<String>(
              label: '手动主题',
              value: CityThemePresets.byId(
                citySettings.manualThemeId,
              ).id,
              icon: Icons.palette_outlined,
              options: [
                for (final preset in CityThemePresets.all)
                  SettingsSelectOption(value: preset.id, label: preset.label),
              ],
              onChanged: settings.setManualCityTheme,
            ),
          ],
          const SizedBox(height: 16),
          SettingsSelectField<AtmosphereBlendMode>(
            label: '动态背景',
            value: citySettings.blendMode,
            icon: Icons.auto_awesome_motion_outlined,
            options: [
              for (final mode in AtmosphereBlendMode.values)
                SettingsSelectOption(value: mode, label: mode.label),
            ],
            enabled: enabled,
            onChanged: enabled ? settings.setAtmosphereBlendMode : null,
          ),
          if (enabled &&
              citySettings.blendMode == AtmosphereBlendMode.manualOverride) ...[
            const SizedBox(height: 14),
            SettingsSelectField<AtmosphereScene>(
              label: '手动氛围',
              value: _manualSceneValue(citySettings.manualScene),
              icon: Icons.filter_drama_outlined,
              options: [
                for (final scene in _manualSceneOptions)
                  SettingsSelectOption(value: scene, label: scene.label),
              ],
              onChanged: settings.setManualAtmosphereScene,
            ),
          ],
          const SizedBox(height: 16),
          _SectionLabel(text: '强度', enabled: enabled),
          Slider(
            value: citySettings.normalizedIntensity,
            min: 0,
            max: 1,
            divisions: 10,
            label: '${(citySettings.normalizedIntensity * 100).round()}%',
            onChanged:
                enabled &&
                    citySettings.blendMode != AtmosphereBlendMode.off &&
                    !citySettings.reduceMotion
                ? settings.setAtmosphereIntensity
                : null,
          ),
          const SizedBox(height: 8),
          _SectionLabel(text: '性能模式', enabled: enabled),
          const SizedBox(height: 8),
          SegmentedButton<AtmospherePerformanceMode>(
            segments: [
              for (final mode in AtmospherePerformanceMode.values)
                ButtonSegment(value: mode, label: Text(mode.label)),
            ],
            selected: {citySettings.performanceMode},
            onSelectionChanged: enabled
                ? (value) {
                    if (value.isEmpty) return;
                    settings.setAtmospherePerformanceMode(value.first);
                  }
                : null,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('减少动态效果'),
            value: citySettings.reduceMotion,
            onChanged: enabled ? settings.setReduceAtmosphereMotion : null,
          ),
        ],
      ),
    );
  }

  static const _manualSceneOptions = <AtmosphereScene>[
    AtmosphereScene.none,
    AtmosphereScene.cityLandscapeDay,
    AtmosphereScene.cityRain,
    AtmosphereScene.cityWind,
    AtmosphereScene.cityStormHint,
  ];

  static AtmosphereScene _manualSceneValue(AtmosphereScene scene) {
    return _manualSceneOptions.contains(scene) ? scene : AtmosphereScene.none;
  }
}

class _CityAtmospherePreview extends StatelessWidget {
  const _CityAtmospherePreview({required this.preset, required this.scene});

  final CityThemePreset preset;
  final AtmosphereScene scene;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [preset.surfaceSoft, preset.pageBackground],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: preset.outline.withValues(alpha: 0.78)),
      ),
      child: SizedBox(
        height: 92,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: preset.accent.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  _iconFor(scene),
                  color: preset.primaryText.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: preset.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scene.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: preset.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(AtmosphereScene scene) {
    return switch (scene) {
      AtmosphereScene.cityMorning => Icons.wb_twilight_outlined,
      AtmosphereScene.cityDay => Icons.wb_sunny_outlined,
      AtmosphereScene.cityLandscapeDay => Icons.landscape_outlined,
      AtmosphereScene.cityDusk => Icons.wb_twilight,
      AtmosphereScene.cityMoon => Icons.nightlight_round,
      AtmosphereScene.cityRain => Icons.water_drop_outlined,
      AtmosphereScene.cityWind => Icons.air,
      AtmosphereScene.cityStormHint => Icons.thunderstorm_outlined,
      AtmosphereScene.none => Icons.layers_clear_outlined,
    };
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.enabled});

  final String text;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        color: enabled
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

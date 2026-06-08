import 'package:flutter/widgets.dart';

import 'city_atmosphere_settings.dart';
import 'city_theme_preset.dart';

class CityThemeScope extends InheritedWidget {
  final CityThemePreset preset;
  final CityAtmosphereSettings settings;

  const CityThemeScope({
    super.key,
    required this.preset,
    required this.settings,
    required super.child,
  });

  static CityThemeScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CityThemeScope>();
  }

  static CityThemePreset of(BuildContext context) {
    return maybeOf(context)?.preset ?? CityThemePresets.cityDay;
  }

  @override
  bool updateShouldNotify(CityThemeScope oldWidget) {
    return oldWidget.preset.id != preset.id || oldWidget.settings != settings;
  }
}

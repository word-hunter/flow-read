import 'package:flutter/widgets.dart';

import 'atmosphere_background.dart';
import 'city_atmosphere_settings.dart';
import 'city_theme_resolver.dart';
import 'city_theme_scope.dart';

typedef CityAtmosphereClock = DateTime Function();

class CityAtmosphere extends StatelessWidget {
  final CityAtmosphereSettings settings;
  final Widget child;
  final bool enabled;
  final CityAtmosphereClock clock;

  const CityAtmosphere({
    super.key,
    required this.settings,
    required this.child,
    this.enabled = true,
    this.clock = DateTime.now,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled || !settings.enabled) {
      return child;
    }

    final preset = CityThemeResolver.resolve(
      now: clock(),
      settings: settings,
    );
    final scene = AtmosphereSceneResolver.resolve(
      preset: preset,
      settings: settings,
    );
    final intensity = settings.normalizedIntensity.clamp(0.0, 1.0).toDouble();

    return CityThemeScope(
      preset: preset,
      settings: settings,
      child: AtmosphereBackground(
        scene: scene,
        intensity: intensity,
        reduceMotion: settings.reduceMotion,
        performanceMode: settings.performanceMode,
        child: child,
      ),
    );
  }
}

import 'package:flow_read_atmosphere/flow_read_atmosphere.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AtmosphereBackground does not block child taps', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      CityThemeScope(
        preset: CityThemePresets.cityDawn,
        settings: const CityAtmosphereSettings(enabled: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: AtmosphereBackground(
            scene: AtmosphereScene.cityMorning,
            child: Center(
              child: GestureDetector(
                key: const ValueKey('tap-target'),
                behavior: HitTestBehavior.opaque,
                onTap: () => taps += 1,
                child: const SizedBox(width: 80, height: 80),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('tap-target')));

    expect(taps, 1);
  });

  testWidgets('reduceMotion keeps the background static', (tester) async {
    await tester.pumpWidget(
      CityThemeScope(
        preset: CityThemePresets.cityDawn,
        settings: const CityAtmosphereSettings(
          enabled: true,
          reduceMotion: true,
        ),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: AtmosphereBackground(
            scene: AtmosphereScene.cityMorning,
            reduceMotion: true,
            child: SizedBox(width: 80, height: 80),
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsOneWidget);
  });

  testWidgets('city landscape day paints through the atmosphere layer', (
    tester,
  ) async {
    await tester.pumpWidget(
      CityThemeScope(
        preset: CityThemePresets.cityDay,
        settings: const CityAtmosphereSettings(enabled: true),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: AtmosphereBackground(
            scene: AtmosphereScene.cityLandscapeDay,
            child: SizedBox(width: 80, height: 80),
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsOneWidget);
  });

  testWidgets('zero intensity keeps the theme without dynamic paint', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CityAtmosphere(
          settings: const CityAtmosphereSettings(
            enabled: true,
            atmosphereIntensity: 0,
          ),
          clock: () => DateTime(2026, 6, 9, 6),
          child: const SizedBox(width: 80, height: 80),
        ),
      ),
    );

    expect(find.byType(CityThemeScope), findsOneWidget);
    expect(find.byType(CustomPaint), findsNothing);
  });

  testWidgets('CityAtmosphere creates a scope only when enabled', (
    tester,
  ) async {
    CityThemePreset? scopedPreset;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CityAtmosphere(
          enabled: false,
          settings: const CityAtmosphereSettings(enabled: true),
          child: Builder(
            builder: (context) {
              scopedPreset = CityThemeScope.maybeOf(context)?.preset;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(scopedPreset, isNull);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CityAtmosphere(
          settings: const CityAtmosphereSettings(enabled: true),
          clock: () => DateTime(2026, 6, 9, 18),
          child: Builder(
            builder: (context) {
              scopedPreset = CityThemeScope.maybeOf(context)?.preset;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(scopedPreset?.phase, CityTimePhase.dusk);
  });
}

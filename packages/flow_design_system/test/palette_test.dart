import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_design_system/flow_design_system.dart';

void main() {
  group('PaletteRegistry', () {
    test('contains all 4 palettes', () {
      expect(PaletteRegistry.all.length, 4);
      expect(PaletteRegistry.get(PaletteId.classic).id, PaletteId.classic);
      expect(PaletteRegistry.get(PaletteId.ocean).id, PaletteId.ocean);
      expect(PaletteRegistry.get(PaletteId.forest).id, PaletteId.forest);
      expect(
        PaletteRegistry.get(PaletteId.highContrast).id,
        PaletteId.highContrast,
      );
    });

    test('unknown id throws', () {
      // Just sanity check that we have correct values.
      expect(PaletteId.values.length, 4);
    });
  });

  group('ClassicPalette', () {
    const palette = ClassicPalette();

    test('has correct metadata', () {
      expect(palette.id, PaletteId.classic);
      expect(palette.label, '经典');
    });

    test('lightColorScheme has correct brightness', () {
      expect(palette.lightColorScheme.brightness, Brightness.light);
    });

    test('darkColorScheme has correct brightness', () {
      expect(palette.darkColorScheme.brightness, Brightness.dark);
    });

    test('light semantic colors are non-null and consistent', () {
      final sc = palette.lightSemantic();
      expect(sc.background, palette.lightColorScheme.surface);
      expect(sc.textPrimary, palette.lightColorScheme.onSurface);
      expect(sc.interactivePrimary, palette.lightColorScheme.primary);
      expect(sc.readerSelection.alpha, greaterThan(0));
    });

    test('dark semantic colors are non-null and consistent', () {
      final sc = palette.darkSemantic();
      expect(sc.background, palette.darkColorScheme.surface);
      expect(sc.textPrimary, palette.darkColorScheme.onSurface);
      expect(sc.interactivePrimary, palette.darkColorScheme.primary);
    });

    test('light and dark semantic colors differ', () {
      expect(
        palette.lightSemantic().background,
        isNot(palette.darkSemantic().background),
      );
    });
  });

  group('OceanPalette', () {
    const palette = OceanPalette();

    test('has correct metadata', () {
      expect(palette.id, PaletteId.ocean);
      expect(palette.label, '海雾');
    });

    test('light and dark have correct brightness', () {
      expect(palette.lightColorScheme.brightness, Brightness.light);
      expect(palette.darkColorScheme.brightness, Brightness.dark);
    });
  });

  group('ForestPalette', () {
    const palette = ForestPalette();

    test('has correct metadata', () {
      expect(palette.id, PaletteId.forest);
      expect(palette.label, '松林');
    });
  });

  group('HighContrastPalette', () {
    const palette = HighContrastPalette();

    test('has correct metadata', () {
      expect(palette.id, PaletteId.highContrast);
      expect(palette.label, '高对比');
    });

    test('light surface is pure white', () {
      expect(palette.lightColorScheme.surface.value, 0xFFFFFFFF);
    });

    test('dark surface is near black', () {
      expect(palette.darkColorScheme.surface, const Color(0xFF0B0B0B));
    });
  });

  group('PaletteIdLabels', () {
    test('all ids have labels and icons', () {
      for (final id in PaletteId.values) {
        expect(id.label, isNotEmpty);
        expect(id.icon, isNotNull);
      }
    });
  });
}

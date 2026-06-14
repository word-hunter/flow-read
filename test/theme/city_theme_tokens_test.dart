import 'package:flow_design_system/flow_design_system.dart';
import 'package:flow_read/theme/app_surface_tokens.dart';
import 'package:flow_read/theme/city_theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ThemeData _buildCityTheme(Brightness brightness) {
  final base = FlowTheme.build(
    shellId: ShellId.macosStandard,
    paletteId: PaletteId.classic,
    brightness: brightness,
  );
  return base.copyWith(
    extensions: [
      ...base.extensions.values,
      brightness == Brightness.dark
          ? AppSurfaceTokens.cityDark()
          : AppSurfaceTokens.cityLight(),
      CityThemeTokens.forBrightness(brightness),
    ],
  );
}

void main() {
  test('city light theme exposes city color and surface tokens', () {
    final theme = _buildCityTheme(Brightness.light);
    final city = theme.extension<CityThemeTokens>();
    final surface = theme.extension<AppSurfaceTokens>();

    expect(city, isNotNull);
    expect(city!.activeBlue, const Color(0xFF0277FE));
    expect(city.shellSurface, const Color(0xFFFEFAF3));
    expect(surface, isNotNull);
    expect(surface!.leftWorkspaceColor, const Color(0xFFFEFAF3));
    expect(surface.readerOpaqueSurface, const Color(0xFFFEFCF8));
  });

  test('city dark theme uses dark city tokens', () {
    final theme = _buildCityTheme(Brightness.dark);
    final city = theme.extension<CityThemeTokens>();
    final surface = theme.extension<AppSurfaceTokens>();

    expect(city, isNotNull);
    expect(city!.activeBlue, const Color(0xFF5DB0FF));
    expect(city.shellSurface, const Color(0xFF1A2233));
    expect(surface, isNotNull);
    expect(surface!.leftWorkspaceColor, const Color(0xFF1A2233));
    expect(surface.readerOpaqueSurface, const Color(0xFF121926));
  });
}

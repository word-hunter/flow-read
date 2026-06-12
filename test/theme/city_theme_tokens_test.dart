import 'package:flow_read/theme/app_surface_tokens.dart';
import 'package:flow_read/theme/app_theme.dart';
import 'package:flow_read/theme/city_theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('city light theme exposes city color and surface tokens', () {
    final theme = AppTheme.lightThemeFor(AppThemeId.classic);
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
    final theme = AppTheme.darkThemeFor(AppThemeId.classic);
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

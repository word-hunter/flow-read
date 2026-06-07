import 'package:flutter_test/flutter_test.dart';
import 'package:flow_design_system/flow_design_system.dart';

void main() {
  group('ReaderLayoutConfig', () {
    test('resolve returns workspace for desktop on wide screens', () {
      final config = ReaderLayoutConfig.resolve(
        shellId: ShellId.macosStandard,
        screenWidth: 1200,
      );
      expect(config.mode, ReaderLayoutMode.workspace);
      expect(config.sidebarVisibleByDefault, isTrue);
      expect(config.toolbarVisible, isTrue);
      expect(config.showChapterNav, isTrue);
    });

    test('resolve returns compact for desktop on narrow screens', () {
      final config = ReaderLayoutConfig.resolve(
        shellId: ShellId.macosStandard,
        screenWidth: 800,
      );
      expect(config.mode, ReaderLayoutMode.compact);
      expect(config.sidebarVisibleByDefault, isFalse);
    });

    test('resolve returns workspace for windows on wide screens', () {
      final config = ReaderLayoutConfig.resolve(
        shellId: ShellId.windows,
        screenWidth: 1200,
      );
      expect(config.mode, ReaderLayoutMode.workspace);
      expect(config.sidebarWidth, 256);
      expect(config.contentMaxWidth, 860);
      expect(config.toolbarHeight, 40);
    });

    test('resolve returns workspace for macosLiquidGlass on wide screens', () {
      final config = ReaderLayoutConfig.resolve(
        shellId: ShellId.macosLiquidGlass,
        screenWidth: 1200,
      );
      expect(config.mode, ReaderLayoutMode.workspace);
      expect(config.sidebarWidth, 240);
      expect(config.toolbarHeight, 38);
    });

    test('resolve returns compact for mobile shells', () {
      for (final shellId in [
        ShellId.ios,
        ShellId.android,
      ]) {
        final config = ReaderLayoutConfig.resolve(
          shellId: shellId,
          screenWidth: 1200,
        );
        expect(config.mode, ReaderLayoutMode.compact,
            reason: '$shellId should be compact even on wide screens');
        expect(config.sidebarVisibleByDefault, isFalse);
      }
    });

    test('resolve at breakpoint boundary (900)', () {
      final configWide = ReaderLayoutConfig.resolve(
        shellId: ShellId.macosStandard,
        screenWidth: 900,
      );
      expect(configWide.mode, ReaderLayoutMode.workspace);

      final configNarrow = ReaderLayoutConfig.resolve(
        shellId: ShellId.macosStandard,
        screenWidth: 899,
      );
      expect(configNarrow.mode, ReaderLayoutMode.compact);
    });

    test('ios compact layout has correct values', () {
      final config = ReaderLayoutConfig.resolve(
        shellId: ShellId.ios,
        screenWidth: 400,
      );
      expect(config.contentMaxWidth, 720);
      expect(config.toolbarHeight, 44);
      expect(config.showChapterNav, isFalse);
    });

    test('android compact layout has correct values', () {
      final config = ReaderLayoutConfig.resolve(
        shellId: ShellId.android,
        screenWidth: 400,
      );
      expect(config.contentMaxWidth, 800);
    });

    test('immersive layout has no chrome', () {
      final config = ReaderLayoutConfig.immersive();
      expect(config.mode, ReaderLayoutMode.immersive);
      expect(config.sidebarWidth, 0);
      expect(config.toolbarHeight, 0);
      expect(config.sidebarVisibleByDefault, isFalse);
      expect(config.toolbarVisible, isFalse);
      expect(config.showChapterNav, isFalse);
    });

    test('all shells return valid configs', () {
      for (final shellId in ShellId.values) {
        for (final width in [400.0, 800.0, 1200.0, 2000.0]) {
          final config = ReaderLayoutConfig.resolve(
            shellId: shellId,
            screenWidth: width,
          );
          expect(config.mode, isA<ReaderLayoutMode>());
          expect(config.contentMaxWidth, greaterThan(0));
        }
      }
    });
  });

  group('ReaderShellConfig', () {
    test('forShell returns correct config per shell', () {
      // macOS Liquid Glass - prefers glass
      final glassConfig = ReaderShellConfig.forShell(
        ShellId.macosLiquidGlass,
        screenWidth: 1200,
      );
      expect(glassConfig.prefersGlassSurface, isTrue);
      expect(glassConfig.showScrollbar, isFalse);

      // Windows - shows scrollbar
      final windowsConfig = ReaderShellConfig.forShell(
        ShellId.windows,
        screenWidth: 1200,
      );
      expect(windowsConfig.prefersGlassSurface, isFalse);
      expect(windowsConfig.showScrollbar, isTrue);

      // macOS Standard - no glass, no scrollbar
      final macConfig = ReaderShellConfig.forShell(
        ShellId.macosStandard,
        screenWidth: 1200,
      );
      expect(macConfig.prefersGlassSurface, isFalse);
      expect(macConfig.showScrollbar, isFalse);

      // iOS - no scrollbar
      final iosConfig = ReaderShellConfig.forShell(
        ShellId.ios,
        screenWidth: 400,
      );
      expect(iosConfig.showScrollbar, isFalse);

      // Android - shows scrollbar
      final androidConfig = ReaderShellConfig.forShell(
        ShellId.android,
        screenWidth: 400,
      );
      expect(androidConfig.showScrollbar, isTrue);
    });

    test('forShell delegates layout to ReaderLayoutConfig', () {
      final config = ReaderShellConfig.forShell(
        ShellId.macosStandard,
        screenWidth: 1200,
      );
      expect(config.layout.mode, ReaderLayoutMode.workspace);

      final configNarrow = ReaderShellConfig.forShell(
        ShellId.macosStandard,
        screenWidth: 800,
      );
      expect(configNarrow.layout.mode, ReaderLayoutMode.compact);
    });

    test('forShell applies shell-specific font/line height steps', () {
      final macConfig = ReaderShellConfig.forShell(
        ShellId.macosStandard,
        screenWidth: 1200,
      );
      expect(macConfig.fontSizeStep, 1.0);
      expect(macConfig.lineHeightStep, 0.1);

      final androidConfig = ReaderShellConfig.forShell(
        ShellId.android,
        screenWidth: 400,
      );
      expect(androidConfig.fontSizeStep, 2.0);
      expect(androidConfig.lineHeightStep, 0.2);
    });

    test('all shells return valid ReaderShellConfig', () {
      for (final shellId in ShellId.values) {
        final config = ReaderShellConfig.forShell(
          shellId,
          screenWidth: 1200,
        );
        expect(config.layout, isA<ReaderLayoutConfig>());
        expect(config.fontSizeStep, greaterThan(0));
        expect(config.lineHeightStep, greaterThan(0));
      }
    });
  });
}

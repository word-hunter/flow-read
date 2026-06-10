import 'package:flutter_test/flutter_test.dart';
import 'package:flow_read/layout/width_class_policy.dart';
import 'package:flow_read/layout/reader_layout_policy.dart';
import 'package:flow_read/layout/reader_layout_spec.dart';
import 'package:flow_read/layout/app_platform_class.dart';

void main() {
  group('WidthClass', () {
    test('compact below 760', () {
      expect(WidthClass.resolve(300), WidthClass.compact);
      expect(WidthClass.resolve(759), WidthClass.compact);
    });

    test('medium 760 to 1199', () {
      expect(WidthClass.resolve(760), WidthClass.medium);
      expect(WidthClass.resolve(1199), WidthClass.medium);
    });

    test('wide 1200 to 1439', () {
      expect(WidthClass.resolve(1200), WidthClass.wide);
      expect(WidthClass.resolve(1439), WidthClass.wide);
    });

    test('workspace 1440+', () {
      expect(WidthClass.resolve(1440), WidthClass.workspace);
      expect(WidthClass.resolve(2000), WidthClass.workspace);
    });
  });

  group('ReaderLayoutPolicy', () {
    test('desktop wide with feature enabled returns workspace', () {
      final spec = ReaderLayoutPolicy.resolveLayout(
        platform: AppPlatformClass.desktop,
        width: 1440,
        workspaceFeatureEnabled: true,
        userRequestedImmersive: false,
      );
      expect(spec.shellKind, ReaderShellKind.desktopWorkspace);
      expect(spec.isWorkspace, true);
      expect(spec.tocHost, TocPanelHost.leftWorkspace);
      expect(spec.leftPanelOpenByDefault, true);
    });

    test('desktop wide can restore left panel closed', () {
      final spec = ReaderLayoutPolicy.resolveLayout(
        platform: AppPlatformClass.desktop,
        width: 1440,
        workspaceFeatureEnabled: true,
        userRequestedImmersive: false,
        restoreLeftPanelOpen: false,
      );
      expect(spec.leftPanelOpenByDefault, false);
    });

    test('desktop wide with feature disabled returns immersive', () {
      final spec = ReaderLayoutPolicy.resolveLayout(
        platform: AppPlatformClass.desktop,
        width: 1440,
        workspaceFeatureEnabled: false,
        userRequestedImmersive: false,
      );
      expect(spec.shellKind, ReaderShellKind.immersive);
      expect(spec.tocHost, TocPanelHost.sheet);
    });

    test(
      'desktop medium with feature enabled returns immersive with drawer',
      () {
        final spec = ReaderLayoutPolicy.resolveLayout(
          platform: AppPlatformClass.desktop,
          width: 900,
          workspaceFeatureEnabled: true,
          userRequestedImmersive: false,
        );
        expect(spec.shellKind, ReaderShellKind.immersive);
        expect(spec.tocHost, TocPanelHost.drawer);
      },
    );

    test('desktop compact returns immersive', () {
      final spec = ReaderLayoutPolicy.resolveLayout(
        platform: AppPlatformClass.desktop,
        width: 500,
        workspaceFeatureEnabled: true,
        userRequestedImmersive: false,
      );
      expect(spec.shellKind, ReaderShellKind.immersive);
      expect(spec.tocHost, TocPanelHost.sheet);
    });

    test('user requested immersive overrides workspace', () {
      final spec = ReaderLayoutPolicy.resolveLayout(
        platform: AppPlatformClass.desktop,
        width: 1440,
        workspaceFeatureEnabled: true,
        userRequestedImmersive: true,
      );
      expect(spec.shellKind, ReaderShellKind.immersive);
    });

    test('non-desktop platform always immersive', () {
      for (final platform in [
        AppPlatformClass.tablet,
        AppPlatformClass.phone,
      ]) {
        final spec = ReaderLayoutPolicy.resolveLayout(
          platform: platform,
          width: 1440,
          workspaceFeatureEnabled: true,
          userRequestedImmersive: false,
        );
        expect(spec.shellKind, ReaderShellKind.immersive);
      }
    });
  });
}

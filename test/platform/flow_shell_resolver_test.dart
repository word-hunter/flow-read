import 'package:flow_design_system/flow_design_system.dart';
import 'package:flow_read/platform/flow_shell_resolver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowShellResolver', () {
    test('registers desktop shells that the app can route to', () {
      expect(
        FlowShellResolver.availableShells,
        containsAll([
          ShellId.android,
          ShellId.ios,
          ShellId.macosStandard,
          ShellId.windows,
        ]),
      );
    });

    test('routes Windows to Fluent shell', () {
      expect(
        FlowShellResolver.resolve(
          platform: TargetPlatform.windows,
          isWeb: false,
        ),
        ShellId.windows,
      );
    });

    test('routes Linux to the explicit desktop standard shell', () {
      expect(
        FlowShellResolver.resolve(
          platform: TargetPlatform.linux,
          isWeb: false,
        ),
        ShellId.macosStandard,
      );
    });

    test('does not fallback Windows or Linux to Android', () {
      expect(
        FlowShellResolver.resolve(
          platform: TargetPlatform.windows,
          isWeb: false,
        ),
        isNot(ShellId.android),
      );
      expect(
        FlowShellResolver.resolve(
          platform: TargetPlatform.linux,
          isWeb: false,
        ),
        isNot(ShellId.android),
      );
    });

    test('keeps Android and iOS routed to their native mobile shells', () {
      expect(
        FlowShellResolver.resolve(
          platform: TargetPlatform.android,
          isWeb: false,
        ),
        ShellId.android,
      );
      expect(
        FlowShellResolver.resolve(platform: TargetPlatform.iOS, isWeb: false),
        ShellId.ios,
      );
    });
  });
}

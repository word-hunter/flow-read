import 'package:flow_design_system/flow_design_system.dart';
import 'package:flutter/foundation.dart';

class FlowShellResolver {
  const FlowShellResolver._();

  static const availableShells = {
    ShellId.android,
    ShellId.ios,
    ShellId.macosStandard,
    ShellId.windows,
  };

  static ShellId resolve({
    required TargetPlatform platform,
    bool isWeb = kIsWeb,
  }) {
    if (isWeb) {
      return ShellId.android;
    }

    return switch (platform) {
      TargetPlatform.macOS => ShellId.macosStandard,
      TargetPlatform.windows => ShellId.windows,
      // Linux is currently treated as a desktop shell with the macOS standard
      // layout tokens. It must not inherit Android Material defaults.
      TargetPlatform.linux => ShellId.macosStandard,
      TargetPlatform.iOS => ShellId.ios,
      TargetPlatform.android || TargetPlatform.fuchsia => ShellId.android,
    };
  }

  static ShellId resolveCurrent() {
    final shellId = resolve(platform: defaultTargetPlatform, isWeb: kIsWeb);
    if (availableShells.contains(shellId)) {
      return shellId;
    }
    return ShellId.macosStandard;
  }
}

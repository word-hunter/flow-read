import 'package:flutter/foundation.dart';

enum PlatformCapability {
  glassBlur,
  acrylicBlur,
  micaMaterial,
}

class PlatformCapabilityDetector {
  PlatformCapabilityDetector._();

  static bool isSupported(PlatformCapability capability) {
    switch (capability) {
      case PlatformCapability.glassBlur:
        return defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.iOS;
      case PlatformCapability.acrylicBlur:
        return defaultTargetPlatform == TargetPlatform.windows;
      case PlatformCapability.micaMaterial:
        return defaultTargetPlatform == TargetPlatform.windows;
    }
  }

  static bool get supportsBackdropFilter {
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.windows;
  }
}

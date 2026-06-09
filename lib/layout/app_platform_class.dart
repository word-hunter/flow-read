import 'package:flutter/foundation.dart';

enum AppPlatformClass { desktop, tablet, phone }

class AppPlatformClassPolicy {
  const AppPlatformClassPolicy._();

  static AppPlatformClass get current {
    if (kIsWeb) return AppPlatformClass.desktop;
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return AppPlatformClass.desktop;
      case TargetPlatform.iOS:
        return AppPlatformClass.phone;
      case TargetPlatform.android:
        return AppPlatformClass.phone;
      case TargetPlatform.fuchsia:
        return AppPlatformClass.phone;
    }
  }
}

import 'package:flutter/painting.dart';

abstract class ButtonTokens {
  BorderRadius get borderRadius;
  EdgeInsets get paddingSmall;
  EdgeInsets get paddingMedium;
  EdgeInsets get paddingLarge;
  double get minHeight;
  Duration get animationDuration;
}

abstract class CardTokens {
  BorderRadius get borderRadius;
  double get elevation;
  EdgeInsets get padding;
  Color? get backgroundColor;
}

abstract class NavigationTokens {
  double get sidebarWidth;
  double get collapsedSidebarWidth;
  BorderRadius get itemRadius;
  double get iconSize;
}

class _AndroidButtonTokens implements ButtonTokens {
  const _AndroidButtonTokens();

  @override
  BorderRadius get borderRadius => BorderRadius.circular(20);
  @override
  EdgeInsets get paddingSmall => const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );
  @override
  EdgeInsets get paddingMedium => const EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 10,
  );
  @override
  EdgeInsets get paddingLarge => const EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 14,
  );
  @override
  double get minHeight => 40;
  @override
  Duration get animationDuration => const Duration(milliseconds: 200);
}

class _AndroidCardTokens implements CardTokens {
  const _AndroidCardTokens();

  @override
  BorderRadius get borderRadius => BorderRadius.circular(16);
  @override
  double get elevation => 0;
  @override
  EdgeInsets get padding => const EdgeInsets.all(16);
  @override
  Color? get backgroundColor => null;
}

class _AndroidNavigationTokens implements NavigationTokens {
  const _AndroidNavigationTokens();

  @override
  double get sidebarWidth => 260;
  @override
  double get collapsedSidebarWidth => 72;
  @override
  BorderRadius get itemRadius => BorderRadius.circular(16);
  @override
  double get iconSize => 24;
}

const ButtonTokens androidButtonTokens = _AndroidButtonTokens();
const CardTokens androidCardTokens = _AndroidCardTokens();
const NavigationTokens androidNavigationTokens = _AndroidNavigationTokens();

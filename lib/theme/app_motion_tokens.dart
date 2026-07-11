import 'package:flutter/animation.dart';

class ReaderMotionTokens {
  const ReaderMotionTokens._();

  static const panelOpenDuration = Duration(milliseconds: 220);
  static const panelCloseDuration = Duration(milliseconds: 180);
  static const panelSwitchDuration = Duration(milliseconds: 140);

  static const strongEaseOut = Cubic(0.23, 1, 0.32, 1);
  static const openCurve = strongEaseOut;
  static const closeCurve = strongEaseOut;

  static const reducedMotionDuration = Duration(milliseconds: 80);
}

class ReaderPanelWidths {
  const ReaderPanelWidths._();

  static const double leftPanelDefault = 288;
  static const double leftPanelMin = 240;
  static const double leftPanelMax = 360;

  static const double rightPanelDefault = 360;
  static const double rightPanelMin = 320;
  static const double rightPanelMax = 460;

  static const double centerMin = 520;
  static const double readerMaxWidth = 680;
}

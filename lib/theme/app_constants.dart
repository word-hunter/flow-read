import 'package:flutter/foundation.dart';

abstract final class AppConstants {
  static const double layoutBreakpoint = 600;
  static const double wideBreakpoint = 900;
  static const double sidebarWidth = 260;
  static double get immersiveTitleBarTopInset =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS ? 40 : 0;
  static const double readerMaxWidth = 700;
  static const int syntaxLimit = 8;
  static const int minWordLength = 3;
  static const int longSentenceThreshold = 30;
  static const int veryLongSentenceThreshold = 25;
  static const double familiarityCutoff = 0.75;
  static const int familiarityLengthCutoff = 5;
  static const int quizItemCount = 12;
  static const int quizSeed = 42;
}

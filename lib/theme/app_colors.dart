import 'package:flutter/material.dart';

@Deprecated('Use FunctionalColors from package:flow_design_system instead')
abstract final class AppColors {
  static const familiarityLow = Color(0xFFE74C3C);
  static const familiarityMediumLow = Color(0xFFE67E22);
  static const familiarityMedium = Color(0xFF2980B9);
  static const familiarityHigh = Color(0xFF27AE60);
  static const vocabLearning = Color(0xFF8E44AD);
  static const vocabKnown = Color(0xFF999999);

  static const correct = Color(0xFF27AE60);
  static const incorrect = Color(0xFFE74C3C);

  static const practiceInference = Color(0xFF8E44AD);
  static const practiceVocab = Color(0xFF2980B9);
  static const practiceSentence = Color(0xFF27AE60);
  static const practiceParaphrasing = Color(0xFFE67E22);
  static const practiceDefault = Color(0xFF7F8C8D);

  static Color familiarityColor(double score) {
    if (score <= 0.3) return familiarityLow;
    if (score <= 0.5) return vocabLearning;
    if (score <= 0.7) return familiarityMedium;
    return familiarityHigh;
  }
}

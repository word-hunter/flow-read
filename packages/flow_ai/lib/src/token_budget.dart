import 'dart:convert';

import 'prompt_builder.dart';

class AnalysisTokenConfig {
  const AnalysisTokenConfig._();

  static const int chapterInputMaxChars = 12000;
  static const double chapterOversizeRatio = 1.5;
  static const int synthesisInputMaxTokens = 15000;
  static const int synthesisOutputMaxTokens = 4000;
  static const int synthesisMaxCharacters = 30;
  static const int synthesisMaxEvents = 50;
  static const double heuristicSafetyMargin = 0.2;
}

class TokenEstimator {
  const TokenEstimator({
    this.safetyMargin = AnalysisTokenConfig.heuristicSafetyMargin,
  });

  final double safetyMargin;

  int estimate(String text) {
    if (text.isEmpty) return 0;
    final englishWords = _englishWord.allMatches(text).length;
    final chineseChars = _cjkCharacter.allMatches(text).length;
    final remainingChars = text
        .replaceAll(_englishWord, '')
        .replaceAll(_cjkCharacter, '')
        .replaceAll(RegExp(r'\s+'), '')
        .length;
    final rawEstimate =
        englishWords * 1.3 + chineseChars * 2.0 + remainingChars / 4.0;
    return (rawEstimate * (1 + safetyMargin)).ceil();
  }

  int estimatePrompt(PromptBuildResult prompt) {
    return estimate('${prompt.systemPrompt}\n\n${prompt.userPrompt}');
  }

  int estimateJson(Object? value) {
    return estimate(jsonEncode(value));
  }
}

class TokenBudget {
  const TokenBudget({
    this.maxInputTokens = AnalysisTokenConfig.synthesisInputMaxTokens,
    this.reservedOutputTokens = AnalysisTokenConfig.synthesisOutputMaxTokens,
    this.estimator = const TokenEstimator(),
  });

  final int maxInputTokens;
  final int reservedOutputTokens;
  final TokenEstimator estimator;

  int get availableInputTokens {
    final available = maxInputTokens - reservedOutputTokens;
    return available < 0 ? 0 : available;
  }

  bool checkFit(String prompt) {
    return estimator.estimate(prompt) + reservedOutputTokens <= maxInputTokens;
  }

  bool checkPrompt(PromptBuildResult prompt) {
    return estimatePrompt(prompt) + reservedOutputTokens <= maxInputTokens;
  }

  int estimatePrompt(PromptBuildResult prompt) {
    return estimator.estimatePrompt(prompt);
  }

  TokenBudget copyWith({
    int? maxInputTokens,
    int? reservedOutputTokens,
    TokenEstimator? estimator,
  }) {
    return TokenBudget(
      maxInputTokens: maxInputTokens ?? this.maxInputTokens,
      reservedOutputTokens: reservedOutputTokens ?? this.reservedOutputTokens,
      estimator: estimator ?? this.estimator,
    );
  }
}

final _englishWord = RegExp(r"[A-Za-z]+(?:['-][A-Za-z]+)?");
final _cjkCharacter = RegExp(r'[\u4e00-\u9fff]');

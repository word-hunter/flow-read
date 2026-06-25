class TokenUsageInfo {
  const TokenUsageInfo({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  static const empty = TokenUsageInfo(
    promptTokens: 0,
    completionTokens: 0,
    totalTokens: 0,
  );

  static TokenUsageInfo? tryFromJson(Map<String, dynamic> json) {
    final rawUsage = json['usage'];
    if (rawUsage is! Map<String, dynamic>) return null;

    return TokenUsageInfo(
      promptTokens: _readTokenCount(rawUsage['prompt_tokens']),
      completionTokens: _readTokenCount(rawUsage['completion_tokens']),
      totalTokens: _readTokenCount(rawUsage['total_tokens']),
    );
  }

  bool get isEmpty =>
      promptTokens == 0 && completionTokens == 0 && totalTokens == 0;

  Map<String, int> toJson() => {
    'prompt_tokens': promptTokens,
    'completion_tokens': completionTokens,
    'total_tokens': totalTokens,
  };

  static int _readTokenCount(Object? value) {
    if (value is num) return value.toInt();
    return 0;
  }
}

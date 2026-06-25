import 'token_usage_info.dart';

class AIResult<T> {
  const AIResult({
    required this.value,
    required this.providerId,
    required this.model,
    this.usage,
    this.cacheHit = false,
    this.cacheKey,
    this.durationMs = 0,
    this.promptVersion,
  });

  final T value;
  final TokenUsageInfo? usage;
  final bool cacheHit;
  final String? cacheKey;
  final int durationMs;
  final String providerId;
  final String model;
  final int? promptVersion;
}

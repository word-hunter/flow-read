import 'package:flow_ai/flow_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses OpenAI-compatible usage object', () {
    final usage = TokenUsageInfo.tryFromJson({
      'usage': {
        'prompt_tokens': 1523,
        'completion_tokens': 418,
        'total_tokens': 1941,
      },
    });

    expect(usage?.promptTokens, 1523);
    expect(usage?.completionTokens, 418);
    expect(usage?.totalTokens, 1941);
    expect(usage?.isEmpty, isFalse);
  });

  test('returns null when usage object is absent', () {
    expect(TokenUsageInfo.tryFromJson({'choices': []}), isNull);
  });

  test('uses zero for missing usage fields', () {
    final usage = TokenUsageInfo.tryFromJson({
      'usage': {'prompt_tokens': 12.0},
    });

    expect(usage?.promptTokens, 12);
    expect(usage?.completionTokens, 0);
    expect(usage?.totalTokens, 0);
  });
}

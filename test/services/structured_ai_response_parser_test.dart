import 'package:flow_ai/flow_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = StructuredAIResponseParser();

  test('parses JSON wrapped in a markdown fence', () async {
    final result = await parser.parseStructuredResponse<BookSynthesisResult>(
      rawResponse: '```json\n{"fullStoryline":"cached"}\n```',
      parser: BookSynthesisResult.fromJson,
      repairFn: (_) async => fail('repair should not be called'),
      fallback: BookSynthesisResult.fallback(rawResponse: 'fallback'),
    );

    expect(result.fullStoryline, 'cached');
  });

  test('repairs simple trailing commas and truncated braces locally', () async {
    final result = await parser.parseStructuredResponse<BookSynthesisResult>(
      rawResponse: '{"fullStoryline":"repaired","keyInsights":["one",],',
      parser: BookSynthesisResult.fromJson,
      repairFn: (_) async => fail('repair should not be called'),
      fallback: BookSynthesisResult.fallback(rawResponse: 'fallback'),
    );

    expect(result.fullStoryline, 'repaired');
    expect(result.keyInsights, ['one']);
  });

  test('asks repair function before returning fallback', () async {
    var repairCalls = 0;
    final result = await parser.parseStructuredResponse<BookSynthesisResult>(
      rawResponse: 'not json',
      parser: BookSynthesisResult.fromJson,
      repairFn: (_) async {
        repairCalls += 1;
        return '{"fullStoryline":"model repaired"}';
      },
      fallback: BookSynthesisResult.fallback(rawResponse: 'fallback'),
    );

    expect(repairCalls, 1);
    expect(result.fullStoryline, 'model repaired');
  });

  test('returns fallback when response and repair are invalid', () async {
    final fallback = BookSynthesisResult.fallback(rawResponse: 'broken');
    final result = await parser.parseStructuredResponse<BookSynthesisResult>(
      rawResponse: '{"fullStoryline": 42}',
      parser: BookSynthesisResult.fromJson,
      repairFn: (_) async => '{"fullStoryline": 42}',
      fallback: fallback,
    );

    expect(result, same(fallback));
    expect(result.fullStoryline, contains('broken'));
  });
}

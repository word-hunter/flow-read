import 'package:flow_read/models/analysis_result.dart';
import 'package:flow_read/services/analysis_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('practice generation keeps source excerpts for display surfaces', () {
    final result = AnalysisService.analyzeChapter(
      'Observatory',
      'The cartographer adjusted the sextant carefully. '
          'Moonlight shimmered across the observatory dome.',
    );

    expect(result.practice, isNotEmpty);
    expect(
      result.practice
          .where((item) => item.type == 'vocabulary_in_context')
          .every((item) => item.sourceExcerpt.isNotEmpty),
      isTrue,
    );
    expect(
      result.practice.any(
        (item) =>
            item.type == 'inference' &&
            item.sourceExcerpt.contains(
              'The cartographer adjusted the sextant carefully.',
            ),
      ),
      isTrue,
    );
  });

  test('practice json round-trip preserves source excerpt', () {
    const practice = Practice(
      type: 'vocabulary_in_context',
      question: 'What does "sextant" mean here?',
      sourceExcerpt: 'The cartographer adjusted the sextant carefully.',
      expectedReasoning: 'Use the surrounding action to infer it is a tool.',
    );

    final restored = Practice.fromJson(practice.toJson());

    expect(restored.sourceExcerpt, practice.sourceExcerpt);
  });
}

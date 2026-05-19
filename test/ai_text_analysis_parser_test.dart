import 'package:flow_read/models/ai_text_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses structured selected text analysis fields', () {
    final analysis = AITextAnalysis.fromJson({
      'translation': '她停下来，仿佛在等待回答。',
      'structure_notes': [
        {
          'source': 'as if waiting for an answer',
          'role': 'modifier',
          'explanation': '补充说明停下来的状态。',
        },
      ],
      'grammar_points': [
        {
          'source': 'as if waiting',
          'explanation': 'as if 引导方式状语。',
          'difficulty': 'medium',
        },
      ],
      'vocabulary_notes': [
        {'word': 'answer', 'context_meaning': '回应', 'pos': 'noun'},
      ],
      'expression_notes': [
        {
          'source': 'waiting for an answer',
          'meaning': '等待回应',
          'usage': '可用于描述期待反馈的状态。',
        },
      ],
      'reading_tip': '注意 as if 的虚拟语气意味。',
    });

    expect(analysis.translation, '她停下来，仿佛在等待回答。');
    expect(analysis.structureNotes.single.role, 'modifier');
    expect(analysis.grammarPoints.single.source, 'as if waiting');
    expect(analysis.vocabularyNotes.single.contextMeaning, '回应');
    expect(analysis.expressionNotes.single.usage, '可用于描述期待反馈的状态。');
    expect(analysis.isEmpty, isFalse);
  });

  test('keeps backward-compatible empty lists for older JSON', () {
    final analysis = AITextAnalysis.fromJson({
      'translation': '旧格式译文',
      'grammar_points': const [],
      'vocabulary_notes': const [],
      'reading_tip': '',
    });

    expect(analysis.translation, '旧格式译文');
    expect(analysis.structureNotes, isEmpty);
    expect(analysis.expressionNotes, isEmpty);
  });
}

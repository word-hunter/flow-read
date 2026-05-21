import 'package:flow_read/models/ai_practice_questions.dart';
import 'package:flow_read/services/prompt_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'practice prompt asks for source excerpts and three to five questions',
    () {
      final prompt = PromptRegistry.practiceUser(
        'Alice stopped when she heard a sound.',
        const ['stopped'],
        const [],
      );

      expect(prompt, contains('"source_excerpt"'));
      expect(prompt, contains('Total questions: at least 3, at most 5'));
    },
  );

  test(
    'practice parser accepts source_excerpt and keeps answer in options',
    () {
      final set = AIPracticeSet.fromJson({
        'questions': [
          {
            'type': 'detail',
            'question': 'Why did Alice stop?',
            'source_excerpt': 'Alice stopped when she heard a sound.',
            'answer': 'She heard a sound.',
            'answer_explanation': '原文直接说明她听到了声音。',
            'distractors': [
              {'text': 'She was tired.', 'why_wrong': '原文没有这样说。'},
              {'text': 'She saw a rabbit.', 'why_wrong': '原文没有出现 rabbit。'},
              {'text': 'She finished reading.', 'why_wrong': '原文没有提到。'},
            ],
            'difficulty': 'easy',
          },
        ],
      });

      final question = set.questions.single;

      expect(question.sourceExcerpt, 'Alice stopped when she heard a sound.');
      expect(question.source, question.sourceExcerpt);
      expect(
        question.answerOptions.map((option) => option.text),
        contains('She heard a sound.'),
      );
    },
  );

  test('practice parser caps a generated set at five questions', () {
    final set = AIPracticeSet.fromJson({
      'questions': List.generate(
        7,
        (index) => {
          'question': 'Question $index',
          'source_excerpt': 'Source $index',
          'answer': 'Answer $index',
          'distractors': const [],
        },
      ),
    });

    expect(set.questions, hasLength(5));
  });
}

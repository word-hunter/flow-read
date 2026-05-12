class AIPracticeSet {
  final List<PracticeQuestion> questions;

  const AIPracticeSet({required this.questions});

  factory AIPracticeSet.fromJson(Map<String, dynamic> json) {
    return AIPracticeSet(
      questions: (json['questions'] as List<dynamic>?)
              ?.map(
                  (e) => PracticeQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'questions': questions.map((e) => e.toJson()).toList(),
      };

  factory AIPracticeSet.empty() => const AIPracticeSet(questions: []);

  bool get isEmpty => questions.isEmpty;
}

class PracticeQuestion {
  final String type;
  final String question;
  final String source;
  final String answer;
  final String answerExplanation;
  final List<Distractor> distractors;
  final String difficulty;

  const PracticeQuestion({
    required this.type,
    required this.question,
    required this.source,
    required this.answer,
    required this.answerExplanation,
    required this.distractors,
    required this.difficulty,
  });

  factory PracticeQuestion.fromJson(Map<String, dynamic> json) {
    return PracticeQuestion(
      type: json['type'] as String? ?? 'detail',
      question: json['question'] as String? ?? '',
      source: json['source'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      answerExplanation: json['answer_explanation'] as String? ?? '',
      distractors: (json['distractors'] as List<dynamic>?)
              ?.map((e) => Distractor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      difficulty: json['difficulty'] as String? ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'question': question,
        'source': source,
        'answer': answer,
        'answer_explanation': answerExplanation,
        'distractors': distractors.map((e) => e.toJson()).toList(),
        'difficulty': difficulty,
      };
}

class Distractor {
  final String text;
  final String whyWrong;

  const Distractor({required this.text, required this.whyWrong});

  factory Distractor.fromJson(Map<String, dynamic> json) {
    return Distractor(
      text: json['text'] as String? ?? '',
      whyWrong: json['why_wrong'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'why_wrong': whyWrong,
      };
}

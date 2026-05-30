class AIPracticeSet {
  final List<PracticeQuestion> questions;

  const AIPracticeSet({required this.questions});

  factory AIPracticeSet.fromJson(Map<String, dynamic> json) {
    return AIPracticeSet(
      questions:
          (json['questions'] as List<dynamic>?)
              ?.map((e) => PracticeQuestion.fromJson(e as Map<String, dynamic>))
              .take(5)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'questions': questions.map((e) => e.toJson()).toList(),
  };

  factory AIPracticeSet.empty() => const AIPracticeSet(questions: []);

  factory AIPracticeSet.fallback(String rawText) => AIPracticeSet(
    questions: [
      PracticeQuestion(
        type: 'detail',
        question: 'AI 返回了非结构化练习内容',
        source: '',
        answer: rawText,
        answerExplanation: rawText,
        distractors: const [],
        difficulty: 'medium',
      ),
    ],
  );

  bool get isEmpty => questions.isEmpty;
}

class ReadingPracticeItem {
  final String type;
  final String question;
  final String sourceExcerpt;
  final String answer;
  final String answerExplanation;
  final List<Distractor> distractors;
  final String difficulty;

  const ReadingPracticeItem({
    required this.type,
    required this.question,
    required this.sourceExcerpt,
    required this.answer,
    required this.answerExplanation,
    required this.distractors,
    required this.difficulty,
  });

  String get source => sourceExcerpt;

  List<Distractor> get answerOptions {
    final options = [
      Distractor(text: answer, whyWrong: ''),
      ...distractors.where((option) => option.text != answer).take(3),
    ].where((option) => option.text.trim().isNotEmpty).toList();
    if (options.length <= 1) return options;

    final offset = question.hashCode.abs() % options.length;
    return [...options.skip(offset), ...options.take(offset)];
  }

  factory ReadingPracticeItem.fromJson(Map<String, dynamic> json) {
    return ReadingPracticeItem(
      type: json['type'] as String? ?? 'detail',
      question: json['question'] as String? ?? '',
      sourceExcerpt:
          (json['source_excerpt'] as String?) ??
          (json['source'] as String?) ??
          '',
      answer: json['answer'] as String? ?? '',
      answerExplanation: json['answer_explanation'] as String? ?? '',
      distractors:
          (json['distractors'] as List<dynamic>?)
              ?.map((e) => Distractor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      difficulty: json['difficulty'] as String? ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'question': question,
    'source_excerpt': sourceExcerpt,
    'source': sourceExcerpt,
    'answer': answer,
    'answer_explanation': answerExplanation,
    'distractors': distractors.map((e) => e.toJson()).toList(),
    'difficulty': difficulty,
  };
}

class PracticeQuestion extends ReadingPracticeItem {
  const PracticeQuestion({
    required super.type,
    required super.question,
    required String source,
    required super.answer,
    required super.answerExplanation,
    required super.distractors,
    required super.difficulty,
  }) : super(sourceExcerpt: source);

  factory PracticeQuestion.fromJson(Map<String, dynamic> json) {
    final item = ReadingPracticeItem.fromJson(json);
    return PracticeQuestion(
      type: item.type,
      question: item.question,
      source: item.sourceExcerpt,
      answer: item.answer,
      answerExplanation: item.answerExplanation,
      distractors: item.distractors,
      difficulty: item.difficulty,
    );
  }
}

class PracticeAnswerRecord {
  final String question;
  final String selectedAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final DateTime answeredAt;

  const PracticeAnswerRecord({
    required this.question,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.answeredAt,
  });
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

  Map<String, dynamic> toJson() => {'text': text, 'why_wrong': whyWrong};
}

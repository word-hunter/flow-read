class Vocabulary {
  final String word;
  final String meaning;
  final String context;
  final double familiarity;
  final String? level;

  const Vocabulary({
    required this.word,
    required this.meaning,
    required this.context,
    required this.familiarity,
    this.level,
  });

  factory Vocabulary.fromJson(Map<String, dynamic> json) {
    return Vocabulary(
      word: json['word'] as String,
      meaning: json['meaning'] as String,
      context: json['context'] as String,
      familiarity: (json['familiarity'] as num).toDouble(),
      level: json['level'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'meaning': meaning,
        'context': context,
        'familiarity': familiarity,
        'level': level,
      };
}

class SyntaxPattern {
  final String type;
  final String originalSentence;
  final String simplifiedSentence;
  final String explanation;

  const SyntaxPattern({
    required this.type,
    required this.originalSentence,
    required this.simplifiedSentence,
    required this.explanation,
  });

  factory SyntaxPattern.fromJson(Map<String, dynamic> json) {
    return SyntaxPattern(
      type: json['type'] as String,
      originalSentence: json['original_sentence'] as String,
      simplifiedSentence: json['simplified_sentence'] as String,
      explanation: json['explanation'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'original_sentence': originalSentence,
        'simplified_sentence': simplifiedSentence,
        'explanation': explanation,
      };
}

class Comprehension {
  final String whatHappened;
  final String whyHappened;
  final String implicitMeaning;

  const Comprehension({
    required this.whatHappened,
    required this.whyHappened,
    required this.implicitMeaning,
  });

  factory Comprehension.fromJson(Map<String, dynamic> json) {
    return Comprehension(
      whatHappened: json['what_happened'] as String,
      whyHappened: json['why_happened'] as String,
      implicitMeaning: json['implicit_meaning'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'what_happened': whatHappened,
        'why_happened': whyHappened,
        'implicit_meaning': implicitMeaning,
      };
}

class Practice {
  final String type;
  final String question;
  final String expectedReasoning;

  const Practice({
    required this.type,
    required this.question,
    required this.expectedReasoning,
  });

  factory Practice.fromJson(Map<String, dynamic> json) {
    return Practice(
      type: json['type'] as String,
      question: json['question'] as String,
      expectedReasoning: json['expected_reasoning'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'question': question,
        'expected_reasoning': expectedReasoning,
      };
}

class Difficulty {
  final int vocab;
  final int syntax;
  final int inference;
  final String explanation;

  const Difficulty({
    required this.vocab,
    required this.syntax,
    required this.inference,
    required this.explanation,
  });

  factory Difficulty.fromJson(Map<String, dynamic> json) {
    return Difficulty(
      vocab: (json['vocab'] as num).toInt(),
      syntax: (json['syntax'] as num).toInt(),
      inference: (json['inference'] as num).toInt(),
      explanation: json['explanation'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'vocab': vocab,
        'syntax': syntax,
        'inference': inference,
        'explanation': explanation,
      };
}

class AnalysisResult {
  final String passageText;
  final String title;
  final List<Vocabulary> vocabulary;
  final Set<String> knownWords;
  final Set<String> learningWords;
  final List<SyntaxPattern> syntaxPatterns;
  final Comprehension comprehension;
  final List<Practice> practice;
  final Difficulty difficulty;

  const AnalysisResult({
    required this.passageText,
    required this.title,
    required this.vocabulary,
    this.knownWords = const {},
    this.learningWords = const {},
    required this.syntaxPatterns,
    required this.comprehension,
    required this.practice,
    required this.difficulty,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      passageText: json['passage_text'] as String,
      title: json['title'] as String,
      vocabulary: (json['vocabulary'] as List)
          .map((e) => Vocabulary.fromJson(e as Map<String, dynamic>))
          .toList(),
      knownWords: (json['known_words'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
      learningWords: (json['learning_words'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
      syntaxPatterns: (json['syntax_patterns'] as List)
          .map((e) => SyntaxPattern.fromJson(e as Map<String, dynamic>))
          .toList(),
      comprehension: Comprehension.fromJson(
          json['comprehension'] as Map<String, dynamic>),
      practice: (json['practice'] as List)
          .map((e) => Practice.fromJson(e as Map<String, dynamic>))
          .toList(),
      difficulty: Difficulty.fromJson(
          json['difficulty'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'passage_text': passageText,
        'title': title,
        'vocabulary': vocabulary.map((e) => e.toJson()).toList(),
        'known_words': knownWords.toList(),
        'learning_words': learningWords.toList(),
        'syntax_patterns': syntaxPatterns.map((e) => e.toJson()).toList(),
        'comprehension': comprehension.toJson(),
        'practice': practice.map((e) => e.toJson()).toList(),
        'difficulty': difficulty.toJson(),
      };
}

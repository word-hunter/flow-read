import 'json_helpers.dart';

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
      word: json.str('word'),
      meaning: json.str('meaning'),
      context: json.str('context'),
      familiarity: json.floating('familiarity'),
      level: json.strOrNull('level'),
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
      type: json.str('type'),
      originalSentence: json.str('original_sentence'),
      simplifiedSentence: json.str('simplified_sentence'),
      explanation: json.str('explanation'),
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
      whatHappened: json.str('what_happened'),
      whyHappened: json.str('why_happened'),
      implicitMeaning: json.str('implicit_meaning'),
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
      type: json.str('type'),
      question: json.str('question'),
      expectedReasoning: json.str('expected_reasoning'),
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
      vocab: json.integer('vocab'),
      syntax: json.integer('syntax'),
      inference: json.integer('inference'),
      explanation: json.str('explanation'),
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
      passageText: json.str('passage_text'),
      title: json.str('title'),
      vocabulary: json
          .list('vocabulary')
          .whereType<Map>()
          .map((e) => Vocabulary.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      knownWords: (json['known_words'] is List)
          ? json.list('known_words').map((e) => e.toString()).toSet()
          : const {},
      learningWords: (json['learning_words'] is List)
          ? json.list('learning_words').map((e) => e.toString()).toSet()
          : const {},
      syntaxPatterns: json
          .list('syntax_patterns')
          .whereType<Map>()
          .map((e) => SyntaxPattern.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      comprehension: Comprehension.fromJson(json.nested('comprehension')),
      practice: json
          .list('practice')
          .whereType<Map>()
          .map((e) => Practice.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      difficulty: Difficulty.fromJson(json.nested('difficulty')),
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

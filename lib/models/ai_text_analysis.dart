class AITextAnalysis {
  final String translation;
  final List<GrammarPoint> grammarPoints;
  final List<VocabularyNote> vocabularyNotes;
  final String readingTip;

  const AITextAnalysis({
    required this.translation,
    required this.grammarPoints,
    required this.vocabularyNotes,
    required this.readingTip,
  });

  factory AITextAnalysis.fromJson(Map<String, dynamic> json) {
    return AITextAnalysis(
      translation: json['translation'] as String? ?? '',
      grammarPoints:
          (json['grammar_points'] as List<dynamic>?)
              ?.map((e) => GrammarPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      vocabularyNotes:
          (json['vocabulary_notes'] as List<dynamic>?)
              ?.map((e) => VocabularyNote.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      readingTip: json['reading_tip'] as String? ?? '',
    );
  }

  bool get isEmpty =>
      translation.isEmpty &&
      grammarPoints.isEmpty &&
      vocabularyNotes.isEmpty &&
      readingTip.isEmpty;
}

class GrammarPoint {
  final String source;
  final String explanation;
  final String difficulty;

  const GrammarPoint({
    required this.source,
    required this.explanation,
    required this.difficulty,
  });

  factory GrammarPoint.fromJson(Map<String, dynamic> json) {
    return GrammarPoint(
      source: json['source'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'medium',
    );
  }
}

class VocabularyNote {
  final String word;
  final String contextMeaning;
  final String pos;

  const VocabularyNote({
    required this.word,
    required this.contextMeaning,
    required this.pos,
  });

  factory VocabularyNote.fromJson(Map<String, dynamic> json) {
    return VocabularyNote(
      word: json['word'] as String? ?? '',
      contextMeaning: json['context_meaning'] as String? ?? '',
      pos: json['pos'] as String? ?? '',
    );
  }
}

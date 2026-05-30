class AITextAnalysis {
  final String translation;
  final List<StructureNote> structureNotes;
  final List<GrammarPoint> grammarPoints;
  final List<VocabularyNote> vocabularyNotes;
  final List<ExpressionNote> expressionNotes;
  final String readingTip;

  const AITextAnalysis({
    required this.translation,
    this.structureNotes = const [],
    required this.grammarPoints,
    required this.vocabularyNotes,
    this.expressionNotes = const [],
    required this.readingTip,
  });

  factory AITextAnalysis.fromJson(Map<String, dynamic> json) {
    return AITextAnalysis(
      translation: json['translation'] as String? ?? '',
      structureNotes: _readList(
        json['structure_notes'] ??
            json['structure'] ??
            json['sentence_structure'],
      ).map(StructureNote.fromJson).toList(),
      grammarPoints: _readList(
        json['grammar_points'],
      ).map(GrammarPoint.fromJson).toList(),
      vocabularyNotes: _readList(
        json['vocabulary_notes'],
      ).map(VocabularyNote.fromJson).toList(),
      expressionNotes: _readList(
        json['expression_notes'] ?? json['expressions'],
      ).map(ExpressionNote.fromJson).toList(),
      readingTip: json['reading_tip'] as String? ?? '',
    );
  }

  bool get isEmpty =>
      translation.isEmpty &&
      structureNotes.isEmpty &&
      grammarPoints.isEmpty &&
      vocabularyNotes.isEmpty &&
      expressionNotes.isEmpty &&
      readingTip.isEmpty;

  factory AITextAnalysis.fallback(String rawText) {
    return AITextAnalysis(
      translation: rawText,
      grammarPoints: const [],
      vocabularyNotes: const [],
      readingTip: '',
    );
  }

  static List<Map<String, dynamic>> _readList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList(growable: false);
  }
}

class StructureNote {
  final String source;
  final String role;
  final String explanation;

  const StructureNote({
    required this.source,
    required this.role,
    required this.explanation,
  });

  factory StructureNote.fromJson(Map<String, dynamic> json) {
    return StructureNote(
      source: json['source'] as String? ?? '',
      role: json['role'] as String? ?? json['label'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }
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

class ExpressionNote {
  final String source;
  final String meaning;
  final String usage;

  const ExpressionNote({
    required this.source,
    required this.meaning,
    required this.usage,
  });

  factory ExpressionNote.fromJson(Map<String, dynamic> json) {
    return ExpressionNote(
      source: json['source'] as String? ?? json['expression'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      usage: json['usage'] as String? ?? json['explanation'] as String? ?? '',
    );
  }
}

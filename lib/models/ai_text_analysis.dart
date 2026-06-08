import 'json_helpers.dart';

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
      translation: json.str('translation'),
      structureNotes: _readList(
        json['structure_notes'] ??
            json['structure'] ??
            json['sentence_structure'],
      ).map(StructureNote.fromJson).toList(),
      grammarPoints: _readList(json['grammar_points'])
          .map(GrammarPoint.fromJson)
          .toList(),
      vocabularyNotes: _readList(json['vocabulary_notes'])
          .map(VocabularyNote.fromJson)
          .toList(),
      expressionNotes: _readList(
        json['expression_notes'] ?? json['expressions'],
      ).map(ExpressionNote.fromJson).toList(),
      readingTip: json.str('reading_tip'),
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
      source: json.str('source'),
      role: json.strOrNull('role') ?? json.str('label'),
      explanation: json.str('explanation'),
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
      source: json.str('source'),
      explanation: json.str('explanation'),
      difficulty: json.str('difficulty', def: 'medium'),
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
      word: json.str('word'),
      contextMeaning: json.str('context_meaning'),
      pos: json.str('pos'),
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
      source: json.strOrNull('source') ?? json.str('expression'),
      meaning: json.str('meaning'),
      usage: json.strOrNull('usage') ?? json.str('explanation'),
    );
  }
}

import 'json_helpers.dart';

class WordAnalysis {
  final String pronunciation;
  final List<ContextualMeaning> meanings;
  final List<String> usageTips;
  final String memoryTip;

  const WordAnalysis({
    required this.pronunciation,
    required this.meanings,
    required this.usageTips,
    required this.memoryTip,
  });

  factory WordAnalysis.fromJson(Map<String, dynamic> json) {
    return WordAnalysis(
      pronunciation: json.str('pronunciation'),
      meanings: json
          .list('meanings')
          .whereType<Map>()
          .map((e) => ContextualMeaning.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      usageTips: json.list('usage_tips').map((e) => e.toString()).toList(),
      memoryTip: json.str('memory_tip'),
    );
  }

  factory WordAnalysis.fallback(String rawText) => WordAnalysis(
    pronunciation: '',
    meanings: [ContextualMeaning(meaning: rawText, explanation: '')],
    usageTips: const [],
    memoryTip: '',
  );

  Map<String, dynamic> toJson() => {
    'pronunciation': pronunciation,
    'meanings': meanings.map((meaning) => meaning.toJson()).toList(),
    'usage_tips': usageTips,
    'memory_tip': memoryTip,
  };

  bool get isEmpty =>
      pronunciation.isEmpty &&
      meanings.isEmpty &&
      usageTips.isEmpty &&
      memoryTip.isEmpty;
}

class ContextualMeaning {
  final String meaning;
  final String explanation;

  const ContextualMeaning({required this.meaning, required this.explanation});

  factory ContextualMeaning.fromJson(Map<String, dynamic> json) {
    return ContextualMeaning(
      meaning: json.str('meaning'),
      explanation: json.str('explanation'),
    );
  }

  Map<String, dynamic> toJson() => {
    'meaning': meaning,
    'explanation': explanation,
  };
}

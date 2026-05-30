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
      pronunciation: json['pronunciation'] as String? ?? '',
      meanings:
          (json['meanings'] as List<dynamic>?)
              ?.map(
                (e) => ContextualMeaning.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      usageTips:
          (json['usage_tips'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      memoryTip: json['memory_tip'] as String? ?? '',
    );
  }

  factory WordAnalysis.fallback(String rawText) => WordAnalysis(
    pronunciation: '',
    meanings: [ContextualMeaning(meaning: rawText, explanation: '')],
    usageTips: const [],
    memoryTip: '',
  );

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
      meaning: json['meaning'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

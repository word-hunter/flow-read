import 'json_helpers.dart';

class ParagraphInsight {
  final String gist;
  final String? narrativeFunction;
  final bool hasMoodShift;
  final List<String> keyReferences;
  final List<String> difficultLanguage;
  final String? whyItMattersNow;
  final List<String> sourceEvidence;

  const ParagraphInsight({
    required this.gist,
    this.narrativeFunction,
    this.hasMoodShift = false,
    this.keyReferences = const [],
    this.difficultLanguage = const [],
    this.whyItMattersNow,
    this.sourceEvidence = const [],
  });

  factory ParagraphInsight.fromJson(Map<String, dynamic> json) {
    return ParagraphInsight(
      gist: json.str('gist'),
      narrativeFunction: json['narrative_function'] as String?,
      hasMoodShift: json['has_mood_shift'] == true,
      keyReferences: (json['key_references'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      difficultLanguage: (json['difficult_language'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      whyItMattersNow: json['why_it_matters_now'] as String?,
      sourceEvidence: (json['source_evidence'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  factory ParagraphInsight.fallback(String raw) => ParagraphInsight(
        gist: raw,
      );

  bool get isEmpty => gist.isEmpty;
}

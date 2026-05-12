class AISummary {
  final List<SummaryEvent> events;
  final List<CharacterDevelopment> characterDevelopments;
  final List<KeyVocabulary> keyVocabulary;
  final String readingGuidance;

  const AISummary({
    required this.events,
    required this.characterDevelopments,
    required this.keyVocabulary,
    required this.readingGuidance,
  });

  factory AISummary.fromJson(Map<String, dynamic> json) {
    return AISummary(
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => SummaryEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      characterDevelopments: (json['character_developments'] as List<dynamic>?)
              ?.map((e) =>
                  CharacterDevelopment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      keyVocabulary: (json['key_vocabulary'] as List<dynamic>?)
              ?.map((e) => KeyVocabulary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      readingGuidance: json['reading_guidance'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'events': events.map((e) => e.toJson()).toList(),
        'character_developments':
            characterDevelopments.map((e) => e.toJson()).toList(),
        'key_vocabulary': keyVocabulary.map((e) => e.toJson()).toList(),
        'reading_guidance': readingGuidance,
      };

  factory AISummary.empty() => const AISummary(
        events: [],
        characterDevelopments: [],
        keyVocabulary: [],
        readingGuidance: '',
      );

  bool get isEmpty =>
      events.isEmpty &&
      characterDevelopments.isEmpty &&
      keyVocabulary.isEmpty &&
      readingGuidance.isEmpty;
}

class SummaryEvent {
  final String description;
  final String source;
  final String significance;
  final String confidence;

  const SummaryEvent({
    required this.description,
    required this.source,
    required this.significance,
    required this.confidence,
  });

  factory SummaryEvent.fromJson(Map<String, dynamic> json) {
    return SummaryEvent(
      description: json['description'] as String? ?? '',
      source: json['source'] as String? ?? '',
      significance: json['significance'] as String? ?? '',
      confidence: json['confidence'] as String? ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'source': source,
        'significance': significance,
        'confidence': confidence,
      };
}

class CharacterDevelopment {
  final String character;
  final String change;
  final String source;
  final String confidence;

  const CharacterDevelopment({
    required this.character,
    required this.change,
    required this.source,
    required this.confidence,
  });

  factory CharacterDevelopment.fromJson(Map<String, dynamic> json) {
    return CharacterDevelopment(
      character: json['character'] as String? ?? '',
      change: json['change'] as String? ?? '',
      source: json['source'] as String? ?? '',
      confidence: json['confidence'] as String? ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() => {
        'character': character,
        'change': change,
        'source': source,
        'confidence': confidence,
      };
}

class KeyVocabulary {
  final String word;
  final String sentence;
  final String meaningInContext;
  final String whyImportant;

  const KeyVocabulary({
    required this.word,
    required this.sentence,
    required this.meaningInContext,
    required this.whyImportant,
  });

  factory KeyVocabulary.fromJson(Map<String, dynamic> json) {
    return KeyVocabulary(
      word: json['word'] as String? ?? '',
      sentence: json['sentence'] as String? ?? '',
      meaningInContext: json['meaning_in_context'] as String? ?? '',
      whyImportant: json['why_important'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'sentence': sentence,
        'meaning_in_context': meaningInContext,
        'why_important': whyImportant,
      };
}

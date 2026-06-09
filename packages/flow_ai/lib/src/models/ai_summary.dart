import 'json_helpers.dart';

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
      events: json
          .list('events')
          .whereType<Map>()
          .map((e) => SummaryEvent.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      characterDevelopments: json
          .list('character_developments')
          .whereType<Map>()
          .map((e) =>
              CharacterDevelopment.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      keyVocabulary: json
          .list('key_vocabulary')
          .whereType<Map>()
          .map((e) => KeyVocabulary.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      readingGuidance: json.str('reading_guidance'),
    );
  }

  Map<String, dynamic> toJson() => {
    'events': events.map((e) => e.toJson()).toList(),
    'character_developments': characterDevelopments
        .map((e) => e.toJson())
        .toList(),
    'key_vocabulary': keyVocabulary.map((e) => e.toJson()).toList(),
    'reading_guidance': readingGuidance,
  };

  factory AISummary.empty() => const AISummary(
    events: [],
    characterDevelopments: [],
    keyVocabulary: [],
    readingGuidance: '',
  );

  factory AISummary.fallback(String rawText) => AISummary(
    events: const [],
    characterDevelopments: const [],
    keyVocabulary: const [],
    readingGuidance: rawText,
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
      description: json.str('description'),
      source: json.str('source'),
      significance: json.str('significance'),
      confidence: json.str('confidence', def: 'medium'),
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
      character: json.str('character'),
      change: json.str('change'),
      source: json.str('source'),
      confidence: json.str('confidence', def: 'medium'),
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
      word: json.str('word'),
      sentence: json.str('sentence'),
      meaningInContext: json.str('meaning_in_context'),
      whyImportant: json.str('why_important'),
    );
  }

  Map<String, dynamic> toJson() => {
    'word': word,
    'sentence': sentence,
    'meaning_in_context': meaningInContext,
    'why_important': whyImportant,
  };
}

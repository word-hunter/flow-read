import 'ai_summary.dart';
import 'json_helpers.dart';

class ChapterInsight {
  static const currentSchemaVersion = '1.0.0';

  final AISummary summary;
  final List<LocationRef> locations;
  final List<String> themes;
  final List<SourceAnchor> anchors;
  final String schemaVersion;
  final String contentHash;
  final int promptVersion;

  const ChapterInsight({
    required this.summary,
    this.locations = const [],
    this.themes = const [],
    this.anchors = const [],
    this.schemaVersion = currentSchemaVersion,
    this.contentHash = '',
    this.promptVersion = 0,
  });

  factory ChapterInsight.fromSummary(
    AISummary summary, {
    List<LocationRef> locations = const [],
    List<String> themes = const [],
    List<SourceAnchor> anchors = const [],
    String schemaVersion = currentSchemaVersion,
    String contentHash = '',
    int promptVersion = 0,
  }) {
    return ChapterInsight(
      summary: summary,
      locations: locations,
      themes: themes,
      anchors: anchors,
      schemaVersion: schemaVersion,
      contentHash: contentHash,
      promptVersion: promptVersion,
    );
  }

  factory ChapterInsight.fromJson(Map<String, dynamic> json) {
    final wrappedSummary = json.nestedOrNull('summary');
    final anchorJson = _listFromEither(json, 'source_anchors', 'anchors');

    return ChapterInsight(
      summary: AISummary.fromJson(wrappedSummary ?? json),
      locations: json
          .nestedList('locations')
          .map(LocationRef.fromJson)
          .toList(),
      themes: json
          .list('themes')
          .map((theme) => theme.toString().trim())
          .where((theme) => theme.isNotEmpty)
          .toList(),
      anchors: anchorJson
          .whereType<Map>()
          .map(
            (anchor) =>
                SourceAnchor.fromJson(Map<String, dynamic>.from(anchor)),
          )
          .toList(),
      schemaVersion: _stringFromEither(
        json,
        'schema_version',
        'schemaVersion',
        currentSchemaVersion,
      ),
      contentHash: _stringFromEither(json, 'content_hash', 'contentHash', ''),
      promptVersion: _intFromEither(json, 'prompt_version', 'promptVersion'),
    );
  }

  Map<String, dynamic> toJson() => {
    'summary': summary.toJson(),
    'locations': locations.map((location) => location.toJson()).toList(),
    'themes': themes,
    'source_anchors': anchors.map((anchor) => anchor.toJson()).toList(),
    'schema_version': schemaVersion,
    'content_hash': contentHash,
    'prompt_version': promptVersion,
  };

  ChapterInsight copyWith({
    AISummary? summary,
    List<LocationRef>? locations,
    List<String>? themes,
    List<SourceAnchor>? anchors,
    String? schemaVersion,
    String? contentHash,
    int? promptVersion,
  }) {
    return ChapterInsight(
      summary: summary ?? this.summary,
      locations: locations ?? this.locations,
      themes: themes ?? this.themes,
      anchors: anchors ?? this.anchors,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      contentHash: contentHash ?? this.contentHash,
      promptVersion: promptVersion ?? this.promptVersion,
    );
  }
}

class SourceAnchor {
  final int chapterIndex;
  final String? chapterTitle;
  final int? blockIndex;
  final int? startOffset;
  final int? endOffset;
  final String quoteSnippet;
  final double confidence;

  const SourceAnchor({
    required this.chapterIndex,
    this.chapterTitle,
    this.blockIndex,
    this.startOffset,
    this.endOffset,
    required this.quoteSnippet,
    this.confidence = 1.0,
  });

  factory SourceAnchor.fromJson(Map<String, dynamic> json) {
    return SourceAnchor(
      chapterIndex: json.integer('chapter_index'),
      chapterTitle: json.strOrNull('chapter_title'),
      blockIndex: _nullableIntFromEither(
        json,
        'block_index',
        'paragraph_index',
      ),
      startOffset: _nullableInt(json['start_offset']),
      endOffset: _nullableInt(json['end_offset']),
      quoteSnippet: _stringFromEither(json, 'quote_snippet', 'quote', ''),
      confidence: _boundedConfidence(json.floating('confidence', def: 1.0)),
    );
  }

  Map<String, dynamic> toJson() => {
    'chapter_index': chapterIndex,
    if (chapterTitle != null) 'chapter_title': chapterTitle,
    if (blockIndex != null) 'block_index': blockIndex,
    if (startOffset != null) 'start_offset': startOffset,
    if (endOffset != null) 'end_offset': endOffset,
    'quote_snippet': quoteSnippet,
    'confidence': confidence,
  };
}

class LocationRef {
  final String name;
  final String? description;
  final List<SourceAnchor> anchors;
  final double confidence;

  const LocationRef({
    required this.name,
    this.description,
    this.anchors = const [],
    this.confidence = 1.0,
  });

  factory LocationRef.fromJson(Map<String, dynamic> json) {
    return LocationRef(
      name: json.str('name').trim(),
      description: json.strOrNull('description'),
      anchors: json.nestedList('anchors').map(SourceAnchor.fromJson).toList(),
      confidence: _boundedConfidence(json.floating('confidence', def: 1.0)),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    'anchors': anchors.map((anchor) => anchor.toJson()).toList(),
    'confidence': confidence,
  };
}

List<dynamic> _listFromEither(
  Map<String, dynamic> json,
  String primaryKey,
  String fallbackKey,
) {
  final primary = json.list(primaryKey);
  if (primary.isNotEmpty) return primary;
  return json.list(fallbackKey);
}

String _stringFromEither(
  Map<String, dynamic> json,
  String primaryKey,
  String fallbackKey,
  String fallback,
) {
  final primary = json.strOrNull(primaryKey);
  if (primary != null && primary.isNotEmpty) return primary;
  final secondary = json.strOrNull(fallbackKey);
  if (secondary != null && secondary.isNotEmpty) return secondary;
  return fallback;
}

int _intFromEither(
  Map<String, dynamic> json,
  String primaryKey,
  String fallbackKey,
) {
  final primary = _nullableInt(json[primaryKey]);
  if (primary != null) return primary;
  return _nullableInt(json[fallbackKey]) ?? 0;
}

int? _nullableIntFromEither(
  Map<String, dynamic> json,
  String primaryKey,
  String fallbackKey,
) {
  return _nullableInt(json[primaryKey]) ?? _nullableInt(json[fallbackKey]);
}

int? _nullableInt(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double _boundedConfidence(double value) {
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}

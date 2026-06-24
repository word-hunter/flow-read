import 'chapter_insight.dart';
import 'json_helpers.dart';

class BookSynthesisResult {
  static const currentSchemaVersion = '1.0.0';

  final String fullStoryline;
  final CharacterRelationGraph characterGraph;
  final MindMapGraph bookMindMap;
  final String structure;
  final String themeAnalysis;
  final List<String> keyInsights;
  final String schemaVersion;
  final DateTime generatedAt;

  BookSynthesisResult({
    required this.fullStoryline,
    required this.characterGraph,
    required this.bookMindMap,
    this.structure = '',
    this.themeAnalysis = '',
    Iterable<String> keyInsights = const [],
    this.schemaVersion = currentSchemaVersion,
    DateTime? generatedAt,
  }) : keyInsights = List.unmodifiable(keyInsights),
       generatedAt = generatedAt ?? DateTime.now().toUtc();

  factory BookSynthesisResult.fromJson(
    Map<String, dynamic> json, {
    DateTime? generatedAt,
  }) {
    return BookSynthesisResult(
      fullStoryline: _requiredString(json, 'fullStoryline', 'full_storyline'),
      characterGraph: CharacterRelationGraph.fromJson(
        _nestedFromEither(json, 'characterGraph', 'character_graph'),
      ),
      bookMindMap: MindMapGraph.fromJson(
        _nestedFromEither(json, 'bookMindMap', 'book_mind_map'),
      ),
      structure: _stringFromEither(json, 'structure', 'story_structure', ''),
      themeAnalysis: _stringFromEither(
        json,
        'themeAnalysis',
        'theme_analysis',
        '',
      ),
      keyInsights: _stringListFromEither(json, 'keyInsights', 'key_insights'),
      schemaVersion: _stringFromEither(
        json,
        'schemaVersion',
        'schema_version',
        currentSchemaVersion,
      ),
      generatedAt: _dateFromEither(json, generatedAt: generatedAt),
    );
  }

  factory BookSynthesisResult.fallback({
    required String rawResponse,
    DateTime? generatedAt,
  }) {
    final text = _safeFallbackText(rawResponse);
    return BookSynthesisResult(
      fullStoryline: text,
      characterGraph: const CharacterRelationGraph(),
      bookMindMap: const MindMapGraph(
        root: MindMapNode(id: 'analysis', label: 'Analysis'),
      ),
      keyInsights: const ['AI returned non-structured content.'],
      generatedAt: generatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'full_storyline': fullStoryline,
    'character_graph': characterGraph.toJson(),
    'book_mind_map': bookMindMap.toJson(),
    'structure': structure,
    'theme_analysis': themeAnalysis,
    'key_insights': keyInsights,
    'schema_version': schemaVersion,
    'generated_at': generatedAt.toUtc().toIso8601String(),
  };

  BookSynthesisResult copyWith({
    String? fullStoryline,
    CharacterRelationGraph? characterGraph,
    MindMapGraph? bookMindMap,
    String? structure,
    String? themeAnalysis,
    Iterable<String>? keyInsights,
    String? schemaVersion,
    DateTime? generatedAt,
  }) {
    return BookSynthesisResult(
      fullStoryline: fullStoryline ?? this.fullStoryline,
      characterGraph: characterGraph ?? this.characterGraph,
      bookMindMap: bookMindMap ?? this.bookMindMap,
      structure: structure ?? this.structure,
      themeAnalysis: themeAnalysis ?? this.themeAnalysis,
      keyInsights: keyInsights ?? this.keyInsights,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}

class CharacterRelationGraph {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  const CharacterRelationGraph({
    this.nodes = const [],
    this.edges = const [],
  });

  factory CharacterRelationGraph.fromJson(Map<String, dynamic> json) {
    return CharacterRelationGraph(
      nodes: json.nestedList('nodes').map(GraphNode.fromJson).toList(),
      edges: json
          .nestedList('edges')
          .map(GraphEdge.fromJson)
          .where((edge) => edge.hasEndpoints)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'nodes': nodes.map((node) => node.toJson()).toList(),
    'edges': edges.map((edge) => edge.toJson()).toList(),
  };
}

class GraphNode {
  final String id;
  final String label;
  final String? role;
  final String? group;

  const GraphNode({
    required this.id,
    required this.label,
    this.role,
    this.group,
  });

  factory GraphNode.fromJson(Map<String, dynamic> json) {
    final rawId = _stringFromEither(json, 'id', 'character_id', '');
    final rawLabel = json.str('label').trim();
    final label = rawLabel.isNotEmpty ? rawLabel : rawId;
    final id = rawId.isNotEmpty ? rawId : _nodeIdFromLabel(label);
    return GraphNode(
      id: id,
      label: label,
      role: json.strOrNull('role'),
      group: json.strOrNull('group'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    if (role != null && role!.trim().isNotEmpty) 'role': role,
    if (group != null && group!.trim().isNotEmpty) 'group': group,
  };
}

class GraphEdge {
  final String fromCharacterId;
  final String toCharacterId;
  final String relation;
  final List<SourceAnchor> anchors;
  final double confidence;

  GraphEdge({
    required this.fromCharacterId,
    required this.toCharacterId,
    required this.relation,
    Iterable<SourceAnchor> anchors = const [],
    this.confidence = 1.0,
  }) : anchors = List.unmodifiable(anchors);

  factory GraphEdge.fromJson(Map<String, dynamic> json) {
    return GraphEdge(
      fromCharacterId: _stringFromEither(
        json,
        'from',
        'fromCharacterId',
        '',
      ).trim(),
      toCharacterId: _stringFromEither(json, 'to', 'toCharacterId', '').trim(),
      relation: json.str('relation').trim(),
      anchors: json.nestedList('anchors').map(SourceAnchor.fromJson).toList(),
      confidence: _boundedConfidence(json.floating('confidence', def: 1.0)),
    );
  }

  bool get hasEndpoints =>
      fromCharacterId.isNotEmpty && toCharacterId.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'from': fromCharacterId,
    'to': toCharacterId,
    'relation': relation,
    'anchors': anchors.map((anchor) => anchor.toJson()).toList(),
    'confidence': confidence,
  };
}

class MindMapGraph {
  final MindMapNode root;

  const MindMapGraph({required this.root});

  factory MindMapGraph.fromJson(Map<String, dynamic> json) {
    final rootJson = json.nestedOrNull('root');
    if (rootJson == null || rootJson.isEmpty) {
      return const MindMapGraph(
        root: MindMapNode(id: 'analysis', label: 'Analysis'),
      );
    }
    return MindMapGraph(root: MindMapNode.fromJson(rootJson));
  }

  Map<String, dynamic> toJson() => {'root': root.toJson()};
}

class MindMapNode {
  final String id;
  final String label;
  final List<MindMapNode> children;

  const MindMapNode({
    required this.id,
    required this.label,
    this.children = const [],
  });

  factory MindMapNode.fromJson(Map<String, dynamic> json) {
    final rawId = json.str('id').trim();
    final rawLabel = json.str('label').trim();
    final label = rawLabel.isNotEmpty ? rawLabel : rawId;
    final id = rawId.isNotEmpty ? rawId : _nodeIdFromLabel(label);
    return MindMapNode(
      id: id,
      label: label,
      children: json.nestedList('children').map(MindMapNode.fromJson).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'children': children.map((child) => child.toJson()).toList(),
  };
}

String _requiredString(
  Map<String, dynamic> json,
  String primaryKey,
  String fallbackKey,
) {
  final value = json[primaryKey] ?? json[fallbackKey];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing required string field "$primaryKey".');
  }
  return value.trim();
}

Map<String, dynamic> _nestedFromEither(
  Map<String, dynamic> json,
  String primaryKey,
  String fallbackKey,
) {
  final primary = json.nestedOrNull(primaryKey);
  if (primary != null) return primary;
  return json.nested(fallbackKey);
}

String _stringFromEither(
  Map<String, dynamic> json,
  String primaryKey,
  String fallbackKey,
  String fallback,
) {
  final primary = json.strOrNull(primaryKey);
  if (primary != null && primary.trim().isNotEmpty) return primary.trim();
  final secondary = json.strOrNull(fallbackKey);
  if (secondary != null && secondary.trim().isNotEmpty) return secondary.trim();
  return fallback;
}

List<String> _stringListFromEither(
  Map<String, dynamic> json,
  String primaryKey,
  String fallbackKey,
) {
  final raw = json[primaryKey] ?? json[fallbackKey];
  if (raw is String) {
    return raw
        .split(RegExp(r'(?:\r?\n|[;；])'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  if (raw is List) {
    return raw
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
}

DateTime _dateFromEither(
  Map<String, dynamic> json, {
  DateTime? generatedAt,
}) {
  final raw = json.strOrNull('generated_at') ?? json.strOrNull('generatedAt');
  if (raw != null) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed.toUtc();
  }
  return generatedAt ?? DateTime.now().toUtc();
}

double _boundedConfidence(double value) {
  if (value.isNaN) return 1.0;
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}

String _nodeIdFromLabel(String label) {
  final normalized = label
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return normalized.isEmpty ? 'node' : normalized;
}

String _safeFallbackText(String rawResponse) {
  var content = rawResponse.trim();
  if (content.startsWith('```json')) {
    content = content.substring(7);
  } else if (content.startsWith('```')) {
    content = content.substring(3);
  }
  if (content.endsWith('```')) {
    content = content.substring(0, content.length - 3);
  }
  content = content.trim();
  if (content.length > 4000) {
    content = '${content.substring(0, 4000)}...';
  }
  return content.isEmpty
      ? 'AI returned non-structured content, with no displayable text.'
      : 'AI returned non-structured content:\n\n$content';
}

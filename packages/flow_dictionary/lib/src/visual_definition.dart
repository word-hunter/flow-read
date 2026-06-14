class VisualDefinition {
  final String word;
  final String entityId;
  final String label;
  final String? description;
  final String thumbnailUrl;
  final String? imageUrl;
  final String sourcePageUrl;
  final String? license;
  final double confidence;

  const VisualDefinition({
    required this.word,
    required this.entityId,
    required this.label,
    this.description,
    required this.thumbnailUrl,
    this.imageUrl,
    required this.sourcePageUrl,
    this.license,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'word': word,
    'entityId': entityId,
    'label': label,
    if (description != null) 'description': description,
    'thumbnailUrl': thumbnailUrl,
    if (imageUrl != null) 'imageUrl': imageUrl,
    'sourcePageUrl': sourcePageUrl,
    if (license != null) 'license': license,
    'confidence': confidence,
  };

  factory VisualDefinition.fromJson(Map<String, dynamic> json) {
    return VisualDefinition(
      word: json['word'] as String,
      entityId: json['entityId'] as String,
      label: json['label'] as String,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String,
      imageUrl: json['imageUrl'] as String?,
      sourcePageUrl: json['sourcePageUrl'] as String,
      license: json['license'] as String?,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

class AIChapterPreview {
  final String setup;
  final List<String> focusPoints;
  final List<String> vocabularyHints;
  final String spoilerBoundaryNote;

  const AIChapterPreview({
    required this.setup,
    required this.focusPoints,
    required this.vocabularyHints,
    required this.spoilerBoundaryNote,
  });

  factory AIChapterPreview.fromJson(Map<String, dynamic> json) {
    return AIChapterPreview(
      setup: json['setup'] as String? ?? '',
      focusPoints:
          (json['focus_points'] as List<dynamic>?)
              ?.map((value) => value.toString())
              .where((value) => value.trim().isNotEmpty)
              .take(5)
              .toList(growable: false) ??
          const [],
      vocabularyHints:
          (json['vocabulary_hints'] as List<dynamic>?)
              ?.map((value) => value.toString())
              .where((value) => value.trim().isNotEmpty)
              .take(5)
              .toList(growable: false) ??
          const [],
      spoilerBoundaryNote: json['spoiler_boundary_note'] as String? ?? '',
    );
  }

  factory AIChapterPreview.fallback(String rawText) {
    return AIChapterPreview(
      setup: 'AI 返回了非结构化读前预览。',
      focusPoints: [rawText],
      vocabularyHints: const [],
      spoilerBoundaryNote: '此内容来自 fallback 展示，仍只应按当前章节边界使用。',
    );
  }

  Map<String, dynamic> toJson() => {
    'setup': setup,
    'focus_points': focusPoints,
    'vocabulary_hints': vocabularyHints,
    'spoiler_boundary_note': spoilerBoundaryNote,
  };

  bool get isEmpty {
    return setup.trim().isEmpty &&
        focusPoints.isEmpty &&
        vocabularyHints.isEmpty &&
        spoilerBoundaryNote.trim().isEmpty;
  }
}

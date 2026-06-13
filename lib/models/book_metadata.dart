import 'book_difficulty.dart';

class BookMetadata {
  final String id;
  final String title;
  final String author;
  final String sourcePath;
  final String? coverPath;
  final int totalChapters;
  final double globalProgress;
  final int currentChapter;
  final double chapterProgress;
  final DateTime? lastReadAt;
  final List<String>? difficultyStudyWords;
  final Map<String, dynamic>? difficultyRatingJson;
  final String? difficultyVocabularySignature;
  final DateTime? difficultyComputedAt;
  final double? chapterScrollOffset;
  final String? sourceLanguage;
  final String? sourceLanguageOverride;
  final double? languageConfidence;
  final String? targetExplanationLanguage;

  const BookMetadata({
    required this.id,
    required this.title,
    required this.author,
    required this.sourcePath,
    this.coverPath,
    this.totalChapters = 0,
    this.globalProgress = 0.0,
    this.currentChapter = 0,
    this.chapterProgress = 0.0,
    this.lastReadAt,
    this.difficultyStudyWords,
    this.difficultyRatingJson,
    this.difficultyVocabularySignature,
    this.difficultyComputedAt,
    this.chapterScrollOffset,
    this.sourceLanguage,
    this.sourceLanguageOverride,
    this.languageConfidence,
    this.targetExplanationLanguage,
  });

  String get effectiveSourceLanguage =>
      sourceLanguageOverride ?? sourceLanguage ?? 'en';

  String effectiveTargetExplanationLanguage(String globalLanguage) =>
      targetExplanationLanguage ?? globalLanguage;

  BookDifficultyRating? get difficultyRating {
    final json = difficultyRatingJson;
    if (json == null) return null;
    try {
      return BookDifficultyRating.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  BookMetadata copyWith({
    String? id,
    String? title,
    String? author,
    String? sourcePath,
    String? coverPath,
    int? totalChapters,
    double? globalProgress,
    int? currentChapter,
    double? chapterProgress,
    DateTime? lastReadAt,
    List<String>? difficultyStudyWords,
    Map<String, dynamic>? difficultyRatingJson,
    String? difficultyVocabularySignature,
    DateTime? difficultyComputedAt,
    double? chapterScrollOffset,
    String? sourceLanguage,
    String? sourceLanguageOverride,
    double? languageConfidence,
    String? targetExplanationLanguage,
    bool clearSourceLanguageOverride = false,
    bool clearLanguageConfidence = false,
    bool clearTargetExplanationLanguage = false,
  }) {
    return BookMetadata(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      sourcePath: sourcePath ?? this.sourcePath,
      coverPath: coverPath ?? this.coverPath,
      totalChapters: totalChapters ?? this.totalChapters,
      globalProgress: globalProgress ?? this.globalProgress,
      currentChapter: currentChapter ?? this.currentChapter,
      chapterProgress: chapterProgress ?? this.chapterProgress,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      difficultyStudyWords: difficultyStudyWords ?? this.difficultyStudyWords,
      difficultyRatingJson: difficultyRatingJson ?? this.difficultyRatingJson,
      difficultyVocabularySignature:
          difficultyVocabularySignature ?? this.difficultyVocabularySignature,
      difficultyComputedAt: difficultyComputedAt ?? this.difficultyComputedAt,
      chapterScrollOffset: chapterScrollOffset ?? this.chapterScrollOffset,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      sourceLanguageOverride: clearSourceLanguageOverride
          ? null
          : sourceLanguageOverride ?? this.sourceLanguageOverride,
      languageConfidence: clearLanguageConfidence
          ? null
          : languageConfidence ?? this.languageConfidence,
      targetExplanationLanguage: clearTargetExplanationLanguage
          ? null
          : targetExplanationLanguage ?? this.targetExplanationLanguage,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'sourcePath': sourcePath,
    'coverPath': coverPath,
    'totalChapters': totalChapters,
    'globalProgress': globalProgress,
    'currentChapter': currentChapter,
    'chapterProgress': chapterProgress,
    'lastReadAt': lastReadAt?.toIso8601String(),
    'difficultyStudyWords': difficultyStudyWords,
    'difficultyRating': difficultyRatingJson,
    'difficultyVocabularySignature': difficultyVocabularySignature,
    'difficultyComputedAt': difficultyComputedAt?.toIso8601String(),
    'chapterScrollOffset': chapterScrollOffset,
    'sourceLanguage': sourceLanguage,
    'sourceLanguageOverride': sourceLanguageOverride,
    'languageConfidence': languageConfidence,
    'targetExplanationLanguage': targetExplanationLanguage,
  };

  factory BookMetadata.fromJson(Map<String, dynamic> json) {
    final rawDifficultyStudyWords = json['difficultyStudyWords'];
    final rawDifficultyRating = json['difficultyRating'];
    final rawDifficultyComputedAt = json['difficultyComputedAt'];
    return BookMetadata(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      sourcePath: json['sourcePath'] as String,
      coverPath: json['coverPath'] as String?,
      totalChapters: json['totalChapters'] as int? ?? 0,
      globalProgress: (json['globalProgress'] as num?)?.toDouble() ?? 0.0,
      currentChapter: json['currentChapter'] as int? ?? 0,
      chapterProgress: (json['chapterProgress'] as num?)?.toDouble() ?? 0.0,
      lastReadAt: json['lastReadAt'] != null
          ? DateTime.tryParse(json['lastReadAt'] as String)
          : null,
      difficultyStudyWords: rawDifficultyStudyWords is Iterable
          ? rawDifficultyStudyWords.map((word) => word.toString()).toList()
          : null,
      difficultyRatingJson: rawDifficultyRating is Map
          ? rawDifficultyRating.map(
              (key, value) => MapEntry(key.toString(), value),
            )
          : null,
      difficultyVocabularySignature: json['difficultyVocabularySignature']
          ?.toString(),
      difficultyComputedAt: rawDifficultyComputedAt is String
          ? DateTime.tryParse(rawDifficultyComputedAt)
          : null,
      chapterScrollOffset: (json['chapterScrollOffset'] as num?)?.toDouble(),
      sourceLanguage: json['sourceLanguage']?.toString(),
      sourceLanguageOverride: json['sourceLanguageOverride']?.toString(),
      languageConfidence: (json['languageConfidence'] as num?)?.toDouble(),
      targetExplanationLanguage: json['targetExplanationLanguage']?.toString(),
    );
  }
}

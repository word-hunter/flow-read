import 'package:hive/hive.dart';

import 'book_difficulty.dart';

part 'book_metadata.g.dart';

@HiveType(typeId: 0)
class BookMetadata {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String author;

  @HiveField(3)
  final String sourcePath;

  @HiveField(4)
  final String? coverPath;

  @HiveField(5)
  final int totalChapters;

  @HiveField(6)
  final double globalProgress;

  @HiveField(7)
  final int currentChapter;

  @HiveField(8)
  final double chapterProgress;

  @HiveField(9)
  final DateTime? lastReadAt;

  @HiveField(10)
  final List<String>? difficultyStudyWords;

  @HiveField(11)
  final Map<String, dynamic>? difficultyRatingJson;

  @HiveField(12)
  final String? difficultyVocabularySignature;

  @HiveField(13)
  final DateTime? difficultyComputedAt;

  @HiveField(14)
  final double? chapterScrollOffset;

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
  });

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
    );
  }
}

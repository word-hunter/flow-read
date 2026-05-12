import 'package:hive/hive.dart';

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
  });

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
      };

  factory BookMetadata.fromJson(Map<String, dynamic> json) {
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
    );
  }
}

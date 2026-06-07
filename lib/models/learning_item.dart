import 'package:hive/hive.dart';

import 'ai_text_analysis.dart';

part 'learning_item.g.dart';

enum LearningItemType { word, sentence, grammar, expression, questionMistake }

LearningItemType learningItemTypeFromName(String? value) {
  for (final type in LearningItemType.values) {
    if (type.name == value) return type;
  }
  return LearningItemType.word;
}

enum LearningReviewResult { newItem, remembered, missed }

LearningReviewResult learningReviewResultFromName(String? value) {
  for (final result in LearningReviewResult.values) {
    if (result.name == value) return result;
  }
  return LearningReviewResult.newItem;
}

extension LearningItemTypeLabel on LearningItemType {
  String get label {
    return switch (this) {
      LearningItemType.word => '词汇',
      LearningItemType.sentence => '句段',
      LearningItemType.grammar => '语法',
      LearningItemType.expression => '表达',
      LearningItemType.questionMistake => '错题',
    };
  }
}

@HiveType(typeId: 11)
class LearningItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final LearningItemType type;

  @HiveField(2)
  final String canonicalKey;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final String content;

  @HiveField(5)
  final String answer;

  @HiveField(6)
  final String note;

  @HiveField(7)
  final String sourceText;

  @HiveField(8)
  final String bookId;

  @HiveField(9)
  final int chapterIndex;

  @HiveField(10)
  final String chapterTitle;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime updatedAt;

  @HiveField(13)
  final List<String> tags;

  @HiveField(14)
  final Map<String, String> metadata;

  @HiveField(15)
  final DateTime nextReviewAt;

  @HiveField(16)
  final int reviewCount;

  @HiveField(17)
  final LearningReviewResult lastResult;

  const LearningItem({
    required this.id,
    required this.type,
    required this.canonicalKey,
    required this.title,
    required this.content,
    required this.answer,
    required this.note,
    required this.sourceText,
    required this.bookId,
    required this.chapterIndex,
    required this.chapterTitle,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.metadata = const {},
    DateTime? nextReviewAt,
    this.reviewCount = 0,
    this.lastResult = LearningReviewResult.newItem,
  }) : nextReviewAt = nextReviewAt ?? createdAt;

  bool matchesIdentity({
    required String bookId,
    required int chapterIndex,
    required LearningItemType type,
    required String canonicalKey,
  }) {
    return this.bookId == bookId &&
        this.chapterIndex == chapterIndex &&
        this.type == type &&
        this.canonicalKey == canonicalKey;
  }

  LearningItem copyWith({
    String? id,
    LearningItemType? type,
    String? canonicalKey,
    String? title,
    String? content,
    String? answer,
    String? note,
    String? sourceText,
    String? bookId,
    int? chapterIndex,
    String? chapterTitle,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    Map<String, String>? metadata,
    DateTime? nextReviewAt,
    int? reviewCount,
    LearningReviewResult? lastResult,
  }) {
    return LearningItem(
      id: id ?? this.id,
      type: type ?? this.type,
      canonicalKey: canonicalKey ?? this.canonicalKey,
      title: title ?? this.title,
      content: content ?? this.content,
      answer: answer ?? this.answer,
      note: note ?? this.note,
      sourceText: sourceText ?? this.sourceText,
      bookId: bookId ?? this.bookId,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      reviewCount: reviewCount ?? this.reviewCount,
      lastResult: lastResult ?? this.lastResult,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'canonicalKey': canonicalKey,
      'title': title,
      'content': content,
      'answer': answer,
      'note': note,
      'sourceText': sourceText,
      'bookId': bookId,
      'chapterIndex': chapterIndex,
      'chapterTitle': chapterTitle,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'metadata': metadata,
      'nextReviewAt': nextReviewAt.toIso8601String(),
      'reviewCount': reviewCount,
      'lastResult': lastResult.name,
    };
  }

  factory LearningItem.fromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final updatedAt =
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return LearningItem(
      id: json['id'] as String,
      type: learningItemTypeFromName(json['type'] as String?),
      canonicalKey: json['canonicalKey'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      note: json['note'] as String? ?? '',
      sourceText: json['sourceText'] as String? ?? '',
      bookId: json['bookId'] as String? ?? '',
      chapterIndex: json['chapterIndex'] as int? ?? -1,
      chapterTitle: json['chapterTitle'] as String? ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((value) => value.toString())
              .where((value) => value.isNotEmpty)
              .toList() ??
          const [],
      metadata:
          (json['metadata'] as Map?)
              ?.map((key, value) => MapEntry(key.toString(), value.toString()))
              .cast<String, String>() ??
          const {},
      nextReviewAt:
          DateTime.tryParse(json['nextReviewAt'] as String? ?? '') ?? createdAt,
      reviewCount: json['reviewCount'] as int? ?? 0,
      lastResult: learningReviewResultFromName(json['lastResult'] as String?),
    );
  }
}

class LearningItemSource {
  final String bookId;
  final String? bookTitle;
  final int chapterIndex;
  final String chapterTitle;

  const LearningItemSource({
    required this.bookId,
    this.bookTitle,
    required this.chapterIndex,
    required this.chapterTitle,
  });

  const LearningItemSource.unknown()
      : bookId = '',
        bookTitle = null,
        chapterIndex = -1,
        chapterTitle = '';
}

class LearningItemSaveResult {
  final LearningItem item;
  final bool created;

  const LearningItemSaveResult({required this.item, required this.created});
}

class LearningItemDraft {
  final LearningItemType type;
  final String canonicalKey;
  final String title;
  final String content;
  final String answer;
  final String note;
  final String sourceText;
  final LearningItemSource source;
  final List<String> tags;
  final Map<String, String> metadata;

  const LearningItemDraft({
    required this.type,
    required this.canonicalKey,
    required this.title,
    required this.content,
    required this.answer,
    required this.note,
    required this.sourceText,
    required this.source,
    this.tags = const [],
    this.metadata = const {},
  });

  factory LearningItemDraft.word({
    required String word,
    required String definition,
    required String context,
    required LearningItemSource source,
    Map<String, String> metadata = const {},
  }) {
    return LearningItemDraft(
      type: LearningItemType.word,
      canonicalKey: word,
      title: word,
      content: word,
      answer: definition,
      note: '',
      sourceText: context,
      source: source,
      tags: const ['lookup'],
      metadata: metadata,
    );
  }

  factory LearningItemDraft.selectedText({
    required String selectedText,
    required AITextAnalysis analysis,
    required LearningItemSource source,
  }) {
    return LearningItemDraft(
      type: LearningItemType.sentence,
      canonicalKey: selectedText,
      title: _preview(selectedText),
      content: selectedText,
      answer: analysis.translation,
      note: analysis.readingTip,
      sourceText: selectedText,
      source: source,
      tags: const ['ai'],
      metadata: {
        'grammarCount': analysis.grammarPoints.length.toString(),
        'vocabularyCount': analysis.vocabularyNotes.length.toString(),
        'expressionCount': analysis.expressionNotes.length.toString(),
      },
    );
  }

  factory LearningItemDraft.vocabularyNote({
    required VocabularyNote note,
    required String selectedText,
    required LearningItemSource source,
  }) {
    return LearningItemDraft(
      type: LearningItemType.word,
      canonicalKey: note.word,
      title: note.word,
      content: note.word,
      answer: note.contextMeaning,
      note: note.pos,
      sourceText: selectedText,
      source: source,
      tags: const ['ai', 'vocabulary'],
      metadata: {'pos': note.pos},
    );
  }

  factory LearningItemDraft.grammarPoint({
    required GrammarPoint point,
    required String selectedText,
    required LearningItemSource source,
  }) {
    return LearningItemDraft(
      type: LearningItemType.grammar,
      canonicalKey: point.source,
      title: _preview(point.source),
      content: point.source,
      answer: point.explanation,
      note: point.difficulty,
      sourceText: selectedText,
      source: source,
      tags: const ['ai', 'grammar'],
      metadata: {'difficulty': point.difficulty},
    );
  }

  factory LearningItemDraft.expressionNote({
    required ExpressionNote note,
    required String selectedText,
    required LearningItemSource source,
  }) {
    return LearningItemDraft(
      type: LearningItemType.expression,
      canonicalKey: note.source,
      title: _preview(note.source),
      content: note.source,
      answer: note.meaning,
      note: note.usage,
      sourceText: selectedText,
      source: source,
      tags: const ['ai', 'expression'],
    );
  }

  factory LearningItemDraft.questionMistake({
    required String question,
    required String correctAnswer,
    required String selectedAnswer,
    required String sourceExcerpt,
    required String explanation,
    required LearningItemSource source,
    Map<String, String> metadata = const {},
  }) {
    return LearningItemDraft(
      type: LearningItemType.questionMistake,
      canonicalKey: question,
      title: _preview(question),
      content: question,
      answer: correctAnswer,
      note: explanation,
      sourceText: sourceExcerpt,
      source: source,
      tags: const ['practice', 'mistake'],
      metadata: {
        ...metadata,
        if (selectedAnswer.trim().isNotEmpty)
          'selectedAnswer': selectedAnswer.trim(),
      },
    );
  }

  static String _preview(String text, {int maxLength = 80}) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxLength) return normalized;
    return '${normalized.substring(0, maxLength).trim()}...';
  }
}

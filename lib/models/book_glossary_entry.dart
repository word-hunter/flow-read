import 'dart:convert';

import 'package:hive/hive.dart';

import '../storage/hive_type_ids.dart';

part 'book_glossary_entry.g.dart';

@HiveType(typeId: HiveTypeIds.bookGlossaryEntry)
class BookGlossaryEntry {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String bookId;

  @HiveField(2)
  final String word;

  @HiveField(3)
  final String? canonicalForm;

  @HiveField(4)
  final String explanation;

  @HiveField(5)
  final String? sourceContext;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? lastAccessedAt;

  const BookGlossaryEntry({
    required this.id,
    required this.bookId,
    required this.word,
    this.canonicalForm,
    required this.explanation,
    this.sourceContext,
    required this.createdAt,
    this.lastAccessedAt,
  });

  factory BookGlossaryEntry.create({
    required String bookId,
    required String word,
    String? canonicalForm,
    required String explanation,
    String? sourceContext,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
  }) {
    return BookGlossaryEntry(
      id: buildId(bookId: bookId, word: word, canonicalForm: canonicalForm),
      bookId: bookId,
      word: word,
      canonicalForm: canonicalForm,
      explanation: explanation,
      sourceContext: sourceContext,
      createdAt: createdAt ?? DateTime.now(),
      lastAccessedAt: lastAccessedAt,
    );
  }

  static String buildId({
    required String bookId,
    required String word,
    String? canonicalForm,
  }) {
    final raw = [
      bookId.trim(),
      word.trim().toLowerCase(),
      canonicalForm?.trim().toLowerCase() ?? '',
    ].join('\u001f');
    return _fnv1a64(utf8.encode(raw)).toRadixString(16).padLeft(16, '0');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookId': bookId,
    'word': word,
    'canonicalForm': canonicalForm,
    'explanation': explanation,
    'sourceContext': sourceContext,
    'createdAt': createdAt.toIso8601String(),
    'lastAccessedAt': lastAccessedAt?.toIso8601String(),
  };

  factory BookGlossaryEntry.fromJson(Map<String, dynamic> json) {
    return BookGlossaryEntry(
      id: json['id']?.toString() ?? '',
      bookId: json['bookId']?.toString() ?? '',
      word: json['word']?.toString() ?? '',
      canonicalForm: json['canonicalForm']?.toString(),
      explanation: json['explanation']?.toString() ?? '',
      sourceContext: json['sourceContext']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      lastAccessedAt: DateTime.tryParse(
        json['lastAccessedAt']?.toString() ?? '',
      ),
    );
  }
}

int _fnv1a64(List<int> bytes) {
  const mask = 0x7fffffffffffffff;
  var hash = 0xcbf29ce484222325;
  for (final byte in bytes) {
    hash ^= byte;
    hash = (hash * 0x100000001b3) & mask;
  }
  return hash;
}

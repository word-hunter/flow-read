import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../models/book_metadata.dart';
import '../../repositories/book_metadata_repository.dart';
import '../app_database.dart';
import '../dao/book_dao.dart';

final class DriftBookRepository implements BookMetadataRepository {
  DriftBookRepository(
    this._dao, {
    required String languageCode,
    Iterable<BookMetadata> initialValues = const [],
  }) : _languageCode = languageCode {
    for (final book in initialValues) {
      _cache[book.id] = book;
    }
  }

  final BookDao _dao;
  final String _languageCode;
  final Map<String, BookMetadata> _cache = {};

  @override
  Future<void> init() async {
    final entries = await _dao.allBooks(_languageCode);
    _cache
      ..clear()
      ..addEntries(
        entries.map((entry) {
          final metadata = metadataFromEntry(entry);
          return MapEntry(metadata.id, metadata);
        }),
      );
  }

  @override
  Iterable<BookMetadata> get values => _cache.values;

  @override
  BookMetadata? get(String id) => _cache[id];

  @override
  Future<void> put(String id, BookMetadata metadata) async {
    await _dao.upsert(
      companionFromMetadata(metadata, languageCode: _languageCode),
    );
    _cache[id] = metadata;
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deleteById(id);
    _cache.remove(id);
  }

  @override
  Future<void> close() async {}

  Future<List<BookMetadata>> allBooks(String language) async {
    final entries = await _dao.allBooks(language);
    return entries.map(metadataFromEntry).toList(growable: false);
  }

  Future<BookMetadata?> getById(String id) async {
    final entry = await _dao.getById(id);
    return entry == null ? null : metadataFromEntry(entry);
  }

  Future<List<BookEntry>> recentlyRead(String language, {int limit = 20}) =>
      _dao.recentlyReadBooks(language, limit: limit);

  Future<void> upsert(BookEntriesCompanion entry) => _dao.upsert(entry);

  Future<void> deleteById(String id) => _dao.deleteById(id);

  Stream<List<BookEntry>> watchAll(String language) => _dao.watchAll(language);

  Stream<BookEntry?> watchById(String id) => _dao.watchById(id);

  static BookMetadata metadataFromEntry(BookEntry entry) {
    return BookMetadata(
      id: entry.id,
      title: entry.title,
      author: entry.author,
      sourcePath: entry.sourcePath,
      coverPath: entry.coverPath,
      totalChapters: entry.totalChapters,
      globalProgress: entry.globalProgress,
      currentChapter: entry.currentChapter,
      chapterProgress: entry.chapterProgress,
      lastReadAt: _parseDate(entry.lastReadAt),
      difficultyStudyWords: _decodeStringList(entry.difficultyStudyWords),
      difficultyRatingJson: _decodeStringMap(entry.difficultyRatingJson),
      difficultyVocabularySignature: entry.difficultyVocabularySignature,
      difficultyComputedAt: _parseDate(entry.difficultyComputedAt),
      chapterScrollOffset: entry.chapterScrollOffset,
      sourceLanguage: entry.sourceLanguage,
      sourceLanguageOverride: entry.sourceLanguageOverride,
      languageConfidence: entry.languageConfidence,
      targetExplanationLanguage: entry.targetExplanationLanguage,
    );
  }

  static BookEntriesCompanion companionFromMetadata(
    BookMetadata metadata, {
    required String languageCode,
  }) {
    return BookEntriesCompanion.insert(
      id: metadata.id,
      title: metadata.title,
      sourcePath: metadata.sourcePath,
      language: Value(_effectiveLanguage(metadata, languageCode)),
      author: Value(metadata.author),
      coverPath: Value(metadata.coverPath),
      totalChapters: Value(metadata.totalChapters),
      globalProgress: Value(metadata.globalProgress),
      currentChapter: Value(metadata.currentChapter),
      chapterProgress: Value(metadata.chapterProgress),
      lastReadAt: Value(_dateString(metadata.lastReadAt)),
      chapterScrollOffset: Value(metadata.chapterScrollOffset),
      sourceLanguage: Value(metadata.sourceLanguage ?? languageCode),
      sourceLanguageOverride: Value(metadata.sourceLanguageOverride),
      languageConfidence: Value(metadata.languageConfidence),
      targetExplanationLanguage: Value(metadata.targetExplanationLanguage),
      difficultyStudyWords: Value(_encodeOrNull(metadata.difficultyStudyWords)),
      difficultyRatingJson: Value(_encodeOrNull(metadata.difficultyRatingJson)),
      difficultyVocabularySignature: Value(
        metadata.difficultyVocabularySignature,
      ),
      difficultyComputedAt: Value(_dateString(metadata.difficultyComputedAt)),
    );
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static String? _dateString(DateTime? value) =>
      value?.toUtc().toIso8601String();

  static String _effectiveLanguage(BookMetadata metadata, String languageCode) {
    return metadata.sourceLanguageOverride ??
        metadata.sourceLanguage ??
        languageCode;
  }

  static String? _encodeOrNull(Object? value) {
    if (value == null) return null;
    return jsonEncode(value);
  }

  static List<String>? _decodeStringList(String? value) {
    if (value == null || value.isEmpty) return null;
    final decoded = jsonDecode(value);
    if (decoded is! Iterable) return null;
    return decoded.map((item) => item.toString()).toList(growable: false);
  }

  static Map<String, dynamic>? _decodeStringMap(String? value) {
    if (value == null || value.isEmpty) return null;
    final decoded = jsonDecode(value);
    if (decoded is! Map) return null;
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
}

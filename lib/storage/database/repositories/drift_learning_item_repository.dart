import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../models/learning_item.dart' as models;
import '../app_database.dart';
import '../dao/learning_item_dao.dart';
import '../../repositories/learning_item_repository.dart';
import '../../repositories/repository_language.dart';

final class DriftLearningItemRepository implements LearningItemRepository {
  DriftLearningItemRepository(
    this._dao, {
    required String languageCode,
    Iterable<models.LearningItem> initialValues = const [],
  }) : _languageCode = normalizeRepositoryLanguageCode(languageCode) {
    for (final item in initialValues) {
      _cache[item.id] = item;
    }
  }

  final LearningItemDao _dao;
  final String _languageCode;
  final Map<String, models.LearningItem> _cache = {};

  @override
  Future<void> init() async {
    final rows = await _dao.allForLanguage(_languageCode);
    _cache
      ..clear()
      ..addEntries(
        rows.map((entry) {
          final item = itemFromEntry(entry);
          return MapEntry(item.id, item);
        }),
      );
  }

  @override
  Iterable<models.LearningItem> get values => _cache.values;

  @override
  Iterable<dynamic> get keys => _cache.keys;

  @override
  int get length => _cache.length;

  @override
  models.LearningItem? get(dynamic key) => _cache[key?.toString()];

  @override
  Future<void> put(String id, models.LearningItem item) async {
    await _dao.upsert(companionFromItem(item, languageCode: _languageCode));
    _cache[id] = item;
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deleteById(id);
    _cache.remove(id);
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    final ids = keys.map((key) => key.toString()).toSet();
    if (ids.isEmpty) return;
    await _dao.deleteByIds(ids);
    for (final id in ids) {
      _cache.remove(id);
    }
  }

  @override
  Future<void> clear() async {
    await _dao.clearForLanguage(_languageCode);
    _cache.clear();
  }

  @override
  Future<void> close() async {}

  static models.LearningItem itemFromEntry(LearningItemEntry entry) {
    final createdAt = _parseDate(entry.createdAt);
    return models.LearningItem(
      id: entry.id,
      type: models.learningItemTypeFromName(entry.type),
      canonicalKey: entry.canonicalKey,
      title: entry.title,
      content: entry.content,
      answer: entry.answer,
      note: entry.note,
      sourceText: entry.sourceText,
      bookId: entry.bookId,
      chapterIndex: entry.chapterIndex,
      chapterTitle: entry.chapterTitle,
      createdAt: createdAt,
      updatedAt: _parseDate(entry.updatedAt),
      tags: _decodeStringList(entry.tags),
      metadata: _decodeStringMap(entry.metadata),
      nextReviewAt: _parseDate(entry.nextReviewAt),
      reviewCount: entry.reviewCount,
      lastResult: models.learningReviewResultFromName(entry.lastResult),
    );
  }

  static LearningItemsCompanion companionFromItem(
    models.LearningItem item, {
    required String languageCode,
  }) {
    return LearningItemsCompanion.insert(
      id: item.id,
      type: item.type.name,
      nextReviewAt: _dateString(item.nextReviewAt),
      language: Value(languageCode),
      canonicalKey: Value(item.canonicalKey),
      title: Value(item.title),
      content: Value(item.content),
      answer: Value(item.answer),
      note: Value(item.note),
      sourceText: Value(item.sourceText),
      bookId: Value(item.bookId),
      chapterIndex: Value(item.chapterIndex),
      chapterTitle: Value(item.chapterTitle),
      tags: Value(jsonEncode(item.tags)),
      metadata: Value(jsonEncode(item.metadata)),
      reviewCount: Value(item.reviewCount),
      lastResult: Value(item.lastResult.name),
      createdAt: Value(_dateString(item.createdAt)),
      updatedAt: Value(_dateString(item.updatedAt)),
    );
  }

  static DateTime _parseDate(String value) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _dateString(DateTime value) => value.toUtc().toIso8601String();

  static List<String> _decodeStringList(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Iterable) return const [];
    return decoded.map((item) => item.toString()).toList(growable: false);
  }

  static Map<String, String> _decodeStringMap(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) return const {};
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }
}

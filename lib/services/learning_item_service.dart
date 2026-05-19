import 'package:hive/hive.dart';

import '../models/learning_item.dart';
import '../storage/hive_box_names.dart';

class LearningItemService {
  late Box<LearningItem> _box;

  Future<void> init() async {
    _box = Hive.box<LearningItem>(HiveBoxNames.learningItems);
  }

  List<LearningItem> get allItems {
    final items = _box.values.toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  int get count => _box.length;

  LearningItem? findDuplicate({
    required String bookId,
    required int chapterIndex,
    required LearningItemType type,
    required String canonicalKey,
  }) {
    final normalizedBookId = bookId.trim();
    final normalizedKey = normalizeCanonicalKey(canonicalKey);
    if (normalizedKey.isEmpty) return null;

    for (final item in _box.values) {
      if (item.matchesIdentity(
        bookId: normalizedBookId,
        chapterIndex: chapterIndex,
        type: type,
        canonicalKey: normalizedKey,
      )) {
        return item;
      }
    }
    return null;
  }

  bool contains({
    required String bookId,
    required int chapterIndex,
    required LearningItemType type,
    required String canonicalKey,
  }) {
    return findDuplicate(
          bookId: bookId,
          chapterIndex: chapterIndex,
          type: type,
          canonicalKey: canonicalKey,
        ) !=
        null;
  }

  Future<LearningItemSaveResult> saveDraft(LearningItemDraft draft) async {
    final normalizedKey = normalizeCanonicalKey(draft.canonicalKey);
    final source = draft.source;
    final duplicate = findDuplicate(
      bookId: source.bookId,
      chapterIndex: source.chapterIndex,
      type: draft.type,
      canonicalKey: normalizedKey,
    );
    if (duplicate != null) {
      return LearningItemSaveResult(item: duplicate, created: false);
    }

    final now = DateTime.now();
    final item = LearningItem(
      id: _newId(draft.type, normalizedKey, now),
      type: draft.type,
      canonicalKey: normalizedKey,
      title: draft.title.trim(),
      content: draft.content.trim(),
      answer: draft.answer.trim(),
      note: draft.note.trim(),
      sourceText: draft.sourceText.trim(),
      bookId: source.bookId.trim(),
      chapterIndex: source.chapterIndex,
      chapterTitle: source.chapterTitle.trim(),
      createdAt: now,
      updatedAt: now,
      tags: _cleanList(draft.tags),
      metadata: _cleanMap(draft.metadata),
    );
    await _box.put(item.id, item);
    return LearningItemSaveResult(item: item, created: true);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> deleteForBook(String bookId) async {
    final keys = <dynamic>[];
    for (final key in _box.keys) {
      final item = _box.get(key);
      if (item?.bookId == bookId) keys.add(key);
    }
    if (keys.isNotEmpty) {
      await _box.deleteAll(keys);
    }
  }

  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> close() async {
    await _box.close();
  }

  static String normalizeCanonicalKey(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '')
        .trim();
  }

  String _newId(
    LearningItemType type,
    String canonicalKey,
    DateTime createdAt,
  ) {
    return '${type.name}_${createdAt.microsecondsSinceEpoch}_${canonicalKey.hashCode.abs()}';
  }

  List<String> _cleanList(List<String> source) {
    return source
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  Map<String, String> _cleanMap(Map<String, String> source) {
    return {
      for (final entry in source.entries)
        if (entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty)
          entry.key.trim(): entry.value.trim(),
    };
  }
}

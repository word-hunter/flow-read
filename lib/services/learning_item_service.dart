import '../models/learning_item.dart';
import '../storage/repositories/learning_item_repository.dart';

class LearningItemService {
  LearningItemService({
    required LearningItemRepository repository,
    DateTime Function()? clock,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now;

  final LearningItemRepository _repository;
  final DateTime Function() _clock;

  Future<void> init() async {
    await _repository.init();
  }

  List<LearningItem> get allItems {
    final items = _repository.values.toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  int get count => _repository.length;

  LearningItem? getById(String id) {
    return _repository.get(id);
  }

  LearningItem? findDuplicate({
    required String bookId,
    required int chapterIndex,
    required LearningItemType type,
    required String canonicalKey,
  }) {
    final normalizedBookId = bookId.trim();
    final normalizedKey = normalizeCanonicalKey(canonicalKey);
    if (normalizedKey.isEmpty) return null;

    for (final item in _repository.values) {
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

    final now = _clock();
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
    await _repository.put(item.id, item);
    return LearningItemSaveResult(item: item, created: true);
  }

  Future<void> saveItem(LearningItem item) async {
    await _repository.put(item.id, item);
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
  }

  Future<void> deleteForBook(String bookId) async {
    final keys = <dynamic>[];
    for (final key in _repository.keys) {
      final item = _repository.get(key);
      if (item?.bookId == bookId) keys.add(key);
    }
    if (keys.isNotEmpty) {
      await _repository.deleteAll(keys);
    }
  }

  Future<void> clear() async {
    await _repository.clear();
  }

  Future<void> close() async {
    await _repository.close();
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

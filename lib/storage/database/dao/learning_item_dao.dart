import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'learning_item_dao.g.dart';

@DriftAccessor(tables: [LearningItems])
class LearningItemDao extends DatabaseAccessor<AppDatabase>
    with _$LearningItemDaoMixin {
  LearningItemDao(super.db);

  Future<List<LearningItemEntry>> allForLanguage(
    String language, {
    int? limit,
  }) {
    final query = select(learningItems)
      ..where((r) => r.language.equals(language))
      ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]);
    if (limit != null) {
      query.limit(limit);
    }
    return query.get();
  }

  Future<LearningItemEntry?> getById(String id) {
    final q = select(learningItems)..where((r) => r.id.equals(id));
    return q.getSingleOrNull();
  }

  Future<void> upsert(LearningItemsCompanion entry) =>
      into(learningItems).insertOnConflictUpdate(entry);

  Future<void> deleteById(String id) =>
      (delete(learningItems)..where((r) => r.id.equals(id))).go();

  Future<void> deleteByIds(Set<String> ids) {
    return (delete(learningItems)..where((r) => r.id.isIn(ids))).go();
  }

  Future<void> clearForLanguage(String language) =>
      (delete(learningItems)..where((r) => r.language.equals(language))).go();

  Future<int> countForLanguage(String language) {
    final q = selectOnly(learningItems)
      ..addColumns([learningItems.id])
      ..where(learningItems.language.equals(language));
    return q.map((r) => r.read(learningItems.id)).get().then((r) => r.length);
  }

  Future<List<LearningItemEntry>> dueForReview(
    String language,
    DateTime before,
  ) {
    final cutoff = before.toUtc().toIso8601String();
    return (select(learningItems)
          ..where(
            (r) =>
                r.language.equals(language) &
                r.nextReviewAt.isSmallerOrEqualValue(cutoff),
          )
          ..orderBy([(r) => OrderingTerm.asc(r.nextReviewAt)]))
        .get();
  }
}

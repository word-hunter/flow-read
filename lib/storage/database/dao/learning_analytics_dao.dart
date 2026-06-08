import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'learning_analytics_dao.g.dart';

@DriftAccessor(tables: [LearningAnalytics])
class LearningAnalyticsDao extends DatabaseAccessor<AppDatabase>
    with _$LearningAnalyticsDaoMixin {
  LearningAnalyticsDao(super.db);

  Future<int> valueFor(String key, String language) async {
    final q = select(learningAnalytics)
      ..where((r) => r.key.equals(key) & r.language.equals(language));
    final result = await q.map((r) => r.value).getSingleOrNull();
    return result ?? 0;
  }

  Future<void> putValue(String key, String language, int value) =>
      into(learningAnalytics).insertOnConflictUpdate(
        LearningAnalyticsCompanion.insert(
          key: key,
          language: Value(language),
          value: Value(value),
        ),
      );

  Future<List<LearningAnalyticsEntry>> allForLanguage(String language) =>
      (select(learningAnalytics)
            ..where((r) => r.language.equals(language)))
          .get();

  @override
  Future<void> close() async {}
}

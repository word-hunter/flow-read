import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'reading_time_dao.g.dart';

@DriftAccessor(tables: [ReadingTime])
class ReadingTimeDao extends DatabaseAccessor<AppDatabase>
    with _$ReadingTimeDaoMixin {
  ReadingTimeDao(super.db);

  Future<int> secondsFor(String key, String language) async {
    final q = select(readingTime)
      ..where((r) => r.key.equals(key) & r.language.equals(language));
    final result = await q.map((r) => r.seconds).getSingleOrNull();
    return result ?? 0;
  }

  Future<void> putSeconds(String key, String language, int seconds) =>
      into(readingTime).insertOnConflictUpdate(
        ReadingTimeCompanion.insert(
          key: key,
          language: Value(language),
          seconds: Value(seconds),
        ),
      );

  Future<int> totalSecondsForLanguage(String language) async {
    final rows = await (select(readingTime)
          ..where((r) => r.language.equals(language)))
        .get();
    return rows.fold<int>(0, (sum, r) => sum + r.seconds);
  }
}

import '../app_database.dart';
import '../dao/learning_item_dao.dart';

final class DriftLearningItemRepository {
  final LearningItemDao _dao;

  DriftLearningItemRepository(this._dao);

  Future<List<LearningItemEntry>> allForLanguage(String language,
          {int? limit}) =>
      _dao.allForLanguage(language, limit: limit);

  Future<LearningItemEntry?> getById(String id) => _dao.getById(id);

  Future<void> upsert(LearningItemsCompanion entry) => _dao.upsert(entry);

  Future<void> deleteById(String id) => _dao.deleteById(id);

  Future<void> deleteByIds(Set<String> ids) => _dao.deleteByIds(ids);

  Future<void> clearForLanguage(String language) =>
      _dao.clearForLanguage(language);

  Future<int> countForLanguage(String language) =>
      _dao.countForLanguage(language);

  Future<List<LearningItemEntry>> dueForReview(
    String language,
    DateTime before,
  ) =>
      _dao.dueForReview(language, before);
}

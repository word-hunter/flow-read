// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_analytics_dao.dart';

// ignore_for_file: type=lint
mixin _$LearningAnalyticsDaoMixin on DatabaseAccessor<AppDatabase> {
  $LearningAnalyticsTable get learningAnalytics =>
      attachedDatabase.learningAnalytics;
  LearningAnalyticsDaoManager get managers => LearningAnalyticsDaoManager(this);
}

class LearningAnalyticsDaoManager {
  final _$LearningAnalyticsDaoMixin _db;
  LearningAnalyticsDaoManager(this._db);
  $$LearningAnalyticsTableTableManager get learningAnalytics =>
      $$LearningAnalyticsTableTableManager(
        _db.attachedDatabase,
        _db.learningAnalytics,
      );
}

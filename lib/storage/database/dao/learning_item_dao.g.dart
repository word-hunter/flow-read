// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_item_dao.dart';

// ignore_for_file: type=lint
mixin _$LearningItemDaoMixin on DatabaseAccessor<AppDatabase> {
  $BookEntriesTable get bookEntries => attachedDatabase.bookEntries;
  $LearningItemsTable get learningItems => attachedDatabase.learningItems;
  LearningItemDaoManager get managers => LearningItemDaoManager(this);
}

class LearningItemDaoManager {
  final _$LearningItemDaoMixin _db;
  LearningItemDaoManager(this._db);
  $$BookEntriesTableTableManager get bookEntries =>
      $$BookEntriesTableTableManager(_db.attachedDatabase, _db.bookEntries);
  $$LearningItemsTableTableManager get learningItems =>
      $$LearningItemsTableTableManager(_db.attachedDatabase, _db.learningItems);
}

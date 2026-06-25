// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_usage_dao.dart';

// ignore_for_file: type=lint
mixin _$AiUsageDaoMixin on DatabaseAccessor<AppDatabase> {
  $AiUsageEventsTable get aiUsageEvents => attachedDatabase.aiUsageEvents;
  $BookEntriesTable get bookEntries => attachedDatabase.bookEntries;
  AiUsageDaoManager get managers => AiUsageDaoManager(this);
}

class AiUsageDaoManager {
  final _$AiUsageDaoMixin _db;
  AiUsageDaoManager(this._db);
  $$AiUsageEventsTableTableManager get aiUsageEvents =>
      $$AiUsageEventsTableTableManager(_db.attachedDatabase, _db.aiUsageEvents);
  $$BookEntriesTableTableManager get bookEntries =>
      $$BookEntriesTableTableManager(_db.attachedDatabase, _db.bookEntries);
}

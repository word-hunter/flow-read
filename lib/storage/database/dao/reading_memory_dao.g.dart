// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_memory_dao.dart';

// ignore_for_file: type=lint
mixin _$ReadingMemoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $SourceRecordsTable get sourceRecords => attachedDatabase.sourceRecords;
  $KnowledgeEntitiesTable get knowledgeEntities =>
      attachedDatabase.knowledgeEntities;
  $KnowledgeExplanationsTable get knowledgeExplanations =>
      attachedDatabase.knowledgeExplanations;
  $KnowledgeEvidencesTable get knowledgeEvidences =>
      attachedDatabase.knowledgeEvidences;
  $MemoryEventsTable get memoryEvents => attachedDatabase.memoryEvents;
  $SourceScopeCacheTable get sourceScopeCache =>
      attachedDatabase.sourceScopeCache;
  $ReviewCandidatesTable get reviewCandidates =>
      attachedDatabase.reviewCandidates;
  ReadingMemoryDaoManager get managers => ReadingMemoryDaoManager(this);
}

class ReadingMemoryDaoManager {
  final _$ReadingMemoryDaoMixin _db;
  ReadingMemoryDaoManager(this._db);
  $$SourceRecordsTableTableManager get sourceRecords =>
      $$SourceRecordsTableTableManager(_db.attachedDatabase, _db.sourceRecords);
  $$KnowledgeEntitiesTableTableManager get knowledgeEntities =>
      $$KnowledgeEntitiesTableTableManager(
        _db.attachedDatabase,
        _db.knowledgeEntities,
      );
  $$KnowledgeExplanationsTableTableManager get knowledgeExplanations =>
      $$KnowledgeExplanationsTableTableManager(
        _db.attachedDatabase,
        _db.knowledgeExplanations,
      );
  $$KnowledgeEvidencesTableTableManager get knowledgeEvidences =>
      $$KnowledgeEvidencesTableTableManager(
        _db.attachedDatabase,
        _db.knowledgeEvidences,
      );
  $$MemoryEventsTableTableManager get memoryEvents =>
      $$MemoryEventsTableTableManager(_db.attachedDatabase, _db.memoryEvents);
  $$SourceScopeCacheTableTableManager get sourceScopeCache =>
      $$SourceScopeCacheTableTableManager(
        _db.attachedDatabase,
        _db.sourceScopeCache,
      );
  $$ReviewCandidatesTableTableManager get reviewCandidates =>
      $$ReviewCandidatesTableTableManager(
        _db.attachedDatabase,
        _db.reviewCandidates,
      );
}

import 'package:flow_read/models/reading_memory.dart';
import 'package:flow_read/models/user_vocabulary.dart';
import 'package:flow_read/models/word_context_example.dart';
import 'package:flow_read/services/reading_memory/reading_memory_ids.dart';
import 'package:flow_read/services/reading_memory/reading_memory_service.dart';
import 'package:flow_read/services/reading_memory/source_scope_service.dart';
import 'package:flow_read/services/reading_memory/word_memory_service.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/services/word_context_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_memory_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_user_vocabulary_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_word_context_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.createInMemory();
  });

  tearDown(() async {
    await db.close();
  });

  test('source scope service creates and tombstones book sources', () async {
    final repository = DriftReadingMemoryRepository(
      db.readingMemoryDao,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 15, 9),
    );
    final service = SourceScopeService(
      repository: repository,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 15, 8),
    );

    final source = await service.upsertBookSource(
      bookId: 'book-1',
      title: 'Book One',
      author: 'Author',
      fingerprint: 'sha256:book',
    );

    expect(source.id, 'book:book-1');
    expect(source.availability, SourceAvailability.available);

    await service.deleteSourceKeepLearningMemory(source.id);

    final deleted = await repository.sourceRecord(source.id);
    expect(deleted?.availability, SourceAvailability.deleted);
    expect(deleted?.deletedAt, DateTime.utc(2026, 6, 15, 8));
  });

  test('records lookup and saved explanation into word memory card', () async {
    final memoryRepository = DriftReadingMemoryRepository(
      db.readingMemoryDao,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 15, 9),
    );
    final userVocabulary = UserVocabularyService(
      repository: DriftUserVocabularyRepository(
        db.userVocabularyDao,
        languageCode: 'en',
      ),
      languageCode: 'en',
    );
    final wordContext = WordContextService(
      repository: DriftWordContextRepository(
        db.wordContextDao,
        languageCode: 'en',
      ),
    );
    await userVocabulary.init();
    await wordContext.init();

    var tick = 0;
    DateTime nextTime() {
      return DateTime.utc(2026, 6, 15, 8).add(Duration(minutes: tick++));
    }

    final memory = ReadingMemoryService(
      repository: memoryRepository,
      languageCode: 'en',
      clock: nextTime,
    );
    final wordMemory = WordMemoryService(
      repository: memoryRepository,
      userVocabulary: userVocabulary,
      wordContext: wordContext,
      languageCode: 'en',
    );

    const sourceRef = MemorySourceRef(
      sourceId: 'book:book-1',
      sourceKind: SourceKind.book,
      sourceTitleSnapshot: 'Book One',
      bookId: 'book-1',
      chapterIndex: 2,
      locationLocator: 'chapter:2:sentence:4',
    );
    await memory.recordLookup(
      targetText: 'Reluctant',
      canonical: 'reluctant',
      sourceRef: sourceRef,
      sentence: 'He was reluctant to admit defeat.',
    );
    await memory.saveExplanation(
      targetText: 'reluctant',
      explanation: 'reluctant to do means unwilling to do something.',
      sourceRef: sourceRef,
      promptVersion: 'text-analysis-v1',
    );
    await userVocabulary.setLearning('reluctant');
    await wordContext.saveExamples('reluctant', [
      WordContextExample(
        word: 'reluctant',
        text: 'He was reluctant to admit defeat.',
        title: 'Book One',
        createdAt: DateTime.utc(2026, 6, 15, 8),
      ),
    ]);

    final card = await wordMemory.getWordCard(canonical: 'Reluctant');

    expect(card.canonical, 'reluctant');
    expect(card.userStatus, UserWordStatus.learning);
    expect(card.lookupCount, 1);
    expect(card.contextExamples.single.text, contains('admit defeat'));
    expect(card.savedExplanations.single.source, ExplanationSource.ai);
    expect(card.evidences.single.sourceTitleSnapshot, 'Book One');
    expect(card.recentEvents.map((event) => event.type), [
      MemoryEventType.saveExplanation,
      MemoryEventType.lookup,
    ]);
    expect(card.hasPersonalMemory, isTrue);
    expect(
      ReadingMemoryIds.entity(
        languageCode: 'en',
        type: KnowledgeEntityType.word,
        canonicalKey: 'Reluctant',
      ),
      'entity:en:word:reluctant',
    );
  });

  test(
    'user vocabulary status changes are mirrored to reading memory',
    () async {
      final memoryRepository = DriftReadingMemoryRepository(
        db.readingMemoryDao,
        languageCode: 'en',
        clock: () => DateTime.utc(2026, 6, 15, 9),
      );
      var tick = 0;
      DateTime nextTime() {
        return DateTime.utc(2026, 6, 15, 8).add(Duration(minutes: tick++));
      }

      final memory = ReadingMemoryService(
        repository: memoryRepository,
        languageCode: 'en',
        clock: nextTime,
      );
      final userVocabulary = UserVocabularyService(
        repository: DriftUserVocabularyRepository(
          db.userVocabularyDao,
          languageCode: 'en',
        ),
        readingMemory: memory,
        languageCode: 'en',
      );
      await userVocabulary.init();

      await userVocabulary.setLearning('Reluctant');
      await userVocabulary.setKnown('Reluctant');
      await userVocabulary.setUnknown('Reluctant');

      final events = await memoryRepository.eventsForCanonical(
        languageCode: 'en',
        canonicalKey: 'reluctant',
      );
      expect(events.map((event) => event.type), [
        MemoryEventType.markUnknown,
        MemoryEventType.markKnown,
        MemoryEventType.markLearning,
      ]);
      final entity = await memoryRepository.entityByCanonical(
        languageCode: 'en',
        type: KnowledgeEntityType.word,
        canonicalKey: 'reluctant',
      );
      expect(entity?.masteryState, KnowledgeMasteryState.unknown);
      expect(userVocabulary.getStatus('reluctant'), isNull);
    },
  );
}

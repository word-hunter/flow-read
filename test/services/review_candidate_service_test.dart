import 'package:flow_read/models/reading_memory.dart';
import 'package:flow_read/models/user_vocabulary.dart';
import 'package:flow_read/services/reading_memory/reading_memory_service.dart';
import 'package:flow_read/services/reading_memory/review_candidate_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_memory_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.createInMemory();
  });

  tearDown(() async {
    await db.close();
  });

  test('saved explanations create pending review candidates', () async {
    final repository = DriftReadingMemoryRepository(
      db.readingMemoryDao,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 15, 10),
    );
    final reviewCandidates = ReviewCandidateService(
      repository: repository,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 15, 9),
    );
    final memory = ReadingMemoryService(
      repository: repository,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 15, 8),
      reviewCandidates: reviewCandidates,
    );

    final saved = await memory.saveExplanation(
      targetText: 'reluctant',
      explanation: 'reluctant to do means unwilling to do something.',
      promptVersion: 'assistant-word-analysis-v2',
    );

    final entity = await repository.entityByCanonical(
      languageCode: 'en',
      type: KnowledgeEntityType.word,
      canonicalKey: 'reluctant',
    );
    final candidates = await reviewCandidates.candidatesForEntity(entity!.id);

    expect(saved, isNotNull);
    expect(candidates, hasLength(1));
    expect(candidates.single.entityId, entity.id);
    expect(candidates.single.explanationId, saved!.id);
    expect(candidates.single.targetText, 'reluctant');
    expect(candidates.single.suggestedQuestionType, 'word_meaning');
    expect(candidates.single.priority, 0.8);
    expect(candidates.single.status, ReviewCandidateStatus.pending);
  });

  test(
    'repeated lookups create one evidence-backed pending candidate',
    () async {
      final repository = DriftReadingMemoryRepository(
        db.readingMemoryDao,
        languageCode: 'en',
        clock: () => DateTime.utc(2026, 6, 15, 10),
      );
      final reviewCandidates = ReviewCandidateService(
        repository: repository,
        languageCode: 'en',
        clock: () => DateTime.utc(2026, 6, 15, 9),
      );
      final memory = ReadingMemoryService(
        repository: repository,
        languageCode: 'en',
        clock: () => DateTime.utc(2026, 6, 15, 8),
        reviewCandidates: reviewCandidates,
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

      final entity = await repository.entityByCanonical(
        languageCode: 'en',
        type: KnowledgeEntityType.word,
        canonicalKey: 'reluctant',
      );
      expect(await reviewCandidates.candidatesForEntity(entity!.id), isEmpty);

      await memory.recordLookup(
        targetText: 'Reluctant',
        canonical: 'reluctant',
        sourceRef: sourceRef,
        sentence: 'He was reluctant to answer.',
      );
      await memory.recordLookup(
        targetText: 'Reluctant',
        canonical: 'reluctant',
      );

      final candidates = await reviewCandidates.candidatesForEntity(entity.id);

      expect(candidates, hasLength(1));
      expect(candidates.single.entityId, entity.id);
      expect(candidates.single.evidenceId, isNotNull);
      expect(candidates.single.targetText, 'Reluctant');
      expect(candidates.single.suggestedQuestionType, 'fill_blank');
      expect(candidates.single.priority, 0.65);
      expect(candidates.single.status, ReviewCandidateStatus.pending);
    },
  );

  test(
    'learning vocabulary creates one idempotent pending candidate',
    () async {
      final repository = DriftReadingMemoryRepository(
        db.readingMemoryDao,
        languageCode: 'en',
        clock: () => DateTime.utc(2026, 6, 15, 10),
      );
      final reviewCandidates = ReviewCandidateService(
        repository: repository,
        languageCode: 'en',
        clock: () => DateTime.utc(2026, 6, 15, 9),
      );
      final memory = ReadingMemoryService(
        repository: repository,
        languageCode: 'en',
        clock: () => DateTime.utc(2026, 6, 15, 8),
        reviewCandidates: reviewCandidates,
      );

      await memory.recordVocabularyStatus(
        targetText: 'Reluctant',
        status: UserWordStatus.learning,
      );
      await memory.recordVocabularyStatus(
        targetText: 'Reluctant',
        status: UserWordStatus.learning,
      );

      final entity = await repository.entityByCanonical(
        languageCode: 'en',
        type: KnowledgeEntityType.word,
        canonicalKey: 'reluctant',
      );
      final candidates = await reviewCandidates.candidatesForEntity(entity!.id);

      expect(candidates, hasLength(1));
      expect(candidates.single.explanationId, isNull);
      expect(candidates.single.targetText, 'Reluctant');
      expect(candidates.single.suggestedQuestionType, 'word_meaning');
      expect(candidates.single.priority, 0.65);
      expect(candidates.single.status, ReviewCandidateStatus.pending);
    },
  );
}

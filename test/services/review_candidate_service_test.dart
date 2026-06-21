import 'package:flow_read/models/learning_item.dart';
import 'package:flow_read/models/reading_memory.dart';
import 'package:flow_read/models/user_vocabulary.dart';
import 'package:flow_read/services/learning_item_service.dart';
import 'package:flow_read/services/reading_memory/reading_memory_service.dart';
import 'package:flow_read/services/reading_memory/review_candidate_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_learning_item_repository.dart';
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

  test('accepts and dismisses pending candidates', () async {
    final repository = DriftReadingMemoryRepository(
      db.readingMemoryDao,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 15, 10),
    );
    final reviewCandidates = ReviewCandidateService(
      repository: repository,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 15, 11),
    );
    final memory = ReadingMemoryService(
      repository: repository,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 15, 8),
      reviewCandidates: reviewCandidates,
    );

    await memory.saveExplanation(
      targetText: 'Reluctant',
      canonical: 'reluctant',
      explanation: 'Unwilling in this context.',
    );
    await memory.saveExplanation(
      targetText: 'Scrutiny',
      canonical: 'scrutiny',
      explanation: 'Careful inspection.',
    );
    final pending = await reviewCandidates.pendingCandidates();

    await reviewCandidates.acceptCandidate(pending.first.id);
    await reviewCandidates.dismissCandidates([pending.last.id]);

    expect(await reviewCandidates.pendingCandidates(), isEmpty);
    expect(
      (await repository.reviewCandidateById(pending.first.id))?.status,
      ReviewCandidateStatus.accepted,
    );
    expect(
      (await repository.reviewCandidateById(pending.last.id))?.status,
      ReviewCandidateStatus.dismissed,
    );
  });

  test(
    'accepting a candidate creates one learning item and marks it converted',
    () async {
      final repository = DriftReadingMemoryRepository(
        db.readingMemoryDao,
        languageCode: 'en',
        clock: () => DateTime.utc(2026, 6, 15, 10),
      );
      final learningItems = LearningItemService(
        repository: DriftLearningItemRepository(
          db.learningItemDao,
          languageCode: 'en',
        ),
        clock: () => DateTime.utc(2026, 6, 15, 12),
      );
      final reviewCandidates = ReviewCandidateService(
        repository: repository,
        languageCode: 'en',
        clock: () => DateTime.utc(2026, 6, 15, 11),
      );
      final memory = ReadingMemoryService(
        repository: repository,
        languageCode: 'en',
        clock: () => DateTime.utc(2026, 6, 15, 8),
        reviewCandidates: reviewCandidates,
      );
      await learningItems.init();

      await memory.saveExplanation(
        targetText: 'Reluctant',
        canonical: 'reluctant',
        explanation: 'Unwilling in this context.',
        sourceRef: const MemorySourceRef(
          sourceId: 'book:book-1',
          sourceKind: SourceKind.book,
          sourceTitleSnapshot: 'Book One',
          bookId: 'book-1',
          chapterIndex: 2,
          locationLocator: 'chapter:2:sentence:4',
        ),
      );
      final pending = await reviewCandidates.pendingCandidates();

      final first = await reviewCandidates.acceptCandidateForReview(
        pending.single.id,
        learningItems: learningItems,
      );
      final second = await reviewCandidates.acceptCandidateForReview(
        pending.single.id,
        learningItems: learningItems,
      );

      expect(first, isNotNull);
      expect(first!.created, isTrue);
      expect(second, isNull);
      expect(learningItems.count, 1);
      expect(await reviewCandidates.pendingCandidates(), isEmpty);
      expect(
        (await repository.reviewCandidateById(pending.single.id))?.status,
        ReviewCandidateStatus.converted,
      );

      final item = learningItems.allItems.single;
      expect(item.type, LearningItemType.word);
      expect(item.canonicalKey, 'reluctant');
      expect(item.answer, 'Unwilling in this context.');
      expect(item.bookId, 'book-1');
      expect(item.chapterIndex, 2);
      expect(item.tags, containsAll(['reading-memory', 'saved-explanation']));
      expect(item.metadata['reviewCandidateId'], pending.single.id);
      expect(item.metadata['sourceKind'], SourceKind.book.storageValue);
    },
  );
}

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

  test(
    'saved explanations keep one pending candidate per entity and type',
    () async {
      final repository = DriftReadingMemoryRepository(
        db.readingMemoryDao,
        languageCode: 'en',
        clock: () => DateTime.utc(2026, 6, 15, 10),
      );
      var tick = 0;
      final reviewCandidates = ReviewCandidateService(
        repository: repository,
        languageCode: 'en',
        clock: () =>
            DateTime.utc(2026, 6, 15, 11).add(Duration(minutes: tick++)),
      );
      final memory = ReadingMemoryService(
        repository: repository,
        languageCode: 'en',
        clock: () =>
            DateTime.utc(2026, 6, 15, 8).add(Duration(minutes: tick++)),
        reviewCandidates: reviewCandidates,
      );

      await memory.saveExplanation(
        targetText: 'Reluctant',
        canonical: 'reluctant',
        explanation: 'Unwilling.',
      );
      await memory.saveExplanation(
        targetText: 'Reluctant',
        canonical: 'reluctant',
        explanation: 'Not eager to do something.',
      );

      final entity = await repository.entityByCanonical(
        languageCode: 'en',
        type: KnowledgeEntityType.word,
        canonicalKey: 'reluctant',
      );
      final pending = await reviewCandidates.candidatesForEntity(
        entity!.id,
        status: ReviewCandidateStatus.pending,
      );
      final dismissed = await reviewCandidates.candidatesForEntity(
        entity.id,
        status: ReviewCandidateStatus.dismissed,
      );

      expect(pending, hasLength(1));
      expect(dismissed, hasLength(1));
      expect(
        pending.single.createdAt.isAfter(dismissed.single.createdAt),
        isTrue,
      );
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

  test('promotion rules cover phrase, pattern, and grammar candidates', () {
    final repository = DriftReadingMemoryRepository(
      db.readingMemoryDao,
      languageCode: 'en',
    );
    final reviewCandidates = ReviewCandidateService(
      repository: repository,
      languageCode: 'en',
    );

    final rules = reviewCandidates.promotionRules();
    final savedExplanation = rules.singleWhere(
      (rule) => rule.trigger == 'saved_explanation',
    );
    final repeatedLookup = rules.singleWhere(
      (rule) => rule.trigger == 'repeated_lookup',
    );

    expect(
      savedExplanation.entityTypes,
      containsAll([
        KnowledgeEntityType.phrase,
        KnowledgeEntityType.pattern,
        KnowledgeEntityType.grammar,
      ]),
    );
    expect(repeatedLookup.questionType, 'fill_blank');
  });

  test(
    'grammar explanations become grammar review items instead of words',
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
        targetText: 'as if waiting',
        canonical: 'as if waiting',
        explanation: 'as if 引导方式状语，制造假设和画面感。',
        type: KnowledgeEntityType.grammar,
        source: ExplanationSource.ai,
      );

      final pending = await reviewCandidates.pendingCandidates();
      expect(pending.single.entityType, KnowledgeEntityType.grammar);
      expect(pending.single.suggestedQuestionType, 'fill_blank');

      final result = await reviewCandidates.acceptCandidateForReview(
        pending.single.id,
        learningItems: learningItems,
      );

      expect(result?.created, isTrue);
      final item = learningItems.allItems.single;
      expect(item.type, LearningItemType.grammar);
      expect(item.canonicalKey, 'as if waiting');
      expect(item.tags, containsAll(['grammar', 'fill_blank', 'ai']));
    },
  );

  test('dismisses low-value stale and duplicate pending candidates', () async {
    final repository = DriftReadingMemoryRepository(
      db.readingMemoryDao,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 15, 10),
    );
    final reviewCandidates = ReviewCandidateService(
      repository: repository,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 10, 1, 9),
    );
    final entity = _entity(
      id: 'entity:reluctant',
      canonicalKey: 'reluctant',
      displayText: 'Reluctant',
      now: DateTime.utc(2026, 6, 1),
    );
    final other = _entity(
      id: 'entity:other',
      canonicalKey: 'other',
      displayText: 'Other',
      now: DateTime.utc(2026, 6, 1),
    );
    await repository.upsertEntity(entity);
    await repository.upsertEntity(other);

    await repository.upsertReviewCandidate(
      _candidate(
        id: 'candidate:keep',
        entity: entity,
        priority: 0.8,
        questionType: 'word_meaning',
        createdAt: DateTime.utc(2026, 9, 1),
        updatedAt: DateTime.utc(2026, 9, 1),
      ),
    );
    await repository.upsertReviewCandidate(
      _candidate(
        id: 'candidate:duplicate',
        entity: entity,
        priority: 0.7,
        questionType: 'word_meaning',
        createdAt: DateTime.utc(2026, 8, 1),
        updatedAt: DateTime.utc(2026, 8, 1),
      ),
    );
    await repository.upsertReviewCandidate(
      _candidate(
        id: 'candidate:low',
        entity: other,
        priority: 0.4,
        questionType: 'recall_context',
        createdAt: DateTime.utc(2026, 9, 1),
        updatedAt: DateTime.utc(2026, 9, 1),
      ),
    );
    await repository.upsertReviewCandidate(
      _candidate(
        id: 'candidate:stale',
        entity: other,
        priority: 0.65,
        questionType: 'fill_blank',
        createdAt: DateTime.utc(2026, 6, 1),
        updatedAt: DateTime.utc(2026, 6, 1),
      ),
    );

    final result = await reviewCandidates.cleanupPendingCandidates();

    expect(result.totalDismissed, 3);
    expect(result.lowPriorityDismissed, 1);
    expect(result.staleDismissed, 1);
    expect(result.duplicateDismissed, 1);
    expect(
      (await repository.reviewCandidateById('candidate:keep'))?.status,
      ReviewCandidateStatus.pending,
    );
    expect(
      (await repository.reviewCandidateById('candidate:duplicate'))?.status,
      ReviewCandidateStatus.dismissed,
    );
    expect(
      (await repository.reviewCandidateById('candidate:low'))?.status,
      ReviewCandidateStatus.dismissed,
    );
    expect(
      (await repository.reviewCandidateById('candidate:stale'))?.status,
      ReviewCandidateStatus.dismissed,
    );
  });
}

MemoryKnowledgeEntity _entity({
  required String id,
  required String canonicalKey,
  required String displayText,
  required DateTime now,
  KnowledgeEntityType type = KnowledgeEntityType.word,
}) {
  return MemoryKnowledgeEntity(
    id: id,
    languageCode: 'en',
    type: type,
    canonicalKey: canonicalKey,
    displayText: displayText,
    normalizedText: canonicalKey,
    createdAt: now,
    updatedAt: now,
  );
}

ReviewCandidate _candidate({
  required String id,
  required MemoryKnowledgeEntity entity,
  required double priority,
  required String questionType,
  required DateTime createdAt,
  required DateTime updatedAt,
}) {
  return ReviewCandidate(
    id: id,
    entityId: entity.id,
    entityType: entity.type,
    targetText: entity.displayText,
    suggestedQuestionType: questionType,
    priority: priority,
    status: ReviewCandidateStatus.pending,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

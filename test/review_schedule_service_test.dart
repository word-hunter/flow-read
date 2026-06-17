import 'dart:convert';
import 'dart:io';

import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/models/learning_item.dart';
import 'package:flow_read/models/reading_memory.dart';
import 'package:flow_read/services/learning_item_service.dart';
import 'package:flow_read/services/reading_memory/reading_memory_service.dart';
import 'package:flow_read/services/review_schedule_service.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_learning_item_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_memory_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_user_vocabulary_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_storage.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late LearningItemService learningItems;
  late DriftReadingMemoryRepository memoryRepository;
  late ReadingMemoryService readingMemory;
  late ReviewScheduleService schedule;

  final now = DateTime.utc(2026, 5, 21, 9);
  const source = LearningItemSource(
    bookId: 'book-1',
    chapterIndex: 0,
    chapterTitle: 'Chapter 1',
  );

  setUp(() async {
    tempDir = await initTestStorage('flow_read_review_schedule_test_');
    db = await createTestAppDatabase();
    learningItems = LearningItemService(
      repository: DriftLearningItemRepository(
        db.learningItemDao,
        languageCode: 'en',
      ),
      clock: () => now,
    );
    await learningItems.init();
    memoryRepository = DriftReadingMemoryRepository(
      db.readingMemoryDao,
      languageCode: 'en',
      clock: () => now,
    );
    readingMemory = ReadingMemoryService(
      repository: memoryRepository,
      languageCode: 'en',
      clock: () => now,
    );
    await readingMemory.init();
    schedule = ReviewScheduleService(
      learningItems,
      clock: () => now,
      readingMemory: readingMemory,
    );
  });

  tearDown(() async {
    await disposeTestStorage(tempDir);
  });

  test('counts today due items and limits one session to ten cards', () async {
    const words = [
      'amber',
      'breeze',
      'cinder',
      'drift',
      'ember',
      'fable',
      'glimmer',
      'harbor',
      'ivory',
      'jovial',
      'kindle',
      'lantern',
    ];
    for (final word in words) {
      await _saveWord(learningItems, source, word);
    }
    final future = await _saveWord(learningItems, source, 'tomorrow');
    await learningItems.saveItem(
      future.copyWith(nextReviewAt: now.add(const Duration(days: 1))),
    );

    expect(schedule.dueCount(), 12);

    final cards = schedule.buildSessionCards();
    expect(cards, hasLength(10));
    expect(cards.map((card) => card.type).toSet(), {
      LearningReviewCardType.fillBlank,
      LearningReviewCardType.contextMeaning,
      LearningReviewCardType.meaningToWord,
    });
  });

  test('builds selectable context meaning and meaning-to-word cards', () async {
    await _saveWord(learningItems, source, 'hesitate', definition: '犹豫');
    await _saveWord(learningItems, source, 'gleam', definition: '微光');
    await _saveWord(learningItems, source, 'conceal', definition: '隐藏');

    final cards = schedule.buildSessionCards();

    final contextMeaning = cards.singleWhere(
      (card) => card.type == LearningReviewCardType.contextMeaning,
    );
    expect(contextMeaning.prompt, contains('gleam'));
    expect(contextMeaning.prompt, contains('A sentence with gleam inside.'));
    expect(contextMeaning.answer, '微光');
    expect(contextMeaning.options, containsAll(['犹豫', '微光', '隐藏']));

    final meaningToWord = cards.singleWhere(
      (card) => card.type == LearningReviewCardType.meaningToWord,
    );
    expect(meaningToWord.prompt, contains('隐藏'));
    expect(meaningToWord.answer, 'conceal');
    expect(
      meaningToWord.options,
      containsAll(['hesitate', 'gleam', 'conceal']),
    );
  });

  test(
    'enriches context meaning cards with AI distractors and explanation',
    () async {
      await _saveWord(learningItems, source, 'hesitate', definition: '犹豫');
      await _saveWord(learningItems, source, 'gleam', definition: '微光');
      await _saveWord(learningItems, source, 'conceal', definition: '隐藏');
      final scheduleWithAI = ReviewScheduleService(
        learningItems,
        clock: () => now,
        practiceGenerator: (items) async {
          expect(items.map((item) => item.title), [
            'hesitate',
            'gleam',
            'conceal',
          ]);
          return const AIPracticeSet(
            questions: [
              PracticeQuestion(
                type: 'vocabulary',
                question: '在这句中，"gleam" 最接近哪种含义？',
                source: 'A sentence with gleam inside.',
                answer: '微光',
                answerExplanation: 'AI 解释：这里指短暂出现的微弱光亮。',
                distractors: [
                  Distractor(text: '隐藏', whyWrong: '动作含义，不符合语境。'),
                  Distractor(text: '犹豫', whyWrong: '心理状态，不符合语境。'),
                  Distractor(text: '交易', whyWrong: '名词含义，不符合语境。'),
                ],
                difficulty: 'medium',
              ),
            ],
          );
        },
      );

      final cards = await scheduleWithAI.buildSessionCardsWithAI();

      final contextMeaning = cards.singleWhere(
        (card) => card.type == LearningReviewCardType.contextMeaning,
      );
      expect(contextMeaning.prompt, '在这句中，"gleam" 最接近哪种含义？');
      expect(contextMeaning.answer, '微光');
      expect(contextMeaning.explanation, contains('AI 解释'));
      expect(contextMeaning.sourceText, 'A sentence with gleam inside.');
      expect(
        contextMeaning.options,
        containsAll(['微光', '隐藏', '犹豫', '交易']),
      );
    },
  );

  test('falls back to local cards when AI practice generation fails', () async {
    await _saveWord(learningItems, source, 'hesitate', definition: '犹豫');
    await _saveWord(learningItems, source, 'gleam', definition: '微光');
    await _saveWord(learningItems, source, 'conceal', definition: '隐藏');
    final scheduleWithFailingAI = ReviewScheduleService(
      learningItems,
      clock: () => now,
      practiceGenerator: (_) => throw StateError('offline'),
    );

    final cards = await scheduleWithFailingAI.buildSessionCardsWithAI();

    final contextMeaning = cards.singleWhere(
      (card) => card.type == LearningReviewCardType.contextMeaning,
    );
    expect(contextMeaning.prompt, contains('A sentence with gleam inside.'));
    expect(contextMeaning.answer, '微光');
    expect(contextMeaning.explanation, isEmpty);
    expect(contextMeaning.options, containsAll(['犹豫', '微光', '隐藏']));
  });

  test('records remembered review with the next interval', () async {
    final item = await _saveWord(learningItems, source, 'flow');

    final updated = await schedule.recordReview(
      item.id,
      LearningReviewResult.remembered,
    );

    expect(updated, isNotNull);
    expect(updated!.reviewCount, 1);
    expect(updated.lastResult, LearningReviewResult.remembered);
    expect(updated.nextReviewAt, now.add(const Duration(days: 1)));
    expect(schedule.dueCount(), 0);
  });

  test(
    'records four familiarity results with distinct next intervals',
    () async {
      final forgotten = await _saveWord(learningItems, source, 'forgotten');
      final vague = await _saveWord(learningItems, source, 'vague');
      final remembered = await _saveWord(learningItems, source, 'remembered');
      final mastered = await _saveWord(learningItems, source, 'mastered');

      final forgottenUpdate = await schedule.recordReview(
        forgotten.id,
        LearningReviewResult.forgotten,
      );
      final vagueUpdate = await schedule.recordReview(
        vague.id,
        LearningReviewResult.vague,
      );
      final rememberedUpdate = await schedule.recordReview(
        remembered.id,
        LearningReviewResult.remembered,
      );
      final masteredUpdate = await schedule.recordReview(
        mastered.id,
        LearningReviewResult.mastered,
      );

      expect(forgottenUpdate!.nextReviewAt, now.add(const Duration(hours: 6)));
      expect(vagueUpdate!.nextReviewAt, now.add(const Duration(days: 1)));
      expect(rememberedUpdate!.nextReviewAt, now.add(const Duration(days: 1)));
      expect(masteredUpdate!.nextReviewAt, now.add(const Duration(days: 30)));
      expect(forgottenUpdate.reviewCount, 0);
      expect(vagueUpdate.reviewCount, 0);
      expect(rememberedUpdate.reviewCount, 1);
      expect(masteredUpdate.reviewCount, 1);
    },
  );

  test('mastered review marks word vocabulary as known', () async {
    final vocabulary = UserVocabularyService(
      repository: DriftUserVocabularyRepository(
        db.userVocabularyDao,
        languageCode: 'en',
      ),
    );
    await vocabulary.init();
    final scheduleWithVocabulary = ReviewScheduleService(
      learningItems,
      clock: () => now,
      userVocabulary: vocabulary,
    );
    final item = await _saveWord(learningItems, source, 'mastered');

    await scheduleWithVocabulary.recordReview(
      item.id,
      LearningReviewResult.mastered,
    );

    expect(vocabulary.isKnown('mastered'), isTrue);
  });

  test('writes review results back to reading memory mastery', () async {
    final item = await _saveWord(learningItems, source, 'flow');

    await schedule.recordReview(item.id, LearningReviewResult.remembered);
    var entity = await memoryRepository.entityByCanonical(
      languageCode: 'en',
      type: KnowledgeEntityType.word,
      canonicalKey: 'flow',
    );
    expect(entity?.masteryState, KnowledgeMasteryState.learning);

    await schedule.recordReview(item.id, LearningReviewResult.remembered);
    entity = await memoryRepository.entityByCanonical(
      languageCode: 'en',
      type: KnowledgeEntityType.word,
      canonicalKey: 'flow',
    );
    expect(entity?.masteryState, KnowledgeMasteryState.mastered);

    await schedule.recordReview(item.id, LearningReviewResult.missed);
    entity = await memoryRepository.entityByCanonical(
      languageCode: 'en',
      type: KnowledgeEntityType.word,
      canonicalKey: 'flow',
    );
    expect(entity?.masteryState, KnowledgeMasteryState.learning);

    final events = await memoryRepository.eventsForCanonical(
      languageCode: 'en',
      canonicalKey: 'flow',
    );
    expect(events, hasLength(3));
    expect(
      events.every((event) => event.type == MemoryEventType.review),
      isTrue,
    );
    final metadata = events
        .map((event) => jsonDecode(event.metadataJson) as Map<String, dynamic>)
        .toList();
    expect(
      metadata.map((item) => item['reviewResult']),
      contains(LearningReviewResult.missed.name),
    );
    expect(
      metadata.where(
        (item) => item['reviewResult'] == LearningReviewResult.remembered.name,
      ),
      hasLength(2),
    );
    expect(
      metadata.singleWhere(
        (item) => item['reviewResult'] == LearningReviewResult.missed.name,
      )['reviewCount'],
      2,
    );
  });

  test('builds a mistake card from a wrong chapter answer', () async {
    await learningItems.saveDraft(
      LearningItemDraft.questionMistake(
        question: 'Why did Alice stop?',
        correctAnswer: 'She heard a sound.',
        selectedAnswer: 'She was tired.',
        sourceExcerpt: 'Alice stopped when she heard a sound.',
        explanation: '原文说明她是因为听到声音停下。',
        source: source,
      ),
    );

    final card = schedule.buildSessionCards().single;

    expect(card.type, LearningReviewCardType.questionMistake);
    expect(card.prompt, 'Why did Alice stop?');
    expect(card.answer, 'She heard a sound.');
    expect(card.sourceText, contains('heard a sound'));
  });

  test('builds fill blank card for a single word', () async {
    await _saveWord(learningItems, source, 'flow', definition: '流动');

    final card = schedule.buildSessionCards().single;

    expect(card.type, LearningReviewCardType.fillBlank);
    expect(card.queueLabel, '原句挖空');
    expect(card.studyGoal, contains('语境词义'));
    expect(card.prompt, 'A sentence with ______ inside.');
    expect(card.answer, 'flow');
  });

  test('uses context meaning instead of fill blank for phrases', () async {
    await learningItems.saveDraft(
      LearningItemDraft(
        type: LearningItemType.grammar,
        canonicalKey: 'On the back of her eyelids',
        title: 'On the back of her eyelids',
        content: 'On the back of her eyelids',
        answer: '介词短语作地点状语，说明画面出现在闭眼后的视觉感受里。',
        note: 'medium',
        sourceText: 'On the back of her eyelids she could see her twin sister,',
        source: source,
        tags: const ['ai', 'grammar'],
      ),
    );

    final card = schedule.buildSessionCards().single;

    expect(card.type, LearningReviewCardType.contextMeaning);
    expect(card.queueLabel, '语境选义');
    expect(card.studyGoal, contains('语法片段'));
    expect(card.prompt, contains('"On the back of her eyelids"'));
    expect(card.prompt, contains('On the back of her eyelids she could see'));
    expect(card.prompt, isNot(contains('______')));
    expect(card.answer, contains('介词短语'));
    expect(card.explanation, contains('介词短语'));
    expect(card.explanation, isNot('medium'));
  });
}

Future<LearningItem> _saveWord(
  LearningItemService service,
  LearningItemSource source,
  String word, {
  String? definition,
}) async {
  final result = await service.saveDraft(
    LearningItemDraft.word(
      word: word,
      definition: definition ?? 'meaning of $word',
      context: 'A sentence with $word inside.',
      source: source,
    ),
  );
  return result.item;
}

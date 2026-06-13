import 'dart:io';

import 'package:flow_read/models/learning_item.dart';
import 'package:flow_read/services/learning_item_service.dart';
import 'package:flow_read/services/review_schedule_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_test_storage.dart';
import 'support/legacy_hive_repositories.dart';

void main() {
  late Directory tempDir;
  late LearningItemService learningItems;
  late ReviewScheduleService schedule;

  final now = DateTime.utc(2026, 5, 21, 9);
  const source = LearningItemSource(
    bookId: 'book-1',
    chapterIndex: 0,
    chapterTitle: 'Chapter 1',
  );

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_review_schedule_test_');
    await openFlowReadTestBoxes();
    learningItems = LearningItemService(
      repository: HiveLearningItemRepository(),
      clock: () => now,
    );
    await learningItems.init();
    schedule = ReviewScheduleService(learningItems, clock: () => now);
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test('counts today due items and limits one session to ten cards', () async {
    for (var i = 0; i < 12; i++) {
      await _saveWord(learningItems, source, 'word$i');
    }
    final future = await _saveWord(learningItems, source, 'tomorrow');
    await learningItems.saveItem(
      future.copyWith(nextReviewAt: now.add(const Duration(days: 1))),
    );

    expect(schedule.dueCount(), 12);

    final cards = schedule.buildSessionCards();
    expect(cards, hasLength(10));
    expect(
      cards.every((card) => card.type == LearningReviewCardType.fillBlank),
      isTrue,
    );
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

  test('builds fill blank card with study goal and explanation', () async {
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

    expect(card.type, LearningReviewCardType.fillBlank);
    expect(card.studyGoal, contains('语法片段'));
    expect(card.prompt, startsWith('______ she could see'));
    expect(card.answer, 'On the back of her eyelids');
    expect(card.explanation, contains('介词短语'));
    expect(card.explanation, isNot('medium'));
  });
}

Future<LearningItem> _saveWord(
  LearningItemService service,
  LearningItemSource source,
  String word,
) async {
  final result = await service.saveDraft(
    LearningItemDraft.word(
      word: word,
      definition: 'meaning of $word',
      context: 'A sentence with $word inside.',
      source: source,
    ),
  );
  return result.item;
}

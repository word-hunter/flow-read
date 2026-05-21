import 'dart:io';

import 'package:flow_read/models/ai_text_analysis.dart';
import 'package:flow_read/models/learning_item.dart';
import 'package:flow_read/services/learning_item_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_test_storage.dart';

void main() {
  late Directory tempDir;
  late LearningItemService service;

  const source = LearningItemSource(
    bookId: 'book-1',
    chapterIndex: 2,
    chapterTitle: 'Chapter 3',
  );

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_learning_item_test_');
    await openFlowReadTestBoxes();
    service = LearningItemService();
    await service.init();
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test('saves a lookup word as a learning item', () async {
    final result = await service.saveDraft(
      LearningItemDraft.word(
        word: 'Flow',
        definition: 'movement',
        context: 'A steady flow of ideas.',
        source: source,
      ),
    );

    expect(result.created, isTrue);
    expect(result.item.type, LearningItemType.word);
    expect(result.item.canonicalKey, 'flow');
    expect(result.item.bookId, 'book-1');
    expect(result.item.chapterIndex, 2);
    expect(result.item.nextReviewAt, result.item.createdAt);
    expect(result.item.reviewCount, 0);
    expect(result.item.lastResult, LearningReviewResult.newItem);
    expect(service.allItems.single.answer, 'movement');
  });

  test('deduplicates by book, chapter, type, and canonical key', () async {
    final first = await service.saveDraft(
      LearningItemDraft.word(
        word: 'Flow',
        definition: 'movement',
        context: 'A steady flow of ideas.',
        source: source,
      ),
    );
    final duplicate = await service.saveDraft(
      LearningItemDraft.word(
        word: ' flow ',
        definition: 'stream',
        context: 'A later flow of events.',
        source: source,
      ),
    );

    expect(first.created, isTrue);
    expect(duplicate.created, isFalse);
    expect(duplicate.item.id, first.item.id);
    expect(service.count, 1);
  });

  test('saves structured AI selected text as a sentence card', () async {
    final result = await service.saveDraft(
      LearningItemDraft.selectedText(
        selectedText: 'The quick fox jumps over the lazy dog.',
        analysis: const AITextAnalysis(
          translation: '敏捷的狐狸跳过了懒狗。',
          structureNotes: [
            StructureNote(
              source: 'The quick fox',
              role: 'main subject',
              explanation: '主语部分。',
            ),
          ],
          grammarPoints: [
            GrammarPoint(
              source: 'jumps over',
              explanation: '短语动词。',
              difficulty: 'medium',
            ),
          ],
          vocabularyNotes: [
            VocabularyNote(word: 'quick', contextMeaning: '敏捷的', pos: 'adj.'),
          ],
          expressionNotes: [
            ExpressionNote(
              source: 'lazy dog',
              meaning: '懒狗',
              usage: '可用于形容行动迟缓的人或物。',
            ),
          ],
          readingTip: '注意主谓关系。',
        ),
        source: source,
      ),
    );

    expect(result.created, isTrue);
    expect(result.item.type, LearningItemType.sentence);
    expect(result.item.answer, '敏捷的狐狸跳过了懒狗。');
    expect(result.item.metadata['grammarCount'], '1');
    expect(result.item.metadata['vocabularyCount'], '1');
    expect(result.item.metadata['expressionCount'], '1');
  });
}

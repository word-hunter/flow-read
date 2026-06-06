import 'package:flow_read/models/learning_item.dart';
import 'package:flow_read/providers/reading/reading_provider_riverpod.dart'
    as riverpod_reading;
import 'package:flow_read/providers/reading/services_provider.dart';
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/screens/spaced_review_screen.dart';
import 'package:flow_read/services/learning_item_service.dart';
import 'package:flow_read/services/review_schedule_service.dart';
import 'package:flow_read/storage/repositories/learning_item_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';

class _InMemoryLearningItemRepository implements LearningItemRepository {
  final List<LearningItem> _items = [];

  @override
  Future<void> init() async {}

  @override
  Iterable<LearningItem> get values => _items;

  @override
  Iterable<dynamic> get keys => _items.map((i) => i.id);

  @override
  int get length => _items.length;

  @override
  LearningItem? get(dynamic id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> put(String id, LearningItem item) async {
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      _items[index] = item;
    } else {
      _items.add(item);
    }
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    final keySet = keys.toSet();
    _items.removeWhere((item) => keySet.contains(item.id));
  }

  @override
  Future<void> clear() async {
    _items.clear();
  }

  @override
  Future<void> close() async {}
}

class _StubReviewScheduleService extends ReviewScheduleService {
  _StubReviewScheduleService(super.learningItemService);

  final List<LearningReviewCard> _cards = [];

  void setCards(List<LearningReviewCard> cards) {
    _cards
      ..clear()
      ..addAll(cards);
  }

  @override
  List<LearningReviewCard> buildSessionCards({DateTime? now, int? limit}) =>
      _cards.toList();

  @override
  Future<LearningItem?> recordReview(
    String id,
    LearningReviewResult result, {
    DateTime? reviewedAt,
  }) async {
    return null;
  }

  @override
  int dueCount({DateTime? now}) => _cards.length;
}

void main() {
  testWidgets('fill blank review requires input before showing source answer', (
    tester,
  ) async {
    const sourceText =
        'On the back of her eyelids she could see her twin sister,';
    final item = LearningItem(
      id: 'item-1',
      type: LearningItemType.grammar,
      canonicalKey: 'on the back of her eyelids',
      title: 'On the back of her eyelids',
      content: 'On the back of her eyelids',
      answer: '介词短语作地点状语。',
      note: 'medium',
      sourceText: sourceText,
      bookId: 'book-1',
      chapterIndex: 0,
      chapterTitle: 'Chapter 1',
      createdAt: DateTime.utc(2026, 5, 21),
      updatedAt: DateTime.utc(2026, 5, 21),
    );
    final provider = _FakeReadingProvider([
      LearningReviewCard(
        item: item,
        type: LearningReviewCardType.fillBlank,
        studyGoal: '练习已沉淀的语法片段，确认能在原句中主动复现。',
        prompt: '______ she could see her twin sister,',
        answer: 'On the back of her eyelids',
        explanation: '介词短语作地点状语。',
        sourceText: sourceText,
      ),
    ]);

    final learningItemService = LearningItemService(
      repository: _InMemoryLearningItemRepository(),
    );
    final reviewService =
        _StubReviewScheduleService(learningItemService);
    reviewService.setCards(provider.todayReviewCards);

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          riverpod_reading.readingProvider.overrideWith((ref) => provider),
          learningItemServiceProvider.overrideWith((ref) => learningItemService),
          reviewScheduleServiceProvider.overrideWith((ref) => reviewService),
        ],
        child: const MaterialApp(home: SpacedReviewScreen()),
      ),
    );

    expect(find.text('学习点'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(sourceText), findsNothing);

    await tester.enterText(
      find.byType(TextField),
      'On the back of her eyelids',
    );
    await tester.pump();
    final submitButton = find.widgetWithText(FilledButton, '提交');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('答案'), findsOneWidget);
    expect(find.text('On the back of her eyelids'), findsWidgets);
    expect(find.text('介词短语作地点状语。'), findsOneWidget);
    expect(find.text(sourceText), findsOneWidget);
  });

  testWidgets('close button avoids macOS traffic light title area', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final provider = _FakeReadingProvider([_reviewCard()]);

      final learningItemService = LearningItemService(
        repository: _InMemoryLearningItemRepository(),
      );
      final reviewService =
          _StubReviewScheduleService(learningItemService);
      reviewService.setCards(provider.todayReviewCards);

      await tester.pumpWidget(
        riverpod.ProviderScope(
          overrides: [
            riverpod_reading.readingProvider.overrideWith((ref) => provider),
            learningItemServiceProvider
                .overrideWith((ref) => learningItemService),
            reviewScheduleServiceProvider
                .overrideWith((ref) => reviewService),
          ],
          child: const MaterialApp(home: SpacedReviewScreen()),
        ),
      );

      final closeIconTop = tester.getTopLeft(find.byIcon(Icons.close)).dy;
      expect(closeIconTop, greaterThanOrEqualTo(40));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

LearningReviewCard _reviewCard() {
  const sourceText =
      'On the back of her eyelids she could see her twin sister,';
  final item = LearningItem(
    id: 'item-1',
    type: LearningItemType.grammar,
    canonicalKey: 'on the back of her eyelids',
    title: 'On the back of her eyelids',
    content: 'On the back of her eyelids',
    answer: '介词短语作地点状语。',
    note: 'medium',
    sourceText: sourceText,
    bookId: 'book-1',
    chapterIndex: 0,
    chapterTitle: 'Chapter 1',
    createdAt: DateTime.utc(2026, 5, 21),
    updatedAt: DateTime.utc(2026, 5, 21),
  );
  return LearningReviewCard(
    item: item,
    type: LearningReviewCardType.fillBlank,
    studyGoal: '练习已沉淀的语法片段，确认能在原句中主动复现。',
    prompt: '______ she could see her twin sister,',
    answer: 'On the back of her eyelids',
    explanation: '介词短语作地点状语。',
    sourceText: sourceText,
  );
}

class _FakeReadingProvider extends ReadingProvider {
  _FakeReadingProvider(this._cards);

  final List<LearningReviewCard> _cards;

  @override
  List<LearningReviewCard> get todayReviewCards => _cards;

  @override
  Future<void> recordLearningReview(
    String itemId,
    LearningReviewResult result,
  ) async {}
}

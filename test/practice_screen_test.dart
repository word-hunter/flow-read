import 'dart:io';

import 'package:flow_read/models/analysis_result.dart';
import 'package:flow_read/models/learning_item.dart';
import 'package:flow_read/models/reading_memory.dart';
import 'package:flow_read/providers/reading/current_book_notifier.dart';
import 'package:flow_read/providers/reading/services_provider.dart';
import 'package:flow_read/screens/practice_screen.dart';
import 'package:flow_read/services/learning_item_service.dart';
import 'package:flow_read/services/reading_memory/reading_memory_service.dart';
import 'package:flow_read/services/reading_memory/review_candidate_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_learning_item_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_memory_repository.dart';
import 'package:flow_read/widgets/practice_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';

import 'support/test_storage.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late ReviewCandidateService reviewCandidates;
  late LearningItemService learningItems;

  setUp(() async {
    tempDir = await initTestStorage('practice_screen_test_');
    db = await createTestAppDatabase();
    reviewCandidates = ReviewCandidateService(
      repository: DriftReadingMemoryRepository(
        db.readingMemoryDao,
        languageCode: 'en',
      ),
      languageCode: 'en',
    );
    learningItems = LearningItemService(
      repository: DriftLearningItemRepository(
        db.learningItemDao,
        languageCode: 'en',
      ),
    );
    await reviewCandidates.init();
    await learningItems.init();
  });

  tearDown(() async {
    await disposeTestStorage(tempDir);
  });

  testWidgets('practice screen shows chapter overview and source excerpt', (
    tester,
  ) async {
    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          currentBookNotifierProvider.overrideWith(
            () => _PracticeTestCurrentBookNotifier(_result),
          ),
          reviewCandidateServiceProvider.overrideWith(
            (ref) => reviewCandidates,
          ),
        ],
        child: const MaterialApp(home: PracticeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('本章词汇练习'), findsOneWidget);
    expect(find.text('1 道练习'), findsOneWidget);
    expect(
      find.text('The cartographer adjusted the sextant carefully.'),
      findsOneWidget,
    );
  });

  testWidgets('practice card reveals guidance when requested', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: PracticeCard(
                practice: Practice(
                  type: 'vocabulary_in_context',
                  question: 'What does "sextant" most likely mean here?',
                  sourceExcerpt:
                      'The cartographer adjusted the sextant carefully.',
                  expectedReasoning:
                      'Use the surrounding action to infer it is a tool.',
                ),
                index: 0,
                total: 1,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('查看参考思路'));
    await tester.pumpAndSettle();

    expect(find.text('参考思路'), findsOneWidget);
    expect(
      find.text('Use the surrounding action to infer it is a tool.'),
      findsOneWidget,
    );
  });

  testWidgets('review candidate queue converts accepted item', (tester) async {
    final repository = DriftReadingMemoryRepository(
      db.readingMemoryDao,
      languageCode: 'en',
    );
    final memory = ReadingMemoryService(
      repository: repository,
      languageCode: 'en',
      reviewCandidates: reviewCandidates,
    );
    await memory.saveExplanation(
      targetText: 'Reluctant',
      canonical: 'reluctant',
      explanation: 'Unwilling in this context.',
    );
    final pending = await reviewCandidates.pendingCandidates();

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          currentBookNotifierProvider.overrideWith(
            () => _PracticeTestCurrentBookNotifier(_result),
          ),
          reviewCandidateServiceProvider.overrideWith(
            (ref) => reviewCandidates,
          ),
          learningItemServiceProvider.overrideWithValue(learningItems),
        ],
        child: const MaterialApp(home: PracticeScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('记忆候选'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.check).first);
    await tester.pumpAndSettle();

    expect(learningItems.count, 1);
    expect(learningItems.allItems.single.type, LearningItemType.word);
    expect(
      (await repository.reviewCandidateById(pending.single.id))?.status,
      ReviewCandidateStatus.converted,
    );
    expect(find.text('记忆候选'), findsNothing);
  });
}

class _PracticeTestCurrentBookNotifier extends CurrentBookNotifier {
  _PracticeTestCurrentBookNotifier(this._result);

  final AnalysisResult _result;

  @override
  CurrentBookState build() => CurrentBookState(
    hasBeenOpened: true,
    result: _result,
  );

  @override
  bool get hasBook => true;

  @override
  AnalysisResult? get result => _result;
}

const _result = AnalysisResult(
  passageText:
      'The cartographer adjusted the sextant carefully. '
      'Moonlight shimmered across the observatory dome.',
  title: 'Observatory',
  vocabulary: [
    Vocabulary(
      word: 'sextant',
      meaning: 'a navigation instrument',
      context: 'The cartographer adjusted the sextant carefully.',
      familiarity: 0.2,
    ),
  ],
  syntaxPatterns: [],
  comprehension: Comprehension(
    whatHappened: '',
    whyHappened: '',
    implicitMeaning: '',
  ),
  practice: [
    Practice(
      type: 'vocabulary_in_context',
      question: 'What does "sextant" most likely mean here?',
      sourceExcerpt: 'The cartographer adjusted the sextant carefully.',
      expectedReasoning: 'Use the surrounding action to infer it is a tool.',
    ),
  ],
  difficulty: Difficulty(
    vocab: 1,
    syntax: 1,
    inference: 1,
    explanation: '',
  ),
);

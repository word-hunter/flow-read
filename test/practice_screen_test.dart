import 'package:flow_read/models/analysis_result.dart';
import 'package:flow_read/providers/reading/current_book_notifier.dart';
import 'package:flow_read/screens/practice_screen.dart';
import 'package:flow_read/widgets/practice_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('practice screen shows chapter overview and source excerpt', (
    tester,
  ) async {
    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          currentBookNotifierProvider.overrideWith(
            () => _PracticeTestCurrentBookNotifier(_result),
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

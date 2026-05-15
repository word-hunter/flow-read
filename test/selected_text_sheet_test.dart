import 'package:flow_read/models/ai_text_analysis.dart';
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/widgets/selected_text_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('analysis sheet shows selected text and AI result', (
    tester,
  ) async {
    final provider = _SelectedTextReadingProvider(
      aiTextAnalysis: const AITextAnalysis(
        translation: '敏捷的狐狸跳过了懒狗。',
        grammarPoints: [
          GrammarPoint(
            source: 'jumps over',
            explanation: '短语动词结构，表示越过某物。',
            difficulty: 'medium',
          ),
        ],
        vocabularyNotes: [
          VocabularyNote(word: 'quick', contextMeaning: '敏捷的，快速的', pos: 'adj.'),
        ],
        readingTip: '注意主语和谓语动作之间的关系。',
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<ReadingProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: SelectedTextSheet(
                selectedText: 'The quick fox jumps over the lazy dog.',
                analysis: null,
                tab: SelectedTextTab.analysis,
                analyzerName: 'DeepSeek AI',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('The quick fox jumps over the lazy dog.'), findsOneWidget);
    expect(find.text('译文'), findsOneWidget);
    expect(find.text('敏捷的狐狸跳过了懒狗。'), findsOneWidget);
    expect(find.text('语法要点'), findsOneWidget);
    expect(find.text('jumps over'), findsOneWidget);
    expect(find.text('词汇说明'), findsOneWidget);
    expect(find.text('quick'), findsOneWidget);
    expect(find.text('阅读提示'), findsOneWidget);
  });
}

class _SelectedTextReadingProvider extends ReadingProvider {
  _SelectedTextReadingProvider({this.aiTextAnalysis});

  @override
  final AITextAnalysis? aiTextAnalysis;

  @override
  bool get isAnalyzingText => false;

  @override
  String? get aiTranslation => null;

  @override
  bool get isTranslatingText => false;

  @override
  String? get errorMessage => null;
}

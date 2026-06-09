import 'package:flow_ai/flow_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds paragraph bounded current passage for selected text', () {
    const source = '''
Opening paragraph that should stay outside the selected request.

The river moved slowly through the valley. Alice watched the current and marked the place in her notebook.

Later paragraph with future details that should stay outside.''';

    const builder = PassageRequestBuilder();
    final request = builder.buildSelectedTextAnalysis(
      selectedText: 'Alice watched the current',
      sourceText: source,
    );

    expect(request.selectedText, 'Alice watched the current');
    expect(request.currentPassage, contains('The river moved slowly'));
    expect(request.currentPassage, contains('Alice watched the current'));
    expect(request.currentPassage, isNot(contains('Opening paragraph')));
    expect(request.currentPassage, isNot(contains('future details')));
    expect(request.sourceLanguage, SourceLanguage.english);
    expect(request.spoilerBoundary.scope, AIContextScope.currentPassage);
  });

  test('matches selections with normalized whitespace', () {
    const source = 'The sentence spans\nmultiple lines in the rendered block.';
    const builder = PassageRequestBuilder();

    final request = builder.buildSelectedTextAnalysis(
      selectedText: 'sentence spans multiple lines',
      sourceText: source,
    );

    expect(request.currentPassage, source);
  });
}

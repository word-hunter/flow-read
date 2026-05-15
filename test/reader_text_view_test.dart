import 'package:flow_read/models/analysis_result.dart';
import 'package:flow_read/models/content_block.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/widgets/reader_text_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const unknownColor = Color(0xFF123456);
  const learningColor = Color(0xFF654321);
  const knownColor = Color(0xFFABCDEF);

  final colorSettings = VocabularyColorSettings(
    unknownColor: unknownColor,
    learningColor: learningColor,
    knownColor: knownColor,
  );

  final result = AnalysisResult(
    passageText: 'known learning mystery',
    title: 'Test',
    vocabulary: const [],
    knownWords: const {'known'},
    learningWords: const {'learning'},
    syntaxPatterns: const [],
    comprehension: const Comprehension(
      whatHappened: '',
      whyHappened: '',
      implicitMeaning: '',
    ),
    practice: const [],
    difficulty: const Difficulty(
      vocab: 0,
      syntax: 0,
      inference: 0,
      explanation: '',
    ),
  );

  testWidgets(
    'highlighted paragraph uses configured colors except known words',
    (tester) async {
      final theme = ThemeData();

      final span = buildHighlightedParagraph(
        'known learning mystery',
        result,
        theme,
        onWordTapped: (_, _) {},
        colorSettings: colorSettings,
      );

      final widgetTexts = _widgetTexts(span);

      expect(widgetTexts.map((item) => item.text), contains('learning'));
      expect(widgetTexts.map((item) => item.text), contains('mystery'));
      expect(widgetTexts.map((item) => item.text), isNot(contains('known')));
      expect(_colorFor(widgetTexts, 'learning'), learningColor);
      expect(_colorFor(widgetTexts, 'mystery'), unknownColor);
    },
  );

  testWidgets('styled blocks do not highlight known words', (tester) async {
    final theme = ThemeData();
    final block = TextBlock(
      type: BlockType.paragraph,
      spans: const [StyledText('known learning mystery')],
    );

    final span = buildStyledBlock(
      block,
      result,
      theme,
      onWordTapped: (_, _) {},
      colorSettings: colorSettings,
    );

    final widgetTexts = _widgetTexts(span);

    expect(widgetTexts.map((item) => item.text), contains('learning'));
    expect(widgetTexts.map((item) => item.text), contains('mystery'));
    expect(widgetTexts.map((item) => item.text), isNot(contains('known')));
    expect(_colorFor(widgetTexts, 'learning'), learningColor);
    expect(_colorFor(widgetTexts, 'mystery'), unknownColor);
  });
}

List<({String text, Color? color})> _widgetTexts(InlineSpan span) {
  final result = <({String text, Color? color})>[];

  void visit(InlineSpan item) {
    if (item is TextSpan) {
      item.children?.forEach(visit);
      return;
    }
    if (item is WidgetSpan) {
      final text = _textFromWidget(item.child);
      if (text != null) result.add(text);
    }
  }

  visit(span);
  return result;
}

({String text, Color? color})? _textFromWidget(Widget widget) {
  if (widget is Text) {
    return (
      text: widget.data ?? widget.textSpan?.toPlainText() ?? '',
      color: widget.style?.color,
    );
  }
  if (widget is GestureDetector && widget.child != null) {
    return _textFromWidget(widget.child!);
  }
  return null;
}

Color? _colorFor(List<({String text, Color? color})> items, String text) {
  return items.firstWhere((item) => item.text == text).color;
}

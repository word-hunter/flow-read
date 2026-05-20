import 'package:flow_read/models/analysis_result.dart';
import 'package:flow_read/models/content_block.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/widgets/reader_text_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _TappableTextProbe = ({
  String text,
  Color? color,
  Color? backgroundColor,
  GestureRecognizer? recognizer,
});

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

      final tappableTexts = _tappableTextSpans(span);

      expect(span.toPlainText(), 'known learning mystery');
      expect(_hasWidgetSpan(span), isFalse);
      expect(tappableTexts.map((item) => item.text), contains('learning'));
      expect(tappableTexts.map((item) => item.text), contains('mystery'));
      expect(tappableTexts.map((item) => item.text), isNot(contains('known')));
      expect(_colorFor(tappableTexts, 'learning'), learningColor);
      expect(_colorFor(tappableTexts, 'mystery'), unknownColor);
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

    final tappableTexts = _tappableTextSpans(span);

    expect(span.toPlainText(), 'known learning mystery');
    expect(_hasWidgetSpan(span), isFalse);
    expect(tappableTexts.map((item) => item.text), contains('learning'));
    expect(tappableTexts.map((item) => item.text), contains('mystery'));
    expect(tappableTexts.map((item) => item.text), isNot(contains('known')));
    expect(_colorFor(tappableTexts, 'learning'), learningColor);
    expect(_colorFor(tappableTexts, 'mystery'), unknownColor);
  });

  testWidgets('search query highlights matching plain text spans', (
    tester,
  ) async {
    final theme = ThemeData();

    final span = buildHighlightedParagraph(
      'known learning mystery',
      result,
      theme,
      onWordTapped: (_, _) {},
      colorSettings: colorSettings,
      searchQuery: 'known',
    );

    expect(_hasHighlightedTextSpan(span, 'known'), isTrue);
  });

  testWidgets('search highlight uses theme-specific contrast colors', (
    tester,
  ) async {
    final lightTheme = ThemeData();
    final darkTheme = ThemeData.dark();

    final lightSpan = buildHighlightedParagraph(
      'known learning mystery',
      result,
      lightTheme,
      onWordTapped: (_, _) {},
      colorSettings: colorSettings,
      searchQuery: 'known',
    );
    final darkSpan = buildHighlightedParagraph(
      'known learning mystery',
      result,
      darkTheme,
      onWordTapped: (_, _) {},
      colorSettings: colorSettings,
      searchQuery: 'mystery',
    );

    expect(
      _textSpanStyleFor(lightSpan, 'known')?.backgroundColor,
      searchHighlightBackgroundFor(lightTheme),
    );
    expect(
      _textSpanStyleFor(lightSpan, 'known')?.color,
      searchHighlightForegroundFor(lightTheme),
    );

    final darkWidgetText = _tappableTextSpans(
      darkSpan,
    ).firstWhere((item) => item.text == 'mystery');
    expect(
      darkWidgetText.backgroundColor,
      searchHighlightBackgroundFor(darkTheme),
    );
    expect(darkWidgetText.color, searchHighlightForegroundFor(darkTheme));
  });

  testWidgets('highlighted word text spans remain tappable', (tester) async {
    final theme = ThemeData();
    String? tappedWord;
    String? tappedContext;

    final span = buildHighlightedParagraph(
      'known learning mystery',
      result,
      theme,
      onWordTapped: (word, context) {
        tappedWord = word;
        tappedContext = context;
      },
      colorSettings: colorSettings,
    );

    final mystery = _tappableTextSpans(
      span,
    ).firstWhere((item) => item.text == 'mystery');

    expect(mystery.recognizer, isA<TapGestureRecognizer>());
    (mystery.recognizer as TapGestureRecognizer).onTap?.call();

    expect(tappedWord, 'mystery');
    expect(tappedContext, '...mystery...');
  });
}

List<_TappableTextProbe> _tappableTextSpans(InlineSpan span) {
  final result = <_TappableTextProbe>[];

  void visit(InlineSpan item) {
    if (item is TextSpan) {
      final text = item.text;
      if (text != null && item.recognizer != null) {
        result.add((
          text: text,
          color: item.style?.color,
          backgroundColor: item.style?.backgroundColor,
          recognizer: item.recognizer,
        ));
      }
      item.children?.forEach(visit);
    }
  }

  visit(span);
  return result;
}

Color? _colorFor(List<_TappableTextProbe> items, String text) {
  return items.firstWhere((item) => item.text == text).color;
}

bool _hasWidgetSpan(InlineSpan span) {
  var found = false;

  void visit(InlineSpan item) {
    if (item is WidgetSpan) {
      found = true;
      return;
    }
    if (item is TextSpan) {
      item.children?.forEach(visit);
    }
  }

  visit(span);
  return found;
}

bool _hasHighlightedTextSpan(InlineSpan span, String text) {
  var found = false;

  void visit(InlineSpan item) {
    if (item is! TextSpan) return;
    if (item.text == text && item.style?.backgroundColor != null) {
      found = true;
    }
    item.children?.forEach(visit);
  }

  visit(span);
  return found;
}

TextStyle? _textSpanStyleFor(InlineSpan span, String text) {
  TextStyle? style;

  void visit(InlineSpan item) {
    if (item is! TextSpan) return;
    if (item.text == text) {
      style = item.style;
      return;
    }
    item.children?.forEach(visit);
  }

  visit(span);
  return style;
}

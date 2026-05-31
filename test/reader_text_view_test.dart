import 'dart:convert';
import 'dart:typed_data';

import 'package:flow_read/models/analysis_result.dart';
import 'package:flow_read/models/content_block.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/widgets/reader_text_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_read_image_viewer/flow_read_image_viewer.dart';

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

  testWidgets('known words stay visually plain but remain tappable', (
    tester,
  ) async {
    final theme = ThemeData();

    final span = buildHighlightedParagraph(
      'known learning mystery',
      result,
      theme,
      onWordTapped: (_, _, {contextWordStart, contextWordEnd}) {},
      colorSettings: colorSettings,
    );

    final tappableTexts = _tappableTextSpans(span);

    expect(span.toPlainText(), 'known learning mystery');
    expect(_hasWidgetSpan(span), isFalse);
    expect(tappableTexts.map((item) => item.text), contains('known'));
    expect(tappableTexts.map((item) => item.text), contains('learning'));
    expect(tappableTexts.map((item) => item.text), contains('mystery'));
    expect(_colorFor(tappableTexts, 'known'), isNot(unknownColor));
    expect(_colorFor(tappableTexts, 'known'), isNot(learningColor));
    expect(_colorFor(tappableTexts, 'learning'), learningColor);
    expect(_colorFor(tappableTexts, 'mystery'), unknownColor);
  });

  testWidgets('styled blocks keep known words plain but tappable', (
    tester,
  ) async {
    final theme = ThemeData();
    final block = TextBlock(
      type: BlockType.paragraph,
      spans: const [StyledText('known learning mystery')],
    );

    final span = buildStyledBlock(
      block,
      result,
      theme,
      onWordTapped: (_, _, {contextWordStart, contextWordEnd}) {},
      colorSettings: colorSettings,
    );

    final tappableTexts = _tappableTextSpans(span);

    expect(span.toPlainText(), 'known learning mystery');
    expect(_hasWidgetSpan(span), isFalse);
    expect(tappableTexts.map((item) => item.text), contains('known'));
    expect(tappableTexts.map((item) => item.text), contains('learning'));
    expect(tappableTexts.map((item) => item.text), contains('mystery'));
    expect(_colorFor(tappableTexts, 'known'), isNot(unknownColor));
    expect(_colorFor(tappableTexts, 'known'), isNot(learningColor));
    expect(_colorFor(tappableTexts, 'learning'), learningColor);
    expect(_colorFor(tappableTexts, 'mystery'), unknownColor);
  });

  testWidgets('reader font family is applied to tappable paragraph spans', (
    tester,
  ) async {
    final theme = ThemeData();

    final span = buildHighlightedParagraph(
      'known learning mystery',
      result,
      theme,
      onWordTapped: (_, _, {contextWordStart, contextWordEnd}) {},
      colorSettings: colorSettings,
      fontFamily: 'Literata',
    );

    expect(_textSpanStyleFor(span, 'known')?.fontFamily, 'Literata');
    expect(_textSpanStyleFor(span, 'learning')?.fontFamily, 'Literata');
    expect(_textSpanStyleFor(span, 'mystery')?.fontFamily, 'Literata');
    expect(_tappableTextSpans(span), hasLength(3));
  });

  testWidgets('styled block inline emphasis keeps selected reader font', (
    tester,
  ) async {
    final theme = ThemeData();
    final block = TextBlock(
      type: BlockType.paragraph,
      spans: const [
        StyledText('known ', InlineStyle(bold: true)),
        StyledText('learning', InlineStyle(italic: true)),
      ],
    );

    final span = buildStyledBlock(
      block,
      result,
      theme,
      onWordTapped: (_, _, {contextWordStart, contextWordEnd}) {},
      colorSettings: colorSettings,
      fontFamily: 'Literata',
    );

    final knownStyle = _textSpanStyleFor(span, 'known');
    final learningStyle = _textSpanStyleFor(span, 'learning');

    expect(knownStyle?.fontFamily, 'Literata');
    expect(knownStyle?.fontWeight, FontWeight.bold);
    expect(learningStyle?.fontFamily, 'Literata');
    expect(learningStyle?.fontStyle, FontStyle.italic);
  });

  testWidgets('styled blocks can use reader theme text color', (tester) async {
    const readerTextColor = Color(0xFFE8E2D6);
    final theme = ThemeData();
    final block = TextBlock(
      type: BlockType.paragraph,
      spans: const [
        StyledText('known ', InlineStyle(bold: true)),
        StyledText('learning', InlineStyle(italic: true)),
      ],
    );

    final span = buildStyledBlock(
      block,
      result,
      theme,
      onWordTapped: (_, _, {contextWordStart, contextWordEnd}) {},
      colorSettings: colorSettings,
      baseTextColor: readerTextColor,
    );

    expect(_textSpanStyleFor(span, 'known')?.color, readerTextColor);
    expect(_textSpanStyleFor(span, 'known')?.fontWeight, FontWeight.bold);
  });

  testWidgets('block widget applies reader theme text color', (tester) async {
    const readerTextColor = Color(0xFFE8E2D6);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildBlockWidget(
            TextBlock(
              type: BlockType.paragraph,
              spans: const [StyledText('known learning')],
            ),
            result,
            ThemeData(),
            baseTextColor: readerTextColor,
            onWordTapped: (_, _, {contextWordStart, contextWordEnd}) {},
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText() == 'known learning',
      ),
    );
    expect(richText.text.style?.color, readerTextColor);
  });

  testWidgets(
    'common contractions with straight or curly apostrophes stay plain but tappable',
    (tester) async {
      final theme = ThemeData();
      const text =
          "didn't isn't wasn\u2019t Wouldn\u2019t hadn\u2019t "
          "shouldn\u2019t\u2019ve You\u2018re They\u02BCve We\uFF07ll "
          "It\u00B4s y\u2019all Cannot \u2019Twas \u2019til";
      final contractionResult = AnalysisResult(
        passageText: text,
        title: 'Test',
        vocabulary: const [],
        knownWords: const {},
        learningWords: const {},
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

      final paragraphSpan = buildHighlightedParagraph(
        text,
        contractionResult,
        theme,
        onWordTapped: (_, _, {contextWordStart, contextWordEnd}) {},
        colorSettings: colorSettings,
      );
      final blockSpan = buildStyledBlock(
        TextBlock(type: BlockType.paragraph, spans: const [StyledText(text)]),
        contractionResult,
        theme,
        onWordTapped: (_, _, {contextWordStart, contextWordEnd}) {},
        colorSettings: colorSettings,
      );

      expect(paragraphSpan.toPlainText(), text);
      expect(blockSpan.toPlainText(), text);
      expect(_tappableTextSpans(paragraphSpan), isNotEmpty);
      expect(_tappableTextSpans(blockSpan), isNotEmpty);
      expect(
        _tappableTextSpans(paragraphSpan).map((item) => item.text),
        contains("didn't"),
      );
      expect(
        _tappableTextSpans(blockSpan).map((item) => item.text),
        contains("didn't"),
      );
    },
  );

  testWidgets('search query highlights matching plain text spans', (
    tester,
  ) async {
    final theme = ThemeData();

    final span = buildHighlightedParagraph(
      'known learning mystery',
      result,
      theme,
      onWordTapped: (_, _, {contextWordStart, contextWordEnd}) {},
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
      onWordTapped: (_, _, {contextWordStart, contextWordEnd}) {},
      colorSettings: colorSettings,
      searchQuery: 'known',
    );
    final darkSpan = buildHighlightedParagraph(
      'known learning mystery',
      result,
      darkTheme,
      onWordTapped: (_, _, {contextWordStart, contextWordEnd}) {},
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

  testWidgets('lookup highlight backgrounds every matching known word', (
    tester,
  ) async {
    final theme = ThemeData();

    final span = buildHighlightedParagraph(
      'known learning mystery known',
      result,
      theme,
      onWordTapped: (_, _, {contextWordStart, contextWordEnd}) {},
      colorSettings: colorSettings,
      lookupHighlightWord: 'known',
    );

    final tappableTexts = _tappableTextSpans(span);
    final knownSpans = tappableTexts.where((item) => item.text == 'known');

    expect(knownSpans, hasLength(2));
    expect(
      knownSpans.map((item) => item.backgroundColor),
      everyElement(lookupHighlightBackgroundFor(theme)),
    );
    expect(_backgroundFor(tappableTexts, 'learning'), isNull);
    expect(_backgroundFor(tappableTexts, 'mystery'), isNull);
  });

  testWidgets('lookup highlight also applies to learning and unknown words', (
    tester,
  ) async {
    final theme = ThemeData();

    final learningSpan = buildHighlightedParagraph(
      'known learning mystery',
      result,
      theme,
      onWordTapped: (_, _, {contextWordStart, contextWordEnd}) {},
      colorSettings: colorSettings,
      lookupHighlightWord: 'learning',
    );
    final mysterySpan = buildHighlightedParagraph(
      'known learning mystery',
      result,
      theme,
      onWordTapped: (_, _, {contextWordStart, contextWordEnd}) {},
      colorSettings: colorSettings,
      lookupHighlightWord: 'mystery',
    );

    expect(
      _backgroundFor(_tappableTextSpans(learningSpan), 'learning'),
      lookupHighlightBackgroundFor(theme),
    );
    expect(
      _backgroundFor(_tappableTextSpans(mysterySpan), 'mystery'),
      lookupHighlightBackgroundFor(theme),
    );
  });

  testWidgets('search highlight takes precedence over lookup highlight', (
    tester,
  ) async {
    final theme = ThemeData();

    final span = buildHighlightedParagraph(
      'known learning mystery',
      result,
      theme,
      onWordTapped: (_, _, {contextWordStart, contextWordEnd}) {},
      colorSettings: colorSettings,
      searchQuery: 'known',
      lookupHighlightWord: 'known',
    );

    final style = _textSpanStyleFor(span, 'known');

    expect(style?.backgroundColor, searchHighlightBackgroundFor(theme));
    expect(style?.color, searchHighlightForegroundFor(theme));
  });

  testWidgets('styled blocks apply lookup highlight backgrounds', (
    tester,
  ) async {
    final theme = ThemeData();
    final block = TextBlock(
      type: BlockType.paragraph,
      spans: const [StyledText('known learning mystery')],
    );

    final span = buildStyledBlock(
      block,
      result,
      theme,
      onWordTapped: (_, _, {contextWordStart, contextWordEnd}) {},
      colorSettings: colorSettings,
      lookupHighlightWord: 'mystery',
    );

    expect(
      _backgroundFor(_tappableTextSpans(span), 'mystery'),
      lookupHighlightBackgroundFor(theme),
    );
  });

  testWidgets('highlighted word text spans remain tappable', (tester) async {
    final theme = ThemeData();
    String? tappedWord;
    String? tappedContext;
    int? tappedContextWordStart;
    int? tappedContextWordEnd;

    final span = buildHighlightedParagraph(
      'known learning mystery',
      result,
      theme,
      onWordTapped: (word, context, {contextWordStart, contextWordEnd}) {
        tappedWord = word;
        tappedContext = context;
        tappedContextWordStart = contextWordStart;
        tappedContextWordEnd = contextWordEnd;
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
    expect(tappedContextWordStart, 3);
    expect(tappedContextWordEnd, 10);
  });

  testWidgets('plain lookup spans forward paragraph token offsets', (
    tester,
  ) async {
    final theme = ThemeData();
    String? tappedContext;
    int? tappedContextWordStart;
    int? tappedContextWordEnd;

    final span = buildHighlightedParagraph(
      'known learning known',
      result,
      theme,
      onWordTapped: (word, context, {contextWordStart, contextWordEnd}) {
        tappedContext = context;
        tappedContextWordStart = contextWordStart;
        tappedContextWordEnd = contextWordEnd;
      },
      colorSettings: colorSettings,
    );

    final known = _tappableTextSpans(
      span,
    ).firstWhere((item) => item.text == 'known');

    (known.recognizer as TapGestureRecognizer).onTap?.call();

    expect(tappedContext, 'known learning known');
    expect(tappedContextWordStart, 0);
    expect(tappedContextWordEnd, 5);
  });

  testWidgets('EPUB image blocks fit the available text width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 160,
              child: buildBlockWidget(
                ImageBlock(
                  src: 'cover.gif',
                  bytes: _transparentGif,
                  width: 800,
                  height: 400,
                  caption: 'Cover caption',
                ),
                result,
                ThemeData(),
                onWordTapped: (_, _, {contextWordStart, contextWordEnd}) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final preview = tester.renderObject<RenderBox>(
      find.byType(ReadableImagePreview),
    );
    expect(preview.size.width, closeTo(160, 0.1));
    expect(preview.size.height, closeTo(80, 0.1));
    expect(find.text('Cover caption'), findsOneWidget);
  });

  testWidgets('EPUB image blocks open the shared image viewer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            child: buildBlockWidget(
              ImageBlock(src: 'cover.gif', bytes: _transparentGif),
              result,
              ThemeData(),
              onWordTapped: (_, _, {contextWordStart, contextWordEnd}) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ReadableImagePreview));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byTooltip('放大'), findsOneWidget);
    expect(find.byTooltip('缩小'), findsOneWidget);
    expect(find.byTooltip('下载图片'), findsOneWidget);
  });
}

final Uint8List _transparentGif = Uint8List.fromList(
  base64Decode('R0lGODlhAQABAPAAAP///wAAACH5BAAAAAAALAAAAAABAAEAAAICRAEAOw=='),
);

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

Color? _backgroundFor(List<_TappableTextProbe> items, String text) {
  return items.firstWhere((item) => item.text == text).backgroundColor;
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

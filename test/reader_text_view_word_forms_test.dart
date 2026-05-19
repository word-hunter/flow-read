import 'dart:io';

import 'package:flow_read/models/analysis_result.dart';
import 'package:flow_read/models/word_level.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/services/word_level_service.dart';
import 'package:flow_read/widgets/reader_text_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_test_storage.dart';

void main() {
  late Directory tempDir;
  late WordLevelService wordLevels;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_reader_forms_test_');
    await openWordLevelsTestBox();
    await openSettingsTestBox();
    await settingsBox().put('word_levels_imported', 'true');
    await wordLevelsBox().addAll([
      const WordLevelInfo(
        word: 'partitions',
        originForm: 'partition',
        levelIndex: 6,
      ),
      const WordLevelInfo(
        word: 'migrating',
        originForm: 'migrate',
        levelIndex: 5,
      ),
    ]);
    wordLevels = WordLevelService();
    await wordLevels.init();
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  testWidgets(
    'highlighted reader text matches inflected forms to origin words',
    (tester) async {
      const learningColor = Color(0xFF654321);
      final result = AnalysisResult(
        passageText: "Partitions can't keep migrating.",
        title: 'Test',
        vocabulary: const [],
        knownWords: const {'partition', 'can'},
        learningWords: const {'migrate'},
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

      final span = buildHighlightedParagraph(
        "Partitions can't keep migrating.",
        result,
        ThemeData(),
        onWordTapped: (_, _) {},
        colorSettings: VocabularyColorSettings(learningColor: learningColor),
        wordLevelService: wordLevels,
      );

      final widgetTexts = _widgetTexts(span);

      expect(
        widgetTexts.map((item) => item.text),
        isNot(contains('Partitions')),
      );
      expect(widgetTexts.map((item) => item.text), isNot(contains("can't")));
      expect(widgetTexts.map((item) => item.text), contains('migrating'));
      expect(_colorFor(widgetTexts, 'migrating'), learningColor);
    },
  );
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

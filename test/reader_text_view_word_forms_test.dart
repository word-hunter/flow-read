import 'dart:io';

import 'package:flow_language/english/english.dart';
import 'package:flow_read/models/analysis_result.dart';
import 'package:flow_read/models/word_level.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/services/word_level_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_word_level_repository.dart';
import 'package:flow_read/widgets/reader_text_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_storage.dart';

typedef _TappableTextProbe = ({
  String text,
  Color? color,
  GestureRecognizer? recognizer,
});

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late WordLevelService wordLevels;

  setUp(() async {
    tempDir = await initTestStorage('flow_read_reader_forms_test_');
    db = await createTestAppDatabase();
    final repository = DriftWordLevelRepository(
      db.wordLevelDao,
      db.settingsDao,
    );
    await repository.init();
    await repository.addAll(const [
      WordLevelInfo(
        word: 'partitions',
        originForm: 'partition',
        levelIndex: 6,
      ),
      WordLevelInfo(
        word: 'migrating',
        originForm: 'migrate',
        levelIndex: 5,
      ),
    ]);
    await repository.markImported();
    wordLevels = WordLevelService(repository: repository, languageModule: const EnglishLanguageModule());
    await wordLevels.init();
  });

  tearDown(() async {
    await disposeTestStorage(tempDir);
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
        onWordTapped: (_, _, _, _, {contextWordStart, contextWordEnd}) {},
        colorSettings: VocabularyColorSettings(learningColor: learningColor),
        wordLevelService: wordLevels,
      );

      final highlightedTexts = _highlightedTextSpans(span);

      expect(
        highlightedTexts.map((item) => item.text),
        isNot(contains('Partitions')),
      );
      expect(
        highlightedTexts.map((item) => item.text),
        isNot(contains("can't")),
      );
      expect(highlightedTexts.map((item) => item.text), contains('migrating'));
      expect(_colorFor(highlightedTexts, 'migrating'), learningColor);
    },
  );
}

List<_TappableTextProbe> _highlightedTextSpans(InlineSpan span) {
  final result = <_TappableTextProbe>[];

  void visit(InlineSpan item) {
    if (item is TextSpan) {
      final text = item.text;
      final style = item.style;
      final isHighlighted =
          style?.fontWeight == FontWeight.w600 &&
          style?.decoration == TextDecoration.underline;
      if (text != null && item.recognizer != null && isHighlighted) {
        result.add((
          text: text,
          color: style?.color,
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

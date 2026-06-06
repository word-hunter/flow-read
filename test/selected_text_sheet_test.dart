import 'dart:ui' show PointerDeviceKind;

import 'package:flow_read/models/ai_text_analysis.dart';
import 'package:flow_read/providers/reading/reading_provider_riverpod.dart'
    as riverpod_reading;
import 'package:flow_read/providers/reading/services_provider.dart';
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/services/reading_config_service.dart';
import 'package:flow_read/services/reading_time_service.dart';
import 'package:flow_read/storage/repositories/reading_config_repository.dart';
import 'package:flow_read/storage/repositories/reading_time_repository.dart';
import 'package:flow_read/widgets/selected_text_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('analysis sheet shows selected text and AI result', (
    tester,
  ) async {
    final provider = _SelectedTextReadingProvider(
      aiTextAnalysis: const AITextAnalysis(
        translation: '敏捷的狐狸跳过了懒狗。',
        structureNotes: [
          StructureNote(
            source: 'The quick fox',
            role: 'main subject',
            explanation: '主语部分，说明动作发出者。',
          ),
          StructureNote(
            source: 'jumps over the lazy dog',
            role: 'verb phrase with object',
            explanation: '谓语动词短语，说明主语完成的动作。',
          ),
        ],
        grammarPoints: [
          GrammarPoint(
            source: 'jumps over',
            explanation: '短语动词结构，表示越过某物。',
            difficulty: 'medium',
          ),
        ],
        vocabularyNotes: [
          VocabularyNote(word: 'quick', contextMeaning: '敏捷的，快速的', pos: 'adj.'),
          VocabularyNote(
            word: 'jumps over',
            contextMeaning: '跳过，越过',
            pos: 'phrasal verb',
          ),
        ],
        expressionNotes: [
          ExpressionNote(
            source: 'lazy dog',
            meaning: '懒狗',
            usage: '可复用为描述懒散对象的表达。',
          ),
        ],
        readingTip: '注意主语和谓语动作之间的关系。',
      ),
    );

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          riverpod_reading.readingProvider.overrideWith((ref) => provider),
          readingConfigServiceProvider.overrideWith(
            (ref) => _FakeReadingConfigService(),
          ),
          readingTimeServiceProvider.overrideWith(
            (ref) => _FakeReadingTimeService(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: SelectedTextSheet(
                selectedText: 'The quick fox jumps over the lazy dog.',
                analysis: null,
                analyzerName: 'DeepSeek AI',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('The quick fox jumps over the lazy dog.'), findsOneWidget);
    expect(find.text('翻译'), findsNothing);
    expect(find.text('译文'), findsOneWidget);
    expect(find.text('敏捷的狐狸跳过了懒狗。'), findsOneWidget);
    expect(find.text('结构'), findsOneWidget);
    expect(find.byKey(const ValueKey('structure-source-text')), findsOneWidget);
    expect(find.text('main subject'), findsOneWidget);
    expect(find.text('语法要点'), findsOneWidget);
    expect(find.text('jumps over'), findsOneWidget);
    expect(find.text('词汇说明'), findsOneWidget);
    expect(find.textContaining('quick', findRichText: true), findsWidgets);
    expect(find.text('表达'), findsOneWidget);
    expect(find.text('lazy dog'), findsOneWidget);
    expect(find.text('阅读提示'), findsOneWidget);
    expect(find.text('加入学习卡片'), findsOneWidget);

    expect(
      _spanForStructureSource(tester, 'The quick fox')?.style?.backgroundColor,
      isNull,
    );

    final firstStructureExplanation = find.byKey(
      const ValueKey('structure-explanation-0'),
    );
    await tester.ensureVisible(firstStructureExplanation);
    await tester.pump();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(
      location: tester.getCenter(firstStructureExplanation),
    );
    await tester.pump();
    await mouse.moveTo(tester.getCenter(firstStructureExplanation));
    await tester.pump(const Duration(milliseconds: 150));

    expect(
      _spanForStructureSource(tester, 'The quick fox')?.style?.backgroundColor,
      isNotNull,
    );

    final firstVocabularySave = tester.getTopRight(
      find.byKey(const ValueKey('vocabulary-save-0')),
    );
    final secondVocabularySave = tester.getTopRight(
      find.byKey(const ValueKey('vocabulary-save-1')),
    );
    expect(
      (firstVocabularySave.dx - secondVocabularySave.dx).abs(),
      lessThan(1),
    );
  });

  testWidgets('structure hover keeps source text layout stable', (
    tester,
  ) async {
    const selectedText =
        'She would drop her book and leap up to slap him, '
        'and he could jump aside and kick at her, '
        'and for a few heavenly moments there would be a real '
        'down-on-the-floor scuffle.';
    final provider = _SelectedTextReadingProvider(
      aiTextAnalysis: const AITextAnalysis(
        translation: '她会扔下书跳起来打他。',
        structureNotes: [
          StructureNote(
            source: 'She would drop her book and leap up to slap him',
            role: 'main clause',
            explanation: "'would' 表示过去习惯性动作。",
          ),
          StructureNote(
            source: 'he could jump aside and kick at her',
            role: 'coordinated clause',
            explanation: "'could' 表示能力或可能性。",
          ),
          StructureNote(
            source:
                'for a few heavenly moments there would be a real down-on-the-floor scuffle',
            role: 'time phrase',
            explanation: '补充动作持续的时间和场景。',
          ),
        ],
        grammarPoints: [],
        vocabularyNotes: [],
        expressionNotes: [],
        readingTip: '',
      ),
    );

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          riverpod_reading.readingProvider.overrideWith((ref) => provider),
          readingConfigServiceProvider.overrideWith(
            (ref) => _FakeReadingConfigService(),
          ),
          readingTimeServiceProvider.overrideWith(
            (ref) => _FakeReadingTimeService(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 720,
              child: SelectedTextSheet(
                selectedText: selectedText,
                analysis: null,
                embedded: true,
              ),
            ),
          ),
        ),
      ),
    );

    final sourceFinder = find.byKey(const ValueKey('structure-source-text'));
    final targetSpanBefore = _spanForStructureSource(
      tester,
      'he could jump aside and kick at her',
    );
    final sourceHeightBefore = tester.getSize(sourceFinder).height;
    final sourceFontWeightBefore = targetSpanBefore?.style?.fontWeight;

    final secondStructureExplanation = find.byKey(
      const ValueKey('structure-explanation-1'),
    );
    await tester.ensureVisible(secondStructureExplanation);
    await tester.pump();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(
      location: tester.getCenter(secondStructureExplanation),
    );
    await tester.pump();
    await mouse.moveTo(tester.getCenter(secondStructureExplanation));
    await tester.pump(const Duration(milliseconds: 150));

    final targetSpanAfter = _spanForStructureSource(
      tester,
      'he could jump aside and kick at her',
    );
    final sourceHeightAfter = tester.getSize(sourceFinder).height;

    expect(targetSpanAfter?.style?.backgroundColor, isNotNull);
    expect(targetSpanAfter?.style?.fontWeight, sourceFontWeightBefore);
    expect(sourceHeightAfter, sourceHeightBefore);
  });

  testWidgets('embedded title aligns with collapse button', (tester) async {
    final provider = _SelectedTextReadingProvider(
      aiTextAnalysis: const AITextAnalysis(
        translation: '',
        grammarPoints: [],
        vocabularyNotes: [],
        readingTip: '',
      ),
    );

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          riverpod_reading.readingProvider.overrideWith((ref) => provider),
          readingConfigServiceProvider.overrideWith(
            (ref) => _FakeReadingConfigService(),
          ),
          readingTimeServiceProvider.overrideWith(
            (ref) => _FakeReadingTimeService(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 600,
              child: SelectedTextSheet(
                selectedText: 'The quick fox jumps over the lazy dog.',
                analysis: null,
                embedded: true,
              ),
            ),
          ),
        ),
      ),
    );

    final titleCenter = tester.getCenter(find.text('结构分析'));
    final collapseCenter = tester.getCenter(find.byIcon(Icons.chevron_right));
    expect(titleCenter.dy, closeTo(collapseCenter.dy, 1));
  });
}

TextSpan? _spanForStructureSource(WidgetTester tester, String source) {
  final richText = tester.widget<RichText>(
    find.byKey(const ValueKey('structure-source-text')),
  );
  return _findSpanContaining(richText.text, source);
}

TextSpan? _findSpanContaining(InlineSpan span, String source) {
  if (span is! TextSpan) return null;
  if ((span.text ?? '').contains(source)) return span;

  final children = span.children;
  if (children == null) return null;

  for (final child in children) {
    final match = _findSpanContaining(child, source);
    if (match != null) return match;
  }
  return null;
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

class _FakeReadingConfigService extends ReadingConfigService {
  _FakeReadingConfigService()
    : super(repository: _FakeReadingConfigRepo());
}

class _FakeReadingConfigRepo implements ReadingConfigRepository {
  @override
  Future<void> init() async {}

  @override
  String getString(String key, {required String defaultValue}) => defaultValue;

  @override
  Future<void> putString(String key, String value) async {}

  @override
  Future<void> close() async {}
}

class _FakeReadingTimeService extends ReadingTimeService {
  _FakeReadingTimeService()
    : super(repository: _FakeReadingTimeRepo());
}

class _FakeReadingTimeRepo implements ReadingTimeRepository {
  @override
  Future<void> init() async {}

  @override
  int secondsFor(String key) => 0;

  @override
  Future<void> putSeconds(String key, int seconds) async {}

  @override
  Future<void> close() async {}
}

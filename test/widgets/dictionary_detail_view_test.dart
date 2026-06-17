import 'package:flow_dictionary/flow_dictionary.dart';
import 'package:flow_read/models/reading_memory.dart';
import 'package:flow_read/models/user_vocabulary.dart';
import 'package:flow_read/widgets/dictionary_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dictionary detail content is selectable and keeps word lookup', (
    tester,
  ) async {
    String? lookedUpWord;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DictionaryDetailView(
            word: 'flow',
            entry: null,
            primaryDefinition: 'river',
            isLoading: false,
            onLookupWord: (word) => lookedUpWord = word,
          ),
        ),
      ),
    );

    expect(find.byType(SelectionArea), findsOneWidget);

    final riverRect = tester.getRect(find.text('river'));
    await tester.tapAt(Offset(riverRect.left + 8, riverRect.center.dy));
    await tester.pump();

    expect(lookedUpWord, 'river');
  });

  testWidgets('renders AI primary definition markdown and keeps word lookup', (
    tester,
  ) async {
    String? lookedUpWord;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DictionaryDetailView(
            word: 'hippopotomonstrosesquipedaliophobia',
            entry: null,
            primaryDefinition: '**Pip**\n- `knows` long words',
            isLoading: false,
            onLookupWord: (word) => lookedUpWord = word,
          ),
        ),
      ),
    );

    final richText = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((widget) => widget.text.toPlainText())
        .join('\n');
    expect(richText, contains('Pip'));
    expect(richText, contains('knows long words'));
    expect(richText, isNot(contains('**')));
    expect(richText, isNot(contains('`')));

    final pipFinder = find.byWidgetPredicate(
      (widget) => widget is RichText && widget.text.toPlainText() == 'Pip',
    );
    final pipRect = tester.getRect(pipFinder);
    await tester.tapAt(pipRect.center);
    await tester.pump();

    expect(lookedUpWord, 'pip');
  });

  testWidgets('shows personal word memory in dictionary detail view', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 6, 15, 8);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DictionaryDetailView(
            word: 'reluctant',
            entry: null,
            primaryDefinition: null,
            isLoading: false,
            wordMemoryCard: WordMemoryCard(
              canonical: 'reluctant',
              displayText: 'reluctant',
              languageCode: 'en',
              userStatus: UserWordStatus.learning,
              lookupCount: 3,
              savedExplanations: [
                MemoryKnowledgeExplanation(
                  id: 'explanation:1',
                  entityId: 'entity:en:word:reluctant',
                  explanation:
                      'reluctant to do means unwilling to do something.',
                  source: ExplanationSource.ai,
                  targetLanguage: 'zh',
                  createdAt: now,
                  updatedAt: now,
                ),
              ],
              evidences: [
                MemoryKnowledgeEvidence(
                  id: 'evidence:1',
                  entityId: 'entity:en:word:reluctant',
                  sourceId: 'book:book-1',
                  sourceKind: SourceKind.book,
                  shortExcerpt: 'He was reluctant to admit defeat.',
                  sourceTitleSnapshot: 'Book One',
                  sourceAvailability: SourceAvailability.deleted,
                  retentionPolicy: EvidenceRetentionPolicy.keepSnippet,
                  createdAt: now,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('个人记忆'), findsOneWidget);
    expect(find.text('学习中'), findsOneWidget);
    expect(find.text('查词 3 次'), findsOneWidget);
    expect(find.text('保存解释'), findsOneWidget);
    expect(
      find.text('reluctant to do means unwilling to do something.'),
      findsOneWidget,
    );
    expect(find.text('He was reluctant to admit defeat.'), findsOneWidget);
    expect(find.text('Book One · 已删除'), findsOneWidget);
    expect(find.text('未找到词典内容'), findsNothing);
  });

  testWidgets('shows retry action above local dictionary fallback', (
    tester,
  ) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DictionaryDetailView(
            word: 'flow',
            entry: const DictionaryEntry(
              word: 'flow',
              meanings: [
                Meaning(
                  partOfSpeech: 'n.',
                  definitions: ['movement through a channel'],
                ),
              ],
              sourceName: 'WordNet',
              errorMessage: '在线词典请求失败，可重试。已先显示本地 WordNet 释义。',
            ),
            primaryDefinition: 'movement through a channel',
            isLoading: false,
            onRetryLookup: () => retryCount += 1,
          ),
        ),
      ),
    );

    expect(find.text('重试'), findsOneWidget);
    expect(find.text('本地兜底释义'), findsOneWidget);
    expect(find.text('movement through a channel'), findsOneWidget);

    final retryBottom = tester.getBottomLeft(find.text('重试')).dy;
    final fallbackTop = tester
        .getTopLeft(find.text('movement through a channel'))
        .dy;
    expect(fallbackTop, greaterThan(retryBottom));

    await tester.tap(find.text('重试'));
    await tester.pump();

    expect(retryCount, 1);
  });

  testWidgets(
    'keeps primary definition readable on a dark dictionary surface',
    (
      tester,
    ) async {
      final colorScheme =
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF0277FE),
          ).copyWith(
            surface: const Color(0xFF1A2233),
            onSurface: const Color(0xFF002B4D),
            primary: const Color(0xFF0277FE),
            primaryContainer: const Color(0xFFD8E8FF),
            onPrimaryContainer: const Color(0xFF002B4D),
          );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: colorScheme),
          home: Scaffold(
            backgroundColor: colorScheme.surface,
            body: const DictionaryDetailView(
              word: 'jiffy',
              entry: null,
              primaryDefinition: 'a very short time',
              isLoading: false,
            ),
          ),
        ),
      );

      final definition = tester.widget<Text>(find.text('a very short time'));
      final definitionColor = definition.style?.color;
      expect(definitionColor, isNotNull);

      final card = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('a very short time'),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Container &&
                    widget.padding == const EdgeInsets.all(14),
              ),
            )
            .first,
      );
      final decoration = card.decoration as BoxDecoration;
      final cardBackground = decoration.color;
      expect(cardBackground, isNotNull);
      expect(
        _contrastRatio(cardBackground!, definitionColor!),
        greaterThanOrEqualTo(4.5),
      );
    },
  );
}

double _contrastRatio(Color a, Color b) {
  final aLum = a.computeLuminance();
  final bLum = b.computeLuminance();
  final lighter = aLum > bLum ? aLum : bLum;
  final darker = aLum > bLum ? bLum : aLum;
  return (lighter + 0.05) / (darker + 0.05);
}

import 'dart:io';

import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/models/book_glossary_entry.dart';
import 'package:flow_read/providers/book_insight_provider.dart';
import 'package:flow_read/screens/book_insights_page.dart';
import 'package:flow_read/services/book_glossary_service.dart';
import 'package:flow_read/services/character_registry.dart';
import 'package:flow_read/services/reading_memory/chapter_summary_source_scope_cache.dart';
import 'package:flow_read/services/reading_memory/source_scope_service.dart';
import 'package:flow_read/storage/database/app_database.dart'
    hide BookGlossaryEntry, CharacterRegistryEntry;
import 'package:flow_read/storage/database/dao/book_glossary_dao.dart';
import 'package:flow_read/storage/database/repositories/drift_character_registry_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_memory_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late AICacheService cacheService;
  late ChapterSummarySourceScopeCache summarySourceScopeCache;
  late BookInsightProvider provider;
  late List<BookSynthesisRequest> synthesisRequests;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'flow_read_book_insights_test_',
    );
    db = await AppDatabase.createInMemory();
    final glossaryService = BookGlossaryService(BookGlossaryDao(db));
    final characterRegistryWriter = CharacterRegistry(
      repository: DriftCharacterRegistryRepository(db.characterRegistryDao),
    );
    await characterRegistryWriter.init();
    await glossaryService.saveEntry(
      BookGlossaryEntry.create(
        bookId: 'book-1',
        word: 'godswood',
        canonicalForm: 'old godswood',
        explanation: 'A sacred grove tied to the book world.',
        sourceContext: 'The godswood was silent.',
        createdAt: DateTime.utc(2026, 6, 15),
      ),
    );
    await glossaryService.saveEntry(
      BookGlossaryEntry.create(
        bookId: 'other-book',
        word: 'elsewhere',
        explanation: 'Different book.',
        createdAt: DateTime.utc(2026, 6, 15),
      ),
    );
    await characterRegistryWriter.addEntry(
      'book-1',
      CharacterRegistryEntry(
        canonicalName: 'Eddard Stark',
        aliases: const {'Ned'},
        userOverrides: const {'Lord Stark'},
        firstAppearanceChapter: 0,
        updatedAt: DateTime.utc(2026, 6, 15),
      ),
    );
    await characterRegistryWriter.addEntry(
      'other-book',
      CharacterRegistryEntry(
        canonicalName: 'Other Person',
        updatedAt: DateTime.utc(2026, 6, 15),
      ),
    );
    cacheService = AICacheService(
      documentsDirectoryProvider: () async => tempDir,
    );
    final sourceScope = SourceScopeService(
      repository: DriftReadingMemoryRepository(
        db.readingMemoryDao,
        languageCode: 'en',
      ),
      languageCode: 'en',
    );
    await sourceScope.init();
    summarySourceScopeCache = ChapterSummarySourceScopeCache(
      sourceScope: sourceScope,
    );
    synthesisRequests = [];
    provider = BookInsightProvider(
      cacheService: cacheService,
      glossaryService: glossaryService,
      characterRegistry: CharacterRegistry(
        repository: DriftCharacterRegistryRepository(db.characterRegistryDao),
      ),
      chapterSummarySourceScopeCache: summarySourceScopeCache,
      synthesisRunner: (request) async {
        synthesisRequests.add(request);
        return BookSynthesisResult(
          fullStoryline:
              request.analysisData.scope.spoilerBoundary.scope ==
                  AIContextScope.fullBook
              ? '全书合成结果'
              : '已读范围合成结果',
          characterGraph: const CharacterRelationGraph(),
          bookMindMap: const MindMapGraph(
            root: MindMapNode(id: 'root', label: 'Book One'),
          ),
          keyInsights: const ['洞察一'],
          generatedAt: DateTime.utc(2026, 6, 24),
        );
      },
    );
    await provider.loadForBook(
      'book-1',
      totalChapters: 8,
      currentChapter: 2,
    );
  });

  tearDown(() async {
    provider.dispose();
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('shows book glossary entries in insights page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BookInsightsPage(
          provider: provider,
          bookTitle: 'Book One',
          onGenerateChapter: (_) async {},
        ),
      ),
    );

    expect(find.text('暂无章节总结'), findsNothing);
    expect(find.text('术语'), findsOneWidget);

    await tester.tap(find.text('术语'));
    await _pumpTabTransition(tester);

    expect(find.text('godswood'), findsOneWidget);
    expect(find.text('old godswood'), findsOneWidget);
    expect(find.text('A sacred grove tied to the book world.'), findsOneWidget);
    expect(find.textContaining('The godswood was silent.'), findsOneWidget);
    expect(find.text('elsewhere'), findsNothing);
  });

  testWidgets('shows registered book characters in insights page', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BookInsightsPage(
          provider: provider,
          bookTitle: 'Book One',
          onGenerateChapter: (_) async {},
        ),
      ),
    );

    expect(find.text('人物'), findsOneWidget);

    await tester.tap(find.text('人物'));
    await _pumpTabTransition(tester);

    expect(find.text('Eddard Stark'), findsOneWidget);
    expect(find.text('Ned'), findsOneWidget);
    expect(find.text('Lord Stark'), findsOneWidget);
    expect(find.text('首次出现: 第 1 章'), findsOneWidget);
    expect(find.text('Other Person'), findsNothing);
  });

  test('maintains character registry entries', () async {
    await provider.addCharacter('Arya Stark');
    await provider.addCharacterAlias('Arya Stark', 'Arry');

    expect(
      provider.characterRegistryEntries.any(
        (entry) =>
            entry.canonicalName == 'Arya Stark' &&
            entry.userOverrides.contains('Arry'),
      ),
      isTrue,
    );

    await provider.removeCharacterAlias('Arya Stark', 'Arry');
    expect(
      provider.characterRegistryEntries
          .where((entry) => entry.canonicalName == 'Arya Stark')
          .single
          .userOverrides,
      isEmpty,
    );

    await provider.removeCharacter('Arya Stark');
    expect(
      provider.characterRegistryEntries.any(
        (entry) => entry.canonicalName == 'Arya Stark',
      ),
      isFalse,
    );
  });

  test('loads chapter summaries from source scope cache', () async {
    await summarySourceScopeCache.saveChapterSummary(
      bookId: 'book-1',
      bookTitle: 'Book One',
      chapterIndex: 0,
      outputLanguage: 'zh',
      summary: const AISummary(
        events: [
          SummaryEvent(
            description: 'Ned finds a direwolf near Winterfell.',
            source: 'The direwolf lay in the snow.',
            significance: 'This links the children to the northern house.',
            confidence: 'high',
          ),
        ],
        characterDevelopments: [],
        keyVocabulary: [],
        readingGuidance: 'Pay attention to the house symbols.',
      ),
    );

    await provider.loadForBook(
      'book-1',
      totalChapters: 8,
      currentChapter: 2,
    );

    expect(provider.chapterSummaries.keys, contains(0));
    expect(
      provider.chapterSummaries[0]!.events.single.description,
      contains('direwolf'),
    );
    expect(provider.coverage!.summarizedChapters, 1);
    expect(provider.analysisData, isNotNull);
    expect(
      provider.analysisData!.storyEvents.single.description,
      contains('direwolf'),
    );
  });

  test('refreshIfLoaded merges newly generated chapter summaries', () async {
    expect(provider.analysisData, isNull);

    await summarySourceScopeCache.saveChapterSummary(
      bookId: 'book-1',
      bookTitle: 'Book One',
      chapterIndex: 1,
      outputLanguage: 'zh',
      summary: const AISummary(
        events: [
          SummaryEvent(
            description: 'Arya notices a hidden path.',
            source: 'Arya saw the path.',
            significance: 'This opens a new route.',
            confidence: 'high',
          ),
        ],
        characterDevelopments: [
          CharacterDevelopment(
            character: 'Arya Stark',
            change: 'Arya becomes more observant.',
            source: 'Arya saw the path.',
            confidence: 'high',
          ),
        ],
        keyVocabulary: [],
        readingGuidance: '',
      ),
    );

    await provider.refreshIfLoaded('book-1');

    expect(provider.analysisData, isNotNull);
    expect(
      provider.analysisData!.storyEvents.single.description,
      contains('hidden path'),
    );
    expect(
      provider.analysisData!.characters.single.canonicalName,
      'Arya Stark',
    );
  });

  test('confirms AI-inferred characters into registry', () async {
    await provider.confirmCharacterCard(
      const BookCharacterCard(
        canonicalName: 'Arya Stark',
        firstSeenChapter: 1,
        developments: [
          CharacterDevelopment(
            character: 'Arya Stark',
            change: 'Travels under a hidden identity.',
            source: 'Arya kept moving.',
            confidence: 'medium',
          ),
        ],
        evidenceSnippets: ['Arya kept moving.'],
      ),
    );

    expect(
      provider.characterRegistryEntries.any(
        (entry) => entry.canonicalName == 'Arya Stark',
      ),
      isTrue,
    );
  });

  testWidgets('backfills only missing read chapter summaries', (tester) async {
    List<int>? requestedChapters;

    await tester.pumpWidget(
      MaterialApp(
        home: BookInsightsPage(
          provider: provider,
          bookTitle: 'Book One',
          onGenerateChapter: (_) async {},
          onGenerateMissingReadChapters: (chapters) async {
            requestedChapters = chapters;
            return chapters.length;
          },
        ),
      ),
    );
    await tester.tap(find.text('章节'));
    await _pumpTabTransition(tester);

    await tester.tap(find.byIcon(Icons.playlist_add_check));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(requestedChapters, [0, 1, 2]);
  });

  test('generates read and full book synthesis with isolated scopes', () async {
    await _seedSummary(
      summarySourceScopeCache,
      chapterIndex: 0,
      eventDescription: 'Arya finds a hidden path.',
      character: 'Arya Stark',
      change: 'Arya becomes more observant.',
    );
    await provider.loadForBook(
      'book-1',
      totalChapters: 8,
      currentChapter: 2,
      bookTitle: 'Book One',
    );

    expect(provider.canGenerateSynthesis, isTrue);
    expect(
      provider.analysisData!.storyEvents.single.description,
      'Arya finds a hidden path.',
    );
    expect(
      provider.analysisData!.characters.single.canonicalName,
      'Arya Stark',
    );

    await provider.generateReadScopeSynthesis();
    await provider.generateFullBookSynthesis();

    expect(synthesisRequests, hasLength(2));
    expect(
      synthesisRequests[0].analysisData.scope.spoilerBoundary.scope,
      AIContextScope.readSoFar,
    );
    expect(
      synthesisRequests[1].analysisData.scope.spoilerBoundary.scope,
      AIContextScope.fullBook,
    );
    expect(
      synthesisRequests[0].chapterSummaries.single.summary,
      contains('Arya finds a hidden path.'),
    );
    expect(provider.readScopeSynthesis!.fullStoryline, '已读范围合成结果');
    expect(provider.fullBookSynthesis!.fullStoryline, '全书合成结果');
    expect(provider.visibleSynthesis, same(provider.readScopeSynthesis));
  });
}

Future<void> _pumpTabTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _seedSummary(
  ChapterSummarySourceScopeCache cache, {
  required int chapterIndex,
  required String eventDescription,
  required String character,
  required String change,
}) async {
  await cache.saveChapterSummary(
    bookId: 'book-1',
    bookTitle: 'Book One',
    chapterIndex: chapterIndex,
    outputLanguage: 'zh',
    summary: AISummary(
      events: [
        SummaryEvent(
          description: eventDescription,
          source: eventDescription,
          significance: 'Important for the current arc.',
          confidence: 'high',
        ),
      ],
      characterDevelopments: [
        CharacterDevelopment(
          character: character,
          change: change,
          source: change,
          confidence: 'high',
        ),
      ],
      keyVocabulary: const [],
      readingGuidance: 'Follow the character choice.',
    ),
  );
}

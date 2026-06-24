import 'dart:async';
import 'dart:io';

import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/models/book.dart';
import 'package:flow_read/models/book_glossary_entry.dart';
import 'package:flow_read/models/chapter.dart';
import 'package:flow_read/providers/book_insight_provider.dart';
import 'package:flow_read/screens/book_insights_page.dart';
import 'package:flow_read/services/book_glossary_service.dart';
import 'package:flow_read/services/character_registry.dart';
import 'package:flow_read/services/book_insight_chapter_catalog.dart';
import 'package:flow_read/services/reading_memory/book_insight_source_scope_service.dart';
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
          characterGraph: CharacterRelationGraph(
            nodes: request.analysisData.characters
                .map(
                  (character) => GraphNode(
                    id: character.canonicalName,
                    label: character.canonicalName,
                  ),
                )
                .toList(growable: false),
            edges: request.analysisData.characters.length < 2
                ? const []
                : [
                    GraphEdge(
                      fromCharacterId:
                          request.analysisData.characters.first.canonicalName,
                      toCharacterId:
                          request.analysisData.characters.last.canonicalName,
                      relation: '同行',
                    ),
                  ],
          ),
          bookMindMap: const MindMapGraph(
            root: MindMapNode(
              id: 'root',
              label: 'Book One',
              children: [
                MindMapNode(id: 'characters', label: '人物'),
              ],
            ),
          ),
          structure: '起承转合',
          themeAnalysis: '身份与选择',
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
          onGenerateChapter: (_) async =>
              const BookInsightChapterGenerationResult.generated(),
        ),
      ),
    );

    expect(find.text('暂无章节总结'), findsNothing);
    expect(find.text('术语'), findsOneWidget);

    await tester.tap(find.text('术语'));
    await _pumpTabTransition(tester);

    expect(find.text('godswood'), findsOneWidget);
    expect(find.textContaining('old godswood'), findsOneWidget);
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
          onGenerateChapter: (_) async =>
              const BookInsightChapterGenerationResult.generated(),
        ),
      ),
    );

    expect(find.text('人物'), findsOneWidget);

    await tester.tap(find.text('人物'));
    await _pumpTabTransition(tester);

    expect(find.text('Eddard Stark'), findsWidgets);
    expect(find.text('Ned'), findsOneWidget);
    expect(find.text('Lord Stark'), findsOneWidget);
    expect(find.text('首次出现: 第 1 章'), findsOneWidget);
    expect(find.text('Other Person'), findsNothing);
  });

  testWidgets('AI ask button opens the embedded assistant sidebar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var askedAI = false;

    await tester.pumpWidget(
      MaterialApp(
        home: BookInsightsPage(
          provider: provider,
          bookTitle: 'Book One',
          onGenerateChapter: (_) async =>
              const BookInsightChapterGenerationResult.generated(),
          onAskAI: (context) {
            askedAI = true;
            return true;
          },
          aiPanelBuilder: (onClose) => Center(
            child: TextButton(
              onPressed: onClose,
              child: const Text('AI sidebar from insights'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('AI 提问'));
    await tester.pumpAndSettle();

    expect(askedAI, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('AI sidebar from insights'), findsOneWidget);

    await tester.tap(find.byTooltip('关闭面板'));
    await tester.pumpAndSettle();

    expect(find.text('AI sidebar from insights'), findsNothing);
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

  testWidgets('renders story events without matching chapter summaries', (
    tester,
  ) async {
    final eventOnlyProvider = BookInsightProvider(
      cacheService: cacheService,
      bookInsightSourceScopeService: _FakeBookInsightSourceScopeService(
        BookInsightSourceScopeProjection(
          bookId: 'book-1',
          sourceId: 'book:book-1',
          maxReadChapter: 0,
          chapterSummaries: const {},
          analysisData: BookAnalysisData(
            bookId: 'book-1',
            scope: AnalysisScope.readSoFar(
              bookId: 'book-1',
              currentChapterIndex: 0,
            ),
            storyEvents: [
              StoryEvent(
                description: 'The first snow reaches Winterfell.',
                chapterIndex: 0,
              ),
            ],
            coverage: 0.2,
            schemaVersion: '1.0.0',
            analyzedAt: DateTime.utc(2026, 6, 24),
          ),
          storyline: BookStoryline.empty('book-1'),
          characterCards: const [],
          characterRegistryEntries: const [],
          glossaryEntries: const [],
          coverage: const BookInsightCoverage(
            summarizedChapters: 0,
            totalChapters: 3,
            readChapters: 1,
            missingChapters: [0],
          ),
        ),
      ),
    );
    addTearDown(eventOnlyProvider.dispose);
    await eventOnlyProvider.loadForBook(
      'book-1',
      totalChapters: 3,
      currentChapter: 0,
      bookTitle: 'Book One',
    );

    expect(eventOnlyProvider.chapterSummaries, isEmpty);
    expect(eventOnlyProvider.analysisData?.storyEvents, hasLength(1));

    await tester.pumpWidget(
      MaterialApp(
        home: BookInsightsPage(
          provider: eventOnlyProvider,
          bookTitle: 'Book One',
          onGenerateChapter: (_) async =>
              const BookInsightChapterGenerationResult.generated(),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    await tester.tap(find.text('章节'));
    await _pumpTabTransition(tester);

    expect(find.text('The first snow reaches Winterfell.'), findsOneWidget);
  });

  test(
    'ignores fallback chapter summaries in book insights coverage',
    () async {
      await summarySourceScopeCache.saveChapterSummary(
        bookId: 'book-1',
        bookTitle: 'Book One',
        chapterIndex: 0,
        outputLanguage: 'zh',
        summary: AISummary.fallback('AI 返回了非结构化内容，但没有可展示的文本。'),
      );
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
          characterDevelopments: [],
          keyVocabulary: [],
          readingGuidance: '',
        ),
      );

      await provider.loadForBook(
        'book-1',
        totalChapters: 8,
        currentChapter: 2,
      );

      expect(provider.chapterSummaries.keys, isNot(contains(0)));
      expect(provider.chapterSummaries.keys, contains(1));
      expect(provider.coverage!.summarizedChapters, 1);
    },
  );

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
    expect(
      provider.characterRegistryEntries.any(
        (entry) => entry.canonicalName == 'Arya Stark',
      ),
      isTrue,
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

  testWidgets('chapter generate button shows progress while running', (
    tester,
  ) async {
    int? requestedChapter;
    final completion = Completer<BookInsightChapterGenerationResult>();

    await tester.pumpWidget(
      MaterialApp(
        home: BookInsightsPage(
          provider: provider,
          bookTitle: 'Book One',
          onGenerateChapter: (chapterIndex) async {
            requestedChapter = chapterIndex;
            return completion.future;
          },
        ),
      ),
    );
    await tester.tap(find.text('章节'));
    await _pumpTabTransition(tester);

    await tester.tap(find.text('生成').first);
    await tester.pump();

    expect(requestedChapter, 0);
    expect(find.text('生成中'), findsOneWidget);

    completion.complete(
      const BookInsightChapterGenerationResult.notGenerated('该章节没有可分析的正文。'),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('生成'), findsWidgets);
  });

  testWidgets('backfills only missing read chapter summaries', (tester) async {
    List<int>? requestedChapters;

    await tester.pumpWidget(
      MaterialApp(
        home: BookInsightsPage(
          provider: provider,
          bookTitle: 'Book One',
          onGenerateChapter: (_) async =>
              const BookInsightChapterGenerationResult.generated(),
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

  testWidgets('backfills only analyzable body chapters in story map', (
    tester,
  ) async {
    List<int>? requestedChapters;
    final storyMapProvider = BookInsightProvider(
      cacheService: cacheService,
      bookInsightSourceScopeService: _FakeBookInsightSourceScopeService(
        BookInsightSourceScopeProjection(
          bookId: 'book-1',
          sourceId: 'book:book-1',
          maxReadChapter: 1,
          chapterSummaries: const {},
          storyline: BookStoryline.empty('book-1'),
          characterCards: const [],
          characterRegistryEntries: const [],
          glossaryEntries: const [],
          coverage: const BookInsightCoverage(
            summarizedChapters: 0,
            totalChapters: 3,
            readChapters: 2,
            missingChapters: [0, 1],
          ),
        ),
      ),
    );
    addTearDown(storyMapProvider.dispose);
    await storyMapProvider.loadForBook(
      'book-1',
      totalChapters: 3,
      currentChapter: 1,
      bookTitle: 'Book One',
    );
    final chapterCatalog = BookInsightChapterCatalog.fromBook(
      const Book(
        title: 'Book One',
        author: 'Author',
        chapters: [
          Chapter(
            title: 'Preface',
            plainText:
                'This preface explains how the book was edited and prepared.',
            rawHtml: '',
          ),
          Chapter(
            title: 'Chapter One',
            plainText:
                'Alice finds the old map and walks into the valley before dawn.',
            rawHtml: '',
          ),
          Chapter(
            title: 'Chapter Two',
            plainText:
                'Alice follows the river road and finds a hidden bridge.',
            rawHtml: '',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BookInsightsPage(
          provider: storyMapProvider,
          bookTitle: 'Book One',
          chapterCatalog: chapterCatalog,
          onGenerateChapter: (_) async =>
              const BookInsightChapterGenerationResult.generated(),
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

    expect(find.textContaining('Preface'), findsNothing);
    expect(requestedChapters, [1]);
  });

  testWidgets('chapter generation feedback uses story map display number', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int? requestedChapter;
    final storyMapProvider = BookInsightProvider(
      cacheService: cacheService,
      bookInsightSourceScopeService: _FakeBookInsightSourceScopeService(
        BookInsightSourceScopeProjection(
          bookId: 'book-1',
          sourceId: 'book:book-1',
          maxReadChapter: 3,
          chapterSummaries: {
            1: _summaryWithEvent('Alice enters the valley.'),
            2: _summaryWithEvent('Alice finds the bridge.'),
          },
          storyline: BookStoryline.empty('book-1'),
          characterCards: const [],
          characterRegistryEntries: const [],
          glossaryEntries: const [],
          coverage: const BookInsightCoverage(
            summarizedChapters: 2,
            totalChapters: 4,
            readChapters: 4,
            missingChapters: [3],
          ),
        ),
      ),
    );
    addTearDown(storyMapProvider.dispose);
    await storyMapProvider.loadForBook(
      'book-1',
      totalChapters: 4,
      currentChapter: 3,
      bookTitle: 'Book One',
    );
    final chapterCatalog = BookInsightChapterCatalog.fromBook(
      const Book(
        title: 'Book One',
        author: 'Author',
        chapters: [
          Chapter(
            title: 'Preface',
            plainText:
                'This preface explains how the book was edited and prepared.',
            rawHtml: '',
          ),
          Chapter(
            title: 'Chapter One',
            plainText:
                'Alice finds the old map and walks into the valley before dawn.',
            rawHtml: '',
          ),
          Chapter(
            title: 'Chapter Two',
            plainText:
                'Alice follows the river road and finds a hidden bridge.',
            rawHtml: '',
          ),
          Chapter(
            title: 'Chapter Three',
            plainText: 'Alice crosses the bridge and discovers a quiet house.',
            rawHtml: '',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookInsightsPage(
            provider: storyMapProvider,
            bookTitle: 'Book One',
            chapterCatalog: chapterCatalog,
            onGenerateChapter: (chapterIndex) async {
              requestedChapter = chapterIndex;
              return const BookInsightChapterGenerationResult.notGenerated(
                '章节总结已生成。',
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('章节'));
    await _pumpTabTransition(tester);
    await tester.tap(find.text('生成'));
    await tester.pump();

    expect(requestedChapter, 3);
    expect(find.text('未生成第 3 章洞察：章节总结已生成。'), findsOneWidget);
    expect(find.textContaining('第 4 章洞察'), findsNothing);
  });

  test('reloads projections when spoiler boundary changes', () async {
    await _seedSummary(
      summarySourceScopeCache,
      chapterIndex: 0,
      eventDescription: 'Arya finds a hidden path.',
      character: 'Arya Stark',
      change: 'Arya becomes more observant.',
    );
    await _seedSummary(
      summarySourceScopeCache,
      chapterIndex: 2,
      eventDescription: 'Sansa hears a secret.',
      character: 'Sansa Stark',
      change: 'Sansa becomes cautious.',
    );

    await provider.loadForBook(
      'book-1',
      totalChapters: 8,
      currentChapter: 2,
      bookTitle: 'Book One',
    );

    expect(provider.chapterSummaries.keys, containsAll([0, 2]));

    await provider.setReadBoundaryChapter(0);

    expect(provider.isManualReadBoundary, isTrue);
    expect(provider.boundaryChapter, 0);
    expect(provider.coverage!.readChapters, 1);
    expect(provider.chapterSummaries.keys, contains(0));
    expect(provider.chapterSummaries.keys, isNot(contains(2)));

    await provider.followReadingProgress();

    expect(provider.isFollowingProgress, isTrue);
    expect(provider.boundaryChapter, 2);
    expect(provider.chapterSummaries.keys, contains(2));
  });

  test('generates synthesis overview and character relation graph', () async {
    await _seedSummary(
      summarySourceScopeCache,
      chapterIndex: 0,
      eventDescription: 'Arya finds a hidden path.',
      character: 'Arya Stark',
      change: 'Arya becomes more observant.',
    );
    await _seedSummary(
      summarySourceScopeCache,
      chapterIndex: 1,
      eventDescription: 'Sansa hears a secret.',
      character: 'Sansa Stark',
      change: 'Sansa becomes cautious.',
    );
    await provider.loadForBook(
      'book-1',
      totalChapters: 8,
      currentChapter: 2,
      bookTitle: 'Book One',
    );
    await provider.generateReadScopeSynthesis();

    final synthesis = provider.visibleSynthesis!;
    expect(synthesis.fullStoryline, '已读范围合成结果');
    expect(synthesis.keyInsights, contains('洞察一'));
    expect(
      synthesis.characterGraph.nodes.map((node) => node.label),
      containsAll(['Arya Stark', 'Sansa Stark']),
    );
    expect(synthesis.characterGraph.edges.single.relation, '同行');
  });

  test(
    'does not store synthesis when AI returns no visible storyline',
    () async {
      final emptySynthesisProvider = BookInsightProvider(
        cacheService: cacheService,
        bookInsightSourceScopeService: _FakeBookInsightSourceScopeService(
          _projectionWithAnalysis(),
        ),
        synthesisRunner: (_) async => BookSynthesisResult(
          fullStoryline: '   ',
          characterGraph: const CharacterRelationGraph(),
          bookMindMap: const MindMapGraph(
            root: MindMapNode(id: 'root', label: 'Book One'),
          ),
          generatedAt: DateTime.utc(2026, 6, 24),
        ),
      );
      addTearDown(emptySynthesisProvider.dispose);
      await emptySynthesisProvider.loadForBook(
        'book-1',
        totalChapters: 8,
        currentChapter: 2,
        bookTitle: 'Book One',
      );

      final generated = await emptySynthesisProvider
          .generateReadScopeSynthesis();

      expect(generated, isFalse);
      expect(emptySynthesisProvider.visibleSynthesis, isNull);
      expect(emptySynthesisProvider.error, 'AI 未返回可展示的当前范围梗概');
    },
  );

  testWidgets('read scope synthesis button updates visible storyline', (
    tester,
  ) async {
    final synthesisProvider = BookInsightProvider(
      cacheService: cacheService,
      bookInsightSourceScopeService: _FakeBookInsightSourceScopeService(
        _projectionWithAnalysis(),
      ),
      synthesisRunner: (_) async => BookSynthesisResult(
        fullStoryline: '已读范围合成结果',
        characterGraph: const CharacterRelationGraph(),
        bookMindMap: const MindMapGraph(
          root: MindMapNode(id: 'root', label: 'Book One'),
        ),
        generatedAt: DateTime.utc(2026, 6, 24),
      ),
    );
    addTearDown(synthesisProvider.dispose);
    await synthesisProvider.loadForBook(
      'book-1',
      totalChapters: 8,
      currentChapter: 2,
      bookTitle: 'Book One',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BookInsightsPage(
          provider: synthesisProvider,
          bookTitle: 'Book One',
          onGenerateChapter: (_) async =>
              const BookInsightChapterGenerationResult.generated(),
        ),
      ),
    );

    expect(find.text('还没有当前范围梗概'), findsOneWidget);

    await tester.tap(find.text('生成当前范围梗概'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('已读范围合成结果'), findsOneWidget);
    expect(find.text('还没有当前范围梗概'), findsNothing);
    expect(find.text('已生成当前范围梗概'), findsOneWidget);
  });

  testWidgets('read scope synthesis button reports empty AI result', (
    tester,
  ) async {
    final emptySynthesisProvider = BookInsightProvider(
      cacheService: cacheService,
      bookInsightSourceScopeService: _FakeBookInsightSourceScopeService(
        _projectionWithAnalysis(),
      ),
      synthesisRunner: (_) async => BookSynthesisResult(
        fullStoryline: '',
        characterGraph: const CharacterRelationGraph(),
        bookMindMap: const MindMapGraph(
          root: MindMapNode(id: 'root', label: 'Book One'),
        ),
        generatedAt: DateTime.utc(2026, 6, 24),
      ),
    );
    addTearDown(emptySynthesisProvider.dispose);
    await emptySynthesisProvider.loadForBook(
      'book-1',
      totalChapters: 8,
      currentChapter: 2,
      bookTitle: 'Book One',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BookInsightsPage(
          provider: emptySynthesisProvider,
          bookTitle: 'Book One',
          onGenerateChapter: (_) async =>
              const BookInsightChapterGenerationResult.generated(),
        ),
      ),
    );

    await tester.tap(find.text('生成当前范围梗概'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('还没有当前范围梗概'), findsOneWidget);
    expect(find.text('AI 未返回可展示的当前范围梗概'), findsOneWidget);
    expect(find.text('已生成当前范围梗概'), findsNothing);
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

AISummary _summaryWithEvent(String description) {
  return AISummary(
    events: [
      SummaryEvent(
        description: description,
        source: description,
        significance: 'Important for the current arc.',
        confidence: 'high',
      ),
    ],
    characterDevelopments: const [],
    keyVocabulary: const [],
    readingGuidance: 'Follow the current scene.',
  );
}

BookInsightSourceScopeProjection _projectionWithAnalysis() {
  return BookInsightSourceScopeProjection(
    bookId: 'book-1',
    sourceId: 'book:book-1',
    maxReadChapter: 0,
    chapterSummaries: {
      0: _summaryWithEvent('Arya finds a hidden path.'),
    },
    analysisData: BookAnalysisData(
      bookId: 'book-1',
      scope: AnalysisScope.readSoFar(
        bookId: 'book-1',
        currentChapterIndex: 0,
      ),
      storyEvents: [
        StoryEvent(
          description: 'Arya finds a hidden path.',
          chapterIndex: 0,
        ),
      ],
      coverage: 1,
      schemaVersion: '1.0.0',
      analyzedAt: DateTime.utc(2026, 6, 24),
    ),
    storyline: BookStoryline.empty('book-1'),
    characterCards: const [],
    characterRegistryEntries: const [],
    glossaryEntries: const [],
    coverage: const BookInsightCoverage(
      summarizedChapters: 1,
      totalChapters: 3,
      readChapters: 1,
      missingChapters: [],
    ),
  );
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

class _FakeBookInsightSourceScopeService extends BookInsightSourceScopeService {
  _FakeBookInsightSourceScopeService(this.projection);

  final BookInsightSourceScopeProjection projection;

  @override
  Future<BookInsightSourceScopeProjection> loadProjection({
    required String bookId,
    int? maxReadChapter,
    int? totalChapters,
    int? readChapters,
    String? bookTitle,
    String? author,
    String? languageCode,
    Iterable<int>? includedChapterIndexes,
    bool syncInspectableCaches = true,
  }) async {
    return projection;
  }
}

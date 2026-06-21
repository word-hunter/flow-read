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
    provider = BookInsightProvider(
      cacheService: cacheService,
      glossaryService: glossaryService,
      characterRegistry: CharacterRegistry(
        repository: DriftCharacterRegistryRepository(db.characterRegistryDao),
      ),
      chapterSummarySourceScopeCache: summarySourceScopeCache,
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
}

Future<void> _pumpTabTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

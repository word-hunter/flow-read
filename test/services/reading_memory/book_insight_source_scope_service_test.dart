import 'dart:convert';

import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/models/book_glossary_entry.dart';
import 'package:flow_read/models/reading_memory.dart';
import 'package:flow_read/services/book_glossary_service.dart';
import 'package:flow_read/services/character_registry.dart';
import 'package:flow_read/services/reading_memory/book_insight_source_scope_service.dart';
import 'package:flow_read/services/reading_memory/chapter_summary_source_scope_cache.dart';
import 'package:flow_read/services/reading_memory/source_scope_service.dart';
import 'package:flow_read/storage/database/app_database.dart'
    hide BookGlossaryEntry, CharacterRegistryEntry;
import 'package:flow_read/storage/database/dao/book_glossary_dao.dart';
import 'package:flow_read/storage/database/repositories/drift_character_registry_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_memory_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SourceScopeService sourceScope;
  late ChapterSummarySourceScopeCache chapterSummaryCache;
  late BookGlossaryService glossary;
  late CharacterRegistry registry;
  late BookInsightSourceScopeService service;

  setUp(() async {
    db = await AppDatabase.createInMemory();
    final repository = DriftReadingMemoryRepository(
      db.readingMemoryDao,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 23, 9),
    );
    sourceScope = SourceScopeService(
      repository: repository,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 23, 9),
    );
    await sourceScope.init();
    chapterSummaryCache = ChapterSummarySourceScopeCache(
      sourceScope: sourceScope,
    );
    glossary = BookGlossaryService(BookGlossaryDao(db));
    registry = CharacterRegistry(
      repository: DriftCharacterRegistryRepository(db.characterRegistryDao),
    );
    await registry.init();
    service = BookInsightSourceScopeService(
      chapterSummarySourceScopeCache: chapterSummaryCache,
      glossaryService: glossary,
      characterRegistry: registry,
      sourceScope: sourceScope,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('builds a spoiler-safe book source projection', () async {
    await _seedBookInsightData(
      chapterSummaryCache: chapterSummaryCache,
      glossary: glossary,
      registry: registry,
    );

    final projection = await service.loadProjection(
      bookId: 'book-1',
      maxReadChapter: 1,
      totalChapters: 4,
      readChapters: 2,
      bookTitle: 'Book One',
      author: 'Author One',
      languageCode: 'en',
    );

    expect(projection.sourceId, 'book:book-1');
    expect(projection.chapterSummaries.keys, [0]);
    expect(
      projection.storyline.events.map((event) => event.description),
      ['Ned finds a direwolf near Winterfell.'],
    );
    expect(
      projection.characterRegistryEntries.map((entry) => entry.canonicalName),
      ['Eddard Stark'],
    );
    expect(projection.glossaryEntries.map((entry) => entry.word), ['direwolf']);

    final context = projection.contextBundleFor(
      selectedText: 'Ned watched the direwolf in Winterfell.',
      chapterIndex: 1,
    );
    expect(
      context.relatedEvents.map((event) => event.description),
      contains('Ned finds a direwolf near Winterfell.'),
    );
    expect(context.mentionedCharacters.map((character) => character.name), [
      'Eddard Stark',
    ]);
    expect(context.bookTerms.map((term) => term.word), ['direwolf']);
    expect(context.formatForPrompt(), isNot(contains('future betrayal')));
    expect(context.formatForPrompt(), isNot(contains('Future Person')));
  });

  test('syncs source-scoped inspector caches for terms and people', () async {
    await _seedBookInsightData(
      chapterSummaryCache: chapterSummaryCache,
      glossary: glossary,
      registry: registry,
    );

    await service.loadProjection(
      bookId: 'book-1',
      maxReadChapter: 1,
      bookTitle: 'Book One',
    );

    final caches = await sourceScope.sourceScopeCacheForSource(
      'book:book-1',
      limit: 20,
    );
    final cacheTypes = caches.map((cache) => cache.cacheType).toSet();
    expect(cacheTypes, contains(SourceScopeCacheTypes.chapterSummary));
    expect(cacheTypes, contains(SourceScopeCacheTypes.storylineContext));
    expect(cacheTypes, contains(SourceScopeCacheTypes.characterRegistry));
    expect(cacheTypes, contains(SourceScopeCacheTypes.termIndex));

    final storylinePayload = _payloadFor(
      caches,
      SourceScopeCacheTypes.storylineContext,
    );
    expect(
      storylinePayload['sourceScopedDataKinds'],
      contains(BookInsightSourceScopeDataKinds.places),
    );
    expect(jsonEncode(storylinePayload), isNot(contains('future betrayal')));

    final peoplePayload = _payloadFor(
      caches,
      SourceScopeCacheTypes.characterRegistry,
    );
    expect(jsonEncode(peoplePayload), contains('Eddard Stark'));
    expect(jsonEncode(peoplePayload), isNot(contains('Future Person')));

    final termPayload = _payloadFor(caches, SourceScopeCacheTypes.termIndex);
    expect(jsonEncode(termPayload), contains('direwolf'));
    expect(jsonEncode(termPayload), isNot(contains('elsewhere')));
  });

  test(
    'deletes book-scoped insight data without touching other books',
    () async {
      await _seedBookInsightData(
        chapterSummaryCache: chapterSummaryCache,
        glossary: glossary,
        registry: registry,
      );
      await service.loadProjection(
        bookId: 'book-1',
        maxReadChapter: 1,
        bookTitle: 'Book One',
      );

      await service.deleteBookInsight('book-1');

      expect(await glossary.getBookGlossary('book-1'), isEmpty);
      expect(await glossary.getBookGlossary('other-book'), hasLength(1));
      expect(registry.getAll('book-1'), isEmpty);
      expect(registry.getAll('other-book'), hasLength(1));
      expect(
        await sourceScope.sourceScopeCacheForSource('book:book-1'),
        isEmpty,
      );
    },
  );
}

Future<void> _seedBookInsightData({
  required ChapterSummarySourceScopeCache chapterSummaryCache,
  required BookGlossaryService glossary,
  required CharacterRegistry registry,
}) async {
  await chapterSummaryCache.saveChapterSummary(
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
      characterDevelopments: [
        CharacterDevelopment(
          character: 'Eddard Stark',
          change: 'Ned handles the discovery with caution.',
          source: 'Ned knelt beside the direwolf.',
          confidence: 'high',
        ),
      ],
      keyVocabulary: [],
      readingGuidance: 'Watch the house symbols.',
    ),
  );
  await chapterSummaryCache.saveChapterSummary(
    bookId: 'book-1',
    bookTitle: 'Book One',
    chapterIndex: 3,
    outputLanguage: 'zh',
    summary: const AISummary(
      events: [
        SummaryEvent(
          description: 'The direwolf later reveals a future betrayal.',
          source: 'Future chapter.',
          significance: 'This would spoil a later twist.',
          confidence: 'high',
        ),
      ],
      characterDevelopments: [
        CharacterDevelopment(
          character: 'Future Person',
          change: 'Future Person exposes the betrayal.',
          source: 'Future chapter.',
          confidence: 'high',
        ),
      ],
      keyVocabulary: [],
      readingGuidance: '',
    ),
  );
  await glossary.saveEntry(
    BookGlossaryEntry.create(
      bookId: 'book-1',
      word: 'direwolf',
      explanation: 'A large wolf tied to the northern family emblem.',
      createdAt: DateTime.utc(2026, 6, 23),
    ),
  );
  await glossary.saveEntry(
    BookGlossaryEntry.create(
      bookId: 'other-book',
      word: 'elsewhere',
      explanation: 'Different book.',
      createdAt: DateTime.utc(2026, 6, 23),
    ),
  );
  await registry.addEntry(
    'book-1',
    CharacterRegistryEntry(
      canonicalName: 'Eddard Stark',
      aliases: const {'Ned'},
      firstAppearanceChapter: 0,
      updatedAt: DateTime.utc(2026, 6, 23),
    ),
  );
  await registry.addEntry(
    'book-1',
    CharacterRegistryEntry(
      canonicalName: 'Future Person',
      firstAppearanceChapter: 3,
      updatedAt: DateTime.utc(2026, 6, 23),
    ),
  );
  await registry.addEntry(
    'other-book',
    CharacterRegistryEntry(
      canonicalName: 'Other Person',
      updatedAt: DateTime.utc(2026, 6, 23),
    ),
  );
}

Map<String, Object?> _payloadFor(
  List<SourceScopeCacheItem> caches,
  String cacheType,
) {
  final cache = caches.where((item) => item.cacheType == cacheType).single;
  return Map<String, Object?>.from(jsonDecode(cache.payload) as Map);
}

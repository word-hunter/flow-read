import 'dart:convert';
import 'dart:io';

import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/models/book_glossary_entry.dart';
import 'package:flow_read/models/reading_memory.dart';
import 'package:flow_read/services/book_glossary_service.dart';
import 'package:flow_read/services/character_registry.dart';
import 'package:flow_read/services/reading_memory/context_retrieval_service.dart';
import 'package:flow_read/services/reading_memory/reading_memory_service.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/storage/database/app_database.dart'
    hide BookGlossaryEntry, CharacterRegistryEntry;
import 'package:flow_read/storage/database/dao/book_glossary_dao.dart';
import 'package:flow_read/storage/database/repositories/drift_character_registry_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_memory_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_user_vocabulary_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'flow_read_context_retrieval_test_',
    );
    db = await AppDatabase.createInMemory();
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('builds MVP learning memory context for word analysis', () async {
    final memoryRepository = DriftReadingMemoryRepository(
      db.readingMemoryDao,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 15, 9),
    );
    var tick = 0;
    DateTime nextTime() {
      return DateTime.utc(2026, 6, 15, 8).add(Duration(minutes: tick++));
    }

    final memory = ReadingMemoryService(
      repository: memoryRepository,
      languageCode: 'en',
      clock: nextTime,
    );
    await memory.init();
    final userVocabulary = UserVocabularyService(
      repository: DriftUserVocabularyRepository(
        db.userVocabularyDao,
        languageCode: 'en',
      ),
      languageCode: 'en',
    );
    await userVocabulary.init();

    await userVocabulary.setKnown('admit');
    await userVocabulary.setLearning('reluctant');
    const sourceRef = MemorySourceRef(
      sourceId: 'book:book-1',
      sourceKind: SourceKind.book,
      sourceTitleSnapshot: 'Book One',
      bookId: 'book-1',
      chapterIndex: 2,
    );
    await memory.recordLookup(
      targetText: 'Reluctant',
      canonical: 'reluctant',
      sourceRef: sourceRef,
      sentence: 'He was reluctant to admit defeat.',
    );
    await memory.recordLookup(
      targetText: 'reluctant',
      canonical: 'reluctant',
      sourceRef: sourceRef,
      sentence: 'She was reluctant to answer.',
    );
    await memory.saveExplanation(
      targetText: 'reluctant',
      explanation: 'reluctant to do means unwilling to do something.',
      sourceRef: sourceRef,
      promptVersion: 'assistant-word-analysis-v1',
    );

    final service = ContextRetrievalService(
      repository: memoryRepository,
      userVocabulary: userVocabulary,
      languageCode: 'en',
    );

    final bundle = await service.buildForContext(
      AIContextSnapshot(
        source: AIContextSource.readerWord,
        word: 'Reluctant',
        wordSentence: 'He was reluctant to admit defeat.',
        surroundingPassage: 'He was reluctant to admit defeat.',
      ),
    );

    expect(bundle.knownWords, ['admit']);
    expect(bundle.learningWords, ['reluctant']);
    expect(bundle.repeatedLookupWords, ['reluctant']);
    expect(bundle.savedExplanations.single, contains('reluctant to do'));
    expect(bundle.formatForPrompt(), contains('Personal learning memory'));
  });

  test(
    'enriches selected text context with saved sentence explanation',
    () async {
      final memoryRepository = DriftReadingMemoryRepository(
        db.readingMemoryDao,
        languageCode: 'en',
        clock: () => DateTime.utc(2026, 6, 15, 9),
      );
      final memory = ReadingMemoryService(
        repository: memoryRepository,
        languageCode: 'en',
        clock: () => DateTime.utc(2026, 6, 15, 8),
      );
      await memory.init();
      final userVocabulary = UserVocabularyService(
        repository: DriftUserVocabularyRepository(
          db.userVocabularyDao,
          languageCode: 'en',
        ),
        languageCode: 'en',
      );
      await userVocabulary.init();

      await memory.saveExplanation(
        targetText: 'The door opened slowly.',
        canonical: 'The door opened slowly.',
        explanation: 'slowly highlights the suspense of the action.',
        type: KnowledgeEntityType.sentence,
        promptVersion: 'assistant-text-analysis-v1',
      );

      final service = ContextRetrievalService(
        repository: memoryRepository,
        userVocabulary: userVocabulary,
        languageCode: 'en',
      );

      final enriched = await service.enrichContext(
        AIContextSnapshot(
          source: AIContextSource.readerSelectedText,
          selectedText: 'The door opened slowly.',
          surroundingPassage: 'The door opened slowly.',
        ),
        AIAssistantActionType.explain,
      );

      expect(enriched.contextBundle, isNotNull);
      expect(
        enriched.contextBundle!.savedExplanations.single,
        contains('slowly highlights'),
      );
    },
  );

  test(
    'adds spoiler-safe book insight context from summaries and registry',
    () async {
      final memoryRepository = DriftReadingMemoryRepository(
        db.readingMemoryDao,
        languageCode: 'en',
      );
      final userVocabulary = UserVocabularyService(
        repository: DriftUserVocabularyRepository(
          db.userVocabularyDao,
          languageCode: 'en',
        ),
        languageCode: 'en',
      );
      await userVocabulary.init();

      final cache = AICacheService(
        documentsDirectoryProvider: () async => tempDir,
      );
      await cache.init();
      await cache.saveSummary(
        'book-1',
        0,
        'zh',
        jsonEncode(
          const AISummary(
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
            readingGuidance: '',
          ).toJson(),
        ),
      );
      await cache.saveSummary(
        'book-1',
        3,
        'zh',
        jsonEncode(
          const AISummary(
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
          ).toJson(),
        ),
      );

      final glossary = BookGlossaryService(BookGlossaryDao(db));
      await glossary.saveEntry(
        BookGlossaryEntry.create(
          bookId: 'book-1',
          word: 'direwolf',
          explanation: 'A large wolf tied to the northern family emblem.',
          createdAt: DateTime.utc(2026, 6, 15),
        ),
      );

      final characterWriter = CharacterRegistry(
        repository: DriftCharacterRegistryRepository(db.characterRegistryDao),
      );
      await characterWriter.init();
      await characterWriter.addEntry(
        'book-1',
        CharacterRegistryEntry(
          canonicalName: 'Eddard Stark',
          aliases: const {'Ned'},
          firstAppearanceChapter: 0,
          updatedAt: DateTime.utc(2026, 6, 15),
        ),
      );
      await characterWriter.addEntry(
        'book-1',
        CharacterRegistryEntry(
          canonicalName: 'Future Person',
          aliases: const {'Future Person'},
          firstAppearanceChapter: 3,
          updatedAt: DateTime.utc(2026, 6, 15),
        ),
      );

      final service = ContextRetrievalService(
        repository: memoryRepository,
        userVocabulary: userVocabulary,
        cacheService: cache,
        glossaryService: glossary,
        characterRegistry: CharacterRegistry(
          repository: DriftCharacterRegistryRepository(db.characterRegistryDao),
        ),
        languageCode: 'en',
      );

      final bundle = await service.buildForContext(
        AIContextSnapshot(
          source: AIContextSource.readerSelectedText,
          bookId: 'book-1',
          chapterIndex: 1,
          selectedText: 'Ned looked at the direwolf near Winterfell.',
          surroundingPassage: 'Ned looked at the direwolf near Winterfell.',
          spoilerBoundary: SpoilerBoundary.chapter(
            bookId: 'book-1',
            chapterIndex: 1,
            scope: AIContextScope.readSoFar,
          ),
        ),
      );

      expect(
        bundle.relatedEvents.map((event) => event.description),
        contains('Ned finds a direwolf near Winterfell.'),
      );
      expect(
        bundle.relatedEvents.map((event) => event.description).join('\n'),
        isNot(contains('future betrayal')),
      );
      expect(bundle.mentionedCharacters.map((character) => character.name), [
        'Eddard Stark',
      ]);
      expect(
        bundle.mentionedCharacters.single.developments,
        contains('Aliases: Ned'),
      );
      expect(bundle.bookTerms.map((term) => term.word), ['direwolf']);

      final formatted = bundle.formatForPrompt();
      expect(formatted, contains('Related story events from earlier chapters'));
      expect(formatted, contains('Characters mentioned in the current text'));
      expect(formatted, contains('Book-specific terms in the current text'));
      expect(formatted, isNot(contains('Future Person')));
      expect(formatted, isNot(contains('later twist')));
    },
  );
}

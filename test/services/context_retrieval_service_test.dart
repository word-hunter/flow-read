import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/models/reading_memory.dart';
import 'package:flow_read/services/reading_memory/context_retrieval_service.dart';
import 'package:flow_read/services/reading_memory/reading_memory_service.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_memory_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_user_vocabulary_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.createInMemory();
  });

  tearDown(() async {
    await db.close();
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
}

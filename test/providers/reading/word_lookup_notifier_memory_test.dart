import 'package:flow_dictionary/flow_dictionary.dart';
import 'package:flow_read/models/book.dart';
import 'package:flow_read/models/chapter.dart';
import 'package:flow_read/models/reading_memory.dart';
import 'package:flow_read/providers/reading/bookshelf_notifier.dart';
import 'package:flow_read/providers/reading/current_book_notifier.dart';
import 'package:flow_read/providers/reading/services_provider.dart';
import 'package:flow_read/providers/reading/word_lookup_notifier.dart';
import 'package:flow_read/providers/settings_provider.dart';
import 'package:flow_read/services/learning_analytics_service.dart';
import 'package:flow_read/services/reading_memory/reading_memory_ids.dart';
import 'package:flow_read/services/reading_memory/reading_memory_service.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/services/word_context_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_learning_analytics_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_memory_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_word_context_repository.dart';
import 'package:flow_language/english/english.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_word_level_service.dart';

void main() {
  late AppDatabase db;
  late DriftReadingMemoryRepository memoryRepository;
  late ProviderContainer container;

  setUp(() async {
    db = await AppDatabase.createInMemory();
    final settings = SettingsService(db.settingsDao);
    await settings.init();
    memoryRepository = DriftReadingMemoryRepository(
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
    final analytics = LearningAnalyticsService(
      repository: DriftLearningAnalyticsRepository(
        db.learningAnalyticsDao,
        languageCode: 'en',
      ),
      languageModule: const EnglishLanguageModule(),
    );
    await analytics.init();
    final wordContext = WordContextService(
      repository: DriftWordContextRepository(
        db.wordContextDao,
        languageCode: 'en',
      ),
    );
    await wordContext.init();

    container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith((ref) => settings),
        appDatabaseProvider.overrideWith((ref) async => db),
        wordRepositoryProvider.overrideWithValue(_MemoryWordRepository()),
        readingMemoryServiceProvider.overrideWithValue(memory),
        learningAnalyticsServiceProvider.overrideWithValue(analytics),
        wordContextServiceProvider.overrideWithValue(wordContext),
        wordLevelServiceProvider.overrideWithValue(fakeWordLevelService()),
        bookshelfNotifierProvider.overrideWith(
          () => _ReaderBookshelfNotifier(_book()),
        ),
        currentBookNotifierProvider.overrideWith(
          () => _ReaderCurrentBookNotifier(),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  tearDown(() async {
    await db.close();
  });

  test('reader lookup records reading memory source evidence', () async {
    await container
        .read(wordLookupNotifierProvider.notifier)
        .lookupWord(
          'Reluctant',
          canonicalForm: 'reluctant',
          languageCode: 'en',
          contextText: 'He was reluctant to admit defeat.',
          contextWordStart: 7,
          contextWordEnd: 16,
          trackReadingLookup: true,
        );

    final events = await memoryRepository.eventsForCanonical(
      languageCode: 'en',
      canonicalKey: 'reluctant',
    );
    expect(events.single.type, MemoryEventType.lookup);
    expect(events.single.sourceId, 'book:book-1');

    final entity = await memoryRepository.entityByCanonical(
      languageCode: 'en',
      type: KnowledgeEntityType.word,
      canonicalKey: 'reluctant',
    );
    expect(entity, isNotNull);

    final evidences = await memoryRepository.evidencesForEntity(entity!.id);
    expect(evidences.single.sourceKind, SourceKind.book);
    expect(evidences.single.sourceTitleSnapshot, 'Fixture Book');
    expect(evidences.single.bookId, 'book-1');
    expect(evidences.single.chapterIndex, 2);
    expect(evidences.single.locationLocator, 'chapter:2:word:7-16');
    expect(evidences.single.shortExcerpt, contains('admit defeat'));

    final source = await memoryRepository.sourceRecord('book:book-1');
    expect(source?.titleSnapshot, 'Fixture Book');

    final analytics = container.read(learningAnalyticsServiceProvider);
    expect(analytics.lookupCountForChapter('book-1', 2), 1);
  });

  test('explicit lookup source records non-book memory evidence', () async {
    await container
        .read(wordLookupNotifierProvider.notifier)
        .lookupWord(
          'Scrutiny',
          canonicalForm: 'scrutiny',
          languageCode: 'en',
          contextText: 'The policy drew regulatory scrutiny.',
          memorySourceRef: MemorySourceRef(
            sourceId: ReadingMemoryIds.source(
              SourceKind.browser,
              'https://example.com/article',
            ),
            sourceKind: SourceKind.browser,
            sourceTitleSnapshot: 'Policy Article',
            locationLocator: 'https://example.com/article',
          ),
        );

    final entity = await memoryRepository.entityByCanonical(
      languageCode: 'en',
      type: KnowledgeEntityType.word,
      canonicalKey: 'scrutiny',
    );
    expect(entity, isNotNull);

    final evidences = await memoryRepository.evidencesForEntity(entity!.id);
    expect(evidences.single.sourceKind, SourceKind.browser);
    expect(evidences.single.sourceTitleSnapshot, 'Policy Article');
    expect(evidences.single.bookId, isNull);
    expect(evidences.single.shortExcerpt, contains('regulatory scrutiny'));
  });

  test('lookup without dictionary entry clears previous source link', () async {
    final lookup = container.read(wordLookupNotifierProvider.notifier);

    await lookup.lookupWord('Alpha', canonicalForm: 'alpha');
    expect(container.read(wordLookupNotifierProvider).selectedWord, 'Alpha');
    expect(
      container.read(wordLookupNotifierProvider).selectedWordEntry?.sourceUrl,
      'https://dictionary.example/alpha',
    );

    await lookup.lookupWord('Beta', canonicalForm: 'beta');

    final state = container.read(wordLookupNotifierProvider);
    expect(state.selectedWord, 'Beta');
    expect(state.selectedWordEntry, isNull);
    expect(state.selectedWordTranslation, isNull);
    expect(state.selectedWordLookupResult?.request.query, 'beta');
  });
}

class _MemoryWordRepository implements WordRepository {
  @override
  Future<DictionaryEntry?> lookup(
    String word, {
    String languageCode = 'en',
  }) async {
    if (word.toLowerCase().trim() == 'beta') return null;

    return DictionaryEntry(
      word: word,
      meanings: [
        Meaning(partOfSpeech: 'n.', definitions: ['definition for $word']),
      ],
      sourceName: 'Test',
      sourceUrl: 'https://dictionary.example/$word',
    );
  }
}

class _ReaderBookshelfNotifier extends BookshelfNotifier {
  _ReaderBookshelfNotifier(this._book);

  final Book _book;

  @override
  BookshelfState build() {
    return BookshelfState(activeBookId: 'book-1', book: _book);
  }
}

class _ReaderCurrentBookNotifier extends CurrentBookNotifier {
  @override
  CurrentBookState build() {
    return const CurrentBookState(currentChapter: 2);
  }
}

Book _book() {
  return const Book(
    title: 'Fixture Book',
    author: 'Author',
    language: 'en',
    chapters: [
      Chapter(title: 'One', plainText: 'One', rawHtml: ''),
      Chapter(title: 'Two', plainText: 'Two', rawHtml: ''),
      Chapter(
        title: 'Three',
        plainText: 'He was reluctant to admit defeat.',
        rawHtml: '',
      ),
    ],
  );
}

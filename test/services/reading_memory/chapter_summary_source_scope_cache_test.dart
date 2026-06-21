import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/services/reading_memory/chapter_summary_source_scope_cache.dart';
import 'package:flow_read/services/reading_memory/source_scope_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_memory_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftReadingMemoryRepository repository;
  late SourceScopeService sourceScope;
  late ChapterSummarySourceScopeCache cache;

  setUp(() async {
    db = await AppDatabase.createInMemory();
    repository = DriftReadingMemoryRepository(
      db.readingMemoryDao,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 21, 9),
    );
    sourceScope = SourceScopeService(
      repository: repository,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 21, 9),
    );
    cache = ChapterSummarySourceScopeCache(sourceScope: sourceScope);
    await sourceScope.init();
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'writes, reads, and clears chapter summaries with source lifecycle',
    () async {
      const summary = AISummary(
        events: [
          SummaryEvent(
            description: 'Ned finds a direwolf near Winterfell.',
            source: 'The direwolf lay in the snow.',
            significance: 'The discovery links the children to the North.',
            confidence: 'high',
          ),
        ],
        characterDevelopments: [],
        keyVocabulary: [],
        readingGuidance: 'Pay attention to the house symbols.',
      );

      await cache.saveChapterSummary(
        bookId: 'book-1',
        bookTitle: 'Book One',
        author: 'Author One',
        chapterIndex: 0,
        summary: summary,
        outputLanguage: 'zh',
      );

      final entries = await cache.loadBookSummaries('book-1');
      expect(entries, hasLength(1));
      expect(entries.single.chapterIndex, 0);
      expect(entries.single.summary.readingGuidance, summary.readingGuidance);
      expect(entries.single.summary.events.single.description, contains('Ned'));

      final source = await repository.sourceRecord('book:book-1');
      expect(source, isNotNull);
      expect(source!.titleSnapshot, 'Book One');

      final rawCaches = await repository.sourceScopeCacheForSource(
        'book:book-1',
        cacheType: SourceScopeCacheTypes.chapterSummary,
      );
      expect(rawCaches, hasLength(1));
      expect(rawCaches.single.retentionPolicy.storageValue, 'deleteWithSource');

      await sourceScope.deleteBookSourceKeepLearningMemory('book-1');

      expect(await cache.loadBookSummaries('book-1'), isEmpty);
      expect(
        await repository.sourceScopeCacheForSource('book:book-1'),
        isEmpty,
      );
    },
  );
}

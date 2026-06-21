import 'package:flow_language/english/english.dart';
import 'package:flow_read/models/book_glossary_entry.dart' as model;
import 'package:flow_read/models/reading_memory.dart';
import 'package:flow_read/models/reading_memory_overlay.dart';
import 'package:flow_read/services/book_glossary_service.dart';
import 'package:flow_read/services/reading_memory/reading_memory_ids.dart';
import 'package:flow_read/services/reading_memory/reading_memory_overlay_service.dart';
import 'package:flow_read/services/reading_memory/reading_memory_service.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/dao/book_glossary_dao.dart';
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

  test('builds reading overlay markers from memory signals', () async {
    final memoryRepository = DriftReadingMemoryRepository(
      db.readingMemoryDao,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 21, 9),
    );
    final vocabulary = UserVocabularyService(
      repository: DriftUserVocabularyRepository(
        db.userVocabularyDao,
        languageCode: 'en',
      ),
      languageCode: 'en',
    );
    await vocabulary.init();
    await vocabulary.setLearning('ember');

    final memory = ReadingMemoryService(
      repository: memoryRepository,
      languageCode: 'en',
      clock: () => DateTime.utc(2026, 6, 21, 9),
    );
    await memory.recordLookup(targetText: 'river', canonical: 'river');
    await memory.recordLookup(targetText: 'river', canonical: 'river');

    final reviewEntity = MemoryKnowledgeEntity(
      id: ReadingMemoryIds.entity(
        languageCode: 'en',
        type: KnowledgeEntityType.word,
        canonicalKey: 'reviewable',
      ),
      languageCode: 'en',
      type: KnowledgeEntityType.word,
      canonicalKey: 'reviewable',
      displayText: 'reviewable',
      normalizedText: 'reviewable',
      createdAt: DateTime.utc(2026, 6, 21, 9),
      updatedAt: DateTime.utc(2026, 6, 21, 9),
    );
    await memoryRepository.upsertEntity(reviewEntity);
    await memoryRepository.upsertReviewCandidate(
      ReviewCandidate(
        id: 'candidate:reviewable',
        entityId: reviewEntity.id,
        entityType: KnowledgeEntityType.word,
        targetText: 'reviewable',
        priority: 0.8,
        status: ReviewCandidateStatus.pending,
        createdAt: DateTime.utc(2026, 6, 21, 9),
        updatedAt: DateTime.utc(2026, 6, 21, 9),
      ),
    );

    final glossary = BookGlossaryService(BookGlossaryDao(db));
    await glossary.saveEntry(
      model.BookGlossaryEntry.create(
        bookId: 'book-1',
        word: 'lumen',
        explanation: 'A story-specific light unit.',
        sourceContext: 'The lumen faded.',
        createdAt: DateTime.utc(2026, 6, 21, 9),
      ),
    );

    final service = ReadingMemoryOverlayService(
      repository: memoryRepository,
      userVocabulary: vocabulary,
      glossaryService: glossary,
      languageCode: 'en',
    );
    final projection = await service.buildForText(
      text: 'The ember crossed the river with a reviewable lumen.',
      bookId: 'book-1',
      languageModule: const EnglishLanguageModule(),
    );

    expect(
      projection.markerFor('ember')?.types,
      contains(ReadingMemoryOverlayMarkerType.learning),
    );
    expect(
      projection.markerFor('river')?.types,
      contains(ReadingMemoryOverlayMarkerType.repeatedLookup),
    );
    expect(
      projection.markerFor('reviewable')?.types,
      contains(ReadingMemoryOverlayMarkerType.reviewDue),
    );
    expect(
      projection.markerFor('lumen')?.types,
      contains(ReadingMemoryOverlayMarkerType.bookTerm),
    );
    expect(projection.markerFor('absent'), isNull);
  });

  test('empty text produces an empty overlay', () async {
    final memoryRepository = DriftReadingMemoryRepository(
      db.readingMemoryDao,
      languageCode: 'en',
    );
    final vocabulary = UserVocabularyService(
      repository: DriftUserVocabularyRepository(
        db.userVocabularyDao,
        languageCode: 'en',
      ),
      languageCode: 'en',
    );
    final service = ReadingMemoryOverlayService(
      repository: memoryRepository,
      userVocabulary: vocabulary,
      languageCode: 'en',
    );

    final projection = await service.buildForText(text: '');

    expect(projection.isEmpty, isTrue);
  });
}

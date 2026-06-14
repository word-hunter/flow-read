import 'package:flow_language/english/english.dart';
import 'package:flow_read/models/learning_item.dart';
import 'package:flow_read/models/user_vocabulary.dart';
import 'package:flow_read/services/learning_analytics_service.dart';
import 'package:flow_read/services/learning_item_service.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_learning_analytics_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_learning_item_repository.dart';
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

  test(
    'user vocabulary serves bootstrapped values and persists status',
    () async {
      final service = UserVocabularyService(
        repository: DriftUserVocabularyRepository(
          db.userVocabularyDao,
          languageCode: 'en',
          initialValues: const {'flow': UserWordStatus.known},
        ),
        languageCode: 'en',
      );

      expect(service.isKnown('Flow'), isTrue);

      await service.setLearning('Current');
      expect(service.isLearning('current'), isTrue);

      final reloaded = UserVocabularyService(
        repository: DriftUserVocabularyRepository(
          db.userVocabularyDao,
          languageCode: 'en',
        ),
        languageCode: 'en',
      );
      await reloaded.init();

      expect(reloaded.isKnown('flow'), isFalse);
      expect(reloaded.isLearning('current'), isTrue);
      expect(reloaded.learningWords, contains('current'));
    },
  );

  test(
    'learning items serve bootstrapped values and persist updates',
    () async {
      final initial = _item(id: 'boot', title: 'Bootstrapped');
      final service = LearningItemService(
        repository: DriftLearningItemRepository(
          db.learningItemDao,
          languageCode: 'en',
          initialValues: [initial],
        ),
        clock: () => DateTime.utc(2026, 6, 13, 8),
      );

      expect(service.count, 1);
      expect(service.getById('boot')?.title, 'Bootstrapped');

      final result = await service.saveDraft(
        LearningItemDraft.word(
          word: 'Flow',
          definition: 'movement',
          context: 'A steady flow of ideas.',
          source: LearningItemSource(
            bookId: 'book-1',
            chapterIndex: 2,
            chapterTitle: 'Chapter 3',
          ),
        ),
      );

      expect(result.created, isTrue);
      expect(service.count, 2);

      final reloaded = LearningItemService(
        repository: DriftLearningItemRepository(
          db.learningItemDao,
          languageCode: 'en',
        ),
      );
      await reloaded.init();

      expect(reloaded.count, 1);
      expect(reloaded.allItems.single.canonicalKey, 'flow');
      expect(reloaded.allItems.single.tags, ['lookup']);
    },
  );

  test(
    'learning analytics serves bootstrapped counts and persists increments',
    () async {
      final service = LearningAnalyticsService(
        repository: DriftLearningAnalyticsRepository(
          db.learningAnalyticsDao,
          languageCode: 'en',
          initialValues: const {'lookup.day.2026-06-13': 2},
        ),
        clock: () => DateTime.utc(2026, 6, 13, 8),
        languageModule: const EnglishLanguageModule(),
      );

      expect(service.lookupCountForChapter('book-1', 0), 0);
      expect(
        service
            .buildWeeklySummary(
              readingTime: null,
              dailyGoalSeconds: 0,
              learningItems: const [],
              dueReviewCount: 0,
              now: DateTime.utc(2026, 6, 13, 8),
            )
            .lookupCount,
        2,
      );

      await service.recordLookup(
        bookId: 'book-1',
        chapterIndex: 0,
        word: 'Flow',
        at: DateTime.utc(2026, 6, 13, 9),
      );
      expect(service.lookupCountForChapter('book-1', 0), 1);

      final reloaded = LearningAnalyticsService(
        repository: DriftLearningAnalyticsRepository(
          db.learningAnalyticsDao,
          languageCode: 'en',
        ),
        languageModule: const EnglishLanguageModule(),
      );
      await reloaded.init();

      expect(reloaded.lookupCountForChapter('book-1', 0), 1);
    },
  );
}

LearningItem _item({
  required String id,
  required String title,
}) {
  final now = DateTime.utc(2026, 6, 13, 7);
  return LearningItem(
    id: id,
    type: LearningItemType.word,
    canonicalKey: id,
    title: title,
    content: title,
    answer: 'meaning',
    note: '',
    sourceText: 'source',
    bookId: 'book-1',
    chapterIndex: 0,
    chapterTitle: 'Chapter',
    createdAt: now,
    updatedAt: now,
  );
}

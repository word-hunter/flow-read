import 'package:flow_read/models/book_difficulty.dart';
import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_book_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.createInMemory();
  });

  tearDown(() async {
    await db.close();
  });

  test('serves bootstrapped values before async init', () {
    final repo = DriftBookRepository(
      db.bookDao,
      languageCode: 'en',
      initialValues: [
        _book(id: 'book-1', title: 'Bootstrapped'),
      ],
    );

    expect(repo.values.single.title, 'Bootstrapped');
    expect(repo.get('book-1')?.title, 'Bootstrapped');
  });

  test('persists and reloads book metadata from Drift', () async {
    final repo = DriftBookRepository(db.bookDao, languageCode: 'en');
    await repo.init();

    await repo.put(
      'book-1',
      _book(
        id: 'book-1',
        title: 'Flow',
        lastReadAt: DateTime.utc(2026, 6, 12, 8),
        difficultyRatingJson: const BookDifficultyRating(
          studyWordCount: 3,
          masteredWordCount: 1,
          userKnownWordCount: 10,
          learningWordCount: 2,
          newWordCount: 3,
          weightedNewWordCount: 4,
          newWordToKnownRatio: 0.3,
          score: 52,
          level: BookDifficultyLevel.l4,
        ).toJson(),
      ),
    );

    expect(repo.get('book-1')?.title, 'Flow');

    final reloaded = DriftBookRepository(db.bookDao, languageCode: 'en');
    await reloaded.init();
    final book = reloaded.get('book-1')!;

    expect(book.title, 'Flow');
    expect(book.lastReadAt, DateTime.utc(2026, 6, 12, 8));
    expect(book.difficultyRating?.level, BookDifficultyLevel.l4);
    expect(book.sourceLanguage, 'en');

    await reloaded.delete('book-1');

    final afterDelete = DriftBookRepository(db.bookDao, languageCode: 'en');
    await afterDelete.init();
    expect(afterDelete.values, isEmpty);
  });
}

BookMetadata _book({
  required String id,
  required String title,
  DateTime? lastReadAt,
  Map<String, dynamic>? difficultyRatingJson,
}) {
  return BookMetadata(
    id: id,
    title: title,
    author: 'Author',
    sourcePath: '/tmp/$id.epub',
    totalChapters: 4,
    currentChapter: 1,
    chapterProgress: 0.25,
    globalProgress: 0.3,
    lastReadAt: lastReadAt,
    difficultyStudyWords: const ['flow', 'read'],
    difficultyRatingJson: difficultyRatingJson,
    difficultyVocabularySignature: 'sig',
    difficultyComputedAt: DateTime.utc(2026, 6, 12, 7),
    chapterScrollOffset: 120,
    sourceLanguage: 'en',
    languageConfidence: 0.95,
    targetExplanationLanguage: 'zh',
  );
}

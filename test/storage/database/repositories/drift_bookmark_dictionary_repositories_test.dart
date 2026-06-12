import 'package:flow_dictionary/flow_dictionary.dart';
import 'package:flow_read/models/bookmarked_word.dart';
import 'package:flow_read/models/reading_bookmark.dart';
import 'package:flow_read/services/bookmark_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_bookmark_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_dictionary_cache_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.createInMemory();
  });

  tearDown(() async {
    await db.close();
  });

  test('bookmarks serve bootstrapped values and persist replacements', () async {
    final service = BookmarkService(
      repository: DriftBookmarkRepository(
        db.bookmarkDao,
        languageCode: 'en',
        initialWordBookmarks: const {
          'book-1':
              '[{"word":"boot","translation":"启动","context":"boot context","addedAt":"2026-06-13T08:00:00.000Z","bookId":"book-1"}]',
        },
      ),
    );

    expect(service.loadWordBookmarks('book-1').single.word, 'boot');

    await service.saveWordBookmarks('book-1', [
      BookmarkedWord(
        word: 'current',
        translation: '当前',
        context: 'current context',
        addedAt: DateTime.utc(2026, 6, 13, 9),
        bookId: 'book-1',
      ),
    ]);
    await service.saveReadingBookmarks('book-1', [
      ReadingBookmark(
        chapterIndex: 3,
        progress: 0.64,
        chapterTitle: 'Chapter 4',
        excerpt: 'A saved location.',
        createdAt: DateTime.utc(2026, 6, 13, 10),
        bookId: 'book-1',
      ),
    ]);

    final reloaded = BookmarkService(
      repository: DriftBookmarkRepository(
        db.bookmarkDao,
        languageCode: 'en',
      ),
    );
    await reloaded.init();

    expect(reloaded.loadWordBookmarks('book-1').single.word, 'current');
    expect(reloaded.loadReadingBookmarks('book-1').single.progress, 0.64);

    await reloaded.deleteWordBookmarks('book-1');
    await reloaded.deleteReadingBookmarks('book-1');

    final emptyReload = BookmarkService(
      repository: DriftBookmarkRepository(
        db.bookmarkDao,
        languageCode: 'en',
      ),
    );
    await emptyReload.init();

    expect(emptyReload.loadWordBookmarks('book-1'), isEmpty);
    expect(emptyReload.loadReadingBookmarks('book-1'), isEmpty);
  });

  test('dictionary cache persists entries and pruning', () async {
    final service = DictionaryCacheService(
      repository: DriftDictionaryCacheRepository(
        db.dictionaryCacheDao,
        languageCode: 'en',
      ),
      languageCode: 'en',
    );
    await service.init();

    await service.set('Collins', 'flow', '<html>current</html>');
    expect(service.get('Collins', 'flow'), '<html>current</html>');

    for (var index = 0; index < 501; index += 1) {
      await service.set('Longman', 'word$index', 'entry$index');
    }

    expect(service.hasWord('Collins', 'flow'), isFalse);
    expect(service.hasWord('Longman', 'word500'), isTrue);
    expect(service.entryCount, 500);

    final reloaded = DictionaryCacheService(
      repository: DriftDictionaryCacheRepository(
        db.dictionaryCacheDao,
        languageCode: 'en',
      ),
      languageCode: 'en',
    );
    await reloaded.init();

    expect(reloaded.hasWord('Longman', 'word500'), isTrue);
    expect(reloaded.entryCount, 500);

    await reloaded.clear();

    final cleared = DictionaryCacheService(
      repository: DriftDictionaryCacheRepository(
        db.dictionaryCacheDao,
        languageCode: 'en',
      ),
      languageCode: 'en',
    );
    await cleared.init();

    expect(cleared.entryCount, 0);
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/models/book.dart';
import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/models/chapter.dart';
import 'package:flow_read/models/learning_item.dart';
import 'package:flow_read/models/reading_memory.dart';
import 'package:flow_read/providers/reading/bookshelf_notifier.dart';
import 'package:flow_read/providers/reading/current_book_notifier.dart';
import 'package:flow_read/providers/reading/services_provider.dart';
import 'package:flow_read/providers/reading/vocabulary_notifier.dart';
import 'package:flow_read/services/app_logger.dart';
import 'package:flow_read/services/book_cache.dart';
import 'package:flow_read/services/book_service.dart';
import 'package:flow_read/services/bookmark_service.dart';
import 'package:flow_read/services/learning_item_service.dart';
import 'package:flow_read/services/reading_memory/source_scope_service.dart';
import 'package:flow_read/storage/repositories/bookmark_repository.dart';
import 'package:flow_read/storage/repositories/book_metadata_repository.dart';
import 'package:flow_read/storage/repositories/learning_item_repository.dart';
import 'package:flow_read/storage/repositories/reading_memory_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'switchToBook does not construct assistant controller while opening',
    () async {
      final metadata = _metadata(
        id: 'book-1',
        title: 'Parsed Book',
        sourcePath: '/tmp/parsed-book.epub',
      );
      final currentBook = _RecordingCurrentBookNotifier();
      final parserCalls = <String>[];

      final container = ProviderContainer(
        overrides: [
          bookServiceProvider.overrideWithValue(_FakeBookService([metadata])),
          epubBookParserProvider.overrideWithValue((path) async {
            parserCalls.add(path);
            return _book(title: 'Parsed Book');
          }),
          currentBookNotifierProvider.overrideWith(() => currentBook),
          vocabularyNotifierProvider.overrideWith(_NoopVocabularyNotifier.new),
          aiAssistantControllerProvider.overrideWith((ref) {
            throw StateError(
              'assistant controller should not be constructed during book open',
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      final opened = await container
          .read(bookshelfNotifierProvider.notifier)
          .switchToBook('book-1');

      expect(opened, isTrue);
      expect(parserCalls, ['/tmp/parsed-book.epub']);
      expect(container.read(bookshelfNotifierProvider).activeBookId, 'book-1');
      expect(
        container.read(bookshelfNotifierProvider).book?.title,
        'Parsed Book',
      );
      expect(
        container.read(bookCacheProvider).get('book-1')?.title,
        'Parsed Book',
      );
      expect(currentBook._invalidations, 1);
      expect(currentBook._chapterSelections, [0]);
    },
  );

  test(
    'switchToBook logs parser failures with stack and file diagnostics',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'flow_read_open_book_log_test_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final sourceFile = File('${tempDir.path}/book.epub');
      await sourceFile.writeAsBytes([1, 2, 3]);
      final logger = AppLogger(
        logDirectoryProvider: () async => tempDir,
        includeDebugProvider: () => true,
        clock: () => DateTime(2026, 6, 12, 9),
      );
      final metadata = _metadata(
        id: 'book-1',
        title: 'Broken Book',
        sourcePath: sourceFile.path,
      );

      final container = ProviderContainer(
        overrides: [
          appLoggerProvider.overrideWithValue(logger),
          bookServiceProvider.overrideWithValue(_FakeBookService([metadata])),
          epubBookParserProvider.overrideWithValue((_) async {
            throw StateError('parser failed');
          }),
          currentBookNotifierProvider.overrideWith(
            _RecordingCurrentBookNotifier.new,
          ),
          vocabularyNotifierProvider.overrideWith(_NoopVocabularyNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      final opened = await container
          .read(bookshelfNotifierProvider.notifier)
          .switchToBook('book-1');
      await logger.drain();

      expect(opened, isFalse);
      expect(
        container.read(bookshelfNotifierProvider).errorMessage,
        '打开书籍失败：无法读取书籍文件。详情已写入诊断日志。',
      );

      final logFile = File('${tempDir.path}/flow_read-2026-06-12.log');
      final entries = await logFile.readAsLines().then(
        (lines) => lines
            .map((line) => jsonDecode(line) as Map<String, dynamic>)
            .toList(),
      );
      final entry = entries.single;
      expect(entry['event'], 'book.open_failed');
      expect(entry['source'], 'bookshelf_notifier');
      expect(entry['errorType'], 'StateError');
      expect(entry['stackTrace'], isNotNull);
      final metadataLog = entry['metadata'] as Map<String, dynamic>;
      expect(metadataLog['bookId'], 'book-1');
      expect(metadataLog['sourcePathDiagnostics'], {
        'present': true,
        'exists': true,
        'sizeBytes': 3,
      });
    },
  );

  test(
    'missing-source repair ignores same-title books with readable sources',
    () {
      final existing = _metadata(
        id: 'book-1',
        title: 'Memory Book',
        sourcePath: '/tmp/memory-book.epub',
      );

      final candidate = findMissingSourceRepairCandidate(
        existingBooks: [existing],
        importedBook: _book(title: 'Memory Book'),
        hasReadableSource: (_) => true,
      );

      expect(candidate, isNull);
    },
  );

  test(
    'missing-source repair reuses same-title books only when source is lost',
    () {
      final existing = _metadata(
        id: 'book-1',
        title: 'Memory Book',
        sourcePath: '/tmp/memory-book.epub',
      );

      final candidate = findMissingSourceRepairCandidate(
        existingBooks: [existing],
        importedBook: _book(title: 'Memory Book'),
        hasReadableSource: (_) => false,
      );

      expect(candidate, same(existing));
    },
  );

  test(
    'removeBook keeps learning memory and tombstones the book source',
    () async {
      final metadata = _metadata(
        id: 'book-1',
        title: 'Memory Book',
        sourcePath: '/tmp/memory-book.epub',
      );
      final bookService = _FakeBookService([metadata]);
      final bookmarkService = _RecordingBookmarkService();
      final learningItemService = _RecordingLearningItemService();
      final sourceScope = _RecordingSourceScopeService();
      final aiCache = _RecordingAICacheService();
      final bookCache = BookCache();
      bookCache.put('book-1', _book(title: 'Memory Book'));

      final container = ProviderContainer(
        overrides: [
          bookServiceProvider.overrideWithValue(bookService),
          bookmarkServiceProvider.overrideWithValue(bookmarkService),
          learningItemServiceProvider.overrideWithValue(learningItemService),
          sourceScopeServiceProvider.overrideWithValue(sourceScope),
          aiCacheServiceProvider.overrideWithValue(aiCache),
          bookCacheProvider.overrideWithValue(bookCache),
          currentBookNotifierProvider.overrideWith(
            _RecordingCurrentBookNotifier.new,
          ),
          vocabularyNotifierProvider.overrideWith(_NoopVocabularyNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(bookshelfNotifierProvider.notifier)
          .removeBook('book-1');

      expect(bookService._removedBookIds, ['book-1']);
      expect(bookmarkService._wordBookmarkDeletes, ['book-1']);
      expect(bookmarkService._readingBookmarkDeletes, ['book-1']);
      expect(learningItemService._deleteForBookCalls, isEmpty);
      expect(aiCache._clearedBookIds, ['book-1']);
      expect(sourceScope._upsertedBookSources.single, {
        'bookId': 'book-1',
        'title': 'Memory Book',
        'author': 'Author',
        'languageCode': 'en',
      });
      expect(sourceScope._deletedBookSources, ['book-1']);
      expect(sourceScope._deletePolicies, [
        EvidenceRetentionPolicy.keepSnippet,
      ]);
      expect(bookCache.get('book-1'), isNull);
      expect(container.read(bookshelfNotifierProvider).books, isEmpty);
    },
  );

  test('removeBook passes metadata-only retention policy', () async {
    final metadata = _metadata(
      id: 'book-1',
      title: 'Memory Book',
      sourcePath: '/tmp/memory-book.epub',
    );
    final sourceScope = _RecordingSourceScopeService();
    final container = ProviderContainer(
      overrides: [
        bookServiceProvider.overrideWithValue(_FakeBookService([metadata])),
        bookmarkServiceProvider.overrideWithValue(_RecordingBookmarkService()),
        learningItemServiceProvider.overrideWithValue(
          _RecordingLearningItemService(),
        ),
        sourceScopeServiceProvider.overrideWithValue(sourceScope),
        aiCacheServiceProvider.overrideWithValue(_RecordingAICacheService()),
        currentBookNotifierProvider.overrideWith(
          _RecordingCurrentBookNotifier.new,
        ),
        vocabularyNotifierProvider.overrideWith(_NoopVocabularyNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(bookshelfNotifierProvider.notifier)
        .removeBook(
          'book-1',
          memoryRetentionPolicy: EvidenceRetentionPolicy.keepMetadataOnly,
        );

    expect(sourceScope._deletedBookSources, ['book-1']);
    expect(sourceScope._deletePolicies, [
      EvidenceRetentionPolicy.keepMetadataOnly,
    ]);
    expect(sourceScope._deletedBookSourcesWithMemory, isEmpty);
  });

  test('removeBook can delete source-scoped memory', () async {
    final metadata = _metadata(
      id: 'book-1',
      title: 'Memory Book',
      sourcePath: '/tmp/memory-book.epub',
    );
    final sourceScope = _RecordingSourceScopeService();
    final container = ProviderContainer(
      overrides: [
        bookServiceProvider.overrideWithValue(_FakeBookService([metadata])),
        bookmarkServiceProvider.overrideWithValue(_RecordingBookmarkService()),
        learningItemServiceProvider.overrideWithValue(
          _RecordingLearningItemService(),
        ),
        sourceScopeServiceProvider.overrideWithValue(sourceScope),
        aiCacheServiceProvider.overrideWithValue(_RecordingAICacheService()),
        currentBookNotifierProvider.overrideWith(
          _RecordingCurrentBookNotifier.new,
        ),
        vocabularyNotifierProvider.overrideWith(_NoopVocabularyNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(bookshelfNotifierProvider.notifier)
        .removeBook(
          'book-1',
          memoryRetentionPolicy: EvidenceRetentionPolicy.deleteWithSource,
        );

    expect(sourceScope._deletedBookSources, isEmpty);
    expect(sourceScope._deletedBookSourcesWithMemory, ['book-1']);
  });
}

Book _book({required String title}) {
  return Book(
    title: title,
    author: 'Author',
    language: 'en',
    chapters: const [
      Chapter(title: 'Chapter One', plainText: 'A first chapter.', rawHtml: ''),
    ],
  );
}

BookMetadata _metadata({
  required String id,
  required String title,
  required String sourcePath,
}) {
  return BookMetadata(
    id: id,
    title: title,
    author: 'Author',
    sourcePath: sourcePath,
    sourceLanguage: 'en',
    totalChapters: 1,
  );
}

class _FakeBookService extends BookService {
  _FakeBookService(List<BookMetadata> books)
    : _books = books,
      super(repository: _FakeBookMetadataRepository(books));

  final List<BookMetadata> _books;
  final List<String> _removedBookIds = [];

  @override
  List<BookMetadata> get books => _books;

  @override
  Future<void> init() async {}

  @override
  Future<void> removeBook(String id) async {
    _removedBookIds.add(id);
    _books.removeWhere((book) => book.id == id);
  }

  @override
  Future<BookMetadata?> updateProgress(
    String id,
    int currentChapter,
    double chapterProgress, {
    double? chapterScrollOffset,
  }) async {
    return null;
  }
}

class _FakeBookMetadataRepository implements BookMetadataRepository {
  _FakeBookMetadataRepository(Iterable<BookMetadata> books) {
    for (final book in books) {
      _books[book.id] = book;
    }
  }

  final Map<String, BookMetadata> _books = {};

  @override
  Future<void> init() async {}

  @override
  Iterable<BookMetadata> get values => _books.values;

  @override
  BookMetadata? get(String id) => _books[id];

  @override
  Future<void> put(String id, BookMetadata metadata) async {
    _books[id] = metadata;
  }

  @override
  Future<void> delete(String id) async {
    _books.remove(id);
  }

  @override
  Future<void> close() async {}
}

class _RecordingCurrentBookNotifier extends CurrentBookNotifier {
  int _invalidations = 0;
  final List<int> _chapterSelections = [];

  @override
  CurrentBookState build() => const CurrentBookState();

  @override
  void invalidateChapterAnalysisCache() {
    _invalidations += 1;
  }

  @override
  Future<void> goToChapter(int index) async {
    _chapterSelections.add(index);
  }
}

class _NoopVocabularyNotifier extends VocabularyNotifier {
  @override
  VocabularyState build() => const VocabularyState();

  @override
  Future<bool> tryUseCachedDifficulty(BookMetadata meta) async => false;
}

class _RecordingBookmarkService extends BookmarkService {
  _RecordingBookmarkService() : super(repository: _NoopBookmarkRepository());

  final List<String> _wordBookmarkDeletes = [];
  final List<String> _readingBookmarkDeletes = [];

  @override
  Future<void> deleteWordBookmarks(String bookId) async {
    _wordBookmarkDeletes.add(bookId);
  }

  @override
  Future<void> deleteReadingBookmarks(String bookId) async {
    _readingBookmarkDeletes.add(bookId);
  }
}

class _RecordingLearningItemService extends LearningItemService {
  _RecordingLearningItemService()
    : super(repository: _NoopLearningItemRepository());

  final List<String> _deleteForBookCalls = [];

  @override
  Future<void> deleteForBook(String bookId) async {
    _deleteForBookCalls.add(bookId);
  }
}

class _RecordingSourceScopeService extends SourceScopeService {
  _RecordingSourceScopeService()
    : super(repository: _NoopReadingMemoryRepository());

  final List<Map<String, String?>> _upsertedBookSources = [];
  final List<String> _deletedBookSources = [];
  final List<EvidenceRetentionPolicy> _deletePolicies = [];
  final List<String> _deletedBookSourcesWithMemory = [];

  @override
  Future<MemorySourceRecord> upsertBookSource({
    required String bookId,
    required String title,
    String? author,
    String? fingerprint,
    String? languageCode,
  }) async {
    _upsertedBookSources.add({
      'bookId': bookId,
      'title': title,
      'author': author,
      'languageCode': languageCode,
    });
    final now = DateTime.utc(2026, 6, 15, 9);
    return MemorySourceRecord(
      id: 'book:$bookId',
      sourceKind: SourceKind.book,
      titleSnapshot: title,
      authorSnapshot: author,
      languageCode: languageCode ?? 'en',
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> deleteBookSourceKeepLearningMemory(
    String bookId, {
    EvidenceRetentionPolicy? evidencePolicy,
  }) async {
    _deletedBookSources.add(bookId);
    _deletePolicies.add(evidencePolicy ?? EvidenceRetentionPolicy.keepSnippet);
  }

  @override
  Future<void> deleteBookSourceAndRelatedMemory(String bookId) async {
    _deletedBookSourcesWithMemory.add(bookId);
  }
}

class _RecordingAICacheService extends AICacheService {
  final List<String> _clearedBookIds = [];

  @override
  Future<void> clearBookCache(String bookId) async {
    _clearedBookIds.add(bookId);
  }
}

class _NoopBookmarkRepository implements BookmarkRepository {
  @override
  Future<void> close() async {}

  @override
  Future<void> deleteReadingBookmarks(String bookId) async {}

  @override
  Future<void> deleteWordBookmarks(String bookId) async {}

  @override
  String? getReadingBookmarks(String bookId) => null;

  @override
  String? getWordBookmarks(String bookId) => null;

  @override
  Future<void> init() async {}

  @override
  Future<void> putReadingBookmarks(
    String bookId,
    String encodedBookmarks,
  ) async {}

  @override
  Future<void> putWordBookmarks(String bookId, String encodedBookmarks) async {}
}

class _NoopLearningItemRepository implements LearningItemRepository {
  @override
  Future<void> clear() async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {}

  @override
  LearningItem? get(dynamic key) => null;

  @override
  Future<void> init() async {}

  @override
  Iterable<dynamic> get keys => const [];

  @override
  int get length => 0;

  @override
  Future<void> put(String id, LearningItem item) async {}

  @override
  Iterable<LearningItem> get values => const [];
}

class _NoopReadingMemoryRepository implements ReadingMemoryRepository {
  @override
  Future<void> close() async {}

  @override
  Future<MemoryKnowledgeEntity?> entityByCanonical({
    required String languageCode,
    required KnowledgeEntityType type,
    required String canonicalKey,
  }) async => null;

  @override
  Future<MemoryKnowledgeEntity?> entityById(String id) async => null;

  @override
  Future<int> eventCountForCanonical({
    required String languageCode,
    required String canonicalKey,
    MemoryEventType? type,
  }) async => 0;

  @override
  Future<List<MemoryEvent>> eventsForCanonical({
    required String languageCode,
    required String canonicalKey,
    int limit = 20,
  }) async => const [];

  @override
  Future<List<MemoryKnowledgeEvidence>> evidencesForEntity(
    String entityId, {
    int limit = 20,
  }) async => const [];

  @override
  Future<MemoryKnowledgeEvidence?> evidenceById(String id) async => null;

  @override
  Future<List<MemoryKnowledgeExplanation>> explanationsForEntity(
    String entityId, {
    int limit = 20,
  }) async => const [];

  @override
  Future<MemoryKnowledgeExplanation?> explanationById(String id) async => null;

  @override
  Future<void> init() async {}

  @override
  Future<void> recordEvent(MemoryEvent event) async {}

  @override
  Future<void> deleteEntitiesById(Iterable<String> entityIds) async {}

  @override
  Future<void> deleteEventsForSource(String sourceId) async {}

  @override
  Future<void> deleteEvidencesForSource(String sourceId) async {}

  @override
  Future<void> deleteReviewCandidatesForSourceEvidence(String sourceId) async {}

  @override
  Future<void> deleteSourceRecord(String sourceId) async {}

  @override
  Future<void> deleteSourceScopeCacheForSource(
    String sourceId, {
    EvidenceRetentionPolicy? retentionPolicy,
  }) async {}

  @override
  Future<List<String>> entityIdsWithOnlySourceEvidence(String sourceId) async =>
      const [];

  @override
  Future<List<MemoryKnowledgeEvidence>> evidencesForSource(
    String sourceId, {
    int limit = 50,
  }) async => const [];

  @override
  Future<List<ReviewCandidate>> reviewCandidates({
    ReviewCandidateStatus? status,
    int limit = 50,
  }) async => const [];

  @override
  Future<ReviewCandidate?> reviewCandidateById(String id) async => null;

  @override
  Future<void> updateReviewCandidateStatus({
    required String id,
    required ReviewCandidateStatus status,
    required DateTime updatedAt,
  }) async {}

  @override
  Future<List<ReviewCandidate>> reviewCandidatesForEntity(
    String entityId, {
    ReviewCandidateStatus? status,
    int limit = 20,
  }) async => const [];

  @override
  Future<MemorySourceRecord?> sourceRecord(String id) async => null;

  @override
  Future<void> updateSourceAvailability({
    required String sourceId,
    required SourceAvailability availability,
    DateTime? deletedAt,
  }) async {}

  @override
  Future<void> updateEvidencesForSource({
    required String sourceId,
    required SourceAvailability sourceAvailability,
    EvidenceRetentionPolicy? retentionPolicy,
    bool clearShortExcerpt = false,
  }) async {}

  @override
  Future<void> upsertEntity(MemoryKnowledgeEntity entity) async {}

  @override
  Future<void> upsertEvidence(MemoryKnowledgeEvidence evidence) async {}

  @override
  Future<void> upsertExplanation(
    MemoryKnowledgeExplanation explanation,
  ) async {}

  @override
  Future<void> upsertReviewCandidate(ReviewCandidate candidate) async {}

  @override
  Future<void> upsertSourceRecord(MemorySourceRecord record) async {}

  @override
  Future<void> upsertSourceScopeCache(SourceScopeCacheItem item) async {}

  @override
  Future<List<SourceScopeCacheItem>> sourceScopeCacheForSource(
    String sourceId, {
    String? cacheType,
    int limit = 50,
  }) async => const [];
}

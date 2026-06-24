import 'dart:io';

import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/models/book.dart';
import 'package:flow_read/models/chapter.dart';
import 'package:flow_read/providers/book_insight_provider.dart';
import 'package:flow_read/providers/reading/ai_notifier.dart';
import 'package:flow_read/providers/reading/bookshelf_notifier.dart';
import 'package:flow_read/providers/reading/current_book_notifier.dart';
import 'package:flow_read/providers/reading/services_provider.dart';
import 'package:flow_read/providers/settings_provider.dart';
import 'package:flow_read/services/reading_memory/chapter_summary_source_scope_cache.dart';
import 'package:flow_read/services/reading_memory/source_scope_service.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_memory_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('flow_read_ai_notifier_');
    db = await AppDatabase.createInMemory();
    final settings = SettingsService(db.settingsDao);
    await settings.init();
    await settings.setApiKey('test-api-key');
    final sourceScope = SourceScopeService(
      repository: DriftReadingMemoryRepository(
        db.readingMemoryDao,
        languageCode: 'en',
      ),
      languageCode: 'en',
    );
    await sourceScope.init();
    final aiCache = AICacheService(
      documentsDirectoryProvider: () async => tempDir,
    );
    await aiCache.init();

    var bookInsightReadCount = 0;
    container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith((ref) => settings),
        aiServiceProvider.overrideWithValue(_FakeSummaryAIService()),
        aiCacheServiceProvider.overrideWithValue(aiCache),
        sourceScopeServiceProvider.overrideWithValue(sourceScope),
        chapterSummarySourceScopeCacheProvider.overrideWithValue(
          ChapterSummarySourceScopeCache(sourceScope: sourceScope),
        ),
        bookshelfNotifierProvider.overrideWith(
          () => _ReaderBookshelfNotifier(_book()),
        ),
        currentBookNotifierProvider.overrideWith(
          () => _ReaderCurrentBookNotifier(),
        ),
        bookInsightProvider.overrideWith((ref) {
          bookInsightReadCount += 1;
          return BookInsightProvider(
            cacheService: aiCache,
          );
        }),
      ],
    );
    addTearDown(() {
      expect(bookInsightReadCount, 0);
      container.dispose();
    });
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'chapter summary generation does not refresh the UI insight provider',
    () async {
      final generated = await container
          .read(aiNotifierProvider.notifier)
          .generateSummaryForChapter(0);

      expect(generated, 1);
    },
  );

  test(
    'chapter summary generation skips non-body navigation entries',
    () async {
      final generated = await container
          .read(aiNotifierProvider.notifier)
          .generateSummariesForReadChapters([1, 2]);

      final aiService =
          container.read(aiServiceProvider) as _FakeSummaryAIService;
      expect(generated, 1);
      expect(aiService.summaryChapterTexts, [
        'Alice follows the river road and finds a hidden bridge before sunset.',
      ]);
    },
  );
}

class _FakeSummaryAIService extends AIService {
  _FakeSummaryAIService()
    : super(
        LLMClient(
          () => const AIProviderConfig(
            definition: AIProviders.deepSeek,
            apiKey: 'test-api-key',
            baseUrl: 'https://example.invalid',
            model: 'test-model',
          ),
        ),
      );

  final List<String> summaryChapterTexts = [];

  @override
  Stream<AISummary> generateSummary({
    required String chapterText,
    required List<String> vocabulary,
    required String language,
    SourceLanguage? sourceLanguage,
    SpoilerBoundary? spoilerBoundary,
  }) async* {
    summaryChapterTexts.add(chapterText);
    yield const AISummary(
      events: [
        SummaryEvent(
          description: 'Alice finds the old map.',
          source: 'Alice finds the old map.',
          significance: 'Starts the route.',
          confidence: 'high',
        ),
      ],
      characterDevelopments: [],
      keyVocabulary: [],
      readingGuidance: '继续关注地图线索。',
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
      Chapter(
        title: 'Chapter One',
        plainText:
            'Alice finds the old map and marks the road ahead before dawn.',
        rawHtml: '',
      ),
      Chapter(
        title: 'Preface',
        plainText: 'This preface explains how the book was edited.',
        rawHtml: '',
      ),
      Chapter(
        title: 'Chapter Two',
        plainText:
            'Alice follows the river road and finds a hidden bridge before sunset.',
        rawHtml: '',
      ),
    ],
  );
}

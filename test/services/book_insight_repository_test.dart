import 'dart:io';

import 'package:flow_ai/flow_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late AICacheService cacheService;
  late BookInsightRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'flow_read_book_insight_repository_',
    );
    cacheService = AICacheService(
      documentsDirectoryProvider: () async => tempDir,
    );
    await cacheService.init();
    repository = BookInsightRepository(cacheService: cacheService);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('keeps L2 book analysis snapshots in memory and releases by book', () {
    final data = _analysisData(
      bookId: 'book-1',
      currentChapterIndex: 2,
      schemaVersion: '1.0.0',
    );
    final key = BookAnalysisSnapshotKey.fromData(
      data,
      chapterCoverageHash: 'coverage-a',
    );

    repository.saveAnalysisSnapshot(
      data: data,
      chapterCoverageHash: 'coverage-a',
    );

    expect(repository.loadAnalysisSnapshot(key), same(data));
    expect(repository.analysisSnapshotCount, 1);
    expect(
      repository.loadAnalysisSnapshot(
        BookAnalysisSnapshotKey.fromData(
          data,
          chapterCoverageHash: 'coverage-b',
        ),
      ),
      isNull,
    );

    repository.clearAnalysisForBook('book-1');

    expect(repository.loadAnalysisSnapshot(key), isNull);
    expect(repository.analysisSnapshotCount, 0);
  });

  test('L2 snapshot key separates scope and schema changes', () {
    final readSoFar = _analysisData(
      bookId: 'book-1',
      currentChapterIndex: 2,
      schemaVersion: '1.0.0',
    );
    final fullBook = readSoFar.copyWith(
      scope: AnalysisScope.fullBook(bookId: 'book-1', totalChapters: 8),
    );
    final nextSchema = readSoFar.copyWith(schemaVersion: '2.0.0');

    repository.saveAnalysisSnapshot(
      data: readSoFar,
      chapterCoverageHash: 'coverage-a',
    );

    expect(
      repository.loadAnalysisSnapshot(
        BookAnalysisSnapshotKey.fromData(
          readSoFar,
          chapterCoverageHash: 'coverage-a',
        ),
      ),
      same(readSoFar),
    );
    expect(
      repository.loadAnalysisSnapshot(
        BookAnalysisSnapshotKey.fromData(
          fullBook,
          chapterCoverageHash: 'coverage-a',
        ),
      ),
      isNull,
    );
    expect(
      repository.loadAnalysisSnapshot(
        BookAnalysisSnapshotKey.fromData(
          nextSchema,
          chapterCoverageHash: 'coverage-a',
        ),
      ),
      isNull,
    );
  });

  test('persists L3 synthesis result through AICacheService', () async {
    final key = _synthesisKey();

    await repository.saveSynthesisResult(
      key: key,
      jsonString: '{"fullStoryline":"cached"}',
    );

    final reloadedRepository = BookInsightRepository(
      cacheService: cacheService,
    );
    expect(
      await reloadedRepository.loadSynthesisResult(key),
      '{"fullStoryline":"cached"}',
    );
  });

  test('L3 synthesis cache invalidates by all key dimensions', () async {
    final key = _synthesisKey();
    await repository.saveSynthesisResult(
      key: key,
      jsonString: '{"fullStoryline":"cached"}',
    );

    expect(await repository.loadSynthesisResult(key), isNotNull);
    expect(
      await repository.loadSynthesisResult(
        key.copyWith(coverageHash: 'coverage-b'),
      ),
      isNull,
    );
    expect(
      await repository.loadSynthesisResult(
        key.copyWith(scopeHash: 'scope-b'),
      ),
      isNull,
    );
    expect(
      await repository.loadSynthesisResult(
        key.copyWith(promptVersion: 12),
      ),
      isNull,
    );
    expect(
      await repository.loadSynthesisResult(
        key.copyWith(schemaVersion: '2.0.0'),
      ),
      isNull,
    );
    expect(
      await repository.loadSynthesisResult(
        key.copyWith(modelId: 'provider|model-b'),
      ),
      isNull,
    );
    expect(
      await repository.loadSynthesisResult(
        key.copyWith(spoilerBoundaryHash: 'spoiler-b'),
      ),
      isNull,
    );
    expect(
      await repository.loadSynthesisResult(
        key.copyWith(outputLanguage: 'en'),
      ),
      isNull,
    );
  });
}

BookAnalysisData _analysisData({
  required String bookId,
  required int currentChapterIndex,
  required String schemaVersion,
}) {
  final scope = AnalysisScope.readSoFar(
    bookId: bookId,
    currentChapterIndex: currentChapterIndex,
  );
  return BookAnalysisData(
    bookId: bookId,
    scope: scope,
    characters: [
      CharacterCard(
        canonicalName: 'Alice',
        firstChapter: 0,
        lastChapter: currentChapterIndex,
        activeChapters: {0, currentChapterIndex},
      ),
    ],
    coverage: 0.5,
    schemaVersion: schemaVersion,
    analyzedAt: DateTime.utc(2026, 6, 24),
  );
}

BookSynthesisCacheKey _synthesisKey() {
  return const BookSynthesisCacheKey(
    bookId: 'book-1',
    synthesisType: 'read_so_far',
    scopeHash: 'scope-a',
    coverageHash: 'coverage-a',
    promptVersion: 11,
    schemaVersion: '1.0.0',
    modelId: 'provider|model-a',
    outputLanguage: 'zh',
    spoilerBoundaryHash: 'spoiler-a',
  );
}

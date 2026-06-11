import 'dart:io';

import 'package:flow_ai/flow_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late AICacheService cache;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('flow_read_ai_cache_');
    cache = AICacheService(documentsDirectoryProvider: () async => tempDir);
    await cache.init();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'writes upgraded summary keys without overwriting prompt versions',
    () async {
      const bookId = 'book/one';
      const contentHash = 'abc123';

      await cache.saveSummary(
        bookId,
        2,
        'zh',
        '{"version":1}',
        contentHash: contentHash,
        promptVersion: 1,
        sourceLanguage: 'ja',
        outputLanguage: 'zh',
      );
      await cache.saveSummary(
        bookId,
        2,
        'zh',
        '{"version":2}',
        contentHash: contentHash,
        promptVersion: 2,
        sourceLanguage: 'ja',
        outputLanguage: 'zh',
      );

      expect(
        await cache.loadSummary(
          bookId,
          2,
          'zh',
          contentHash: contentHash,
          promptVersion: 1,
          sourceLanguage: 'ja',
          outputLanguage: 'zh',
        ),
        '{"version":1}',
      );
      expect(
        await cache.loadSummary(
          bookId,
          2,
          'zh',
          contentHash: contentHash,
          promptVersion: 2,
          sourceLanguage: 'ja',
          outputLanguage: 'zh',
        ),
        '{"version":2}',
      );
    },
  );

  test('falls back to legacy summary key when upgraded key misses', () async {
    await cache.saveSummary('book-one', 1, 'zh', '{"legacy":true}');

    final cached = await cache.loadSummary(
      'book-one',
      1,
      'zh',
      contentHash: 'missing-hash',
      promptVersion: 1,
      sourceLanguage: 'en',
      outputLanguage: 'zh',
    );

    expect(cached, '{"legacy":true}');
  });

  test('content hash is deterministic and changes with content', () {
    expect(
      AICacheService.contentHashFor('same content'),
      AICacheService.contentHashFor('same content'),
    );
    expect(
      AICacheService.contentHashFor('same content'),
      isNot(AICacheService.contentHashFor('other content')),
    );
  });

  test('caches word analysis by upgraded key', () async {
    await cache.saveWordAnalysis(
      'book-one',
      3,
      '{"word":"quicken"}',
      contentHash: 'word-hash',
      promptVersion: 4,
      sourceLanguage: 'en',
      outputLanguage: 'zh-Hans',
    );

    expect(
      await cache.loadWordAnalysis(
        'book-one',
        3,
        contentHash: 'word-hash',
        promptVersion: 4,
        sourceLanguage: 'en',
        outputLanguage: 'zh-Hans',
      ),
      '{"word":"quicken"}',
    );
    expect(
      await cache.loadWordAnalysis(
        'book-one',
        3,
        contentHash: 'word-hash',
        promptVersion: 5,
        sourceLanguage: 'en',
        outputLanguage: 'zh-Hans',
      ),
      isNull,
    );
  });

  test(
    'caches assistant actions by action kind and model fingerprint',
    () async {
      await cache.saveAssistantAction(
        kind: 'assistant_explain',
        bookId: 'book-one',
        chapterIndex: 3,
        contentHash: 'prompt-hash',
        promptVersion: 4,
        sourceLanguage: 'en',
        outputLanguage: 'zh',
        modelConfigFingerprint: 'provider|base|model-a',
        response: '{"translation":"cached"}',
      );

      expect(
        await cache.loadAssistantAction(
          kind: 'assistant_explain',
          bookId: 'book-one',
          chapterIndex: 3,
          contentHash: 'prompt-hash',
          promptVersion: 4,
          sourceLanguage: 'en',
          outputLanguage: 'zh',
          modelConfigFingerprint: 'provider|base|model-a',
        ),
        '{"translation":"cached"}',
      );
      expect(
        await cache.loadAssistantAction(
          kind: 'assistant_translate',
          bookId: 'book-one',
          chapterIndex: 3,
          contentHash: 'prompt-hash',
          promptVersion: 4,
          sourceLanguage: 'en',
          outputLanguage: 'zh',
          modelConfigFingerprint: 'provider|base|model-a',
        ),
        isNull,
      );
      expect(
        await cache.loadAssistantAction(
          kind: 'assistant_explain',
          bookId: 'book-one',
          chapterIndex: 3,
          contentHash: 'prompt-hash',
          promptVersion: 4,
          sourceLanguage: 'en',
          outputLanguage: 'zh',
          modelConfigFingerprint: 'provider|base|model-b',
        ),
        isNull,
      );
    },
  );

  test('caches chapter preview by upgraded key', () async {
    await cache.saveChapterPreview(
      'book-one',
      1,
      '{"setup":"Watch the opening image."}',
      contentHash: 'preview-hash',
      promptVersion: 2,
      sourceLanguage: 'en',
      outputLanguage: 'zh',
    );

    expect(
      await cache.loadChapterPreview(
        'book-one',
        1,
        contentHash: 'preview-hash',
        promptVersion: 2,
        sourceLanguage: 'en',
        outputLanguage: 'zh',
      ),
      '{"setup":"Watch the opening image."}',
    );
    expect(
      await cache.loadChapterPreview(
        'book-one',
        1,
        contentHash: 'preview-hash',
        promptVersion: 3,
        sourceLanguage: 'en',
        outputLanguage: 'zh',
      ),
      isNull,
    );
  });

  test('summary coverage counts only generated chapter summaries', () async {
    await cache.saveSummary(
      'book/one',
      0,
      'zh',
      '{"events":[]}',
      contentHash: 'summary-a',
      promptVersion: 2,
      sourceLanguage: 'en',
      outputLanguage: 'zh',
    );
    await cache.saveSummary(
      'book/one',
      2,
      'en',
      '{"events":[]}',
      contentHash: 'summary-b',
      promptVersion: 2,
      sourceLanguage: 'en',
      outputLanguage: 'en',
    );
    await cache.savePractice(
      'book/one',
      1,
      '{"questions":[]}',
      contentHash: 'practice',
      promptVersion: 2,
      sourceLanguage: 'en',
      outputLanguage: 'zh',
    );
    await cache.saveChapterPreview(
      'book/one',
      3,
      '{"setup":"Preview"}',
      contentHash: 'preview',
      promptVersion: 2,
      sourceLanguage: 'en',
      outputLanguage: 'zh',
    );

    final coverage = await cache.summaryCoverageFor(
      'book/one',
      totalChapters: 4,
    );

    expect(coverage.generatedChapterIndexes, {0, 2});
    expect(coverage.generatedCount, 2);
    expect(coverage.missingChapterIndexes, [1, 3]);
  });

  test('summary coverage includes legacy summary files', () async {
    await cache.saveSummary('book-one', 1, 'zh', '{"legacy":true}');

    final coverage = await cache.summaryCoverageFor(
      'book-one',
      totalChapters: 3,
    );

    expect(coverage.generatedChapterIndexes, {1});
    expect(coverage.missingCount, 2);
  });
}

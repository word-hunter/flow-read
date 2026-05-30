import 'dart:io';

import 'package:flow_read/services/ai_cache_service.dart';
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
}

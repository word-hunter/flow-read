import 'dart:async';
import 'dart:io';

import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/pages/reader_page.dart';
import 'package:flow_read/providers/reading/services_provider.dart';
import 'package:flow_read/providers/settings_provider.dart';
import 'package:flow_read/services/character_registry.dart';
import 'package:flow_read/services/book_glossary_service.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/services/reading_memory/book_insight_source_scope_service.dart';
import 'package:flow_read/services/reading_memory/chapter_summary_source_scope_cache.dart';
import 'package:flow_read/services/reading_memory/source_scope_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/dao/book_glossary_dao.dart';
import 'package:flow_read/storage/database/repositories/drift_character_registry_repository.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_memory_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('story map provider waits until app database is ready', () async {
    final db = await AppDatabase.createInMemory();
    final tempDir = await Directory.systemTemp.createTemp(
      'flow_read_story_map_ready_',
    );
    final databaseReady = Completer<AppDatabase>();
    final sourceScope = SourceScopeService(
      repository: DriftReadingMemoryRepository(
        db.readingMemoryDao,
        languageCode: 'en',
      ),
      languageCode: 'en',
    );
    await sourceScope.init();
    final characterRegistry = CharacterRegistry(
      repository: DriftCharacterRegistryRepository(db.characterRegistryDao),
    );
    await characterRegistry.init();
    final aiCache = AICacheService(
      documentsDirectoryProvider: () async => tempDir,
    );
    await aiCache.init();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => databaseReady.future),
        sourceScopeServiceProvider.overrideWithValue(sourceScope),
        characterRegistryProvider.overrideWithValue(characterRegistry),
        aiCacheServiceProvider.overrideWithValue(aiCache),
        aiServiceProvider.overrideWithValue(
          AIService(
            LLMClient(
              () => const AIProviderConfig(
                definition: AIProviders.deepSeek,
                apiKey: 'test-api-key',
                baseUrl: 'https://example.invalid',
                model: 'test-model',
              ),
            ),
          ),
        ),
      ],
    );

    try {
      var completed = false;
      final providerFuture =
          readBookInsightProviderWhenReady(
            waitForDatabase: () => container.read(appDatabaseProvider.future),
            readProvider: () => container.read(bookInsightProvider),
            mounted: () => true,
          ).then((provider) {
            completed = true;
            return provider;
          });

      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);

      databaseReady.complete(db);
      final provider = await providerFuture.timeout(const Duration(seconds: 1));

      expect(provider, isNotNull);
      expect(completed, isTrue);
    } finally {
      container.dispose();
      await db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });

  test('story map provider survives AI usage settings notifications', () async {
    final db = await AppDatabase.createInMemory();
    final tempDir = await Directory.systemTemp.createTemp(
      'flow_read_story_map_lifecycle_',
    );
    final settings = SettingsService(db.settingsDao);
    await settings.init();
    final characterRegistry = CharacterRegistry(
      repository: DriftCharacterRegistryRepository(db.characterRegistryDao),
    );
    await characterRegistry.init();
    final aiCache = AICacheService(
      documentsDirectoryProvider: () async => tempDir,
    );
    await aiCache.init();
    final sourceScope = SourceScopeService(
      repository: DriftReadingMemoryRepository(
        db.readingMemoryDao,
        languageCode: 'en',
      ),
      languageCode: 'en',
    );
    await sourceScope.init();
    var sourceScopeBuilds = 0;
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith((ref) => settings),
        aiCacheServiceProvider.overrideWithValue(aiCache),
        bookGlossaryServiceProvider.overrideWithValue(
          BookGlossaryService(BookGlossaryDao(db)),
        ),
        chapterSummarySourceScopeCacheProvider.overrideWithValue(
          ChapterSummarySourceScopeCache(sourceScope: sourceScope),
        ),
        characterRegistryProvider.overrideWithValue(characterRegistry),
        bookInsightSourceScopeServiceProvider.overrideWith((ref) {
          ref.watch(settingsProvider);
          sourceScopeBuilds += 1;
          return BookInsightSourceScopeService(cacheService: aiCache);
        }),
        aiServiceProvider.overrideWithValue(
          AIService(
            LLMClient(
              () => const AIProviderConfig(
                definition: AIProviders.deepSeek,
                apiKey: 'test-api-key',
                baseUrl: 'https://example.invalid',
                model: 'test-model',
              ),
            ),
          ),
        ),
      ],
    );

    try {
      final provider = container.read(bookInsightProvider);
      expect(sourceScopeBuilds, 1);

      await settings.incrementAIUsage(chapterSummary: true);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(bookInsightProvider), same(provider));
      expect(sourceScopeBuilds, 1);
    } finally {
      container.dispose();
      await db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });
}

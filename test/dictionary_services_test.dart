import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flow_read/models/analysis_result.dart';
import 'package:flow_read/models/user_vocabulary.dart';
import 'package:flow_read/models/word_context_example.dart';
import 'package:flow_read/models/word_analysis.dart';
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/services/dictionary/collins_repository.dart';
import 'package:flow_read/storage/repositories/dictionary_cache_repository.dart';
import 'package:flow_read/services/dictionary/dictionary_cache_service.dart';
import 'package:flow_read/services/dictionary/dictionary_manager_service.dart';
import 'package:flow_read/services/dictionary/dictionary_repository.dart';
import 'package:flow_read/services/dictionary/dictionary_source_config.dart';
import 'package:flow_read/services/dictionary/dictionary_source_registry.dart';
import 'package:flow_read/services/dictionary/dictionary_source_test_service.dart';
import 'package:flow_read/services/ai_cache_service.dart';
import 'package:flow_read/services/ai_service.dart';
import 'package:flow_read/services/dictionary/longman_repository.dart';
import 'package:flow_read/services/llm_client.dart';
import 'package:flow_read/services/pronunciation_service.dart';
import 'package:flow_read/services/prompt_builder.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/services/dictionary/word_repository.dart';
import 'package:flow_read/services/dictionary/wordnet_repository.dart';
import 'package:flow_read/storage/repositories/user_vocabulary_repository.dart';
import 'package:flow_read/widgets/dictionary_detail_view.dart';
import 'package:flow_read/widgets/reader/reader_word_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'support/hive_test_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('dictionary source parsers', () {
    test('Collins parser returns structured definitions and examples', () {
      final repository = CollinsRepository(DictionaryCacheService());

      final entry = repository.parseHtml('flow', '''
        <main id="main_content">
          <div class="res_cell_center">
            <script>window.ad = true;</script>
            <div class="mini_h2"><span class="pron">/floʊ/</span></div>
            <div class="cB">
              <span class="gramGrp"><span class="pos">noun</span></span>
              <div class="sense">
                <span class="def">A smooth continuous movement.</span>
                <span class="cit type-example">The flow of ideas was steady.</span>
              </div>
            </div>
          </div>
        </main>
        ''', fromCache: true);

      expect(entry, isNotNull);
      expect(entry!.sourceName, 'Collins');
      expect(entry.sourceUrl, contains('/flow'));
      expect(entry.fromCache, isTrue);
      expect(entry.parserVersion, CollinsRepository.parserVersion);
      expect(entry.phonetic, '/floʊ/');
      expect(entry.meanings.single.partOfSpeech, 'noun');
      expect(entry.meanings.single.definitions, [
        'A smooth continuous movement.',
      ]);
      expect(entry.meanings.single.examples, ['The flow of ideas was steady.']);
      expect(entry.htmlContent, isNot(contains('<script>')));
    });

    test('Collins parser reads IPA text from pron type-ipa span', () {
      final repository = CollinsRepository(DictionaryCacheService());

      final entry = repository.parseHtml('kirby', '''
        <main id="main_content">
          <div class="res_cell_center">
            <span class="pron type-ipa">ˈkɜːrbi</span>
            <div class="cB">
              <span class="gramGrp"><span class="pos">noun</span></span>
              <div class="sense">
                <span class="def">A surname or given name.</span>
              </div>
            </div>
          </div>
        </main>
        ''');

      expect(entry, isNotNull);
      expect(entry!.phonetic, 'ˈkɜːrbi');
    });

    test(
      'Collins lookup decodes UTF-8 phonetics and skips stale caches',
      () async {
        final cache = DictionaryCacheService(
          repository: _MemoryDictionaryCacheRepository(),
        );
        await cache.init();
        await cache.set(
          'Collins',
          'kirby',
          '<span class="pron">/ËˆkÉœËrbi/</span>',
        );
        await cache.set(
          'Collins:collins-html-v2',
          'kirby',
          '<span class="pron">/ËˆkÉœËrbi/</span>',
        );

        final repository = CollinsRepository(
          cache,
          httpClient: MockClient((request) async {
            expect(request.url.toString(), contains('/kirby'));
            return http.Response.bytes(
              utf8.encode('''
              <main id="main_content">
                <div class="res_cell_center">
                  <div class="mini_h2">
                    <span class="pron">/ˈkɜːrbi/</span>
                  </div>
                  <div class="cB">
                    <span class="gramGrp"><span class="pos">noun</span></span>
                    <div class="sense">
                      <span class="def">A surname or given name.</span>
                    </div>
                  </div>
                </div>
              </main>
            '''),
              200,
              headers: {'content-type': 'text/html'},
            );
          }),
        );

        final entry = await repository.lookup('Kirby');

        expect(entry, isNotNull);
        expect(entry!.fromCache, isFalse);
        expect(entry.phonetic, '/ˈkɜːrbi/');
        expect(
          cache.get('Collins:${CollinsRepository.parserVersion}', 'kirby'),
          contains('/ˈkɜːrbi/'),
        );
      },
    );

    test('Longman parser returns source metadata and examples', () {
      final repository = LongmanRepository(DictionaryCacheService());

      final entry = repository.parseHtml('flow', '''
        <div class="responsive_cell6">
          <span class="PronCodes">/fləʊ/</span>
          <span class="dictentry">
            <span class="POS">noun</span>
            <span class="Sense">
              <span class="DEF">a smooth steady movement</span>
              <span class="EXAMPLE">the flow of traffic</span>
            </span>
          </span>
        </div>
        ''');

      expect(entry, isNotNull);
      expect(entry!.sourceName, 'Longman');
      expect(entry.sourceUrl, contains('/flow'));
      expect(entry.phonetic, '/fləʊ/');
      expect(entry.meanings.single.definitions, ['a smooth steady movement']);
      expect(entry.meanings.single.examples, ['the flow of traffic']);
    });

    test('Dictionary API parser preserves examples separately', () {
      final entry = DictionaryRepository().parseEntry({
        'word': 'flow',
        'phonetic': '/floʊ/',
        'meanings': [
          {
            'partOfSpeech': 'verb',
            'definitions': [
              {
                'definition': 'to move continuously',
                'example': 'Rivers flow to the sea.',
              },
            ],
          },
        ],
      });

      expect(entry, isNotNull);
      expect(entry!.sourceName, 'Dictionary API');
      expect(entry.meanings.single.definitions, ['to move continuously']);
      expect(entry.meanings.single.examples, ['Rivers flow to the sea.']);
    });

    test('WordNet lookup keeps offline fallback metadata', () async {
      final entry = await WordNetRepository().lookup('flow');

      expect(entry, isNotNull);
      expect(entry!.sourceName, 'WordNet');
      expect(entry.meanings, isNotEmpty);
    });
  });

  group('DictionaryManagerService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await initHiveTestStorage('flow_read_dictionary_manager_test_');
      await openFlowReadTestBoxes();
    });

    tearDown(() async {
      await disposeHiveTestStorage(tempDir);
    });

    test('default source order is persisted', () async {
      final settings = SettingsService();
      await settings.init();

      expect(
        settings.dictionarySources.map((config) => config.type).toList(),
        DictionarySourceConfig.defaults.map((config) => config.type).toList(),
      );
      expect(settingsBox().get('dictionarySources'), isA<String>());
    });

    test(
      'source registry supplies lookup and diagnostic repositories',
      () async {
        final registry = DictionarySourceRegistry();
        await registry.init();

        expect(
          DictionarySourceRegistry.sourceTypes,
          DictionarySourceConfig.defaults.map((config) => config.type).toList(),
        );

        final adapters = registry.adapters();
        expect(
          adapters.map((adapter) => adapter.type).toList(),
          DictionarySourceRegistry.sourceTypes,
        );

        final repositories = registry.repositories();
        expect(
          repositories.keys.toList(),
          DictionarySourceRegistry.sourceTypes,
        );
        expect(
          repositories[DictionarySourceType.collins],
          isA<CollinsRepository>(),
        );
        expect(
          repositories[DictionarySourceType.wordNet],
          isA<WordNetRepository>(),
        );
        expect(
          repositories[DictionarySourceType.dictionaryApi],
          isA<DictionaryRepository>(),
        );
        expect(
          repositories[DictionarySourceType.longman],
          isA<LongmanRepository>(),
        );
      },
    );

    test(
      'legacy WordNet-first source order migrates to Collins-first',
      () async {
        await settingsBox().put(
          'dictionarySources',
          jsonEncode(
            DictionarySourceConfig.legacyWordNetFirstDefaults
                .map((config) => config.toJson())
                .toList(),
          ),
        );

        final settings = SettingsService();
        await settings.init();

        expect(
          settings.dictionarySources.first.type,
          DictionarySourceType.collins,
        );
        final persisted =
            jsonDecode(settingsBox().get('dictionarySources') as String)
                as List<dynamic>;
        expect(persisted.first, containsPair('type', 'collins'));
      },
    );

    test('source priority can be reordered and persists', () async {
      final settings = SettingsService();
      await settings.init();

      await settings.moveDictionarySource(DictionarySourceType.collins, 1);

      expect(settings.dictionarySources.map((config) => config.type).toList(), [
        DictionarySourceType.wordNet,
        DictionarySourceType.collins,
        DictionarySourceType.dictionaryApi,
        DictionarySourceType.longman,
      ]);
      expect(
        settings.dictionarySources.map((config) => config.priority).toList(),
        [0, 1, 2, 3],
      );

      final reloaded = SettingsService();
      await reloaded.init();
      expect(
        reloaded.dictionarySources.map((config) => config.type).toList(),
        settings.dictionarySources.map((config) => config.type).toList(),
      );
    });

    test('WordNet fallback source stays enabled', () async {
      final settings = SettingsService();
      await settings.init();

      await settings.setDictionarySourceEnabled(
        DictionarySourceType.wordNet,
        false,
      );

      expect(
        settings.dictionarySources
            .singleWhere(
              (config) => config.type == DictionarySourceType.wordNet,
            )
            .enabled,
        isTrue,
      );
    });

    test('enabled Collins source is queried before WordNet', () async {
      final settings = SettingsService();
      await settings.init();

      final collins = _CountingRepository(
        DictionaryEntry(
          word: 'flow',
          meanings: const [
            Meaning(partOfSpeech: 'noun', definitions: ['collins result']),
          ],
          sourceName: 'Collins',
        ),
      );
      final wordNet = _CountingRepository(
        DictionaryEntry(
          word: 'flow',
          meanings: const [
            Meaning(partOfSpeech: 'noun', definitions: ['wordnet result']),
          ],
          sourceName: 'WordNet',
        ),
      );

      final manager = DictionaryManagerService(
        settings: settings,
        sources: [
          DictionarySourceAdapter(
            type: DictionarySourceType.collins,
            repository: collins,
          ),
          DictionarySourceAdapter(
            type: DictionarySourceType.wordNet,
            repository: wordNet,
          ),
        ],
      );

      final entry = await manager.lookup('flow');

      expect(collins.calls, 1);
      expect(wordNet.calls, 0);
      expect(entry!.sourceName, 'Collins');
      expect(entry.meanings.single.definitions.single, 'collins result');
    });

    test('disabled Collins source is skipped', () async {
      final settings = SettingsService();
      await settings.init();
      await settings.setCollinsDictionaryEnabled(false);

      final collins = _CountingRepository(
        DictionaryEntry(
          word: 'flow',
          meanings: const [
            Meaning(partOfSpeech: 'noun', definitions: ['collins result']),
          ],
        ),
      );
      final fallback = _CountingRepository(
        DictionaryEntry(
          word: 'flow',
          meanings: const [
            Meaning(partOfSpeech: 'noun', definitions: ['longman result']),
          ],
        ),
      );

      final manager = DictionaryManagerService(
        settings: settings,
        sources: [
          DictionarySourceAdapter(
            type: DictionarySourceType.collins,
            repository: collins,
          ),
          DictionarySourceAdapter(
            type: DictionarySourceType.longman,
            repository: fallback,
          ),
        ],
      );

      final entry = await manager.lookup('flow');

      expect(collins.calls, 0);
      expect(fallback.calls, 1);
      expect(entry!.sourceName, 'Longman');
      expect(entry.meanings.single.definitions.single, 'longman result');
    });

    test(
      'ReadingProvider lookup falls back after source failure and keeps context',
      () async {
        final settings = SettingsService();
        await settings.init();
        final manager = DictionaryManagerService(
          settings: settings,
          sources: [
            const DictionarySourceAdapter(
              type: DictionarySourceType.wordNet,
              repository: _ThrowingRepository(),
            ),
            DictionarySourceAdapter(
              type: DictionarySourceType.dictionaryApi,
              repository: _CountingRepository(
                DictionaryEntry(
                  word: 'flow',
                  meanings: const [
                    Meaning(
                      partOfSpeech: 'verb',
                      definitions: ['to move continuously'],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
        final provider = ReadingProvider()..setWordRepository(manager);

        await provider.lookupWord(
          'flow',
          contextText: 'Ideas flow clearly in this paragraph.',
        );

        expect(
          provider.selectedWordContext,
          'Ideas flow clearly in this paragraph.',
        );
        expect(provider.selectedWordTranslation, 'to move continuously');
        expect(provider.selectedWordEntry!.sourceName, 'Dictionary API');
        expect(provider.selectedWordEntry!.errorMessage, contains('WordNet'));
      },
    );
  });

  group('DictionarySourceTestService', () {
    test(
      'reports source hit, miss, and failure without real network',
      () async {
        final service = DictionarySourceTestService(
          repositories: {
            DictionarySourceType.wordNet: _CountingRepository(
              const DictionaryEntry(
                word: 'flow',
                meanings: [
                  Meaning(partOfSpeech: 'noun', definitions: ['movement']),
                ],
              ),
            ),
            DictionarySourceType.dictionaryApi: _CountingRepository(null),
            DictionarySourceType.collins: const _ThrowingRepository(),
          },
        );

        final results = await service.testSources(const [
          DictionarySourceType.wordNet,
          DictionarySourceType.dictionaryApi,
          DictionarySourceType.collins,
        ], ' Flow ');

        expect(
          results[DictionarySourceType.wordNet]!.status,
          DictionarySourceTestStatus.hit,
        );
        expect(results[DictionarySourceType.wordNet]!.word, 'flow');
        expect(
          results[DictionarySourceType.dictionaryApi]!.status,
          DictionarySourceTestStatus.noResult,
        );
        expect(
          results[DictionarySourceType.collins]!.status,
          DictionarySourceTestStatus.failed,
        );
        expect(
          results[DictionarySourceType.collins]!.message,
          contains('network down'),
        );
      },
    );
  });

  test(
    'ReadingProvider keeps history for related dictionary lookups',
    () async {
      final provider = ReadingProvider()
        ..setWordRepository(
          _MappedRepository({
            'flow': const DictionaryEntry(
              word: 'flow',
              meanings: [
                Meaning(partOfSpeech: 'noun', definitions: ['movement']),
              ],
              sourceName: 'Fixture',
            ),
            'movement': const DictionaryEntry(
              word: 'movement',
              meanings: [
                Meaning(partOfSpeech: 'noun', definitions: ['act of moving']),
              ],
              sourceName: 'Fixture',
            ),
          }),
        );

      await provider.lookupWord('flow', contextText: 'ideas flow clearly');
      await provider.lookupRelatedWord('movement');

      expect(provider.selectedWord, 'movement');
      expect(provider.selectedWordTranslation, 'act of moving');
      expect(provider.canGoBackWordLookup, isTrue);

      provider.goBackWordLookup();

      expect(provider.selectedWord, 'flow');
      expect(provider.selectedWordContext, 'ideas flow clearly');
      expect(provider.selectedWordTranslation, 'movement');
      expect(provider.canGoBackWordLookup, isFalse);
    },
  );

  testWidgets('DictionaryDetailView shows imported Word Hunter examples', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DictionaryDetailView(
            word: 'flow',
            entry: const DictionaryEntry(
              word: 'flow',
              meanings: [
                Meaning(partOfSpeech: 'noun', definitions: ['movement']),
              ],
            ),
            primaryDefinition: 'movement',
            isLoading: false,
            importedExamples: const [
              WordContextExample(
                word: 'flow',
                text: 'A steady flow of language builds confidence.',
                title: 'Word Hunter',
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      find.text('A steady flow of language builds confidence.'),
      findsOneWidget,
    );
    expect(find.text('Word Hunter'), findsOneWidget);
  });

  testWidgets('DictionaryDetailView renders IPA with phonetic font fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTextStyle.merge(
          style: const TextStyle(fontFamily: 'Serif'),
          child: Scaffold(
            body: DictionaryDetailView(
              word: 'Kirby',
              entry: const DictionaryEntry(
                word: 'Kirby',
                phonetic: 'ˈkɜːrbi',
                meanings: [
                  Meaning(
                    partOfSpeech: 'noun',
                    definitions: ['A surname or given name.'],
                  ),
                ],
                sourceName: 'Collins',
              ),
              primaryDefinition: null,
              isLoading: false,
            ),
          ),
        ),
      ),
    );

    final phoneticText = tester.widget<Text>(find.text('ˈkɜːrbi'));
    expect(phoneticText.style?.fontFamily, 'Lucida Grande');
    expect(
      phoneticText.style?.fontFamilyFallback,
      contains('Arial Unicode MS'),
    );
    expect(phoneticText.style?.fontStyle, FontStyle.normal);
  });

  testWidgets('DictionaryDetailView exposes local pronunciation action', (
    tester,
  ) async {
    var spokenWord = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DictionaryDetailView(
            word: 'flow',
            entry: const DictionaryEntry(
              word: 'flow',
              meanings: [
                Meaning(partOfSpeech: 'verb', definitions: ['move steadily']),
              ],
            ),
            primaryDefinition: null,
            isLoading: false,
            onSpeakWord: (word) async {
              spokenWord = word;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('播放发音'));
    await tester.pump();

    expect(spokenWord, 'flow');
  });

  testWidgets('DictionaryDetailView lets definition words trigger lookup', (
    tester,
  ) async {
    var lookupWord = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DictionaryDetailView(
            word: 'flow',
            entry: const DictionaryEntry(
              word: 'flow',
              meanings: [
                Meaning(
                  partOfSpeech: 'noun',
                  definitions: ['continuous movement'],
                ),
              ],
            ),
            primaryDefinition: null,
            isLoading: false,
            onLookupWord: (word) => lookupWord = word,
          ),
        ),
      ),
    );

    final movementSpan = _findTextSpan(tester, 'movement');
    expect(movementSpan.style?.decoration, isNull);
    (movementSpan.recognizer! as TapGestureRecognizer).onTap!();

    expect(lookupWord, 'movement');
  });

  testWidgets('DictionaryDetailView handles real taps on definition words', (
    tester,
  ) async {
    var lookupWord = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DictionaryDetailView(
            word: 'flow',
            entry: const DictionaryEntry(
              word: 'flow',
              meanings: [
                Meaning(partOfSpeech: 'noun', definitions: ['movement']),
              ],
            ),
            primaryDefinition: null,
            isLoading: false,
            onLookupWord: (word) => lookupWord = word,
          ),
        ),
      ),
    );

    await _tapInlineText(tester, 'movement');
    await tester.pump();

    expect(lookupWord, 'movement');
  });

  testWidgets('ReaderWordSidebar mouse clicks continue dictionary lookup', (
    tester,
  ) async {
    final provider = ReadingProvider()
      ..setWordRepository(
        _MappedRepository({
          'flow': const DictionaryEntry(
            word: 'flow',
            meanings: [
              Meaning(partOfSpeech: 'noun', definitions: ['movement']),
            ],
          ),
          'movement': const DictionaryEntry(
            word: 'movement',
            meanings: [
              Meaning(partOfSpeech: 'noun', definitions: ['act of moving']),
            ],
          ),
          'moving': const DictionaryEntry(
            word: 'moving',
            meanings: [
              Meaning(partOfSpeech: 'adjective', definitions: ['in motion']),
            ],
          ),
        }),
      );
    final settings = SettingsService();
    addTearDown(provider.dispose);
    addTearDown(settings.dispose);

    await provider.lookupWord('flow');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReadingProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 360,
                height: 640,
                child: ReaderWordSidebar(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await _mouseHoverAndTapInlineText(tester, 'movement');
    await tester.pumpAndSettle();

    expect(provider.selectedWord, 'movement');
    expect(provider.selectedWordTranslation, 'act of moving');

    await _mouseHoverAndTapInlineText(tester, 'moving');
    await tester.pumpAndSettle();

    expect(provider.selectedWord, 'moving');
    expect(provider.selectedWordTranslation, 'in motion');
    expect(tester.takeException(), isNull);
  });

  testWidgets('ReaderWordSidebar back action restores previous lookup', (
    tester,
  ) async {
    final provider = ReadingProvider()
      ..setWordRepository(
        _MappedRepository({
          'flow': const DictionaryEntry(
            word: 'flow',
            meanings: [
              Meaning(partOfSpeech: 'noun', definitions: ['movement']),
            ],
          ),
          'movement': const DictionaryEntry(
            word: 'movement',
            meanings: [
              Meaning(partOfSpeech: 'noun', definitions: ['act of moving']),
            ],
          ),
        }),
      );
    final settings = SettingsService();
    addTearDown(provider.dispose);
    addTearDown(settings.dispose);

    await provider.lookupWord('flow');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReadingProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 360,
                height: 640,
                child: ReaderWordSidebar(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await _mouseHoverAndTapInlineText(tester, 'movement');
    await tester.pumpAndSettle();
    expect(provider.selectedWord, 'movement');

    await _mouseHoverAndTapText(tester, '返回上一个词条');
    await tester.pumpAndSettle();

    expect(provider.selectedWord, 'flow');
    expect(provider.selectedWordTranslation, 'movement');
    expect(find.text('flow'), findsOneWidget);
  });

  testWidgets('ReaderWordSidebar can move a known word back to learning', (
    tester,
  ) async {
    final vocab = UserVocabularyService(
      repository: _MemoryUserVocabularyRepository(),
    );
    await vocab.init();
    final provider = ReadingProvider()
      ..setUserVocabulary(vocab)
      ..setWordRepository(
        _MappedRepository({
          'flow': const DictionaryEntry(
            word: 'flow',
            meanings: [
              Meaning(partOfSpeech: 'noun', definitions: ['movement']),
            ],
          ),
        }),
      );
    final settings = SettingsService();
    addTearDown(provider.dispose);
    addTearDown(settings.dispose);

    await provider.lookupWord('flow');
    await provider.markWordKnown('flow');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReadingProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 360, height: 640, child: ReaderWordSidebar()),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('学习中'), findsNothing);
    expect(find.text('Unknown'), findsNothing);
    expect(provider.getWordStatus('flow'), UserWordStatus.known);
    await tester.tap(find.text('生词本'));
    await tester.pumpAndSettle();

    expect(provider.getWordStatus('flow'), UserWordStatus.learning);
    expect(find.text('生词本'), findsOneWidget);
  });

  testWidgets('DictionaryDetailView handles mouse hover before word click', (
    tester,
  ) async {
    var lookupWord = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DictionaryDetailView(
            word: 'flow',
            entry: const DictionaryEntry(
              word: 'flow',
              meanings: [
                Meaning(partOfSpeech: 'noun', definitions: ['movement']),
              ],
            ),
            primaryDefinition: null,
            isLoading: false,
            onLookupWord: (word) => lookupWord = word,
          ),
        ),
      ),
    );

    await _mouseHoverAndTapInlineText(tester, 'movement');
    await tester.pump();

    expect(lookupWord, 'movement');
  });

  testWidgets('DictionaryDetailView shows a clear previous-entry action', (
    tester,
  ) async {
    var wentBack = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DictionaryDetailView(
            word: 'movement',
            entry: const DictionaryEntry(
              word: 'movement',
              meanings: [
                Meaning(partOfSpeech: 'noun', definitions: ['act of moving']),
              ],
            ),
            primaryDefinition: 'act of moving',
            isLoading: false,
            canGoBack: true,
            onGoBack: () => wentBack = true,
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byIcon(Icons.arrow_back)).dx,
      lessThanOrEqualTo(tester.getTopLeft(find.text('movement')).dx),
    );

    await _mouseHoverAndTapText(tester, '返回上一个词条');
    await tester.pump();

    expect(wentBack, isTrue);
  });

  testWidgets('DictionaryContextBlock keeps source context compact', (
    tester,
  ) async {
    const contextText =
        'Opening notes describe the assignment, the research folder, and the '
        'drafting schedule before the paragraph eventually explains that the '
        'production log is intended to chart any obstacles and aims of the '
        'final report while the rest keeps expanding with unrelated detail.';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 260,
            child: DictionaryContextBlock(
              word: 'aims',
              contextText: contextText,
            ),
          ),
        ),
      ),
    );

    final plainContext = _contextPlainText(tester);

    expect(plainContext, contains('aims'));
    expect(plainContext.startsWith('...'), isTrue);
    expect(plainContext.length, lessThan(contextText.length));
  });

  testWidgets('DictionaryContextBlock highlights whole selected words', (
    tester,
  ) async {
    const contextText =
        'The production log is intended to end with notes. End result: the '
        'end of my research.';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: DictionaryContextBlock(
              word: 'end',
              contextText: contextText,
            ),
          ),
        ),
      ),
    );

    expect(_highlightedContextTexts(tester), ['end', 'End', 'end']);
    expect(_highlightedContextStarts(tester), [
      contextText.indexOf('end with'),
      contextText.indexOf('End result'),
      contextText.indexOf('end of'),
    ]);
  });

  testWidgets('DictionaryContextBlock anchors excerpt to selected token', (
    tester,
  ) async {
    const contextText =
        'The end near the opening should not decide the excerpt. '
        'Background notes keep expanding across the page with scheduling '
        'details, research questions, draft reminders, unrelated names, and '
        'several observations that make this context long enough to truncate. '
        'The selected phrase is the end of my research and it matters.';
    final selectedStart = contextText.indexOf('end of my research');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 260,
            child: DictionaryContextBlock(
              word: 'end',
              contextText: contextText,
              contextWordStart: selectedStart,
              contextWordEnd: selectedStart + 'end'.length,
            ),
          ),
        ),
      ),
    );

    final plainContext = _contextPlainText(tester);

    expect(plainContext, contains('end of my research'));
    expect(plainContext, isNot(contains('end near the opening')));
  });

  testWidgets('DictionaryContextBlock keeps selected token visibly in excerpt', (
    tester,
  ) async {
    const contextText =
        'The production log is intended to chart any obstacles you face in '
        'your research, your progress and the aims of your final report. My '
        'production log will have to be a little different because I am going '
        'to record all the research I do here, both relevant and irrelevant, '
        'because as yet I do not really know what my final report will be. '
        'This is starting to feel a little like a diary.';
    final selectedStart = contextText.indexOf('starting');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 260,
            child: DictionaryContextBlock(
              word: 'starting',
              contextText: contextText,
              contextWordStart: selectedStart,
              contextWordEnd: selectedStart + 'starting'.length,
            ),
          ),
        ),
      ),
    );

    expect(_contextPlainText(tester), contains('starting'));
    expect(_contextWordHasVisibleBoxes(tester, 'starting'), isTrue);
  });

  testWidgets(
    'ReaderWordSidebar keeps learning actions outside dictionary scroll',
    (tester) async {
      final provider = ReadingProvider()
        ..setWordRepository(
          _MappedRepository({
            'flow': DictionaryEntry(
              word: 'flow',
              meanings: [
                Meaning(
                  partOfSpeech: 'noun',
                  definitions: List.generate(
                    24,
                    (index) =>
                        'definition $index with enough detail to require scrolling',
                  ),
                ),
              ],
            ),
          }),
        );
      final settings = SettingsService();
      addTearDown(provider.dispose);
      addTearDown(settings.dispose);

      await provider.lookupWord(
        'flow',
        contextText: 'Ideas flow clearly in this paragraph.',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ReadingProvider>.value(value: provider),
            ChangeNotifierProvider<SettingsService>.value(value: settings),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 360,
                  height: 640,
                  child: ReaderWordSidebar(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final sidebarBottom = tester
          .getBottomLeft(find.byType(ReaderWordSidebar))
          .dy;
      final contextTopBefore = tester.getTopLeft(find.text('原文语境')).dy;
      final learningActionBottomBefore = tester
          .getBottomLeft(find.text('生词本'))
          .dy;

      final segmentedButton = tester.widget<SegmentedButton<dynamic>>(
        find.byWidgetPredicate((widget) => widget is SegmentedButton<dynamic>),
      );

      expect(find.text('操作'), findsNothing);
      expect(
        segmentedButton.style?.mouseCursor?.resolve({WidgetState.hovered}),
        SystemMouseCursors.click,
      );
      expect(find.text('学习状态'), findsNothing);
      expect(find.text('学习中'), findsNothing);
      expect(find.text('AI 详解这个词'), findsNothing);
      expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
      expect(_hasTopShadow(tester), isTrue);
      expect(learningActionBottomBefore, lessThanOrEqualTo(sidebarBottom));

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -260),
      );
      await tester.pump();

      expect(tester.getTopLeft(find.text('原文语境')).dy, contextTopBefore);
      expect(
        tester.getBottomLeft(find.text('生词本')).dy,
        learningActionBottomBefore,
      );
    },
  );

  testWidgets('ReaderWordSidebar AI context card supports IPA and speech', (
    tester,
  ) async {
    final provider = _AIAnalysisReadingProvider();
    final settings = _AIEnabledSettingsService();
    addTearDown(provider.dispose);
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReadingProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 360, height: 640, child: ReaderWordSidebar()),
          ),
        ),
      ),
    );
    await tester.pump();

    final aiButton = tester.widget<IconButton>(
      find
          .ancestor(
            of: find.byIcon(Icons.auto_awesome_outlined),
            matching: find.byType(IconButton),
          )
          .first,
    );
    expect(
      aiButton.style?.overlayColor?.resolve({WidgetState.hovered}),
      isNotNull,
    );
    expect(
      aiButton.style?.mouseCursor?.resolve({WidgetState.hovered}),
      SystemMouseCursors.click,
    );

    await tester.tap(find.byIcon(Icons.auto_awesome_outlined));
    await tester.pumpAndSettle();

    final phoneticText = tester.widget<Text>(find.text('/ˈkwɪkənd/'));
    expect(phoneticText.style?.fontFamily, 'Lucida Grande');
    expect(
      phoneticText.style?.fontFamilyFallback,
      contains('Arial Unicode MS'),
    );

    await tester.tap(find.byTooltip('播放发音').last);
    await tester.pumpAndSettle();

    expect(provider.spokenWords, ['quicken']);
  });

  test('ReadingProvider reuses cached word AI analysis', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'flow_read_word_ai_cache_',
    );
    final settings = _AIEnabledSettingsService();
    final aiService = _CountingAIService(settings);
    final cache = AICacheService(
      documentsDirectoryProvider: () async => tempDir,
    );
    await cache.init();
    final provider = _AIWordCacheReadingProvider()
      ..setSettings(settings)
      ..setAIService(aiService)
      ..setAICache(cache);

    addTearDown(provider.dispose);
    addTearDown(settings.dispose);
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    await provider.analyzeWordAI(
      'quicken',
      'The footsteps quickened in the hallway.',
    );
    final first = provider.aiWordAnalysis;

    await provider.analyzeWordAI(
      'quicken',
      'The footsteps quickened in the hallway.',
    );

    expect(aiService.wordAnalysisCalls, 1);
    expect(
      provider.aiWordAnalysis?.meanings.single.meaning,
      first?.meanings.single.meaning,
    );
    expect(provider.isAnalyzingWord, isFalse);
  });

  test('ReadingProvider delegates word pronunciation to service', () async {
    final pronunciation = _FakePronunciationService();
    final provider = ReadingProvider()..setPronunciationService(pronunciation);

    await provider.speakWord('flow');

    expect(pronunciation.spokenWords, ['flow']);
    provider.dispose();
  });
}

class _CountingRepository implements WordRepository {
  final DictionaryEntry? entry;
  int calls = 0;

  _CountingRepository(this.entry);

  @override
  Future<DictionaryEntry?> lookup(String word) async {
    calls += 1;
    return entry;
  }
}

class _MappedRepository implements WordRepository {
  final Map<String, DictionaryEntry> entries;

  _MappedRepository(this.entries);

  @override
  Future<DictionaryEntry?> lookup(String word) async {
    return entries[word.toLowerCase().trim()];
  }
}

class _MemoryUserVocabularyRepository implements UserVocabularyRepository {
  final Map<String, UserWordStatus> _storage = {};

  @override
  Future<void> init() async {}

  @override
  UserWordStatus? getStatus(String word) {
    return _storage[word.toLowerCase().trim()];
  }

  @override
  Set<String> wordsWithStatus(UserWordStatus status) {
    return _storage.entries
        .where((entry) => entry.value == status)
        .map((entry) => entry.key)
        .toSet();
  }

  @override
  Map<String, UserWordStatus> get allWords => Map.unmodifiable(_storage);

  @override
  Future<void> setStatus(String word, UserWordStatus status) async {
    _storage[word.toLowerCase().trim()] = status;
  }

  @override
  Future<void> remove(String word) async {
    _storage.remove(word.toLowerCase().trim());
  }

  @override
  Future<void> close() async {}
}

class _AIEnabledSettingsService extends SettingsService {
  @override
  bool get aiFeaturesEnabled => true;

  @override
  String get aiFeatureDisabledReason => '';

  @override
  Future<void> incrementAIUsage({
    bool chapterSummary = false,
    bool textAnalysis = false,
    bool practice = false,
    bool wordAnalysis = false,
  }) async {}
}

class _AIAnalysisReadingProvider extends ReadingProvider {
  final spokenWords = <String>[];
  WordAnalysis? _analysis;

  @override
  String? get selectedWord => 'quicken';

  @override
  String? get selectedWordTranslation => '加快，加速';

  @override
  String? get selectedWordContext =>
      '...haunted house people’s footsteps quickened as they walked by...';

  @override
  DictionaryEntry? get selectedWordEntry => const DictionaryEntry(
    word: 'quicken',
    meanings: [
      Meaning(partOfSpeech: 'verb', definitions: ['加快，加速']),
    ],
  );

  @override
  bool get aiFeaturesEnabled => true;

  @override
  bool get canPronounceWords => true;

  @override
  WordAnalysis? get aiWordAnalysis => _analysis;

  @override
  Future<void> analyzeWordAI(String word, String sentence) async {
    _analysis = const WordAnalysis(
      pronunciation: '/ˈkwɪkənd/',
      meanings: [
        ContextualMeaning(meaning: '加快，加速', explanation: '这里描述脚步在语境中变快。'),
      ],
      usageTips: ['常用于描述心跳、步伐、节奏等加快。'],
      memoryTip: '',
    );
    notifyListeners();
  }

  @override
  Future<void> speakWord(String word) async {
    spokenWords.add(word);
  }
}

class _AIWordCacheReadingProvider extends ReadingProvider {
  @override
  String? get activeBookId => 'book-one';

  @override
  int get currentChapter => 2;

  @override
  AnalysisResult? get result => const AnalysisResult(
    passageText: 'The footsteps quickened in the hallway.',
    title: 'Chapter',
    vocabulary: [],
    knownWords: {},
    learningWords: {},
    syntaxPatterns: [],
    comprehension: Comprehension(
      whatHappened: '',
      whyHappened: '',
      implicitMeaning: '',
    ),
    practice: [],
    difficulty: Difficulty(vocab: 0, syntax: 0, inference: 0, explanation: ''),
  );
}

class _CountingAIService extends AIService {
  int wordAnalysisCalls = 0;

  _CountingAIService(SettingsService settings) : super(LLMClient(settings));

  @override
  int get promptVersion => 99;

  @override
  Future<WordAnalysis> analyzeWord({
    required String word,
    required String sentence,
    required String chapterContext,
    SourceLanguage? sourceLanguage,
    OutputLanguage outputLanguage = OutputLanguage.zhHans,
    SpoilerBoundary? spoilerBoundary,
  }) async {
    wordAnalysisCalls += 1;
    return WordAnalysis(
      pronunciation: '/ˈkwɪkənd/',
      meanings: [
        ContextualMeaning(
          meaning: 'cached meaning $wordAnalysisCalls',
          explanation: sentence,
        ),
      ],
      usageTips: const ['cache me'],
      memoryTip: '',
    );
  }
}

bool _hasTopShadow(WidgetTester tester) {
  for (final container in tester.widgetList<Container>(
    find.byType(Container),
  )) {
    final decoration = container.decoration;
    if (decoration is BoxDecoration &&
        decoration.boxShadow?.any((shadow) => shadow.offset.dy < 0) == true) {
      return true;
    }
  }
  return false;
}

TextSpan _findTextSpan(WidgetTester tester, String text) {
  for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
    final span = _findSpan(richText.text, text);
    if (span != null) return span;
  }
  throw StateError('Text span not found: $text');
}

TextSpan? _findSpan(InlineSpan span, String text) {
  if (span is! TextSpan) return null;
  if (span.text == text) return span;
  final children = span.children;
  if (children == null) return null;
  for (final child in children) {
    final found = _findSpan(child, text);
    if (found != null) return found;
  }
  return null;
}

String _contextPlainText(WidgetTester tester) {
  return (_contextTextWidget(tester).textSpan! as TextSpan).toPlainText();
}

Text _contextTextWidget(WidgetTester tester) {
  return tester.widget<Text>(
    find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.textSpan != null &&
          widget.maxLines == 4 &&
          widget.overflow == TextOverflow.ellipsis,
    ),
  );
}

List<String> _highlightedContextTexts(WidgetTester tester) {
  final textWidget = _contextTextWidget(tester);
  final highlights = <String>[];
  _collectHighlightedText(textWidget.textSpan!, highlights);
  return highlights;
}

List<int> _highlightedContextStarts(WidgetTester tester) {
  final textWidget = _contextTextWidget(tester);
  final starts = <int>[];
  var offset = 0;
  _collectHighlightedStarts(
    textWidget.textSpan!,
    starts,
    () => offset,
    (value) => offset = value,
  );
  return starts;
}

bool _contextWordHasVisibleBoxes(WidgetTester tester, String word) {
  final richText = tester
      .widgetList<RichText>(find.byType(RichText))
      .firstWhere((widget) => widget.text.toPlainText().contains(word));
  final richTextFinder = find.byWidget(richText);
  final renderParagraph = tester.renderObject<RenderParagraph>(richTextFinder);
  final plainText = richText.text.toPlainText();
  final start = plainText.indexOf(word);
  final boxes = renderParagraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: start + word.length),
  );
  return boxes.isNotEmpty;
}

void _collectHighlightedText(InlineSpan span, List<String> highlights) {
  if (span is! TextSpan) return;
  if (span.style?.fontWeight == FontWeight.w800 && span.text != null) {
    highlights.add(span.text!);
  }
  for (final child in span.children ?? const <InlineSpan>[]) {
    _collectHighlightedText(child, highlights);
  }
}

void _collectHighlightedStarts(
  InlineSpan span,
  List<int> starts,
  int Function() getOffset,
  void Function(int value) setOffset,
) {
  if (span is! TextSpan) return;

  final text = span.text;
  if (text != null) {
    if (span.style?.fontWeight == FontWeight.w800) {
      starts.add(getOffset());
    }
    setOffset(getOffset() + text.length);
  }

  for (final child in span.children ?? const <InlineSpan>[]) {
    _collectHighlightedStarts(child, starts, getOffset, setOffset);
  }
}

Future<void> _tapInlineText(WidgetTester tester, String text) async {
  await tester.tapAt(_inlineTextCenter(tester, text));
}

Future<void> _mouseHoverAndTapInlineText(
  WidgetTester tester,
  String text,
) async {
  final target = _inlineTextCenter(tester, text);
  await _mouseTapAt(tester, target);
}

Future<void> _mouseHoverAndTapText(WidgetTester tester, String text) async {
  await _mouseTapAt(tester, tester.getCenter(find.text(text)));
}

Future<void> _mouseTapAt(WidgetTester tester, Offset target) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: target);
  await tester.pump();
  await gesture.down(target);
  await tester.pump();
  await gesture.up();
  await gesture.removePointer();
}

Offset _inlineTextCenter(WidgetTester tester, String text) {
  final richTextFinder = find
      .byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().contains(text),
      )
      .first;
  final renderParagraph = tester.renderObject<RenderParagraph>(richTextFinder);
  final plainText = renderParagraph.text.toPlainText();
  final start = plainText.indexOf(text);
  final boxes = renderParagraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: start + text.length),
  );

  if (boxes.isEmpty) {
    throw StateError('Text selection box not found: $text');
  }

  return renderParagraph.localToGlobal(boxes.first.toRect().center);
}

class _ThrowingRepository implements WordRepository {
  const _ThrowingRepository();

  @override
  Future<DictionaryEntry?> lookup(String word) async {
    throw Exception('network down');
  }
}

class _MemoryDictionaryCacheRepository implements DictionaryCacheRepository {
  final Map<String, String> _storage = {};

  @override
  Future<void> init() async {}

  @override
  String? get(String key) => _storage[key];

  @override
  Future<void> put(String key, String content) async {
    _storage[key] = content;
  }

  @override
  bool containsKey(String key) => _storage.containsKey(key);

  @override
  int get length => _storage.length;

  @override
  Iterable<dynamic> get keys => _storage.keys;

  @override
  Future<void> delete(dynamic key) async {
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }

  @override
  Future<void> close() async {}
}

class _FakePronunciationService implements PronunciationService {
  final spokenWords = <String>[];

  @override
  Future<void> speakWord(String word) async {
    spokenWords.add(word);
  }

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}

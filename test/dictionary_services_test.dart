import 'dart:convert';
import 'dart:io';

import 'package:flow_read/models/word_context_example.dart';
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/services/dictionary/collins_repository.dart';
import 'package:flow_read/storage/repositories/dictionary_cache_repository.dart';
import 'package:flow_read/services/dictionary/dictionary_cache_service.dart';
import 'package:flow_read/services/dictionary/dictionary_manager_service.dart';
import 'package:flow_read/services/dictionary/dictionary_repository.dart';
import 'package:flow_read/services/dictionary/dictionary_source_config.dart';
import 'package:flow_read/services/dictionary/longman_repository.dart';
import 'package:flow_read/services/pronunciation_service.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/services/dictionary/word_repository.dart';
import 'package:flow_read/services/dictionary/wordnet_repository.dart';
import 'package:flow_read/widgets/dictionary_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
      await openSettingsTestBox();
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

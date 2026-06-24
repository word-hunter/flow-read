import 'dart:convert';
import 'dart:io';

import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/test_storage.dart';

void main() {
  late Directory tempDir;
  late SettingsService settings;
  late AICacheService cacheService;
  late BookInsightRepository repository;

  setUp(() async {
    tempDir = await initTestStorage('flow_read_book_synthesis_service_');
    await openFlowReadTestStorage();
    settings = await createTestSettingsService();
    await settings.setAIProvider('openai_compatible');
    await settings.setAIBaseUrl('https://llm.example.com/v1');
    await settings.setAIModel('reader-model');
    await settings.setApiKey('test-key');
    cacheService = AICacheService(
      documentsDirectoryProvider: () async => tempDir,
    );
    await cacheService.init();
    repository = BookInsightRepository(cacheService: cacheService);
  });

  tearDown(() async {
    await disposeTestStorage(tempDir);
  });

  test('generates synthesis through AI and reuses cached result', () async {
    var requestCount = 0;
    final service = _service(
      settings: settings,
      repository: repository,
      handler: (request) async {
        requestCount += 1;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['response_format'], {'type': 'json_object'});
        final messages = body['messages'] as List<dynamic>;
        expect(messages.first['content'], contains('Reduce stage'));
        expect(messages.last['content'], contains('AnalysisScope'));
        return _chatResponse({
          'fullStoryline': 'Alice follows the rabbit.',
          'characterGraph': {
            'nodes': [
              {'id': 'alice', 'label': 'Alice'},
            ],
            'edges': [],
          },
          'bookMindMap': {
            'root': {'id': 'root', 'label': 'Wonderland', 'children': []},
          },
          'structure': 'Opening movement.',
          'themeAnalysis': 'Curiosity.',
          'keyInsights': ['Watch repeated doors.'],
        });
      },
    );

    final request = BookSynthesisRequest(
      analysisData: _analysisData(),
      bookTitle: 'Wonderland',
      chapterSummaries: [
        BookSynthesisChapterSummary(
          chapterIndex: 0,
          title: 'Down the Rabbit-Hole',
          summary: 'Alice follows a rabbit.',
        ),
      ],
    );

    final first = await service.synthesize(request);
    expect(first.fullStoryline, contains('rabbit'));
    expect(requestCount, 1);

    final cachedService = _service(
      settings: settings,
      repository: repository,
      handler: (_) async => fail('cached synthesis should not call AI'),
    );
    final cached = await cachedService.synthesize(request);

    expect(cached.fullStoryline, first.fullStoryline);
    expect(requestCount, 1);
  });

  test('downgrades prompt payload when input exceeds budget', () async {
    final service = _service(
      settings: settings,
      repository: repository,
      handler: (request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final messages = body['messages'] as List<dynamic>;
        final userPrompt = messages.last['content'] as String;
        expect(userPrompt, contains('"budget_downgraded":true'));
        expect(userPrompt, contains('Character 0'));
        expect(userPrompt, isNot(contains('Character 29')));
        return _chatResponse({
          'fullStoryline': 'Budgeted synthesis.',
          'characterGraph': {'nodes': [], 'edges': []},
          'bookMindMap': {
            'root': {'id': 'root', 'label': 'Budget', 'children': []},
          },
          'keyInsights': ['Trimmed safely.'],
        });
      },
    );

    final result = await service.synthesize(
      BookSynthesisRequest(
        analysisData: _largeAnalysisData(),
        bookTitle: 'Long Book',
        chapterSummaries: List.generate(
          60,
          (index) => BookSynthesisChapterSummary(
            chapterIndex: index,
            summary: 'Chapter $index contains a long but structured summary.',
          ),
        ),
        maxInputCharacters: 1200,
        reservedOutputCharacters: 0,
      ),
    );

    expect(result.fullStoryline, 'Budgeted synthesis.');
  });

  test('uses repair prompt before fallback for malformed AI JSON', () async {
    var requestCount = 0;
    final service = _service(
      settings: settings,
      repository: repository,
      handler: (request) async {
        requestCount += 1;
        if (requestCount == 1) {
          return _chatContent('not json');
        }
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final messages = body['messages'] as List<dynamic>;
        expect(messages.first['content'], contains('repair malformed JSON'));
        return _chatResponse({'fullStoryline': 'Repaired by model.'});
      },
    );

    final result = await service.synthesize(
      BookSynthesisRequest(
        analysisData: _analysisData(),
        bookTitle: 'Wonderland',
        useCache: false,
      ),
    );

    expect(requestCount, 2);
    expect(result.fullStoryline, 'Repaired by model.');
  });

  test(
    'returns fallback result when response and repair are malformed',
    () async {
      final service = _service(
        settings: settings,
        repository: repository,
        handler: (_) async => _chatContent('still not json'),
      );

      final result = await service.synthesize(
        BookSynthesisRequest(
          analysisData: _analysisData(),
          bookTitle: 'Wonderland',
          useCache: false,
        ),
      );

      expect(result.fullStoryline, contains('still not json'));
      expect(result.characterGraph.nodes, isEmpty);
    },
  );
}

BookSynthesisService _service({
  required SettingsService settings,
  required BookInsightRepository repository,
  required Future<http.Response> Function(http.Request request) handler,
}) {
  final aiService = AIService(
    LLMClient(() => settings.aiProviderConfig, httpClient: MockClient(handler)),
  );
  return BookSynthesisService(
    aiService: aiService,
    repository: repository,
    clock: () => DateTime.utc(2026, 6, 24, 10),
  );
}

http.Response _chatResponse(Map<String, dynamic> content) {
  return _chatContent(jsonEncode(content));
}

http.Response _chatContent(String content) {
  return http.Response(
    jsonEncode({
      'choices': [
        {
          'message': {'content': content},
        },
      ],
    }),
    200,
  );
}

BookAnalysisData _analysisData() {
  return BookAnalysisData(
    bookId: 'book-1',
    scope: AnalysisScope.readSoFar(bookId: 'book-1', currentChapterIndex: 2),
    characters: [
      CharacterCard(
        canonicalName: 'Alice',
        traits: const ['curious'],
        actions: const ['follows the rabbit'],
        firstChapter: 0,
        lastChapter: 2,
        activeChapters: const {0, 1, 2},
      ),
    ],
    storyEvents: [
      StoryEvent(
        description: 'Alice follows a rabbit.',
        participants: const ['Alice'],
        chapterIndex: 0,
      ),
    ],
    themes: const ['curiosity'],
    coverage: 0.75,
    schemaVersion: BookAnalysisAggregator.schemaVersion,
    analyzedAt: DateTime.utc(2026, 6, 24),
  );
}

BookAnalysisData _largeAnalysisData() {
  return BookAnalysisData(
    bookId: 'book-large',
    scope: AnalysisScope.fullBook(bookId: 'book-large', totalChapters: 60),
    characters: List.generate(
      30,
      (index) => CharacterCard(
        canonicalName: 'Character $index',
        actions: [
          'Action $index a',
          'Action $index b',
          'Action $index c',
          'Action $index d',
        ],
        firstChapter: index,
        lastChapter: index + 1,
        activeChapters: {index, index + 1},
      ),
    ),
    storyEvents: List.generate(
      100,
      (index) => StoryEvent(
        description: 'Event $index changes the direction of the plot.',
        chapterIndex: index,
      ),
    ),
    locations: List.generate(
      20,
      (index) => LocationNode(name: 'Location $index', chapters: {index}),
    ),
    themes: List.generate(20, (index) => 'Theme $index'),
    coverage: 1.0,
    schemaVersion: BookAnalysisAggregator.schemaVersion,
    analyzedAt: DateTime.utc(2026, 6, 24),
  );
}

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

  setUp(() async {
    tempDir = await initTestStorage('flow_read_ai_action_test_');
    await openFlowReadTestStorage();
    settings = await createTestSettingsService();
    await settings.setAIProvider('openai_compatible');
    await settings.setAIBaseUrl('https://llm.example.com/v1');
    await settings.setAIModel('reader-model');
    await settings.setApiKey('test-key');
  });

  tearDown(() async {
    await disposeTestStorage(tempDir);
  });

  test('AIActionController enqueues prompt and stores typed result', () async {
    final service = _service(settings, (request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['response_format'], isNull);
      return _chatResponse('译文');
    });
    final controller = AIActionController(aiService: service);
    addTearDown(controller.dispose);

    await controller.enqueue(_prompt(), AIAssistantActionType.translate);

    expect(controller.isBusy, isFalse);
    expect(controller.currentAction, isNull);
    final result = controller.lastResult;
    if (result is AIErrorResult) fail(result.message);
    expect(result, isA<AITranslateResult>());
    expect((result as AITranslateResult).translation, '译文');
  });

  test('AIActionController retries the previous prompt', () async {
    var count = 0;
    final service = _service(settings, (_) async {
      count += 1;
      return _chatResponse('response-$count');
    });
    final controller = AIActionController(aiService: service);
    addTearDown(controller.dispose);

    await controller.enqueue(_prompt(), AIAssistantActionType.articleQA);
    await controller.retry();

    expect(count, 2);
    expect((controller.lastResult as AIArticleQAResult).answer, 'response-2');
  });

  test(
    'AIActionController reuses cached action result until retry',
    () async {
      var count = 0;
      final service = _service(settings, (_) async {
        count += 1;
        return _chatResponse('译文-$count');
      });
      final traceDir = Directory('${tempDir.path}/ai_debug');
      final recorder = AIDebugTraceRecorder(
        enabled: true,
        directoryProvider: () async => traceDir,
        clock: () => DateTime(2026, 6, 13, 9, 45),
      );
      final controller = AIActionController(
        aiService: service,
        cacheService: AICacheService(
          documentsDirectoryProvider: () async => tempDir,
        ),
        debugRecorder: recorder,
      );
      addTearDown(controller.dispose);

      await controller.enqueue(_prompt(), AIAssistantActionType.translate);
      expect(count, 1);
      expect((controller.lastResult as AITranslateResult).translation, '译文-1');

      await controller.enqueue(_prompt(), AIAssistantActionType.translate);
      expect(count, 1);
      expect((controller.lastResult as AITranslateResult).translation, '译文-1');
      await recorder.drain();
      final traceFile = File(
        '${traceDir.path}/flow_read_ai_trace-2026-06-13.jsonl',
      );
      final entry =
          jsonDecode((await traceFile.readAsLines()).single)
              as Map<String, dynamic>;
      expect(entry['event'], 'cache_hit');
      expect(entry['action'], 'translate');
      expect(entry['response'], '译文-1');

      await controller.retry();
      expect(count, 2);
      expect((controller.lastResult as AITranslateResult).translation, '译文-2');
    },
  );

  test(
    'AIAssistantController routes current context through registry',
    () async {
      final service = _service(settings, (request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['messages'].last['content'], contains('Selected Text'));
        return _chatResponse(
          jsonEncode({
            'translation': '译文',
            'structure_notes': [
              {
                'source': 'The door opened.',
                'role': 'main clause',
                'explanation': '主句说明发生的动作。',
              },
            ],
          }),
        );
      });
      final actionController = AIActionController(aiService: service);
      final assistant = AIAssistantController(
        registry: const AIAssistantActionRegistry(
          promptBuilder: PromptBuilder(),
        ),
        automationSettings: const AIAutomationSettings(),
        insightProfile: const ReadingInsightProfile(),
        actionController: actionController,
      );
      addTearDown(actionController.dispose);
      addTearDown(assistant.dispose);

      assistant.setContext(
        AIContextSnapshot(
          source: AIContextSource.readerSelectedText,
          selectedText: 'The door opened.',
          surroundingPassage: 'The door opened slowly.',
        ),
      );

      expect(assistant.recentSessions, isEmpty);
      expect(
        assistant.availableActions,
        contains(AIAssistantActionType.explain),
      );

      await assistant.executeAction(AIAssistantActionType.explain);

      final result = actionController.lastResult;
      if (result is AIErrorResult) fail(result.message);
      expect(result, isA<AITextAnalysisResult>());
      final analysis = (result as AITextAnalysisResult).analysis;
      expect(analysis.translation, '译文');
      expect(analysis.structureNotes.single.role, 'main clause');
      expect(assistant.currentSession?.messages, hasLength(1));
      expect(
        assistant.currentSession?.messages.single.citations.single.label,
        '选中文本',
      );
    },
  );

  test('AIAssistantController appends follow-up messages to session', () async {
    final service = _service(settings, (_) async => _chatResponse('answer'));
    final actionController = AIActionController(aiService: service);
    final assistant = AIAssistantController(
      registry: const AIAssistantActionRegistry(
        promptBuilder: PromptBuilder(),
      ),
      automationSettings: const AIAutomationSettings(),
      insightProfile: const ReadingInsightProfile(),
      actionController: actionController,
    );
    addTearDown(actionController.dispose);
    addTearDown(assistant.dispose);

    assistant.setContext(
      AIContextSnapshot(
        source: AIContextSource.readerSelectedText,
        selectedText: 'The door opened.',
        surroundingPassage: 'The door opened slowly.',
      ),
    );

    await assistant.executeAction(
      AIAssistantActionType.chat,
      followUpQuestion: 'Why slowly?',
    );

    final messages = assistant.currentSession?.messages;
    expect(messages, hasLength(2));
    expect(messages?.first.role, AIChatMessageRole.user);
    expect(messages?.first.content, 'Why slowly?');
    expect(messages?.last.role, AIChatMessageRole.assistant);
    expect(messages?.last.content, 'answer');
    expect(assistant.recentSessions, hasLength(1));
  });

  test('AIActionController maps client errors to retryable result', () async {
    final service = _service(
      settings,
      (_) async => http.Response('unauthorized', 401),
    );
    final controller = AIActionController(aiService: service);
    addTearDown(controller.dispose);

    await controller.enqueue(_prompt(), AIAssistantActionType.translate);

    final result = controller.lastResult;
    expect(result, isA<AIErrorResult>());
    expect((result as AIErrorResult).isRetryable, isFalse);
  });
}

AIService _service(
  SettingsService settings,
  Future<http.Response> Function(http.Request) handler,
) {
  return AIService(
    LLMClient(() => settings.aiProviderConfig, httpClient: MockClient(handler)),
  );
}

PromptBuildResult _prompt() {
  return const PromptBuildResult(
    systemPrompt: 'system',
    userPrompt: 'user',
    promptVersion: 1,
    sourceLanguage: SourceLanguage.english,
    outputLanguage: OutputLanguage.zhHans,
    spoilerBoundary: SpoilerBoundary(
      bookId: 'book-1',
      currentUnitId: 'current_passage',
      maxReadUnitOrder: 0,
      unitType: 'passage',
      scope: AIContextScope.currentPassage,
    ),
  );
}

http.Response _chatResponse(String content) {
  return http.Response.bytes(
    utf8.encode(
      jsonEncode({
        'choices': [
          {
            'message': {'content': content},
          },
        ],
      }),
    ),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

import 'dart:convert';
import 'dart:io';

import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/hive_test_storage.dart';

void main() {
  late Directory tempDir;
  late SettingsService settings;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_llm_test_');
    await openFlowReadTestBoxes();
    settings = await createTestSettingsService();
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test('chat uses the selected OpenAI-compatible provider config', () async {
    await settings.setAIProvider('openai_compatible');
    await settings.setAIBaseUrl('https://llm.example.com/v1/');
    await settings.setAIModel('reader-model');
    await settings.setApiKey('test-key');

    final client = LLMClient(
      () => settings.aiProviderConfig,
      httpClient: MockClient((request) async {
        expect(
          request.url.toString(),
          'https://llm.example.com/v1/chat/completions',
        );
        expect(request.headers['Authorization'], 'Bearer test-key');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['model'], 'reader-model');
        expect(body['stream'], isFalse);
        expect(body['response_format'], {'type': 'json_object'});
        expect(body['messages'], hasLength(2));

        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': '{"ok":true}'},
              },
            ],
          }),
          200,
        );
      }),
    );

    final response = await client.chat(
      systemPrompt: 'system',
      userPrompt: 'user',
      jsonMode: true,
    );

    expect(response, '{"ok":true}');
  });

  test('chat fails fast when the selected provider has no API key', () async {
    final client = LLMClient(
      () => settings.aiProviderConfig,
      httpClient: MockClient((_) async {
        fail('request should not be sent without an API key');
      }),
    );

    expect(
      () => client.chat(systemPrompt: 'system', userPrompt: 'user'),
      throwsA(isA<AIClientException>()),
    );
  });

  test(
    'chat writes AI debug trace with full prompt and redacted key',
    () async {
      await settings.setAIProvider('openai_compatible');
      await settings.setAIBaseUrl('https://llm.example.com/v1/');
      await settings.setAIModel('reader-model');
      await settings.setApiKey('sk-secret-token-value');

      final traceDir = Directory('${tempDir.path}/ai_debug');
      final recorder = AIDebugTraceRecorder(
        enabled: true,
        directoryProvider: () async => traceDir,
        clock: () => DateTime(2026, 6, 13, 9, 30),
      );
      final client = LLMClient(
        () => settings.aiProviderConfig,
        debugRecorder: recorder,
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': '完整响应'},
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final response = await client.chat(
        systemPrompt: 'system prompt',
        userPrompt: 'user prompt',
        jsonMode: true,
        debugMetadata: {'action': 'explain'},
      );
      await recorder.drain();

      expect(response, '完整响应');
      final traceFile = File(
        '${traceDir.path}/flow_read_ai_trace-2026-06-13.jsonl',
      );
      final entry =
          jsonDecode((await traceFile.readAsLines()).single)
              as Map<String, dynamic>;
      final request = entry['request'] as Map<String, dynamic>;
      final requestHeaders = request['headers'] as Map<String, dynamic>;
      final requestBody = request['body'] as Map<String, dynamic>;
      final responseTrace = entry['response'] as Map<String, dynamic>;
      final metadata = entry['metadata'] as Map<String, dynamic>;

      expect(entry['event'], 'http_interaction');
      expect(entry['operation'], 'chat');
      expect(entry['statusCode'], 200);
      expect(requestHeaders['Authorization'], '<redacted>');
      expect(jsonEncode(entry), isNot(contains('sk-secret-token-value')));
      expect(requestBody['model'], 'reader-model');
      expect(requestBody['messages'], [
        {'role': 'system', 'content': 'system prompt'},
        {'role': 'user', 'content': 'user prompt'},
      ]);
      expect(responseTrace['body'], contains('完整响应'));
      expect(metadata['action'], 'explain');
      expect(metadata['providerId'], 'openai_compatible');
    },
  );
}

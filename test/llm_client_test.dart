import 'dart:convert';
import 'dart:io';

import 'package:flow_read/services/llm_client.dart';
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
    await openSettingsTestBox();
    settings = SettingsService();
    await settings.init();
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
      settings,
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
      settings,
      httpClient: MockClient((_) async {
        fail('request should not be sent without an API key');
      }),
    );

    expect(
      () => client.chat(systemPrompt: 'system', userPrompt: 'user'),
      throwsA(isA<AIClientException>()),
    );
  });
}

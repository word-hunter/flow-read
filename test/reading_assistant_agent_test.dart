import 'dart:convert';
import 'dart:io';

import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/test_storage.dart';

void main() {
  late Directory tempDir;
  late SettingsService settings;

  setUp(() async {
    tempDir = await initTestStorage('flow_read_agent_test_');
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

  test(
    'summarize sends browser reading context to the configured model',
    () async {
      final client = LLMClient(
        () => settings.aiProviderConfig,
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['model'], 'reader-model');
          final messages = body['messages'] as List<dynamic>;
          expect(
            messages.first['content'],
            contains('EPUB, RSS, and web pages'),
          );
          expect(messages.last['content'], contains('Browser'));
          expect(messages.last['content'], contains('Readable Title'));
          expect(
            messages.last['content'],
            contains('https://example.com/story'),
          );
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'summary'},
                },
              ],
            }),
            200,
          );
        }),
      );

      final agent = ReadingAssistantAgent(client);
      final result = await agent.summarize(
        const ReadingAssistantContext(
          surface: ReadingAssistantSurface.browser,
          title: 'Readable Title',
          text: 'The page content.',
          url: 'https://example.com/story',
        ),
      );

      expect(result, 'summary');
    },
  );
}

import 'dart:convert';
import 'dart:io';

import 'package:flow_read/services/ai_service.dart';
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
    tempDir = await initHiveTestStorage('flow_read_ai_service_test_');
    await openFlowReadTestBoxes();
    settings = SettingsService();
    await settings.init();
    await settings.setAIProvider('openai_compatible');
    await settings.setAIBaseUrl('https://llm.example.com/v1');
    await settings.setAIModel('reader-model');
    await settings.setApiKey('test-key');
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test(
    'selected text analysis falls back to raw text for non-json response',
    () async {
      final client = LLMClient(
        settings,
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['response_format'], {'type': 'json_object'});
          final messages = body['messages'] as List<dynamic>;
          expect(messages.first['content'], contains('Spoiler boundary'));
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'This is useful but not JSON.'},
                },
              ],
            }),
            200,
          );
        }),
      );

      final service = AIService(client);
      final result = await service.analyzeText(
        selectedText: 'Alice opened the door.',
        currentPassage: 'Alice opened the door.',
      );

      expect(result.translation, contains('非结构化内容'));
      expect(result.translation, contains('This is useful but not JSON.'));
      expect(result.isEmpty, isFalse);
    },
  );

  test('chapter preview uses json mode and parses preview response', () async {
    final client = LLMClient(
      settings,
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['response_format'], {'type': 'json_object'});
        final messages = body['messages'] as List<dynamic>;
        expect(messages.first['content'], contains('pre-reading preview'));
        expect(messages.last['content'], contains('Opening Excerpt Only'));
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'setup': 'Notice the room before judging the scene.',
                    'focus_points': ['Watch who speaks first.'],
                    'vocabulary_hints': ['threshold: doorway'],
                    'spoiler_boundary_note':
                        'Only the opening excerpt is used.',
                  }),
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    final service = AIService(client);
    final preview = await service.generateChapterPreview(
      chapterTitle: 'A Room',
      openingText: 'Alice stood on the threshold.',
      vocabulary: const ['threshold'],
    );

    expect(preview.setup, contains('room'));
    expect(preview.focusPoints, contains('Watch who speaks first.'));
    expect(preview.vocabularyHints, contains('threshold: doorway'));
  });
}

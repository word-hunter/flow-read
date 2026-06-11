import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/widgets/ai_assistant_panel.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/hive_test_storage.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late SettingsService settings;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_panel_test_');
    await openFlowReadTestBoxes();
    settings = await createTestSettingsService();
    await settings.setAIProvider('openai_compatible');
    await settings.setAIBaseUrl('https://llm.example.com/v1');
    await settings.setAIModel('reader-model');
    await settings.setApiKey('test-key');
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  testWidgets('shows empty state when no context is set', (tester) async {
    final assistant = _buildController(settings);
    addTearDown(assistant.dispose);

    await tester.pumpWidget(_wrap(AIAssistantPanel(controller: assistant)));
    await tester.pump();

    expect(find.text('选中文字或点击单词开始分析'), findsOneWidget);
  });

  testWidgets('shows header and action strip when context set', (tester) async {
    final assistant = _buildController(settings);
    addTearDown(assistant.dispose);

    assistant.setContext(
      AIContextSnapshot(
        source: AIContextSource.readerSelectedText,
        selectedText: 'The door opened slowly.',
        surroundingPassage: 'He approached. The door opened slowly.',
        bookId: 'book-1',
        chapterTitle: 'Chapter 1',
      ),
    );

    await tester.pumpWidget(_wrap(AIAssistantPanel(controller: assistant)));
    await tester.pump();

    expect(find.text('选中文本'), findsOneWidget);
    expect(find.text('The door opened slowly.'), findsOneWidget);
    expect(find.text('解释'), findsOneWidget);
  });

  testWidgets('shows idle hint when no action executed yet', (tester) async {
    final assistant = _buildController(settings);
    addTearDown(assistant.dispose);

    assistant.setContext(
      AIContextSnapshot(
        source: AIContextSource.readerSelectedText,
        selectedText: 'Sample text.',
        surroundingPassage: 'Sample text.',
      ),
    );

    await tester.pumpWidget(_wrap(AIAssistantPanel(controller: assistant)));
    await tester.pump();

    expect(find.text('选择一个操作开始'), findsOneWidget);
  });

  testWidgets('executes action and shows result via controller', (
    tester,
  ) async {
    final assistant = _buildController(settings);
    addTearDown(assistant.dispose);

    assistant.setContext(
      AIContextSnapshot(
        source: AIContextSource.readerSelectedText,
        selectedText: 'The quick brown fox.',
        surroundingPassage: 'The quick brown fox jumps.',
      ),
    );

    await tester.pumpWidget(_wrap(AIAssistantPanel(controller: assistant)));
    await tester.pump();

    await assistant.executeAction(AIAssistantActionType.translate);
    await tester.pumpAndSettle();

    final result = assistant.actionController.lastResult;
    expect(result, isNotNull);
  });

  testWidgets('renders selected text analysis as structured sections', (
    tester,
  ) async {
    final responseJson = jsonEncode({
      'translation': '正是在一个周六的早上，布伦登被抓到在弹钢琴。',
      'structure_notes': [
        {
          'source':
              'It was on a Saturday morning that Brendon was caught playing the piano.',
          'role': 'main clause',
          'explanation': '强调句型，用来突出时间状语。',
        },
      ],
      'grammar_points': [
        {
          'source': 'was caught playing',
          'explanation': '被动语态后接现在分词，说明被看见时正在做的动作。',
          'difficulty': 'medium',
        },
      ],
    });
    final assistant = _buildController(
      settings,
      responseContent: '```json\n$responseJson\n```',
    );
    addTearDown(assistant.dispose);

    assistant.setContext(
      AIContextSnapshot(
        source: AIContextSource.readerSelectedText,
        selectedText:
            'It was on a Saturday morning that Brendon was caught playing the piano.',
        surroundingPassage:
            'It was on a Saturday morning that Brendon was caught playing the piano.',
      ),
    );

    await tester.pumpWidget(_wrap(AIAssistantPanel(controller: assistant)));
    await tester.pump();

    await assistant.executeAction(AIAssistantActionType.explain);
    await tester.pumpAndSettle();

    expect(find.text('译文'), findsOneWidget);
    expect(find.text('结构'), findsOneWidget);
    expect(find.text('语法'), findsOneWidget);
    expect(find.textContaining('正是在一个周六的早上'), findsOneWidget);
    expect(find.text('main clause'), findsOneWidget);
    expect(find.textContaining('structure_notes'), findsNothing);
  });

  testWidgets('closes via onClose when context is set', (tester) async {
    final assistant = _buildController(settings);
    addTearDown(assistant.dispose);

    assistant.setContext(
      AIContextSnapshot(
        source: AIContextSource.readerSelectedText,
        selectedText: 'Test.',
        surroundingPassage: 'Test.',
      ),
    );

    var closed = false;
    await tester.pumpWidget(
      _wrap(
        AIAssistantPanel(
          controller: assistant,
          onClose: () => closed = true,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close));
    expect(closed, isTrue);
  });

  testWidgets('embedded mode constrains width', (tester) async {
    final assistant = _buildController(settings);
    addTearDown(assistant.dispose);

    assistant.setContext(
      AIContextSnapshot(
        source: AIContextSource.readerWord,
        word: 'godswood',
        wordSentence: 'The godswood was silent.',
        bookId: 'book-1',
      ),
    );

    await tester.pumpWidget(
      _wrap(AIAssistantPanel(controller: assistant, embedded: true)),
    );
    await tester.pump();

    final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
    expect(sizedBox.width, 360);
  });

  testWidgets('word context shows word-specific action label', (tester) async {
    final assistant = _buildController(settings);
    addTearDown(assistant.dispose);

    assistant.setContext(
      AIContextSnapshot(
        source: AIContextSource.readerWord,
        word: 'godswood',
        wordSentence: 'The godswood was silent.',
        bookId: 'book-1',
      ),
    );

    await tester.pumpWidget(_wrap(AIAssistantPanel(controller: assistant)));
    await tester.pump();

    expect(find.text('单词分析'), findsOneWidget);
    expect(find.text('词汇'), findsOneWidget);
  });

  testWidgets('chapter context shows summary action', (tester) async {
    final assistant = _buildController(settings);
    addTearDown(assistant.dispose);

    assistant.setContext(
      AIContextSnapshot(
        source: AIContextSource.readerChapter,
        chapterTitle: 'The Beginning',
        chapterContent: 'Once upon a time...',
        bookId: 'book-1',
      ),
    );

    await tester.pumpWidget(_wrap(AIAssistantPanel(controller: assistant)));
    await tester.pump();

    expect(find.text('章节分析'), findsOneWidget);
    expect(find.text('总结'), findsOneWidget);
  });

  testWidgets('language indicator shows in footer', (tester) async {
    final assistant = _buildController(settings);
    addTearDown(assistant.dispose);

    assistant.setContext(
      AIContextSnapshot(
        source: AIContextSource.readerSelectedText,
        selectedText: 'Hello.',
        surroundingPassage: 'Hello world.',
        sourceLanguage: 'en',
        outputLanguage: 'zh',
      ),
    );

    await tester.pumpWidget(_wrap(AIAssistantPanel(controller: assistant)));
    await tester.pump();

    expect(find.text('EN → ZH'), findsOneWidget);
  });
}

AIAssistantController _buildController(
  SettingsService settings, {
  String responseContent = 'Result text',
}) {
  final aiService = AIService(
    LLMClient(
      () => settings.aiProviderConfig,
      httpClient: MockClient((_) async {
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': responseContent},
                },
              ],
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    ),
  );
  final actionController = AIActionController(aiService: aiService);
  final assistant = AIAssistantController(
    registry: const AIAssistantActionRegistry(
      promptBuilder: PromptBuilder(),
    ),
    automationSettings: const AIAutomationSettings(),
    insightProfile: const ReadingInsightProfile(),
    actionController: actionController,
  );
  addTearDown(actionController.dispose);
  return assistant;
}

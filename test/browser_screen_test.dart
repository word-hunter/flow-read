import 'dart:io';

import 'package:flow_ai/flow_ai.dart';
import 'package:flow_language/english/english.dart';
import 'package:flow_language/flow_language.dart';
import 'package:flow_read/models/reading_memory.dart';
import 'package:flow_read/models/user_vocabulary.dart';
import 'package:flow_read/models/word_context_example.dart';
import 'package:flow_read/providers/reading/services_provider.dart';
import 'package:flow_read/providers/reading/vocabulary_notifier.dart';
import 'package:flow_read/providers/reading/word_lookup_notifier.dart';
import 'package:flow_read/providers/settings_provider.dart';
import 'package:flow_read/providers/web_content_provider.dart';
import 'package:flow_read/screens/browser_screen.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/services/web_content_service.dart';
import 'package:flow_read/widgets/ai_assistant_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_word_level_service.dart';
import 'support/test_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late SettingsService settings;

  setUp(() async {
    tempDir = await initTestStorage('flow_read_browser_screen_test_');
    settings = await createTestSettingsService();
    await settings.setAIProvider('openai_compatible');
    await settings.setAIBaseUrl('https://llm.example.com/v1');
    await settings.setAIModel('reader-model');
    await settings.setApiKey('test-key');
  });

  tearDown(() async {
    await disposeTestStorage(tempDir);
  });

  testWidgets('browser assistant opens with internal web context', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final pageUri = Uri.parse('https://example.com/browser-page');
    final actionController = AIActionController(
      aiService: AIService(
        LLMClient(() => settings.aiProviderConfig),
      ),
    );
    final assistantController = AIAssistantController(
      registry: const AIAssistantActionRegistry(
        promptBuilder: PromptBuilder(),
      ),
      automationSettings: const AIAutomationSettings(),
      insightProfile: const ReadingInsightProfile(),
      actionController: actionController,
    );
    addTearDown(actionController.dispose);
    addTearDown(assistantController.dispose);

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => settings),
          wordLevelServiceProvider.overrideWithValue(fakeWordLevelService()),
          wordLookupNotifierProvider.overrideWith(_BrowserLookupNotifier.new),
          vocabularyNotifierProvider.overrideWith(
            _BrowserVocabularyNotifier.new,
          ),
          aiAssistantControllerProvider.overrideWithValue(assistantController),
          webContentServiceProvider.overrideWithValue(
            _FakeWebContentService(
              WebPageContent(
                url: pageUri,
                title: 'Readable Browser Page',
                paragraphs: const [
                  'The internal browser article body should become AI context.',
                  'The second paragraph keeps the page long enough for extraction.',
                ],
              ),
            ),
          ),
        ],
        child: MaterialApp(home: BrowserScreen(initialUrl: pageUri.toString())),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Readable Browser Page'), findsOneWidget);

    await tester.tap(find.byTooltip('AI 助手'));
    await tester.pumpAndSettle();

    expect(find.byType(AIAssistantPanel), findsOneWidget);
    expect(
      assistantController.currentContext?.source,
      AIContextSource.internalWeb,
    );
    expect(
      assistantController.currentContext?.articleUrl,
      pageUri.toString(),
    );
    expect(
      assistantController.availableActions,
      containsAll([
        AIAssistantActionType.summary,
        AIAssistantActionType.articleQA,
      ]),
    );
  });
}

class _FakeWebContentService extends WebContentService {
  _FakeWebContentService(this._page);

  final WebPageContent _page;

  @override
  Future<WebPageContent> fetch(String inputUrl) async {
    return _page;
  }
}

class _BrowserLookupNotifier extends WordLookupNotifier {
  @override
  WordLookupState build() => const WordLookupState();

  @override
  Future<void> lookupWord(
    String word, {
    String? canonicalForm,
    String? languageCode,
    String? reading,
    String? contextText,
    int? contextWordStart,
    int? contextWordEnd,
    bool trackReadingLookup = false,
    MemorySourceRef? memorySourceRef,
  }) async {
    state = WordLookupState(
      selectedWord: word,
      selectedWordTranslation: '',
      selectedWordContext: contextText,
      selectedWordContextStart: contextWordStart,
      selectedWordContextEnd: contextWordEnd,
    );
  }

  @override
  List<WordContextExample> importedExamplesFor(String word) => const [];

  @override
  Future<void> speakWord(String word) async {}

  @override
  Future<void> lookupRelatedWord(String word) async {}

  @override
  void goBackWordLookup() {}

  @override
  Future<void> retryWordLookup() async {}

  @override
  bool get canGenerateBookGlossaryExplanation => false;

  @override
  Future<void> generateBookGlossaryExplanation() async {}

  @override
  Future<bool> saveBookGlossaryExplanation({String? explanation}) async {
    return false;
  }
}

class _BrowserVocabularyNotifier extends VocabularyNotifier {
  @override
  VocabularyState build() => const VocabularyState();

  @override
  LanguageModule get activeLanguageModule => const EnglishLanguageModule();

  @override
  UserVocabularyService? get userVocabulary => null;

  @override
  UserWordStatus? getWordStatus(String word) => null;

  @override
  Future<void> markWordKnown(String word, {Offset? celebrationOrigin}) async {}

  @override
  Future<void> markWordLearning(String word) async {}

  @override
  Future<void> markWordUnknown(String word) async {}
}

import 'package:flow_ai/flow_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const registry = AIAssistantActionRegistry(promptBuilder: PromptBuilder());

  test('returns available actions for selected text contexts', () {
    final actions = registry.availableActions(
      AIContextSnapshot(
        source: AIContextSource.readerSelectedText,
        selectedText: 'The old road ran north.',
      ),
    );

    expect(actions, [
      AIAssistantActionType.explain,
      AIAssistantActionType.translate,
      AIAssistantActionType.phraseExtraction,
      AIAssistantActionType.pronounReference,
    ]);
  });

  test('returns available actions for chapter and article contexts', () {
    final chapterActions = registry.availableActions(
      AIContextSnapshot(
        source: AIContextSource.readerChapter,
        chapterContent: 'Chapter text',
      ),
    );
    final articleActions = registry.availableActions(
      AIContextSnapshot(
        source: AIContextSource.rssArticle,
        articleContent: 'Article text',
      ),
    );

    expect(chapterActions, [
      AIAssistantActionType.questionGeneration,
      AIAssistantActionType.summary,
    ]);
    expect(articleActions, [
      AIAssistantActionType.translate,
      AIAssistantActionType.questionGeneration,
      AIAssistantActionType.summary,
      AIAssistantActionType.articleQA,
    ]);
  });

  test('builds prompt through existing prompt builder', () {
    final prompt = registry.buildPrompt(
      AIAssistantActionType.wordAnalysis,
      AIContextSnapshot(
        source: AIContextSource.readerWord,
        bookId: 'book-1',
        chapterIndex: 2,
        word: 'threshold',
        wordSentence: 'He crossed the threshold.',
        surroundingPassage: 'He crossed the threshold into the hall.',
        sourceLanguage: 'en',
        outputLanguage: 'zh',
      ),
    );

    expect(prompt.userPrompt, contains('threshold'));
    expect(prompt.spoilerBoundary.currentUnitId, 'chapter:2');
    expect(prompt.sourceLanguage, SourceLanguage.english);
    expect(prompt.outputLanguage, OutputLanguage.zhHans);
  });

  test('builds article answer prompts with follow-up question', () {
    final prompt = registry.buildPrompt(
      AIAssistantActionType.articleQA,
      AIContextSnapshot(
        source: AIContextSource.rssArticle,
        articleTitle: 'News',
        articleContent: 'The article body.',
        articleUrl: 'https://example.com/news',
      ),
      followUpQuestion: 'What changed?',
    );

    expect(prompt.userPrompt, contains('News'));
    expect(prompt.userPrompt, contains('What changed?'));
  });

  test('throws when action is not available for context', () {
    expect(
      () => registry.buildPrompt(
        AIAssistantActionType.wordAnalysis,
        AIContextSnapshot(
          source: AIContextSource.readerSelectedText,
          selectedText: 'Text',
        ),
      ),
      throwsArgumentError,
    );
  });
}

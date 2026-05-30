import '../models/ai_text_analysis.dart';
import 'ai_service.dart';
import 'llm_client.dart';
import 'prompt_builder.dart';

enum ReadingAssistantSurface { epub, rss, browser }

class ReadingAssistantContext {
  final ReadingAssistantSurface surface;
  final String title;
  final String text;
  final String? url;

  const ReadingAssistantContext({
    required this.surface,
    required this.title,
    required this.text,
    this.url,
  });

  String get surfaceLabel {
    switch (surface) {
      case ReadingAssistantSurface.epub:
        return 'EPUB';
      case ReadingAssistantSurface.rss:
        return 'RSS';
      case ReadingAssistantSurface.browser:
        return 'Browser';
    }
  }

  String get compactText {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 12000) return normalized;
    return normalized.substring(0, 12000);
  }
}

class ReadingAssistantAgent {
  final LLMClient _client;
  final PromptBuilder _promptBuilder;
  late final AIService _aiService = AIService(
    _client,
    promptBuilder: _promptBuilder,
  );

  ReadingAssistantAgent(
    this._client, {
    PromptBuilder promptBuilder = const PromptBuilder(),
  }) : _promptBuilder = promptBuilder;

  Future<String> translateSelection(String text) {
    return _aiService.translateText(text);
  }

  Future<AITextAnalysis> analyzeSelection({
    required String selectedText,
    required String contextBefore,
    required String contextAfter,
  }) {
    return _aiService.analyzeText(
      selectedText: selectedText,
      contextBefore: contextBefore,
      contextAfter: contextAfter,
    );
  }

  Future<String> summarize(ReadingAssistantContext context) {
    final prompt = _promptBuilder.buildArticleSummary(
      ArticlePromptRequest(
        surfaceLabel: context.surfaceLabel,
        title: context.title,
        text: context.compactText,
        url: context.url,
        sourceLanguage: SourceLanguage.inferFromText(context.text),
        outputLanguage: OutputLanguage.zhHans,
        spoilerBoundary: SpoilerBoundary.currentPassage(),
      ),
    );
    return _client.chat(
      systemPrompt: prompt.systemPrompt,
      userPrompt: prompt.userPrompt,
    );
  }

  Future<String> answer({
    required ReadingAssistantContext context,
    required String question,
  }) {
    final prompt = _promptBuilder.buildArticleAnswer(
      ArticlePromptRequest(
        surfaceLabel: context.surfaceLabel,
        title: context.title,
        text: context.compactText,
        url: context.url,
        question: question,
        sourceLanguage: SourceLanguage.inferFromText(context.text),
        outputLanguage: OutputLanguage.zhHans,
        spoilerBoundary: SpoilerBoundary.currentPassage(),
      ),
    );
    return _client.chat(
      systemPrompt: prompt.systemPrompt,
      userPrompt: prompt.userPrompt,
    );
  }
}

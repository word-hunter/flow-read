import '../models/ai_text_analysis.dart';
import 'ai_service.dart';
import 'llm_client.dart';

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
  late final AIService _aiService = AIService(_client);

  ReadingAssistantAgent(this._client);

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
    return _client.chat(
      systemPrompt: _systemPrompt,
      userPrompt:
          '''Summarize this ${context.surfaceLabel} reading context in Chinese.

Title: ${context.title}
URL: ${context.url ?? ''}

Text:
${context.compactText}

Return:
1. 3-5 bullet summary
2. Important vocabulary or phrases
3. One reading suggestion''',
    );
  }

  Future<String> answer({
    required ReadingAssistantContext context,
    required String question,
  }) {
    return _client.chat(
      systemPrompt: _systemPrompt,
      userPrompt:
          '''Answer the user's question using only the reading context.

Context type: ${context.surfaceLabel}
Title: ${context.title}
URL: ${context.url ?? ''}

Reading context:
${context.compactText}

Question:
$question

Answer in Chinese. If the context does not contain enough evidence, say so.''',
    );
  }

  static const _systemPrompt =
      'You are a reusable reading assistant embedded in a Flutter reading app. '
      'You help Chinese speakers read English content across EPUB, RSS, and web pages. '
      'Use only the provided context. Be concise and cite short source phrases when useful.';
}

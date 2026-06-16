import 'dart:convert';

import 'models/ai_text_analysis.dart';
import 'models/ai_chapter_preview.dart';
import 'models/ai_summary.dart';
import 'models/ai_practice_questions.dart';
import 'models/word_analysis.dart';
import 'app_logger.dart';
import 'llm_client.dart';
import 'prompt_builder.dart';

class AIService {
  final LLMClient _client;
  final PromptBuilder _promptBuilder;

  AIService(this._client, {PromptBuilder promptBuilder = const PromptBuilder()})
    : _promptBuilder = promptBuilder;

  int get promptVersion => PromptBuilder.currentPromptVersion;
  String get modelConfigFingerprint => _client.modelConfigFingerprint;

  Future<String> executePrompt(
    PromptBuildResult prompt, {
    bool jsonMode = false,
    Map<String, Object?> debugMetadata = const {},
  }) {
    return _client.chat(
      systemPrompt: prompt.systemPrompt,
      userPrompt: prompt.userPrompt,
      jsonMode: jsonMode,
      debugMetadata: {
        'promptVersion': prompt.promptVersion,
        'sourceLanguage': prompt.sourceLanguage.code,
        'outputLanguage': prompt.outputLanguage.code,
        'spoilerBoundary': _spoilerBoundaryTrace(prompt.spoilerBoundary),
        ...debugMetadata,
      },
    );
  }

  Future<AITextAnalysis> analyzeText({
    required String selectedText,
    required String currentPassage,
    SourceLanguage? sourceLanguage,
    OutputLanguage outputLanguage = OutputLanguage.zhHans,
    SpoilerBoundary? spoilerBoundary,
  }) async {
    final prompt = _promptBuilder.buildTextAnalysis(
      TextAnalysisPromptRequest(
        selectedText: selectedText,
        currentPassage: currentPassage,
        sourceLanguage:
            sourceLanguage ??
            SourceLanguage.inferFromText('$selectedText $currentPassage'),
        outputLanguage: outputLanguage,
        spoilerBoundary: spoilerBoundary ?? SpoilerBoundary.currentPassage(),
      ),
    );

    final response = await _client.chat(
      systemPrompt: prompt.systemPrompt,
      userPrompt: prompt.userPrompt,
      jsonMode: true,
      debugMetadata: _promptTraceMetadata('text_analysis', prompt),
    );

    final result = _parseJsonOrFallback(
      response,
      AITextAnalysis.fromJson,
      (raw) => AITextAnalysis.fallback(raw),
      'text_analysis',
    );
    _validateTextAnalysis(result, selectedText);
    return result;
  }

  Future<String> translateText(
    String selectedText, {
    SourceLanguage? sourceLanguage,
    OutputLanguage outputLanguage = OutputLanguage.zhHans,
    SpoilerBoundary? spoilerBoundary,
  }) async {
    final prompt = _promptBuilder.buildTranslation(
      TranslationPromptRequest(
        selectedText: selectedText,
        sourceLanguage:
            sourceLanguage ?? SourceLanguage.inferFromText(selectedText),
        outputLanguage: outputLanguage,
        spoilerBoundary: spoilerBoundary ?? SpoilerBoundary.currentPassage(),
      ),
    );

    final response = await _client.chat(
      systemPrompt: prompt.systemPrompt,
      userPrompt: prompt.userPrompt,
      debugMetadata: _promptTraceMetadata('translation', prompt),
    );

    return response.trim();
  }

  Stream<AISummary> generateSummary({
    required String chapterText,
    required List<String> vocabulary,
    required String language,
    SourceLanguage? sourceLanguage,
    SpoilerBoundary? spoilerBoundary,
  }) async* {
    final prompt = _promptBuilder.buildChapterSummary(
      ChapterSummaryPromptRequest(
        chapterText: chapterText,
        vocabulary: vocabulary,
        sourceLanguage:
            sourceLanguage ?? SourceLanguage.inferFromText(chapterText),
        outputLanguage: OutputLanguage.fromCode(language),
        spoilerBoundary:
            spoilerBoundary ??
            SpoilerBoundary.chapter(bookId: 'current_book', chapterIndex: 0),
      ),
    );

    final buffer = StringBuffer();

    await for (final chunk in _client.streamChat(
      systemPrompt: prompt.systemPrompt,
      userPrompt: prompt.userPrompt,
      jsonMode: true,
      debugMetadata: _promptTraceMetadata('chapter_summary', prompt),
    )) {
      buffer.write(chunk);
    }

    final summary = _parseJsonOrFallback(
      buffer.toString(),
      AISummary.fromJson,
      AISummary.fallback,
      'chapter_summary',
    );
    _validateSummary(summary, chapterText);
    yield summary;
  }

  Future<AIChapterPreview> generateChapterPreview({
    required String chapterTitle,
    required String openingText,
    required List<String> vocabulary,
    SourceLanguage? sourceLanguage,
    OutputLanguage outputLanguage = OutputLanguage.zhHans,
    SpoilerBoundary? spoilerBoundary,
  }) async {
    final prompt = _promptBuilder.buildChapterPreview(
      ChapterPreviewPromptRequest(
        chapterTitle: chapterTitle,
        openingText: openingText,
        vocabulary: vocabulary,
        sourceLanguage:
            sourceLanguage ?? SourceLanguage.inferFromText(openingText),
        outputLanguage: outputLanguage,
        spoilerBoundary:
            spoilerBoundary ??
            SpoilerBoundary.chapter(bookId: 'current_book', chapterIndex: 0),
      ),
    );

    final response = await _client.chat(
      systemPrompt: prompt.systemPrompt,
      userPrompt: prompt.userPrompt,
      jsonMode: true,
      debugMetadata: _promptTraceMetadata('chapter_preview', prompt),
    );

    return _parseJsonOrFallback(
      response,
      AIChapterPreview.fromJson,
      AIChapterPreview.fallback,
      'chapter_preview',
    );
  }

  Stream<AIPracticeSet> generatePractice({
    required String chapterText,
    required List<String> vocabulary,
    required List<SummaryEvent> events,
    SourceLanguage? sourceLanguage,
    OutputLanguage outputLanguage = OutputLanguage.zhHans,
    SpoilerBoundary? spoilerBoundary,
  }) async* {
    final prompt = _promptBuilder.buildPractice(
      PracticePromptRequest(
        chapterText: chapterText,
        vocabulary: vocabulary,
        events: events,
        sourceLanguage:
            sourceLanguage ?? SourceLanguage.inferFromText(chapterText),
        outputLanguage: outputLanguage,
        spoilerBoundary:
            spoilerBoundary ??
            SpoilerBoundary.chapter(
              bookId: 'current_book',
              chapterIndex: 0,
              scope: AIContextScope.readSoFar,
            ),
      ),
    );

    final buffer = StringBuffer();

    await for (final chunk in _client.streamChat(
      systemPrompt: prompt.systemPrompt,
      userPrompt: prompt.userPrompt,
      jsonMode: true,
      debugMetadata: _promptTraceMetadata('practice', prompt),
    )) {
      buffer.write(chunk);
    }

    final practice = _parseJsonOrFallback(
      buffer.toString(),
      AIPracticeSet.fromJson,
      AIPracticeSet.fallback,
      'practice',
    );
    _validatePractice(practice, chapterText);
    yield practice;
  }

  Future<WordAnalysis> analyzeWord({
    required String word,
    required String sentence,
    required String chapterContext,
    SourceLanguage? sourceLanguage,
    OutputLanguage outputLanguage = OutputLanguage.zhHans,
    SpoilerBoundary? spoilerBoundary,
  }) async {
    final prompt = _promptBuilder.buildWordAnalysis(
      WordAnalysisPromptRequest(
        word: word,
        sentence: sentence,
        chapterContext: chapterContext,
        sourceLanguage:
            sourceLanguage ??
            SourceLanguage.inferFromText('$sentence $chapterContext'),
        outputLanguage: outputLanguage,
        spoilerBoundary: spoilerBoundary ?? SpoilerBoundary.currentPassage(),
      ),
    );

    final response = await _client.chat(
      systemPrompt: prompt.systemPrompt,
      userPrompt: prompt.userPrompt,
      jsonMode: true,
      debugMetadata: _promptTraceMetadata('word_analysis', prompt),
    );

    return _parseJsonOrFallback(
      response,
      WordAnalysis.fromJson,
      WordAnalysis.fallback,
      'word_analysis',
    );
  }

  Future<String> explainBookGlossaryTerm({
    required String word,
    required String canonicalForm,
    required String currentPassage,
    List<String> earlierOccurrences = const [],
    List<CharacterCardSnippet> relatedCharacters = const [],
    SourceLanguage? sourceLanguage,
    OutputLanguage outputLanguage = OutputLanguage.zhHans,
    SpoilerBoundary? spoilerBoundary,
  }) async {
    final prompt = _promptBuilder.buildBookGlossaryExplanation(
      BookGlossaryPromptRequest(
        word: word,
        canonicalForm: canonicalForm,
        currentPassage: currentPassage,
        earlierOccurrences: earlierOccurrences,
        relatedCharacters: relatedCharacters,
        sourceLanguage:
            sourceLanguage ??
            SourceLanguage.inferFromText('$word $currentPassage'),
        outputLanguage: outputLanguage,
        spoilerBoundary: spoilerBoundary ?? SpoilerBoundary.currentPassage(),
      ),
    );

    final response = await _client.chat(
      systemPrompt: prompt.systemPrompt,
      userPrompt: prompt.userPrompt,
      debugMetadata: _promptTraceMetadata('book_glossary', prompt),
    );
    return response.trim();
  }

  void _validateTextAnalysis(AITextAnalysis result, String originalText) {
    for (final note in result.structureNotes) {
      if (note.source.isNotEmpty &&
          !originalText.toLowerCase().contains(note.source.toLowerCase())) {
        _logMissingAiSource('structure', note.source.length, originalText);
      }
    }
    for (final point in result.grammarPoints) {
      if (point.source.isNotEmpty &&
          !originalText.toLowerCase().contains(point.source.toLowerCase())) {
        _logMissingAiSource('grammar', point.source.length, originalText);
      }
    }
    for (final note in result.vocabularyNotes) {
      if (note.word.isNotEmpty &&
          !originalText.toLowerCase().contains(note.word.toLowerCase())) {
        _logMissingAiSource('vocabulary', note.word.length, originalText);
      }
    }
    for (final note in result.expressionNotes) {
      if (note.source.isNotEmpty &&
          !originalText.toLowerCase().contains(note.source.toLowerCase())) {
        _logMissingAiSource('expression', note.source.length, originalText);
      }
    }
  }

  void _validateSummary(AISummary summary, String originalText) {
    for (final event in summary.events) {
      if (event.source.isNotEmpty && !originalText.contains(event.source)) {
        _logMissingAiSource('summary_event', event.source.length, originalText);
      }
    }
    for (final cd in summary.characterDevelopments) {
      if (cd.source.isNotEmpty && !originalText.contains(cd.source)) {
        _logMissingAiSource(
          'character_development',
          cd.source.length,
          originalText,
        );
      }
    }
  }

  void _validatePractice(AIPracticeSet practice, String originalText) {
    for (final question in practice.questions) {
      if (question.source.isNotEmpty &&
          !originalText.contains(question.source)) {
        _logMissingAiSource(
          'practice_question',
          question.source.length,
          originalText,
        );
      }
    }
  }

  void _logMissingAiSource(
    String field,
    int sourceLength,
    String originalText,
  ) {
    AppLogger.instance.event(
      'ai.validation_source_missing',
      level: AppLogLevel.debug,
      source: 'ai_service',
      metadata: {
        'field': field,
        'sourceLength': sourceLength,
        'originalTextLength': originalText.length,
      },
    );
  }

  Map<String, Object?> _promptTraceMetadata(
    String task,
    PromptBuildResult prompt,
  ) {
    return {
      'task': task,
      'promptVersion': prompt.promptVersion,
      'sourceLanguage': prompt.sourceLanguage.code,
      'outputLanguage': prompt.outputLanguage.code,
      'spoilerBoundary': _spoilerBoundaryTrace(prompt.spoilerBoundary),
    };
  }

  Map<String, Object?> _spoilerBoundaryTrace(SpoilerBoundary boundary) {
    return {
      'bookId': boundary.bookId,
      'currentUnitId': boundary.currentUnitId,
      'maxReadUnitOrder': boundary.maxReadUnitOrder,
      'unitType': boundary.unitType,
      'scope': boundary.scope.promptValue,
      'allowedUnits': boundary.allowedUnits,
    };
  }

  T _parseJsonOrFallback<T>(
    String response,
    T Function(Map<String, dynamic> json) parse,
    T Function(String rawText) fallback,
    String task,
  ) {
    try {
      return parse(_extractJson(response));
    } on FormatException catch (error) {
      _logJsonFallback(task, response.length, error);
      return fallback(_safeFallbackText(response));
    } on TypeError catch (error) {
      _logJsonFallback(task, response.length, error);
      return fallback(_safeFallbackText(response));
    }
  }

  void _logJsonFallback(String task, int responseLength, Object error) {
    AppLogger.instance.event(
      'ai.json_fallback',
      level: AppLogLevel.warning,
      source: 'ai_service',
      metadata: {
        'task': task,
        'responseLength': responseLength,
        'error': error.toString(),
      },
    );
  }

  String _safeFallbackText(String response) {
    var content = response.trim();
    if (content.startsWith('```json')) {
      content = content.substring(7);
    } else if (content.startsWith('```')) {
      content = content.substring(3);
    }
    if (content.endsWith('```')) {
      content = content.substring(0, content.length - 3);
    }
    content = content.trim();
    if (content.length > 4000) {
      content = '${content.substring(0, 4000)}...';
    }
    if (content.isEmpty) {
      return 'AI 返回了非结构化内容，但没有可展示的文本。';
    }
    return 'AI 返回了非结构化内容，以下为原始文本：\n\n$content';
  }

  Map<String, dynamic> _extractJson(String response) {
    String content = response.trim();

    if (content.startsWith('```json')) {
      content = content.substring(7);
    } else if (content.startsWith('```')) {
      content = content.substring(3);
    }
    if (content.endsWith('```')) {
      content = content.substring(0, content.length - 3);
    }

    return jsonDecode(content.trim()) as Map<String, dynamic>;
  }
}

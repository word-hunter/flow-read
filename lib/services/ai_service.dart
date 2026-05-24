import 'dart:convert';

import '../models/ai_text_analysis.dart';
import '../models/ai_summary.dart';
import '../models/ai_practice_questions.dart';
import '../models/word_analysis.dart';
import 'app_logger.dart';
import 'llm_client.dart';
import 'prompt_registry.dart';

class AIService {
  final LLMClient _client;

  AIService(this._client);

  Future<AITextAnalysis> analyzeText({
    required String selectedText,
    required String contextBefore,
    required String contextAfter,
  }) async {
    final systemPrompt = PromptRegistry.textAnalysisSystem;
    final userPrompt = PromptRegistry.textAnalysisUser(
      selectedText,
      contextBefore,
      contextAfter,
    );

    final response = await _client.chat(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      jsonMode: true,
    );

    final json = _extractJson(response);
    final result = AITextAnalysis.fromJson(json);
    _validateTextAnalysis(result, selectedText);
    return result;
  }

  Future<String> translateText(String selectedText) async {
    final systemPrompt = PromptRegistry.translationSystem;
    final userPrompt = PromptRegistry.translationUser(selectedText);

    final response = await _client.chat(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );

    return response.trim();
  }

  Stream<AISummary> generateSummary({
    required String chapterText,
    required List<String> vocabulary,
    required String language,
  }) async* {
    final systemPrompt = PromptRegistry.summarySystem(language);
    final userPrompt = PromptRegistry.summaryUser(
      chapterText,
      vocabulary,
      language,
    );

    final buffer = StringBuffer();

    await for (final chunk in _client.streamChat(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      jsonMode: true,
    )) {
      buffer.write(chunk);
    }

    final json = _extractJson(buffer.toString());
    final summary = AISummary.fromJson(json);
    _validateSummary(summary, chapterText);
    yield summary;
  }

  Stream<AIPracticeSet> generatePractice({
    required String chapterText,
    required List<String> vocabulary,
    required List<SummaryEvent> events,
  }) async* {
    final systemPrompt = PromptRegistry.practiceSystem;
    final userPrompt = PromptRegistry.practiceUser(
      chapterText,
      vocabulary,
      events,
    );

    final buffer = StringBuffer();

    await for (final chunk in _client.streamChat(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      jsonMode: true,
    )) {
      buffer.write(chunk);
    }

    final json = _extractJson(buffer.toString());
    final practice = AIPracticeSet.fromJson(json);
    _validatePractice(practice, chapterText);
    yield practice;
  }

  Future<WordAnalysis> analyzeWord({
    required String word,
    required String sentence,
    required String chapterContext,
  }) async {
    final systemPrompt = PromptRegistry.wordAnalysisSystem;
    final userPrompt = PromptRegistry.wordAnalysisUser(
      word,
      sentence,
      chapterContext,
    );

    final response = await _client.chat(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      jsonMode: true,
    );

    final json = _extractJson(response);
    return WordAnalysis.fromJson(json);
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

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/ai_text_analysis.dart';
import '../models/ai_summary.dart';
import '../models/ai_practice_questions.dart';
import '../models/word_analysis.dart';
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
    for (final point in result.grammarPoints) {
      if (point.source.isNotEmpty &&
          !originalText.toLowerCase().contains(point.source.toLowerCase())) {
        debugPrint(
            '[AI] Grammar source not found in text: "${point.source}"');
      }
    }
    for (final note in result.vocabularyNotes) {
      if (note.word.isNotEmpty &&
          !originalText.toLowerCase().contains(note.word.toLowerCase())) {
        debugPrint('[AI] Word not found in text: "${note.word}"');
      }
    }
  }

  void _validateSummary(AISummary summary, String originalText) {
    for (final event in summary.events) {
      if (event.source.isNotEmpty &&
          !originalText.contains(event.source)) {
        debugPrint('[AI] Event source not found: "${event.source}"');
      }
    }
    for (final cd in summary.characterDevelopments) {
      if (cd.source.isNotEmpty && !originalText.contains(cd.source)) {
        debugPrint('[AI] Character source not found: "${cd.source}"');
      }
    }
  }

  void _validatePractice(AIPracticeSet practice, String originalText) {
    for (final question in practice.questions) {
      if (question.source.isNotEmpty &&
          !originalText.contains(question.source)) {
        debugPrint('[AI] Question source not found: "${question.source}"');
      }
    }
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

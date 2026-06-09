import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flow_ai/flow_ai.dart';
import '../../models/analysis_result.dart';
import '../../models/sentence_breakdown.dart';
import '../../services/analysis_service.dart';
import 'package:flow_language/flow_language.dart';
import '../settings_provider.dart';
import 'services_provider.dart';

@immutable
class TextSelectionState {
  const TextSelectionState({
    this.selectedText,
    this.selectedAnalysis,
    this.selectedBreakdowns,
    this.aiTextAnalysis,
    this.isAnalyzingText = false,
    this.errorMessage,
  });

  final String? selectedText;
  final AnalysisResult? selectedAnalysis;
  final List<SentenceBreakdown>? selectedBreakdowns;
  final AITextAnalysis? aiTextAnalysis;
  final bool isAnalyzingText;
  final String? errorMessage;

  TextSelectionState copyWith({
    String? selectedText,
    AnalysisResult? selectedAnalysis,
    List<SentenceBreakdown>? selectedBreakdowns,
    AITextAnalysis? aiTextAnalysis,
    bool? isAnalyzingText,
    String? errorMessage,
    bool clearAnalysis = false,
    bool clearBreakdowns = false,
    bool clearAITextAnalysis = false,
  }) {
    return TextSelectionState(
      selectedText: selectedText ?? this.selectedText,
      selectedAnalysis: clearAnalysis
          ? null
          : (selectedAnalysis ?? this.selectedAnalysis),
      selectedBreakdowns: clearBreakdowns
          ? null
          : (selectedBreakdowns ?? this.selectedBreakdowns),
      aiTextAnalysis: clearAITextAnalysis
          ? null
          : (aiTextAnalysis ?? this.aiTextAnalysis),
      isAnalyzingText: isAnalyzingText ?? this.isAnalyzingText,
      errorMessage: errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TextSelectionState &&
        other.selectedText == selectedText &&
        other.selectedAnalysis == selectedAnalysis &&
        other.aiTextAnalysis == aiTextAnalysis &&
        other.isAnalyzingText == isAnalyzingText &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
    selectedText,
    selectedAnalysis,
    aiTextAnalysis,
    isAnalyzingText,
    errorMessage,
  );
}

class TextSelectionNotifier extends Notifier<TextSelectionState> {
  @override
  TextSelectionState build() {
    return const TextSelectionState();
  }

  void analyzeSelectedText(String text) {
    final userVocab = ref.read(userVocabularyServiceProvider);
    final wordLevelService = ref.read(wordLevelServiceProvider);
    final sentenceAnalyzer = ref.read(sentenceAnalyzerProvider);
    final settings = ref.read(settingsProvider);
    final code = settings.activeSourceLanguage;
    final module =
        LanguageRegistry.instance.get(code) ??
        LanguageRegistry.instance.defaultModule;
    if (module == null) throw StateError('Language "$code" not registered');

    final analysis = AnalysisService.analyzeChapter(
      'Selected Text',
      text,
      userVocab,
      wordLevelService,
      module,
    );
    final breakdowns = sentenceAnalyzer.analyze(text);

    state = state.copyWith(
      selectedText: text,
      selectedAnalysis: analysis,
      selectedBreakdowns: breakdowns,
    );
  }

  void clearSelectedText() {
    state = state.copyWith(
      clearAnalysis: true,
      clearBreakdowns: true,
      clearAITextAnalysis: true,
      selectedText: '',
    );
  }

  void setAITextAnalysis(AITextAnalysis? analysis) {
    state = state.copyWith(aiTextAnalysis: analysis);
  }

  void setAnalyzingText(bool value) {
    state = state.copyWith(isAnalyzingText: value);
  }

  void setError(String? message) {
    state = state.copyWith(errorMessage: message);
  }
}

final textSelectionNotifierProvider =
    NotifierProvider<TextSelectionNotifier, TextSelectionState>(
      TextSelectionNotifier.new,
    );

import 'ai_summary.dart';
import 'ai_text_analysis.dart';
import 'paragraph_insight.dart';
import 'word_analysis.dart';

sealed class AIActionResult {
  const AIActionResult();
}

class AIExplainResult extends AIActionResult {
  const AIExplainResult({required this.explanation, this.sources});

  final String explanation;
  final List<String>? sources;
}

class AITextAnalysisResult extends AIActionResult {
  const AITextAnalysisResult({required this.analysis});

  final AITextAnalysis analysis;
}

class AITranslateResult extends AIActionResult {
  const AITranslateResult({required this.translation});

  final String translation;
}

class AIPhraseExtractionResult extends AIActionResult {
  const AIPhraseExtractionResult({required this.phrases});

  final List<AIExtractedPhrase> phrases;
}

class AIExtractedPhrase {
  const AIExtractedPhrase({
    required this.phrase,
    required this.explanation,
    this.sourceText,
  });

  final String phrase;
  final String explanation;
  final String? sourceText;
}

class AIQuestionGenerationResult extends AIActionResult {
  const AIQuestionGenerationResult({required this.questions});

  final List<AIGeneratedQuestion> questions;
}

class AIGeneratedQuestion {
  const AIGeneratedQuestion({
    required this.question,
    required this.answer,
    this.explanation,
  });

  final String question;
  final String answer;
  final String? explanation;
}

class AISummaryResult extends AIActionResult {
  const AISummaryResult({required this.summary});

  final AISummary summary;
}

class AIWordAnalysisResult extends AIActionResult {
  const AIWordAnalysisResult({required this.analysis});

  final WordAnalysis analysis;
}

class AIArticleQAResult extends AIActionResult {
  const AIArticleQAResult({required this.answer});

  final String answer;
}

class AIParagraphInsightResult extends AIActionResult {
  const AIParagraphInsightResult({required this.insight});

  final ParagraphInsight insight;
}

class AIStreamingProgress extends AIActionResult {
  const AIStreamingProgress({required this.chunk, required this.progress});

  final String chunk;
  final double progress;
}

class AIErrorResult extends AIActionResult {
  const AIErrorResult({required this.message, this.isRetryable = true});

  final String message;
  final bool isRetryable;
}

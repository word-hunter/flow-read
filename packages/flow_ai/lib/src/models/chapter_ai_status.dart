import 'ai_chapter_preview.dart';
import 'ai_practice_questions.dart';
import 'ai_summary.dart';

enum ChapterAIStatusKind {
  unconfigured,
  loading,
  cacheHit,
  failed,
  fallback,
  generated,
}

enum ChapterAIFeature { preview, summary, practice }

class ChapterAIStatus {
  final ChapterAIStatusKind kind;
  final ChapterAIFeature feature;
  final String message;

  const ChapterAIStatus({
    required this.kind,
    required this.feature,
    required this.message,
  });

  const ChapterAIStatus.unconfigured(String message)
    : this(
        kind: ChapterAIStatusKind.unconfigured,
        feature: ChapterAIFeature.summary,
        message: message,
      );

  const ChapterAIStatus.loading(ChapterAIFeature feature, String message)
    : this(
        kind: ChapterAIStatusKind.loading,
        feature: feature,
        message: message,
      );

  const ChapterAIStatus.cacheHit(ChapterAIFeature feature, String message)
    : this(
        kind: ChapterAIStatusKind.cacheHit,
        feature: feature,
        message: message,
      );

  const ChapterAIStatus.failed(ChapterAIFeature feature, String message)
    : this(
        kind: ChapterAIStatusKind.failed,
        feature: feature,
        message: message,
      );

  const ChapterAIStatus.fallback(ChapterAIFeature feature, String message)
    : this(
        kind: ChapterAIStatusKind.fallback,
        feature: feature,
        message: message,
      );

  const ChapterAIStatus.generated(ChapterAIFeature feature, String message)
    : this(
        kind: ChapterAIStatusKind.generated,
        feature: feature,
        message: message,
      );

  factory ChapterAIStatus.fromSummary(AISummary summary) {
    return summary.isEmpty
        ? const ChapterAIStatus.fallback(
            ChapterAIFeature.summary,
            'AI 未返回可用章节总结。',
          )
        : isSummaryFallback(summary)
        ? const ChapterAIStatus.fallback(
            ChapterAIFeature.summary,
            'AI 返回了非结构化内容，已显示安全 fallback。',
          )
        : const ChapterAIStatus.generated(ChapterAIFeature.summary, '章节总结已生成。');
  }

  factory ChapterAIStatus.fromPreview(AIChapterPreview preview) {
    return isPreviewFallback(preview)
        ? const ChapterAIStatus.fallback(
            ChapterAIFeature.preview,
            'AI 返回了非结构化内容，已显示安全 fallback。',
          )
        : const ChapterAIStatus.generated(ChapterAIFeature.preview, '读前预览已生成。');
  }

  factory ChapterAIStatus.fromPractice(AIPracticeSet practice) {
    return isPracticeFallback(practice)
        ? const ChapterAIStatus.fallback(
            ChapterAIFeature.practice,
            'AI 返回了非结构化内容，已显示安全 fallback。',
          )
        : const ChapterAIStatus.generated(ChapterAIFeature.practice, '练习题已生成。');
  }

  static bool isSummaryFallback(AISummary summary) {
    return summary.events.isEmpty &&
        summary.characterDevelopments.isEmpty &&
        summary.keyVocabulary.isEmpty &&
        summary.readingGuidance.contains('AI 返回了非结构化内容');
  }

  static bool isPreviewFallback(AIChapterPreview preview) {
    return preview.setup.contains('AI 返回了非结构化读前预览') ||
        preview.spoilerBoundaryNote.toLowerCase().contains('fallback');
  }

  static bool isPracticeFallback(AIPracticeSet practice) {
    return practice.questions.length == 1 &&
        practice.questions.first.question.contains('AI 返回了非结构化练习内容');
  }
}

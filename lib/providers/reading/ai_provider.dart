import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ai_chapter_preview.dart';
import '../../models/ai_summary.dart';
import '../../models/chapter_ai_coverage.dart';
import '../../models/chapter_ai_status.dart';
import '../reading_provider.dart';
import 'reading_provider_riverpod.dart';

class AIController {
  const AIController(this._reader);

  final ReadingProvider _reader;

  AISummary? get aiSummary => _reader.aiSummary;
  AIChapterPreview? get aiChapterPreview => _reader.aiChapterPreview;
  ChapterAIStatus? get chapterAIStatus => _reader.chapterAIStatus;
  ChapterAISummaryCoverage? get chapterAISummaryCoverage =>
      _reader.chapterAISummaryCoverage;
  bool get isGeneratingSummary => _reader.isGeneratingSummary;
  bool get isGeneratingChapterPreview => _reader.isGeneratingChapterPreview;
  bool get isLoadingChapterAISummaryCoverage =>
      _reader.isLoadingChapterAISummaryCoverage;
  int get currentChapter => _reader.currentChapter;
  String get summaryLanguage => _reader.summaryLanguage;

  Future<void> refreshChapterAISummaryCoverage() {
    return _reader.refreshChapterAISummaryCoverage();
  }

  Future<void> generateChapterPreview() {
    return _reader.generateChapterPreview();
  }

  Future<void> generateSummary() {
    return _reader.generateSummary();
  }

  Future<void> generatePractice() {
    return _reader.generatePractice();
  }

  void toggleSummaryLanguage() {
    _reader.toggleSummaryLanguage();
  }
}

final aiProvider = Provider<AIController>((ref) {
  return AIController(ref.watch(readingProvider));
});

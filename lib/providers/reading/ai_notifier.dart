import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ai_chapter_preview.dart';
import '../../models/ai_practice_questions.dart';
import '../../models/ai_summary.dart';
import '../../models/ai_text_analysis.dart';
import '../../models/chapter_ai_coverage.dart';
import '../../models/chapter_ai_status.dart';
import '../../models/word_analysis.dart';
import '../../services/ai_cache_service.dart';
import '../../services/ai_service.dart';
import '../../services/app_logger.dart';
import '../../services/chapter_ai_job.dart';
import '../../services/passage_request_builder.dart';
import '../../services/prompt_builder.dart';
import '../reading_provider.dart';
import '../settings_provider.dart';
import 'reading_provider_riverpod.dart';
import 'services_provider.dart';

@immutable
class AIState {
  const AIState({
    this.aiTextAnalysis,
    this.isAnalyzingText = false,
    this.aiTranslation,
    this.isTranslatingText = false,
    this.aiSummary,
    this.isGeneratingSummary = false,
    this.aiChapterPreview,
    this.isGeneratingChapterPreview = false,
    this.chapterAIStatus,
    this.chapterAISummaryCoverage,
    this.isLoadingChapterAISummaryCoverage = false,
    this.summaryLanguage = 'zh',
    this.aiPractice,
    this.isGeneratingPractice = false,
    this.aiWordAnalysis,
    this.isAnalyzingWord = false,
    this.errorMessage,
  });

  final AITextAnalysis? aiTextAnalysis;
  final bool isAnalyzingText;
  final String? aiTranslation;
  final bool isTranslatingText;
  final AISummary? aiSummary;
  final bool isGeneratingSummary;
  final AIChapterPreview? aiChapterPreview;
  final bool isGeneratingChapterPreview;
  final ChapterAIStatus? chapterAIStatus;
  final ChapterAISummaryCoverage? chapterAISummaryCoverage;
  final bool isLoadingChapterAISummaryCoverage;
  final String summaryLanguage;
  final AIPracticeSet? aiPractice;
  final bool isGeneratingPractice;
  final WordAnalysis? aiWordAnalysis;
  final bool isAnalyzingWord;
  final String? errorMessage;

  AIState copyWith({
    AITextAnalysis? aiTextAnalysis,
    bool? isAnalyzingText,
    String? aiTranslation,
    bool? isTranslatingText,
    AISummary? aiSummary,
    bool? isGeneratingSummary,
    AIChapterPreview? aiChapterPreview,
    bool? isGeneratingChapterPreview,
    ChapterAIStatus? chapterAIStatus,
    ChapterAISummaryCoverage? chapterAISummaryCoverage,
    bool? isLoadingChapterAISummaryCoverage,
    String? summaryLanguage,
    AIPracticeSet? aiPractice,
    bool? isGeneratingPractice,
    WordAnalysis? aiWordAnalysis,
    bool? isAnalyzingWord,
    String? errorMessage,
    bool clearAIResults = false,
    bool clearError = false,
  }) {
    if (clearAIResults) {
      return AIState(
        summaryLanguage: summaryLanguage ?? this.summaryLanguage,
      );
    }
    return AIState(
      aiTextAnalysis: aiTextAnalysis ?? this.aiTextAnalysis,
      isAnalyzingText: isAnalyzingText ?? this.isAnalyzingText,
      aiTranslation: aiTranslation ?? this.aiTranslation,
      isTranslatingText: isTranslatingText ?? this.isTranslatingText,
      aiSummary: aiSummary ?? this.aiSummary,
      isGeneratingSummary: isGeneratingSummary ?? this.isGeneratingSummary,
      aiChapterPreview: aiChapterPreview ?? this.aiChapterPreview,
      isGeneratingChapterPreview: isGeneratingChapterPreview ?? this.isGeneratingChapterPreview,
      chapterAIStatus: chapterAIStatus ?? this.chapterAIStatus,
      chapterAISummaryCoverage: chapterAISummaryCoverage ?? this.chapterAISummaryCoverage,
      isLoadingChapterAISummaryCoverage: isLoadingChapterAISummaryCoverage ?? this.isLoadingChapterAISummaryCoverage,
      summaryLanguage: summaryLanguage ?? this.summaryLanguage,
      aiPractice: aiPractice ?? this.aiPractice,
      isGeneratingPractice: isGeneratingPractice ?? this.isGeneratingPractice,
      aiWordAnalysis: aiWordAnalysis ?? this.aiWordAnalysis,
      isAnalyzingWord: isAnalyzingWord ?? this.isAnalyzingWord,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AIState &&
        other.isAnalyzingText == isAnalyzingText &&
        other.isGeneratingSummary == isGeneratingSummary &&
        other.isGeneratingChapterPreview == isGeneratingChapterPreview &&
        other.isGeneratingPractice == isGeneratingPractice &&
        other.isAnalyzingWord == isAnalyzingWord &&
        other.isLoadingChapterAISummaryCoverage == isLoadingChapterAISummaryCoverage &&
        other.summaryLanguage == summaryLanguage &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
        isAnalyzingText,
        isGeneratingSummary,
        isGeneratingChapterPreview,
        isGeneratingPractice,
        isAnalyzingWord,
        isLoadingChapterAISummaryCoverage,
        summaryLanguage,
        errorMessage,
      );
}

class AINotifier extends Notifier<AIState> {
  static const _chapterPreviewMaxLength = 1400;
  final PassageRequestBuilder _passageRequestBuilder =
      const PassageRequestBuilder();

  AIService? get _aiService => ref.read(aiServiceProvider);
  AICacheService? get _aiCache => ref.read(aiCacheServiceProvider);

  @override
  AIState build() {
    final reader = ref.watch(readingProvider);
    return AIState(
      aiTextAnalysis: reader.aiTextAnalysis,
      isAnalyzingText: reader.isAnalyzingText,
      aiTranslation: reader.aiTranslation,
      isTranslatingText: reader.isTranslatingText,
      aiSummary: reader.aiSummary,
      isGeneratingSummary: reader.isGeneratingSummary,
      aiChapterPreview: reader.aiChapterPreview,
      isGeneratingChapterPreview: reader.isGeneratingChapterPreview,
      chapterAIStatus: reader.chapterAIStatus,
      chapterAISummaryCoverage: reader.chapterAISummaryCoverage,
      isLoadingChapterAISummaryCoverage:
          reader.isLoadingChapterAISummaryCoverage,
      summaryLanguage: reader.summaryLanguage,
      aiPractice: reader.aiPractice,
      isGeneratingPractice: reader.isGeneratingPractice,
      aiWordAnalysis: reader.aiWordAnalysis,
      isAnalyzingWord: reader.isAnalyzingWord,
    );
  }

  Future<void> analyzeSelectedTextAI(String text, {String? sourceText}) async {
    final reader = ref.read(readingProvider);
    if (!_ensureAIReady(reader)) return;
    final request = _passageRequestBuilder.buildSelectedTextAnalysis(
      selectedText: text,
      sourceText: sourceText ?? reader.result?.passageText ?? text,
    );

    state = state.copyWith(
      isAnalyzingText: true,
      aiTextAnalysis: null,
      aiTranslation: null,
      clearError: true,
    );
    try {
      final analysis = await _aiService!.analyzeText(
        selectedText: request.selectedText,
        currentPassage: request.currentPassage,
        sourceLanguage: request.sourceLanguage,
        outputLanguage: OutputLanguage.fromCode(reader.effectiveTargetExplanationLanguage),
        spoilerBoundary: request.spoilerBoundary,
      );
      ref.read(settingsProvider).incrementAIUsage(textAnalysis: true);
      if (state.isAnalyzingText) {
        state = state.copyWith(
          aiTextAnalysis: analysis,
          isAnalyzingText: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'AI 解析失败: $e',
        isAnalyzingText: false,
      );
    }
  }

  Future<void> translateSelectedTextAI(String text) async {
    final reader = ref.read(readingProvider);
    if (!_ensureAIReady(reader)) return;
    state = state.copyWith(
      isTranslatingText: true,
      aiTranslation: null,
      clearError: true,
    );
    try {
      final translation = await _aiService!.translateText(
        text,
        sourceLanguage: SourceLanguage.inferFromText(text),
        outputLanguage: OutputLanguage.fromCode(reader.effectiveTargetExplanationLanguage),
        spoilerBoundary: SpoilerBoundary.currentPassage(),
      );
      if (state.isTranslatingText) {
        state = state.copyWith(
          aiTranslation: translation,
          isTranslatingText: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: '翻译失败: $e',
        isTranslatingText: false,
      );
    }
  }

  Future<void> generateSummary() async {
    final reader = ref.read(readingProvider);
    if (reader.result == null || !_ensureAIReady(reader)) return;
    final bookId = reader.activeBookId;
    if (bookId == null) return;

    state = state.copyWith(
      isGeneratingSummary: true,
      aiSummary: null,
      chapterAIStatus: null,
    );
    try {
      final result = await _createChapterAIJob(reader).generateSummary(
        ChapterSummaryJobRequest(
          bookId: bookId,
          chapterIndex: reader.currentChapter,
          chapterText: reader.result!.passageText,
          vocabulary: reader.result!.vocabulary.map((v) => v.word).toList(),
          outputLanguage: OutputLanguage.fromCode(state.summaryLanguage),
        ),
      );
      state = state.copyWith(
        aiSummary: result.summary,
        chapterAIStatus: result.status,
        isGeneratingSummary: false,
      );
      await _refreshChapterAISummaryCoverage(reader);
    } catch (e) {
      state = state.copyWith(
        errorMessage: '生成总结失败: $e',
        chapterAIStatus: ChapterAIStatus.failed(
          ChapterAIFeature.summary,
          '章节总结生成失败：$e',
        ),
        isGeneratingSummary: false,
      );
    }
  }

  Future<void> generateChapterPreview() async {
    final reader = ref.read(readingProvider);
    if (reader.result == null || reader.book == null || !_ensureAIReady(reader)) return;
    final bookId = reader.activeBookId;
    if (bookId == null) return;

    state = state.copyWith(
      isGeneratingChapterPreview: true,
      aiChapterPreview: null,
      chapterAIStatus: null,
    );
    try {
      final chapter = reader.book!.chapters[reader.currentChapter];
      final chapterText = reader.result!.passageText;
      final openingText = _chapterPreviewOpening(chapterText);
      final sourceLanguage = SourceLanguage.inferFromText(openingText);
      final outputLanguage = OutputLanguage.fromCode(reader.effectiveTargetExplanationLanguage);
      final vocabulary = reader.result!.vocabulary.map((v) => v.word).toList();
      final contentHash = AICacheService.contentHashFor(
        jsonEncode({
          'title': chapter.title,
          'openingText': openingText,
          'vocabulary': vocabulary.take(20).toList(),
        }),
      );

      if (_aiCache != null && _aiService != null) {
        final cacheJson = await _aiCache!.loadChapterPreview(
          bookId,
          reader.currentChapter,
          contentHash: contentHash,
          promptVersion: _aiService!.promptVersion,
          sourceLanguage: sourceLanguage.code,
          outputLanguage: outputLanguage.code,
        );
        if (cacheJson != null) {
          state = state.copyWith(
            aiChapterPreview: AIChapterPreview.fromJson(
              jsonDecode(cacheJson) as Map<String, dynamic>,
            ),
            chapterAIStatus: const ChapterAIStatus.cacheHit(
              ChapterAIFeature.preview,
              '已读取缓存的读前预览。',
            ),
            isGeneratingChapterPreview: false,
          );
          return;
        }
      }

      final preview = await _aiService!.generateChapterPreview(
        chapterTitle: chapter.title,
        openingText: openingText,
        vocabulary: vocabulary,
        sourceLanguage: sourceLanguage,
        outputLanguage: outputLanguage,
        spoilerBoundary: SpoilerBoundary.chapter(
          bookId: bookId,
          chapterIndex: reader.currentChapter,
        ),
      );
      state = state.copyWith(
        aiChapterPreview: preview,
        chapterAIStatus: ChapterAIStatus.fromPreview(preview),
        isGeneratingChapterPreview: false,
      );
      if (_aiCache != null && _aiService != null) {
        await _aiCache!.saveChapterPreview(
          bookId,
          reader.currentChapter,
          jsonEncode(preview.toJson()),
          contentHash: contentHash,
          promptVersion: _aiService!.promptVersion,
          sourceLanguage: sourceLanguage.code,
          outputLanguage: outputLanguage.code,
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: '生成读前预览失败: $e',
        chapterAIStatus: ChapterAIStatus.failed(
          ChapterAIFeature.preview,
          '读前预览生成失败：$e',
        ),
        isGeneratingChapterPreview: false,
      );
    }
  }

  void toggleSummaryLanguage() {
    state = state.copyWith(
      summaryLanguage: state.summaryLanguage == 'zh' ? 'en' : 'zh',
      aiSummary: null,
      chapterAIStatus: null,
    );
  }

  Future<void> generatePractice() async {
    final reader = ref.read(readingProvider);
    if (reader.result == null || !_ensureAIReady(reader)) return;
    final bookId = reader.activeBookId;
    if (bookId == null) return;

    state = state.copyWith(
      isGeneratingPractice: true,
      aiPractice: null,
      chapterAIStatus: null,
    );
    try {
      final result = await _createChapterAIJob(reader).generatePractice(
        ChapterPracticeJobRequest(
          bookId: bookId,
          chapterIndex: reader.currentChapter,
          chapterText: reader.result!.passageText,
          vocabulary: reader.result!.vocabulary.map((v) => v.word).toList(),
          events: state.aiSummary?.events ?? const [],
        ),
      );
      state = state.copyWith(
        aiPractice: result.practice,
        chapterAIStatus: result.status,
        isGeneratingPractice: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: '生成练习题失败: $e',
        chapterAIStatus: ChapterAIStatus.failed(
          ChapterAIFeature.practice,
          '练习题生成失败：$e',
        ),
        isGeneratingPractice: false,
      );
    }
  }

  Future<void> analyzeWordAI(String word, String sentence) async {
    final reader = ref.read(readingProvider);
    final currentResult = reader.result;
    if (currentResult == null || !_ensureAIReady(reader)) return;
    final chapterText = currentResult.passageText;
    final sourceLanguage = SourceLanguage.inferFromText('$sentence $chapterText');
    final outputLanguage =
        OutputLanguage.fromCode(reader.effectiveTargetExplanationLanguage);
    final contentHash = AICacheService.contentHashFor(
      jsonEncode({
        'word': word.trim().toLowerCase(),
        'sentence': sentence.trim(),
        'chapterText': chapterText,
      }),
    );
    final cacheBookId = reader.activeBookId ?? 'word-analysis';
    final cacheChapterIndex = reader.currentChapter;

    if (_aiCache != null && _aiService != null) {
      try {
        final cacheJson = await _aiCache!.loadWordAnalysis(
          cacheBookId,
          cacheChapterIndex,
          contentHash: contentHash,
          promptVersion: _aiService!.promptVersion,
          sourceLanguage: sourceLanguage.code,
          outputLanguage: outputLanguage.code,
        );
        if (cacheJson != null) {
          state = state.copyWith(
            aiWordAnalysis: WordAnalysis.fromJson(
              jsonDecode(cacheJson) as Map<String, dynamic>,
            ),
            isAnalyzingWord: false,
          );
          return;
        }
      } catch (_) {}
    }

    state = state.copyWith(isAnalyzingWord: true, aiWordAnalysis: null);
    try {
      final analysis = await _aiService!.analyzeWord(
        word: word,
        sentence: sentence,
        chapterContext: chapterText,
        sourceLanguage: sourceLanguage,
        outputLanguage: outputLanguage,
        spoilerBoundary: SpoilerBoundary.currentPassage(),
      );
      ref.read(settingsProvider).incrementAIUsage(wordAnalysis: true);
      state = state.copyWith(
        aiWordAnalysis: analysis,
        isAnalyzingWord: false,
      );
      if (_aiCache != null && _aiService != null) {
        await _aiCache!.saveWordAnalysis(
          cacheBookId,
          cacheChapterIndex,
          jsonEncode(analysis.toJson()),
          contentHash: contentHash,
          promptVersion: _aiService!.promptVersion,
          sourceLanguage: sourceLanguage.code,
          outputLanguage: outputLanguage.code,
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'AI 单词解析失败: $e',
        isAnalyzingWord: false,
      );
    }
  }

  void clearAIResults() {
    state = state.copyWith(clearAIResults: true);
  }

  Future<void> clearAICache() async {
    final reader = ref.read(readingProvider);
    await _aiCache?.clearAllCache();
    final totalChapters = reader.book?.chapters.length;
    state = state.copyWith(
      chapterAISummaryCoverage: totalChapters == null
          ? null
          : ChapterAISummaryCoverage(
              totalChapters: totalChapters,
              generatedChapterIndexes: const [],
            ),
    );
  }

  Future<void> refreshChapterAISummaryCoverage() {
    final reader = ref.read(readingProvider);
    return _refreshChapterAISummaryCoverage(reader, notify: true);
  }

  bool _ensureAIReady(ReadingProvider reader) {
    if (_aiService == null) {
      state = state.copyWith(errorMessage: 'AI 服务未初始化');
      return false;
    }
    if (!reader.aiFeaturesEnabled) {
      state = state.copyWith(errorMessage: reader.aiFeatureDisabledReason);
      return false;
    }
    return true;
  }

  ChapterAIJob _createChapterAIJob(ReadingProvider reader) {
    return ChapterAIJob.fromServices(
      aiService: _aiService!,
      cache: _aiCache,
      settings: ref.read(settingsProvider),
    );
  }

  String _chapterPreviewOpening(String chapterText) {
    final trimmed = chapterText.trim();
    if (trimmed.length <= _chapterPreviewMaxLength) return trimmed;
    return trimmed.substring(0, _chapterPreviewMaxLength).trim();
  }

  Future<void> _refreshChapterAISummaryCoverage(
    ReadingProvider reader, {
    bool notify = true,
  }) async {
    final aiCache = _aiCache;
    final bookId = reader.activeBookId;
    final totalChapters = reader.book?.chapters.length;
    if (aiCache == null || bookId == null || totalChapters == null) {
      state = state.copyWith(
        chapterAISummaryCoverage: null,
        isLoadingChapterAISummaryCoverage: false,
      );
      return;
    }

    if (notify) {
      state = state.copyWith(isLoadingChapterAISummaryCoverage: true);
    }

    try {
      final coverage = await aiCache.summaryCoverageFor(
        bookId,
        totalChapters: totalChapters,
      );
      if (reader.activeBookId == bookId &&
          reader.book?.chapters.length == totalChapters) {
        state = state.copyWith(
          chapterAISummaryCoverage: coverage,
          isLoadingChapterAISummaryCoverage: false,
        );
      } else {
        state = state.copyWith(isLoadingChapterAISummaryCoverage: false);
      }
    } catch (e, stackTrace) {
      AppLogger.instance.event(
        'ai.summary_coverage_failed',
        level: AppLogLevel.warning,
        source: 'ai',
        metadata: {'bookId': bookId},
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(isLoadingChapterAISummaryCoverage: false);
    }
  }
}

final aiNotifierProvider =
    NotifierProvider<AINotifier, AIState>(AINotifier.new);

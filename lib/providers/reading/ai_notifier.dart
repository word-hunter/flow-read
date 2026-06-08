import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ai_chapter_preview.dart';
import '../../models/ai_practice_questions.dart';
import '../../models/ai_summary.dart';
import '../../models/ai_text_analysis.dart';
import '../../models/book_metadata.dart';
import '../../models/chapter_ai_coverage.dart';
import '../../models/chapter_ai_status.dart';
import '../../models/learning_item.dart';
import '../../models/word_analysis.dart';
import '../../services/ai_cache_service.dart';
import '../../services/ai_service.dart';
import '../../services/app_logger.dart';
import '../../services/chapter_ai_job.dart';
import '../../services/learning_item_service.dart';
import '../../services/passage_request_builder.dart';
import '../../services/prompt_builder.dart';
import '../../services/settings_service.dart';
import '../settings_provider.dart';
import 'bookshelf_notifier.dart';
import 'current_book_notifier.dart';
import 'services_provider.dart';
import 'text_selection_notifier.dart';

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
      isGeneratingChapterPreview:
          isGeneratingChapterPreview ?? this.isGeneratingChapterPreview,
      chapterAIStatus: chapterAIStatus ?? this.chapterAIStatus,
      chapterAISummaryCoverage:
          chapterAISummaryCoverage ?? this.chapterAISummaryCoverage,
      isLoadingChapterAISummaryCoverage:
          isLoadingChapterAISummaryCoverage ??
              this.isLoadingChapterAISummaryCoverage,
      summaryLanguage: summaryLanguage ?? this.summaryLanguage,
      aiPractice: aiPractice ?? this.aiPractice,
      isGeneratingPractice:
          isGeneratingPractice ?? this.isGeneratingPractice,
      aiWordAnalysis: aiWordAnalysis ?? this.aiWordAnalysis,
      isAnalyzingWord: isAnalyzingWord ?? this.isAnalyzingWord,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AINotifier extends Notifier<AIState> {
  static const _chapterPreviewMaxLength = 1400;

  AIService? get _aiService => ref.read(aiServiceProvider);
  AICacheService? get _aiCache => ref.read(aiCacheServiceProvider);
  SettingsService get _settings => ref.read(settingsProvider);
  LearningItemService? get _learningItemService =>
      ref.read(learningItemServiceProvider);

  String? get _activeBookId => ref.read(bookshelfNotifierProvider).activeBookId;
  int get _currentChapter =>
      ref.read(currentBookNotifierProvider).currentChapter;

  @override
  AIState build() => const AIState();

  bool get aiFeaturesEnabled =>
      _aiService != null && _settings.aiFeaturesEnabled;

  String get aiFeatureDisabledReason => _settings.aiFeatureDisabledReason;

  String get effectiveTargetExplanationLanguage {
    final activeBookId = _activeBookId;
    var globalLanguage = _settings.targetExplanationLanguage;
    if (activeBookId != null) {
      final bookService = ref.read(bookServiceProvider);
      final active = bookService.books
          .where((b) => b.id == activeBookId)
          .firstOrNull;
      final lang = active?.effectiveTargetExplanationLanguage(globalLanguage);
      if (lang != null) return lang;
    }
    return globalLanguage;
  }

  bool _ensureAIReady() {
    if (_aiService == null) {
      state = state.copyWith(errorMessage: 'AI 服务未初始化');
      return false;
    }
    if (!aiFeaturesEnabled) {
      state = state.copyWith(errorMessage: aiFeatureDisabledReason);
      return false;
    }
    return true;
  }

  // ---- Delegation helpers ----

  void _syncTextAnalysis(AITextAnalysis? analysis, {bool analyzing = false}) {
    state = state.copyWith(
      aiTextAnalysis: analysis,
      isAnalyzingText: analyzing,
    );
  }

  void _syncTranslation(String? translation, {bool translating = false}) {
    state = state.copyWith(
      aiTranslation: translation,
      isTranslatingText: translating,
    );
  }

  void _syncWordAnalysis(WordAnalysis? analysis, {bool analyzing = false}) {
    state = state.copyWith(
      aiWordAnalysis: analysis,
      isAnalyzingWord: analyzing,
    );
  }

  // ---- Text Analysis & Translation ----

  Future<void> analyzeSelectedTextAI(String text, {String? sourceText}) async {
    if (!_ensureAIReady()) return;
    final ai = _aiService;
    if (ai == null) return;
    final currentResult = ref.read(currentBookNotifierProvider).result;
    final request = PassageRequestBuilder().buildSelectedTextAnalysis(
      selectedText: text,
      sourceText: sourceText ?? currentResult?.passageText ?? text,
    );

    state = state.copyWith(
      isAnalyzingText: true,
      aiTextAnalysis: null,
      aiTranslation: null,
      clearError: true,
    );
    try {
      final analysis = await ai.analyzeText(
        selectedText: request.selectedText,
        currentPassage: request.currentPassage,
        sourceLanguage: request.sourceLanguage,
        outputLanguage:
            OutputLanguage.fromCode(effectiveTargetExplanationLanguage),
        spoilerBoundary: request.spoilerBoundary,
      );
      _settings.incrementAIUsage(textAnalysis: true);
      if (state.isAnalyzingText) {
        state = state.copyWith(
          aiTextAnalysis: analysis,
          isAnalyzingText: false,
        );
      }
    } catch (e) {
      debugPrint('[AI] analyzeText failed: $e');
      state = state.copyWith(
        errorMessage: 'AI 解析失败: $e',
        isAnalyzingText: false,
      );
    }
  }

  Future<void> translateSelectedTextAI(String text) async {
    if (!_ensureAIReady()) return;
    final ai = _aiService;
    if (ai == null) return;
    state = state.copyWith(
      isTranslatingText: true,
      aiTranslation: null,
      clearError: true,
    );
    try {
      final translation = await ai.translateText(
        text,
        sourceLanguage: SourceLanguage.inferFromText(text),
        outputLanguage:
            OutputLanguage.fromCode(effectiveTargetExplanationLanguage),
        spoilerBoundary: SpoilerBoundary.currentPassage(),
      );
      if (state.isTranslatingText) {
        state = state.copyWith(
          aiTranslation: translation,
          isTranslatingText: false,
        );
      }
    } catch (e) {
      debugPrint('[AI] translateText failed: $e');
      state = state.copyWith(
        errorMessage: '翻译失败: $e',
        isTranslatingText: false,
      );
    }
  }

  Future<LearningItemSaveResult?> addAIGrammarLearningItem(
    GrammarPoint point,
  ) async {
    final service = _learningItemService;
    final selectedText =
        ref.read(textSelectionNotifierProvider).selectedText?.trim();
    if (service == null || selectedText == null || selectedText.isEmpty) {
      return null;
    }
    return service.saveDraft(
      LearningItemDraft.grammarPoint(
        point: point,
        selectedText: selectedText,
        source: _currentLearningItemSource(),
      ),
    );
  }

  Future<LearningItemSaveResult?> addAIVocabularyLearningItem(
    VocabularyNote note,
  ) async {
    final service = _learningItemService;
    final selectedText =
        ref.read(textSelectionNotifierProvider).selectedText?.trim();
    if (service == null || selectedText == null || selectedText.isEmpty) {
      return null;
    }
    return service.saveDraft(
      LearningItemDraft.vocabularyNote(
        note: note,
        selectedText: selectedText,
        source: _currentLearningItemSource(),
      ),
    );
  }

  Future<LearningItemSaveResult?> addAIExpressionLearningItem(
    ExpressionNote note,
  ) async {
    final service = _learningItemService;
    final selectedText =
        ref.read(textSelectionNotifierProvider).selectedText?.trim();
    if (service == null || selectedText == null || selectedText.isEmpty) {
      return null;
    }
    return service.saveDraft(
      LearningItemDraft.expressionNote(
        note: note,
        selectedText: selectedText,
        source: _currentLearningItemSource(),
      ),
    );
  }

  // ---- Practice ----

  Future<void> generatePractice() async {
    final currentResult = ref.read(currentBookNotifierProvider).result;
    if (currentResult == null || !_ensureAIReady()) return;
    final bookId = _activeBookId;
    if (bookId == null) return;

    state = state.copyWith(
      isGeneratingPractice: true,
      aiPractice: null,
      chapterAIStatus: null,
    );
    try {
      final result = await _createChapterAIJob().generatePractice(
        ChapterPracticeJobRequest(
          bookId: bookId,
          chapterIndex: _currentChapter,
          chapterText: currentResult.passageText,
          vocabulary:
              currentResult.vocabulary.map((v) => v.word).toList(),
          events: state.aiSummary?.events ?? const [],
        ),
      );
      state = state.copyWith(
        aiPractice: result.practice,
        chapterAIStatus: result.status,
        isGeneratingPractice: false,
      );
    } catch (e) {
      debugPrint('[AI] generatePractice failed: $e');
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

  // ---- Word Analysis ----

  Future<void> analyzeWordAI(String word, String sentence) async {
    final currentResult = ref.read(currentBookNotifierProvider).result;
    if (currentResult == null || !_ensureAIReady()) return;
    final chapterText = currentResult.passageText;
    final sourceLanguage =
        SourceLanguage.inferFromText('$sentence $chapterText');
    final outputLanguage =
        OutputLanguage.fromCode(effectiveTargetExplanationLanguage);
    final contentHash = AICacheService.contentHashFor(
      jsonEncode({
        'word': word.trim().toLowerCase(),
        'sentence': sentence.trim(),
        'chapterText': chapterText,
      }),
    );
    const cacheBookId = 'word-analysis';
    final cacheChapterIndex = _currentChapter;

    final aiForCache = _aiService;
    final cacheForLookup = _aiCache;
    if (aiForCache != null && cacheForLookup != null) {
      try {
        final cacheJson = await cacheForLookup.loadWordAnalysis(
          cacheBookId,
          cacheChapterIndex,
          contentHash: contentHash,
          promptVersion: aiForCache.promptVersion,
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
      } catch (_) {
        debugPrint('[AI] word analysis cache lookup failed');
      }
    }

    final ai = _aiService;
    if (ai == null) return;
    state = state.copyWith(isAnalyzingWord: true, aiWordAnalysis: null);
    try {
      final analysis = await ai.analyzeWord(
        word: word,
        sentence: sentence,
        chapterContext: chapterText,
        sourceLanguage: sourceLanguage,
        outputLanguage: outputLanguage,
        spoilerBoundary: SpoilerBoundary.currentPassage(),
      );
      _settings.incrementAIUsage(wordAnalysis: true);
      state = state.copyWith(
        aiWordAnalysis: analysis,
        isAnalyzingWord: false,
      );
      if (cacheForLookup != null) {
        await cacheForLookup.saveWordAnalysis(
          cacheBookId,
          cacheChapterIndex,
          jsonEncode(analysis.toJson()),
          contentHash: contentHash,
          promptVersion: ai.promptVersion,
          sourceLanguage: sourceLanguage.code,
          outputLanguage: outputLanguage.code,
        );
      }
    } catch (e) {
      debugPrint('[AI] analyzeWord failed: $e');
      state = state.copyWith(
        errorMessage: 'AI 单词解析失败: $e',
        isAnalyzingWord: false,
      );
    }
  }

  // ---- Chapter AI ----

  Future<void> generateSummary() async {
    final currentResult = ref.read(currentBookNotifierProvider).result;
    if (currentResult == null || !_ensureAIReady()) return;
    final bookId = _activeBookId;
    if (bookId == null) return;

    state = state.copyWith(
      isGeneratingSummary: true,
      aiSummary: null,
      chapterAIStatus: null,
    );
    try {
      final result = await _createChapterAIJob().generateSummary(
        ChapterSummaryJobRequest(
          bookId: bookId,
          chapterIndex: _currentChapter,
          chapterText: currentResult.passageText,
          vocabulary:
              currentResult.vocabulary.map((v) => v.word).toList(),
          outputLanguage: OutputLanguage.fromCode(state.summaryLanguage),
        ),
      );
      state = state.copyWith(
        aiSummary: result.summary,
        chapterAIStatus: result.status,
        isGeneratingSummary: false,
      );
      await _refreshChapterAISummaryCoverage();
    } catch (e) {
      debugPrint('[AI] generateSummary failed: $e');
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
    final currentResult = ref.read(currentBookNotifierProvider).result;
    final book = ref.read(bookshelfNotifierProvider).book;
    if (currentResult == null || book == null || !_ensureAIReady()) return;
    final bookId = _activeBookId;
    if (bookId == null) return;

    state = state.copyWith(
      isGeneratingChapterPreview: true,
      aiChapterPreview: null,
      chapterAIStatus: null,
    );
    try {
      final chapter = book.chapters[_currentChapter];
      final chapterText = currentResult.passageText;
      final openingText = _chapterPreviewOpening(chapterText);
      final sourceLanguage = SourceLanguage.inferFromText(openingText);
      final outputLanguage =
          OutputLanguage.fromCode(effectiveTargetExplanationLanguage);
      final vocabulary =
          currentResult.vocabulary.map((v) => v.word).toList();
      final contentHash = AICacheService.contentHashFor(
        jsonEncode({
          'title': chapter.title,
          'openingText': openingText,
          'vocabulary': vocabulary.take(20).toList(),
        }),
      );

      final ai = _aiService;
      final cache = _aiCache;
      if (ai != null && cache != null) {
        final cacheJson = await cache.loadChapterPreview(
          bookId,
          _currentChapter,
          contentHash: contentHash,
          promptVersion: ai.promptVersion,
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

      if (ai == null) return;
      final preview = await ai.generateChapterPreview(
        chapterTitle: chapter.title,
        openingText: openingText,
        vocabulary: vocabulary,
        sourceLanguage: sourceLanguage,
        outputLanguage: outputLanguage,
        spoilerBoundary: SpoilerBoundary.chapter(
          bookId: bookId,
          chapterIndex: _currentChapter,
        ),
      );
      state = state.copyWith(
        aiChapterPreview: preview,
        chapterAIStatus: ChapterAIStatus.fromPreview(preview),
        isGeneratingChapterPreview: false,
      );
      if (cache != null) {
        await cache.saveChapterPreview(
          bookId,
          _currentChapter,
          jsonEncode(preview.toJson()),
          contentHash: contentHash,
          promptVersion: ai.promptVersion,
          sourceLanguage: sourceLanguage.code,
          outputLanguage: outputLanguage.code,
        );
      }
    } catch (e) {
      debugPrint('[AI] generateChapterPreview failed: $e');
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

  void clearAIResults() {
    state = state.copyWith(clearAIResults: true);
  }

  Future<void> clearAICache() async {
    await _aiCache?.clearAllCache();
    final totalChapters =
        ref.read(bookshelfNotifierProvider).book?.chapters.length;
    state = state.copyWith(
      chapterAISummaryCoverage: totalChapters == null
          ? null
          : ChapterAISummaryCoverage(
              totalChapters: totalChapters,
              generatedChapterIndexes: const [],
            ),
    );
  }

  Future<void> refreshChapterAISummaryCoverage() async {
    await _refreshChapterAISummaryCoverage(notify: true);
  }

  // ---- Internal ----

  ChapterAIJob _createChapterAIJob() {
    final ai = _aiService;
    if (ai == null) throw StateError('AI service not initialized');
    return ChapterAIJob.fromServices(
      aiService: ai,
      cache: _aiCache,
      settings: _settings,
    );
  }

  String _chapterPreviewOpening(String chapterText) {
    final trimmed = chapterText.trim();
    if (trimmed.length <= _chapterPreviewMaxLength) return trimmed;
    return trimmed.substring(0, _chapterPreviewMaxLength).trim();
  }

  LearningItemSource _currentLearningItemSource() {
    final bookId = _activeBookId;
    final book = ref.read(bookshelfNotifierProvider).book;
    if (bookId == null || book == null) {
      return const LearningItemSource.unknown();
    }
    final chapter = _currentChapter < book.chapters.length
        ? book.chapters[_currentChapter]
        : null;
    return LearningItemSource(
      bookId: bookId,
      bookTitle: book.title,
      chapterIndex: _currentChapter,
      chapterTitle: chapter?.title ?? '',
    );
  }

  Future<void> _refreshChapterAISummaryCoverage({
    bool notify = true,
  }) async {
    final aiCache = _aiCache;
    final bookId = _activeBookId;
    final totalChapters =
        ref.read(bookshelfNotifierProvider).book?.chapters.length;
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
      if (_activeBookId == bookId &&
          ref.read(bookshelfNotifierProvider).book?.chapters.length ==
              totalChapters) {
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
